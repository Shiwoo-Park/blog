---
layout: post
title: "운영환경에서 Python Celery 설정 가이드"
date: 2026-01-15
categories: [python, celery, backend]
---

운영환경에서 Celery를 안정적으로 운영하기 위해 필요한 핵심 설정값들과 실전 팁을 정리했습니다.

---

## 1. Celery 운영환경 개요

### Celery의 역할

Celery는 비동기 작업 처리 시스템으로, 웹 서버의 응답 시간을 보장하기 위해 시간이 오래 걸리는 작업을 백그라운드에서 처리합니다.

### Web 서버와 분리 운영하는 이유

- **응답 시간 보장**: 웹 요청과 비동기 작업을 분리하여 사용자 경험 향상
- **리소스 독립성**: Worker 프로세스가 메모리 누수나 장시간 실행으로 인해 문제가 생겨도 웹 서버에 영향 없음
- **확장성**: Worker를 독립적으로 스케일링 가능

---

## 2. Broker / Backend 설정

### Message Broker 선택

**Redis (추천)**

- 설정이 간단하고 운영이 쉬움
- Result Backend로도 활용 가능
- 대부분의 경우 Redis로 충분

**RabbitMQ**

- 더 복잡한 라우팅이 필요할 때
- 메시지 지속성이 중요한 경우

### Result Backend 사용 여부

```python
# settings.py
CELERY_RESULT_BACKEND = 'redis://localhost:6379/0'  # Task 결과 저장
CELERY_RESULT_EXPIRES = 3600  # 결과 저장 시간 (초)
```

**사용 시점**: Task 실행 결과를 확인해야 할 때만 사용. 단순히 작업만 수행한다면 생략 가능.

### 연결 안정성 설정

```python
CELERY_BROKER_CONNECTION_RETRY_ON_STARTUP = True
CELERY_BROKER_CONNECTION_RETRY = True
CELERY_BROKER_CONNECTION_MAX_RETRIES = 10
```

---

## 3. Worker 프로세스 설정

### Worker 수 산정 기준

```
Worker 수 = (CPU 코어 수 - 1) ~ (CPU 코어 수 * 2)
```

- I/O 집약적 작업: 더 많은 Worker 가능
- CPU 집약적 작업: CPU 코어 수에 맞춰 설정

### Concurrency 설정

```bash
celery -A myapp worker --concurrency=4
```

- 기본값: CPU 코어 수
- 각 Worker 프로세스 내에서 실행되는 스레드/프로세스 수
- I/O 대기 시간이 긴 작업은 높게 설정 가능

### Prefetch 설정

```python
CELERY_WORKER_PREFETCH_MULTIPLIER = 4  # 기본값: 4
```

- Worker가 한 번에 가져올 Task 수
- **주의**: 너무 높으면 긴 작업이 있는 Worker가 다른 Task를 가져가서 불공평한 분배 발생
- 권장: 1~4 사이

### Acks 설정

```python
CELERY_TASK_ACKS_LATE = True  # Task 완료 후 ACK
CELERY_WORKER_PREFETCH_MULTIPLIER = 1  # Acks Late 사용 시 1 권장
```

- `ACKS_LATE = True`: Task 완료 후에만 ACK → Worker 장애 시 재시도 가능
- `ACKS_LATE = False`: Task 시작 시 ACK → 빠르지만 Worker 장애 시 유실 가능

### 메모리 누수 방지

```python
CELERY_WORKER_MAX_TASKS_PER_CHILD = 1000  # 1000개 Task 후 재시작
CELERY_WORKER_MAX_MEMORY_PER_CHILD = 200000  # 200MB 초과 시 재시작 (KB 단위)
```

**권장 전략**:

- `max_tasks_per_child`: 500~2000 사이
- `worker_max_memory_per_child`: 메모리 사용 패턴에 따라 조정
- 주기적 재시작으로 메모리 누수 방지

---

## 4. Queue & Routing 전략

### Queue 분리 기준

```python
CELERY_TASK_ROUTES = {
    'app.tasks.email.*': {'queue': 'email'},
    'app.tasks.image.*': {'queue': 'image'},
    'app.tasks.critical.*': {'queue': 'critical'},
}
```

**분리 기준**:

