---
layout: post
title: "캐시 서비스 - Circuit Breaker 패턴 구현"
date: 2025-01-27
categories: [python, django, cache, circuit-breaker]
---

## 개요

`CacheService`는 Django 애플리케이션에서 Redis 캐시를 안전하게 사용하기 위한 공용 캐시 모듈입니다. Redis 장애 시 자동으로 RDB로 fallback하며, Circuit Breaker 패턴을 통해 단시간에 많은 오류가 발생할 때 Redis 접근을 차단하여 시스템을 보호합니다. 또한 에러 발생 시 Slack 알림을 통해 모니터링을 지원합니다.

### 주요 특징

- **Redis + RDB Fallback**: 캐시 조회 실패 시 자동으로 데이터베이스에서 조회
- **Circuit Breaker 패턴**: Redis 장애 시 일정 시간 동안 Redis 접근 차단
- **Thread-Safe**: 멀티스레드 환경에서 안전하게 동작
- **Slack 알림**: 에러 발생 시 중복 방지 및 쿨다운 기능이 있는 알림 전송
- **데코레이터 지원**: 함수에 간편하게 캐시 기능 적용 가능

---

## 1. 주요 메서드

### 1-1. get_with_fallback

캐시에서 조회하고, 실패 시 fallback 함수를 실행하는 핵심 메서드입니다.

```python
@classmethod
def get_with_fallback(
    cls,
    cache_enum: CacheKey,
    fallback_func: Callable,
    cache_key_kwargs: Optional[Dict[str, Any]] = None,
    cache_version: int = 1,
    fallback_args: tuple = (),
    fallback_kwargs: Optional[Dict[str, Any]] = None,
) -> Any:
```

**주요 로직:**

1. Redis 캐시 조회 시도 (Circuit Breaker 체크 포함)
2. 캐시 조회 실패 시 RDB fallback 함수 실행
3. fallback 결과를 Redis와 로컬 캐시에 저장 (비동기)
4. 각 단계별 실패 시 Slack 알림 전송

**사용 예시:**

```python
result = CacheService.get_with_fallback(
    cache_enum=CacheKey.USER_OBJECT,
    fallback_func=get_user_from_db,
    cache_key_kwargs={"user_id": user_id},
    fallback_kwargs={"user_id": user_id}
)
```

### 1-2. Circuit Breaker 메커니즘

Circuit Breaker는 Redis 장애 시 시스템을 보호하기 위한 패턴입니다.

#### \_should_skip_redis

Redis 접근을 건너뛸지 결정하는 메서드입니다.

```python
@classmethod
def _should_skip_redis(cls) -> bool:
```

**동작 방식:**

1. Circuit Breaker가 열려있는지 확인
2. 열려있다면 타임아웃 시간(기본 3분)이 지났는지 체크
3. 타임아웃이 지나지 않았으면 Redis 접근 차단
4. 타임아웃이 지났으면 Circuit을 닫고 Redis 재시도 허용

#### \_check_circuit_breaker

Redis 실패를 기록하고 Circuit Breaker 상태를 관리합니다.

```python
@classmethod
def _check_circuit_breaker(cls, exception: Optional[Exception] = None):
```

**주요 로직:**

1. 예외가 Circuit Breaker 대상인지 확인 (ConnectionError, TimeoutError 등)
2. 오래된 실패 기록 제거 (failure_window_size 이내만 유지)
3. 현재 실패 시간을 리스트에 추가
4. 최근 윈도우 크기(60초) 내 실패 횟수가 임계값(10회) 초과 시 Circuit 열기
5. 여러 캐시 키에서 에러가 발생했을 때만 Circuit 열기 (알림 키 개수 확인)

**Circuit Breaker 설정:**

```python
_redis_circuit_breaker = {
    "is_open": False,  # Circuit이 열려있는지
    "timeout": 60 * 3,  # Circuit 열린 후 상태 유지 시간 (3분)
    "failure_window_size": 60,  # 실패 시간 수집 윈도우 크기 (60초)
    "failure_threshold": 10,  # Circuit 발동을 위한 실패 횟수
}
```

---

## 2. Thread-Safety 보장

멀티스레드 환경에서 안전하게 동작하기 위해 Lock을 사용합니다.

### 2-1. Lock 객체

