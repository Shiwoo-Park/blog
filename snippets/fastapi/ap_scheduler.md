# APScheduler 를 이용하여 API 서버에서 배치돌리기

## main.py

```py
@asynccontextmanager
async def lifespan(app: FastAPI):
    if APSCHEDULER_BATCH_IS_ACTIVE:
        scheduler.start()  # ⏱ APScheduler 시작
        load_app_schedules()  # {APP}/schedules/*.py 순회
        yield  # FastAPI 앱 실행
        scheduler.shutdown(wait=True)  # ⛔ APScheduler 종료 (하던 작업 마무리 후)
    else:
        logger.info(
            "Local, Stage 환경이거나 ECS 내부가 아닌 경우, Batch 스케줄러는 실행하지 않습니다."
        )
        yield


app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    lifespan=lifespan,
    description=read_md_file("docs/index.md"),
    debug=settings.APP_DEBUG is True,
    docs_url=(
        None
        if settings.APP_ENV.lower() == ServiceEnvironment.PROD.value
        else "/swagger"
    ),
    openapi_tags=APIRouterTagsEnum.generate_openapi_tags(),
    responses={
        200: {"description": "성공 응답"},
        401: {
            "description": "인증 오류",
            "model": MessageOut,
            "content": {
                "application/json": {"example": {"message": "인증이 필요합니다."}}
            },
        },
        400: {
            "description": "클라이언트 오류",
            "model": MessageOut,
            "content": {
                "application/json": {
                    "example": {"message": "요청이 올바르지 않습니다."}
                }
            },
        },
        403: {
            "description": "인증 오류",
            "model": MessageOut,
            "content": {
                "application/json": {"example": {"message": "접근 권한이 없습니다."}}
            },
        },
        500: {
            "description": "서버 오류",
            "model": MessageOut,
            "content": {
                "application/json": {
                    "example": {"message": "서버 오류가 발생했습니다."}
                }
            },
        },
    },
)
```

## batch_util.py