- **우선순위**: 긴급한 작업은 별도 Queue
- **리소스 사용**: CPU/메모리 집약적 작업 분리
- **실패 영향도**: 한 작업의 실패가 다른 작업에 영향 주지 않도록

### Priority Queue 활용

```python
CELERY_TASK_ROUTES = {
    'app.tasks.urgent.*': {'queue': 'high_priority'},
}
```

- RabbitMQ는 Priority Queue 지원
- Redis는 기본적으로 지원하지 않지만, 여러 Queue로 분리하여 우선순위 구현 가능

---

## 5. Task 안정성 관련 설정

### Retry 정책

```python
from celery import Task

class MyTask(Task):
    autoretry_for = (Exception,)
    retry_kwargs = {'max_retries': 3, 'countdown': 60}
    retry_backoff = True  # 지수 백오프
    retry_backoff_max = 600  # 최대 600초
    retry_jitter = True  # 재시도 시간에 랜덤성 추가
```

**권장 사항**:

- 일시적 오류만 재시도 (네트워크 오류, 타임아웃 등)
- 영구적 오류는 재시도하지 않음 (ValidationError 등)
- `retry_backoff`로 서버 부하 분산

### Time Limit / Soft Time Limit

```python
from celery.exceptions import SoftTimeLimitExceeded

@celery.task(time_limit=300, soft_time_limit=240)
def my_task():
    try:
        # time_limit: 하드 리밋 (강제 종료)
        # soft_time_limit: 소프트 리밋 (SoftTimeLimitExceeded 예외 발생)
        # Task Logic
        pass
    except SoftTimeLimitExceeded:
        # Graceful 종료 처리
        logger.warning("Task exceeded soft time limit")
        # 정리 작업 수행
        cleanup()
        raise
```

- `soft_time_limit`: 정상 종료 시도 (예외 처리 가능)
- `time_limit`: 강제 종료 (최후의 수단)
- **전역 설정**:
  ```python
  CELERY_TASK_TIME_LIMIT = 300  # 초 단위
  CELERY_TASK_SOFT_TIME_LIMIT = 270  # 초 단위
  ```

### Task 예외 처리

```python
import logging
from celery.utils.log import get_task_logger

logger = get_task_logger(__name__)

@celery.task
def my_task():
    try:
        # Task Logic
        result = do_work()
        logger.info(f"Task completed: {result}")
        return result
    except Exception as e:
        # 예외 로깅
        logger.error(f"Task failed: {e}", exc_info=True)
        # 필요시 재시도를 위해 예외를 다시 던짐
        raise
```

### Idempotency 고려사항

```python
@celery.task(bind=True)
def process_payment(self, order_id):
    # 중복 실행 방지
    if Payment.objects.filter(order_id=order_id).exists():
        return "Already processed"

    # 작업 수행
    process(order_id)
```

- Task가 여러 번 실행되어도 같은 결과가 나오도록 설계
- DB 제약 조건, Redis Lock 등 활용

### Deadlock 방지 (Redis Lock 활용)

```python
import redis
from celery.utils.log import get_task_logger

logger = get_task_logger(__name__)
redis_client = redis.StrictRedis()

@celery.task
def my_task(resource_id):
    lock_key = f"task_lock:{resource_id}"
    lock = redis_client.lock(lock_key, timeout=300)  # 5분 타임아웃

    if not lock.acquire(blocking=False):
        logger.warning(f"Task is already running for resource {resource_id}")
        return "Task already in progress"

    try:
        # Task Logic
        process_resource(resource_id)
    finally:
        lock.release()
```

- 동일 리소스에 대한 중복 실행 방지
- Lock 타임아웃으로 Deadlock 방지

---

## 6. 장애 대응 및 복구 설정

### Task 유실 방지 설정

```python
CELERY_TASK_ACKS_LATE = True
CELERY_WORKER_PREFETCH_MULTIPLIER = 1
CELERY_TASK_REJECT_ON_WORKER_LOST = True
```

- `ACKS_LATE = True`: Task 완료 후 ACK
- `PREFETCH_MULTIPLIER = 1`: 한 번에 하나씩만 가져오기
- `REJECT_ON_WORKER_LOST = True`: Worker 장애 시 Task 재배치

### Worker 재시작 전략

```bash
# Graceful shutdown
celery -A myapp control shutdown

# 또는 Supervisor/systemd로 자동 재시작 설정
```