```python
_circuit_breaker_lock = threading.Lock()  # Circuit Breaker 상태 보호용
_alert_lock = threading.Lock()  # 알림 캐시 보호용
LOCK_TIMEOUT = 0.1  # Lock 획득 최대 대기 시간 (100ms)
```

### 2-2. Fail-Fast 전략

Lock 획득에 실패하면 타임아웃 기반으로 빠르게 실패하여 데드락을 방지합니다.

```python
acquired = cls._circuit_breaker_lock.acquire(timeout=cls.LOCK_TIMEOUT)
if not acquired:
    logger.warning("Lock 획득 실패 (Timeout) - Redis 접근 허용")
    return False  # 안전하게 Redis 접근 허용
```

---

## 3. Slack 알림 시스템

에러 발생 시 Slack으로 알림을 전송하되, 중복 방지 및 쿨다운 기능을 제공합니다.

### 3-1. 알림 제어 메커니즘

```python
ALERT_COOLDOWN = 60 * 10  # 캐시 키 단위 오류 Slack 알림 쿨다운 (10분)
_local_alert_cache_max_size = 6  # 최대 알림 키 개수
```

**동작 방식:**

1. 알림 키 생성 (cache_enum.name)
2. 기존 키인 경우 쿨다운 체크 (10분 이내면 알림 발송 안 함)
3. 새로운 키인 경우 캐시키 개수 제한 체크 (6개 초과 시 알림 발송 안 함)
4. 조건을 만족하면 Slack 알림 전송

### 3-2. \_send_slack_alert

```python
@classmethod
def _send_slack_alert(
    cls, message: str, cache_enum: CacheKey, exc: Optional[Exception] = None
):
```

**알림 내용:**

- 캐시 Enum 이름
- 오류 유형
- 에러 스택 트레이스 (최대 500자)

---

## 4. 비동기 캐시 저장

fallback 결과를 Redis에 저장할 때는 별도 스레드에서 비동기로 실행하여 메인 로직의 응답 시간에 영향을 주지 않습니다.

### 4-1. \_set_cache_data

```python
@classmethod
def _set_cache_data(
    cls, cache_key: str, value: Any, cache_enum: CacheKey, cache_version: int = 1
):
```

**주요 로직:**

1. 별도 스레드에서 캐시 저장 실행
2. Circuit Breaker 체크 (Redis 접근 가능한지 확인)
3. Redis에 캐시 데이터 저장
4. 성공 시 Circuit Breaker 상태 리셋
5. 실패 시 Circuit Breaker 실패 기록 및 로깅

```python
def _set_cache_in_thread():
    if cls._should_skip_redis():
        return
    try:
        cache.set(cache_key, value, cache_enum.timeout, version=cache_version)
        cls._record_redis_success()
    except Exception as e:
        cls._check_circuit_breaker(e)
        cls._send_slack_alert("캐시 저장 실패", cache_enum, e)

thread = threading.Thread(target=_set_cache_in_thread, daemon=True)
thread.start()
```

---

## 5. 데코레이터 사용법

함수에 캐시 기능을 간편하게 적용할 수 있는 데코레이터를 제공합니다.

### 5-1. cache_with_fallback

```python
def cache_with_fallback(
    cache_enum: CacheKey,
    cache_key_kwargs: Optional[Dict[str, Any]] = None,
    cache_version: int = 1,
):
```

**사용 예시:**

```python
@cache_with_fallback(CacheKey.USER_OBJECT, {"user_id": "user_id"})
def get_user_data(user_id):
    return User.objects.get(id=user_id)

@cache_with_fallback(CacheKey.HOME_BAROLIVE, cache_version=2)
def get_barolive_content(self):
    return BaroLiveSerializer(...).data
```

**동작 방식:**

1. 캐시 키 생성 (CacheKey.get() 메서드 활용)
2. CacheService.get_with_fallback() 호출
3. 원본 함수를 fallback_func로 전달
4. 모든 args, kwargs를 fallback 함수에 전달

---

## 6. 모니터링 및 디버깅

### 6-1. get_circuit_breaker_stats

Circuit Breaker 상태 통계를 조회할 수 있습니다.

