---
layout: post
title: "Django에서 Redis로 동시성 제어하기: concurrency_safe() 컨텍스트 매니저 소개"
date: 2025-06-07
categories: [python, django, redis]
---
# 🔐 Django에서 Redis로 동시성 제어하기: `concurrency_safe()` 컨텍스트 매니저 소개

> 날짜: 2025-06-07

[목록으로](https://shiwoo-park.github.io/blog)

---

동일한 사용자 요청이 동시에 여러 번 처리되면 중복 결제, 중복 등록, 상태 꼬임 등의 문제가 생기기 쉽습니다.

이 글에서는 제가 직접 필요해서 만들었던 Django + Redis 기반의 **간단하고 안전하게 동시성 제어를 구현**할 수 있는 `concurrency_safe()` 컨텍스트 매니저를 소개합니다.

---

## 🎯 목적

`concurrency_safe()`는 다음과 같은 목적을 갖고 설계되었습니다:

* **같은 유저/자원에 대한 중복 요청을 차단**
* 여러 프로세스/스레드에서 실행되더라도 **단 한 개만 처리되도록 제어**
* Django 프로젝트에 **가볍게 붙일 수 있는 재사용 가능 로직**

---

## 💻 코드 소개

```python
import logging
import time
from contextlib import contextmanager
from django.core.cache import cache

logger = logging.getLogger(__name__)


class ConcurrencyError(Exception):
    """동시성 충돌로 인한 에러"""


@contextmanager
def concurrency_safe(
    cache_key: str,
    ttl: int = 3,
    wait_timeout: int = 0,
    exception_cls=ConcurrencyError,
    blocked_message="잠시 후 다시 시도해주세요.",
    blocked_log_level=logging.WARNING,
):
    """
    Redis lock 기반 사용자별 요청 동시성 제어 context manager

    Args:
        cache_key (str): 고유한 락 식별 키 (ex. `"lock:purchase:{user_id}:{ticket_id}"`)
        ttl (int): lock 유지 시간 (초)
        wait_timeout (int): lock 획득 대기 시간 (초), 기본 0초 → 대기 없이 즉시 실패
        exception_cls: 요청이 차단 되었을때 발생시킬 오류 클래스
        blocked_message: 요청이 차단 되었을때 유저에게 표시할 오류 메시지
        blocked_log_level: 요청이 차단 되었을때 남길 차단 로그의 로그레벨

    Usage:
        with concurrency_safe("my_key:{user_id}:{ticket_id}"):
            # 동시성 제어가 필요한 코드
    """
    start_time = time.time()

    while True:
        acquired = cache.add(cache_key, "1", timeout=ttl)
        if acquired:
            try:
                yield
            finally:
                cache.delete(cache_key)
            return

        if time.time() - start_time > wait_timeout:
            logger.log(
                blocked_log_level, f"[concurrency_safe] lock 획득 실패: {cache_key=}"
            )
            raise exception_cls(blocked_message)

        time.sleep(0.1)
```


## 🧪 사용법

### 📌 적합한 상황

* 주문/결제 요청 처리
* 좌석/쿠폰/한정 자원 선점
* 상태 변경 API (포인트, 출석 등)
* 외부 API 중복 호출 방지

### 실사용 예제 1: 로직 중복 실행 방지

```python
# 특정 유저 - 특정 보상 중복 지급 방지
cache_key_enum = CacheKey.MISSION_USER_GIVE_REWARD_LOCK
cache_key = cache_key_enum.code.format(user_id=user_id, reward_id=reward_id)

with concurrency_safe(cache_key=cache_key, ttl=cache_key_enum.timeout):
    check_n_setup_mapping_n_give_reward(
        user,
        mission,
        reward,
        user_action_log,
        is_manual=is_manual,
        is_debug=is_debug,
    )
```

### 📌 실사용 예제 2: TTL 을 이용한 요청 간격 제어

```python
@action(detail=False, methods=["put"], url_path="refresh")
def refresh(self, request, *args, **kwargs):

    if Environment.get_member(settings.ENV).is_dev():
        task = dodo_generate_buyer_interested_product.delay(self.partner.id)
        return TaskResponse(task)

    with concurrency_safe(  # 10분 간격 요청 제어
        cache_key=CacheKey.DODO_REFRESH_INTERESTED_PRODUCT.get(
            user_id=request.user.id
        ),
        ttl=CacheKey.DODO_REFRESH_INTERESTED_PRODUCT.timeout,
        exception_cls=ValidationError,
        blocked_message="잠시 후 다시 시도해주세요 (마지막 갱신 후, 10분 뒤 부터 가능)",
    ):
        task = dodo_generate_buyer_interested_product.delay(self.partner.id)

    return TaskResponse(task)
```


## ⚙️ 동작 원리

1. Redis `SETNX` 역할을 하는 `cache.add()`로 락을 시도
2. 락 획득 성공 시 → `yield` 블록 실행
3. 종료 후 → `cache.delete()`로 락 해제
4. 락을 획득하지 못한 경우:

   * `wait_timeout` 내 재시도 (`0.1초` 간격)
   * 타임아웃 시 예외 발생


## ✅ 장점

* Django 기본 `cache`(Redis 연동)로 구현 → **외부 의존성 없이 사용 가능**
* context manager 형태로 **코드에 쉽게 삽입 가능**
* TTL과 재시도(wait\_timeout) 조절로 **유연한 제어 가능**
* **단순한 구조**로 안정성 및 테스트 용이


## ❗ 단점 및 한계

* 락은 프로세스/서버 장애 시 **TTL 만료 전까지 유지됨**
* TTL 설정이 너무 짧으면 → 작업 중 락이 풀릴 수 있음
* 너무 길면 → 다른 요청이 오래 대기함
* 완전한 분산 락이 아니며, **Redlock 수준의 강건성은 아님**
* 락을 획득하지 못한 요청은 **실패하거나 대기 후 실패**


## 📝 마무리

`concurrency_safe()`는 Django + Redis 환경에서 발생할 수 있는 **중복 요청 문제를 간단하게 해결할 수 있는 도구**입니다.
크리티컬한 상태 변화 로직에 가볍게 붙여 중복 실행을 방지하고, 운영 중 문제를 줄이는 데 큰 도움이 됩니다.