### Graceful Shutdown 처리

```python
import signal
from celery import Celery

app = Celery('myapp')

def shutdown_handler(signum, frame):
    # 현재 실행 중인 Task 완료 대기
    app.control.shutdown()

signal.signal(signal.SIGTERM, shutdown_handler)
```

---

## 7. 성능 최적화 관련 설정

### Task Granularity 조절

- **너무 작은 Task**: 오버헤드 증가
- **너무 큰 Task**: Worker 점유 시간 증가, 재시도 비용 증가
- **권장**: 1초~1분 정도 실행 시간이 적절

### Chord / Group 사용 시 주의사항

```python
from celery import group, chord

# Group: 병렬 실행
job = group(task.s(i) for i in range(10))
result = job.apply_async()

# Chord: Group 완료 후 콜백
chord(job)(callback.s())
```

**주의사항**:

- Chord는 모든 Task 완료를 기다리므로 하나라도 실패하면 콜백 실행 안 됨
- 대량의 Task는 메모리 사용량 증가

### DB / 외부 API 병목 방지

```python
@celery.task
def process_data():
    # 배치 처리로 DB 쿼리 최소화
    items = Item.objects.filter(status='pending')[:100]
    for item in items:
        process_item(item)

    # 외부 API 호출은 타임아웃 설정
    response = requests.get(url, timeout=30)
```

---

## 8. 로그 & 모니터링

### Celery 로그 레벨 설정

```python
CELERY_WORKER_LOG_FORMAT = '[%(asctime)s: %(levelname)s/%(processName)s] %(message)s'
CELERY_WORKER_TASK_LOG_FORMAT = '[%(asctime)s: %(levelname)s/%(processName)s][%(task_name)s(%(task_id)s)] %(message)s'
```

### Task 단위 로그 전략

```python
import logging
from celery.utils.log import get_task_logger

logger = get_task_logger(__name__)

@celery.task
def my_task():
    logger.info("Task started")
    try:
        result = do_work()
        logger.info(f"Task completed: {result}")
    except Exception as e:
        logger.error(f"Task failed: {e}", exc_info=True)
        raise
```

### Flower / Prometheus 연동

```bash
# Flower 실행
celery -A myapp flower

# Prometheus 메트릭 수집
CELERY_WORKER_SEND_TASK_EVENTS = True
CELERY_TASK_SEND_SENT_EVENT = True
```

### Dead Letter Queue 설정

실패한 Task를 별도의 Dead Letter Queue로 보내고 분석할 수 있습니다.

**RabbitMQ 설정**:

```python
CELERY_TASK_ROUTES = {
    'app.tasks.*': {'queue': 'default'},
}
CELERY_TASK_DEFAULT_QUEUE = 'default'
CELERY_TASK_DEFAULT_EXCHANGE = 'default'
CELERY_TASK_DEFAULT_ROUTING_KEY = 'default'
```

**Redis에서 Dead Letter 처리**:

```python
from celery import Task

class CustomTask(Task):
    def on_failure(self, exc, task_id, args, kwargs, einfo):
        # 실패한 Task를 별도 저장소에 기록
        save_failed_task(task_id, args, kwargs, str(exc))
        super().on_failure(exc, task_id, args, kwargs, einfo)

@celery.task(base=CustomTask)
def my_task():
    pass
```

---

## 9. 배포 및 운영 전략

### 무중단 배포 고려사항

1. **롤링 업데이트**: Worker를 하나씩 재시작
2. **Graceful Shutdown**: 실행 중인 Task 완료 대기
3. **Queue 모니터링**: 배포 중 Queue 길이 확인

### 롤링 업데이트 시 주의점

```bash
# 1. 새 Worker 시작
celery -A myapp worker --concurrency=4

# 2. 기존 Worker에 shutdown 신호
celery -A myapp control shutdown

# 3. Queue 길이 확인
celery -A myapp inspect active
```

### 환경별 설정 분리

```python
# settings.py
if os.environ.get('ENV') == 'production':
    CELERY_WORKER_CONCURRENCY = 8
    CELERY_WORKER_MAX_TASKS_PER_CHILD = 1000
elif os.environ.get('ENV') == 'development':
    CELERY_WORKER_CONCURRENCY = 2
    CELERY_WORKER_MAX_TASKS_PER_CHILD = 50
```