```python
@classmethod
def get_circuit_breaker_stats(cls):
    return {
        "recent_fail_count": len(cls._redis_circuit_breaker["failure_times"]),
        "is_open": cls._redis_circuit_breaker["is_open"],
        "timeout": cls._redis_circuit_breaker["timeout"],
        "failure_window_size": cls._redis_circuit_breaker["failure_window_size"],
        "failure_threshold": cls._redis_circuit_breaker["failure_threshold"],
        "last_failure_time": cls._redis_circuit_breaker["last_failure_time"],
    }
```

### 6-2. set_circuit_breaker_settings

유닛 테스트 등에서 임시로 Circuit Breaker 설정을 변경할 수 있습니다.

```python
@classmethod
def set_circuit_breaker_settings(cls, key: str, value: Any):
    # 설정 변경 (Lock 보호)
```

---

## 7. 전체 코드 구조

```python
import logging
import threading
import time
import traceback
from collections import deque
from functools import wraps
from typing import Any, Callable, Dict, Optional

from django.conf import settings
from django.core.cache import cache
from redis.exceptions import (
    TimeoutError,
    ConnectionError as RedisConnectionError,
    ClusterDownError,
    OutOfMemoryError,
)

from baro.enums.cache_key import CacheKey
from baro.enums.environment import Environment
from baro.utils2.slack import SlackMessageUtil, SlackChannel

logger = logging.getLogger(__name__)


class CacheService:
    """
    공용 캐시 모듈

    - 모든 종류의 오류 발생 시, RDB fallback 지원
    - 단 시간에 많은 오류 누적 시, Circuit Breaker 지원
    - 에러 발생 시, Slack 알림 (1분당 최대 1회)
    """

    # Slack 알림 횟수 제어용 - 로컬 캐시
    ALERT_COOLDOWN = 60 * 10  # 캐시 키 단위 오류 Slack 알림 쿨다운 (초)
    _local_alert_cache_max_size = 6
    _local_alert_cache: Dict[str, float] = {}
    _last_alert_cache_cleanup: float = 0

    # Thread-Safety 를 위한 Lock 객체
    LOCK_TIMEOUT = 0.1  # Lock 획득 최대 대기 시간 (초, 100ms)
    _circuit_breaker_lock = threading.Lock()
    _alert_lock = threading.Lock()

    # Redis Circuit Breaker 상태 관리
    _redis_circuit_breaker: Dict[str, Any] = {
        "is_open": False,
        "timeout": 60 * 3,
        "target_exc_types": [
            RedisConnectionError,
            TimeoutError,
            OutOfMemoryError,
            ClusterDownError,
        ],
        "failure_times": deque(maxlen=100),
        "failure_window_size": 60,
        "failure_threshold": 10,
        "last_failure_time": time.time() - 3600,
    }

    @classmethod
    def get_with_fallback(
        cls,
        cache_enum: CacheKey,
        fallback_func: Callable,
        cache_key_kwargs: Optional[Dict[str, Any]] = None,
        cache_version: int = 1,
        fallback_args: tuple = (),
        fallback_kwargs: Optional[Dict[str, Any]] = None,
    ) -> Any:
        """캐시에서 조회하고, 실패 시 fallback 함수 실행"""
        # ... (구현 내용)
        pass

    # ... (기타 메서드들)


def cache_with_fallback(
    cache_enum: CacheKey,
    cache_key_kwargs: Optional[Dict[str, Any]] = None,
    cache_version: int = 1,
):
    """함수에 캐시 + fallback 적용하는 데코레이터"""
    # ... (구현 내용)
    pass
```

---

## 8. 설계 고려사항

### 8-1. 멀티프로세스 환경

Circuit Breaker 상태는 클래스 변수로 관리되므로 멀티프로세스 환경에서는 각 프로세스가 독립적으로 상태를 관리합니다. 이는 Redis 장애 시 각 프로세스가 독립적으로 보호받을 수 있도록 의도된 설계입니다.

### 8-2. 실패 기록 관리

`deque(maxlen=100)`을 사용하여 자동으로 오래된 항목이 제거되지만, 시간 기반 윈도우(60초) 체크를 위해 `_cleanup_failure_times()` 메서드에서 추가 필터링을 수행합니다.

### 8-3. Circuit Breaker 발동 조건

단순히 실패 횟수만으로 Circuit을 열지 않고, 여러 캐시 키에서 에러가 발생했을 때만 Circuit을 엽니다. 이를 통해 특정 캐시 키의 일시적 문제로 인한 오작동을 방지합니다.