```py
import logging
import time
import traceback
from functools import wraps
from typing import Callable

from apscheduler.triggers.base import BaseTrigger

from app.Core.consts.base import (
    APSCHEDULER_BATCH_TASK_TIME_LIMIT_SEC,
)
from app.Core.consts.exc_handler import SLACK_MESSAGE_LIMIT_STACK_TRACE
from app.Core.utils.slack import SlackMessageUtil
from app.cache import Cache

logger = logging.getLogger(__name__)


def with_distributed_lock(lock_key: str, ttl_sec: int):
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            lock_acquired = await Cache.set_lock(lock_key, value="1", expire=ttl_sec)
            if lock_acquired:
                logger.info(
                    f"[batch_schedule] lock_key={lock_key} (TTL={ttl_sec}초) 획득"
                )
                start = time.monotonic()  # ✅ 시작시간 기록
                try:
                    result = await func(*args, **kwargs)
                    return result

                except Exception as e:
                    error_stack_trace = traceback.format_exc()
                    logger.error(
                        f"[batch_schedule] 오류 발생: {e}\n{error_stack_trace}"
                    )

                    text_limit = SLACK_MESSAGE_LIMIT_STACK_TRACE
                    if len(error_stack_trace) > text_limit:
                        error_stack_trace = (
                            "전문생략...\n" + error_stack_trace[-text_limit:]
                        )
                    await SlackMessageUtil.send_formatted_auto(
                        main_message=f"[batch_schedule] 오류 발생: {e}",
                        info_message=f"- lock_key: {lock_key}\n\n- Error Stack: {error_stack_trace}",
                    )

                finally:
                    end = time.monotonic()  # ✅ 종료시간 기록
                    duration = end - start
                    time_limit = APSCHEDULER_BATCH_TASK_TIME_LIMIT_SEC
                    if duration >= APSCHEDULER_BATCH_TASK_TIME_LIMIT_SEC:
                        logger.warning(
                            f"[batch_schedule] {lock_key} 작업이 {duration:.2f}초 소요됨 (지연 경고)"
                        )
                        await SlackMessageUtil.send_formatted_auto(
                            main_message=f"⚠️ [batch_schedule] 작업 지연 경고",
                            info_message=f"- 작업: {lock_key}\n- 소요시간: {duration:.2f}초 ({time_limit}초 초과)",
                        )
            else:
                logger.debug(
                    f"[batch_schedule] lock_key={lock_key} (TTL={ttl_sec}초) 획득 실패"
                )

        return wrapper

    return decorator


def batch_schedule(
    trigger: BaseTrigger | str,
    *,
    job_id: str = None,
    job_name: str = None,
    ttl_sec: int = 5,  # 작업의 중복 트리거 방지용
    replace_existing: bool = True,
):
    """
    스케줄링된 작업을 생성할때 활용되는 decorator

    - APScheduler 작업 + 분산 락 래핑
    - 분산 lock(by Redis): 분산환경에서 중복없이 실행하기위함
    - 분산 lock 을 적용한 이유: FastAPI 어플리케이션 서버에서 스케줄러를 각각 띄우기 때문에
        실행되는 ECS task 개수만큼 스케줄러가 생성되고 중복 task 트리거가 발생함.
        이때 1회만 실제 로직이 실행되도록 처리하기 위함.

    [예제]
    @batch_schedule("interval", minutes=60)
    async def send_hourly_report():
        logger.info("📨 [매시간] 보고서 전송 작업 실행 중")
    """

    def decorator(func: Callable):
        from app.scheduler import scheduler

        # id 자동 생성: "batch.{모듈 경로}.{함수명}"
        _job_id = job_id or f"batch.{func.__module__}.{func.__name__}"
        _job_name = job_name or job_id
        lock_key = f"batch:{_job_id}"

        @with_distributed_lock(lock_key, ttl_sec=ttl_sec)
        @wraps(func)
        async def wrapped(*args, **kwargs):
            return await func(*args, **kwargs)

        # 실제 등록
        scheduler.add_job(
            wrapped,
            trigger=trigger,
            id=_job_id,
            name=_job_name,
            replace_existing=replace_existing,
        )

        return wrapped

    return decorator
```

## scheduler.py

```py
"""
# app/scheduler.py

APScheduler 를 기반으로 간단한 batch 작업을 세팅할 수 있도록 한다.
"""

import glob
import importlib
import logging
import os
import time

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger

from app.Core.decorators.batch_schedule import batch_schedule
from app.config import PROJECT_DIR_PATH

logger = logging.getLogger(__name__)

scheduler = AsyncIOScheduler()


def load_app_schedules():
    base_dir = PROJECT_DIR_PATH
    pattern = os.path.join(base_dir, "**", "schedules", "*.py")
    files = glob.glob(pattern, recursive=True)

    for path in files:
        if os.path.basename(path).startswith("_"):
            continue  # __init__.py 등은 제외

        module_name = (
            path.replace(base_dir + os.sep, "").replace(os.sep, ".").replace(".py", "")
        )

        spec = importlib.util.spec_from_file_location(module_name, path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)


# @batch_schedule(CronTrigger(second=0))
# async def run_every_minute():
#     logger.warning("🔁 [매분 0초] 배치 작업 시작")
#     # time.sleep(3)
#     # logger.info("🔁 [매분 0초] 배치 작업 종료")
#     # raise Exception("Batch Error Test")


@batch_schedule(CronTrigger(minute=30))
async def run_every_hour_at_half():
    logger.warning("🕧 [매시 30분] 배치 작업")


@batch_schedule(CronTrigger(hour=12))
async def run_every_day_noon():
    # 배치 스케줄러 정상동작 확인용
    logger.warning("🕧 [batch] 매일 12:00 배치 작업")
```