---

## 10. 운영하면서 자주 겪는 실수들

### Default 설정 그대로 사용

- **문제**: `PREFETCH_MULTIPLIER = 4`로 인해 긴 작업이 있는 Worker가 계속 Task를 가져감
- **해결**: `ACKS_LATE = True`와 함께 `PREFETCH_MULTIPLIER = 1` 사용

### Worker 과다/과소 설정

- **과다 설정**: 컨텍스트 스위칭 오버헤드, 메모리 부족
- **과소 설정**: Queue 쌓임, 처리 지연
- **해결**: 모니터링을 통해 점진적으로 조정

### Retry 폭탄 이슈

```python
# 잘못된 예
@celery.task(autoretry_for=(Exception,), max_retries=10)
def my_task():
    if some_condition:  # 영구적 실패 조건
        raise ValueError("Permanent failure")
    # 이 경우 계속 재시도되어 리소스 낭비
```

**해결**: 영구적 실패는 재시도하지 않도록 예외 타입 구분

---

## 11. 추천 설정 모음

운영환경에서 권장하는 설정값들을 모아놓은 예시입니다.

### 기본 안정성 설정

```python
# settings.py

# Task Timeout
CELERY_TASK_TIME_LIMIT = 300  # 5분 (하드 리밋)
CELERY_TASK_SOFT_TIME_LIMIT = 270  # 4.5분 (소프트 리밋)

# Worker 안정성
CELERY_TASK_ACKS_LATE = True  # Task 완료 후 ACK
CELERY_TASK_REJECT_ON_WORKER_LOST = True  # Worker 장애 시 재배치
CELERY_WORKER_PREFETCH_MULTIPLIER = 1  # 한 번에 하나씩만 가져오기

# Worker 자동 재시작
CELERY_WORKER_MAX_TASKS_PER_CHILD = 1000  # 1000개 Task 후 재시작
CELERY_WORKER_MAX_MEMORY_PER_CHILD = 200000  # 200MB 초과 시 재시작 (KB 단위)

# 재시도 설정
CELERY_TASK_DEFAULT_RETRY_DELAY = 60  # 1분 대기 후 재시도
CELERY_TASK_MAX_RETRIES = 3  # 최대 3회 재시도
```

### Worker 실행 명령어

```bash
celery -A myapp worker \
    --concurrency=4 \
    --max-tasks-per-child=1000 \
    --loglevel=info
```

### Task 예시 (권장 패턴)

```python
from celery import shared_task
from celery.exceptions import SoftTimeLimitExceeded, Retry
from celery.utils.log import get_task_logger
import logging

logger = get_task_logger(__name__)

@shared_task(
    bind=True,
    time_limit=300,
    soft_time_limit=270,
    max_retries=3,
    default_retry_delay=60,
    autoretry_for=(ConnectionError, TimeoutError),
    retry_backoff=True,
    retry_backoff_max=600,
    retry_jitter=True
)
def my_task(self, resource_id):
    try:
        logger.info(f"Task started for resource {resource_id}")

        # Task Logic
        result = process_resource(resource_id)

        logger.info(f"Task completed: {result}")
        return result

    except SoftTimeLimitExceeded:
        logger.warning("Task exceeded soft time limit")
        cleanup()
        raise

    except (ConnectionError, TimeoutError) as e:
        logger.error(f"Temporary error: {e}")
        raise self.retry(exc=e)

    except Exception as e:
        logger.error(f"Task failed: {e}", exc_info=True)
        raise
```

---

## 핵심요약

1. **Worker 설정**: `ACKS_LATE = True`, `PREFETCH_MULTIPLIER = 1`로 Task 유실 방지
2. **메모리 관리**: `max_tasks_per_child`로 주기적 재시작하여 메모리 누수 방지
3. **Queue 분리**: 우선순위와 리소스 사용에 따라 Queue 분리
4. **Retry 전략**: 일시적 오류만 재시도, 지수 백오프 적용
5. **모니터링**: Flower/Prometheus로 Worker 상태와 Queue 길이 지속 모니터링
6. **배포 전략**: Graceful Shutdown으로 무중단 배포 구현

운영환경에서는 기본 설정을 그대로 사용하지 말고, 실제 워크로드에 맞춰 위 설정들을 조정하는 것이 중요합니다.
