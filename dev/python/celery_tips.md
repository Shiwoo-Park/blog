# Django + Celery 안전하게 운용하기위한 Tips

> 날짜: 2024-11-27

[목록으로](https://shiwoo-park.github.io/blog)

---

Django + Celery 프로젝트에서 Celery Task가 **먹통**이 되는 상황을 방지하려면, **Task Timeout 설정**과 **자동 종료 처리**를 설정해야 합니다. 

아래는 이러한 문제를 예방하기 위한 주요 설정과 방법입니다.

## 1. **Celery Task Timeout 설정**

### 1.1. **Hard Time Limit**
- Task가 주어진 시간 안에 종료되지 않으면 강제로 종료.
- Celery에서 `time_limit`(Hard Limit)을 설정합니다.

```python
from celery import shared_task

@shared_task(time_limit=300)  # 5분 (300초)
def my_task():
    # Task Logic
    pass
```

- **전역 설정**으로 적용:
  ```python
  CELERY_TASK_TIME_LIMIT = 300  # 초 단위
  ```

---

### 1.2. **Soft Time Limit**
- Soft Time Limit은 작업이 제한 시간을 초과하기 직전에 알림을 발생시킵니다. 이를 활용해 Graceful 종료 로직을 구현할 수 있습니다.

```python
from celery import shared_task
from celery.exceptions import SoftTimeLimitExceeded

@shared_task(soft_time_limit=300)  # 5분
def my_task():
    try:
        # Task Logic
        pass
    except SoftTimeLimitExceeded:
        # Graceful 종료
        print("Task exceeded soft time limit and will terminate.")
```

- **전역 설정**으로 적용:
  ```python
  CELERY_TASK_SOFT_TIME_LIMIT = 300  # 초 단위
  ```

---

## 2. **Task 예외 처리**
Task 내에서 예상치 못한 상황을 대비해 예외 처리를 구현하세요.

```python
from celery import shared_task

@shared_task
def my_task():
    try:
        # Task Logic
        pass
    except Exception as e:
        # 예외 로깅
        import logging
        logging.error(f"Task failed: {e}")
        raise e  # 필요시 재시도를 위해 예외를 다시 던질 수 있음
```

---

## 3. **Task 재시도 및 제한**
Task 실패 시 재시도를 제한하거나 특정 조건에서만 재시도하도록 설정합니다.

```python
from celery import shared_task

@shared_task(bind=True, max_retries=3, default_retry_delay=60)  # 1분 대기 후 최대 3회 재시도
def my_task(self):
    try:
        # Task Logic
        pass
    except Exception as e:
        # 예외가 발생하면 재시도
        raise self.retry(exc=e)
```

- **전역 설정으로 재시도 제한**:
  ```python
  CELERY_TASK_DEFAULT_RETRY_DELAY = 60  # 초 단위
  CELERY_TASK_MAX_RETRIES = 3
  ```

---

## 4. **Worker Side 설정**

### 4.1. **Concurrency 제한**
- Worker에서 처리 가능한 Task 수를 제한해 과부하를 방지합니다.

```bash
celery -A your_project worker --concurrency=4
```

- Worker 프로세스당 4개의 Task만 처리.

---

### 4.2. **Prefetch Limit**
- 한 번에 가져오는 Task 수를 제한합니다.

```python
CELERY_WORKER_PREFETCH_MULTIPLIER = 1  # 한 번에 하나씩 가져오기
```

---

### 4.3. **Task ACK 설정**
- Task 실행이 끝난 후 성공적으로 ACK를 보내도록 설정합니다. 이 설정은 Worker가 중간에 죽더라도 Task를 다시 처리할 수 있도록 합니다.

```python
CELERY_ACKS_LATE = True
CELERY_TASK_REJECT_ON_WORKER_LOST = True
```

---

## 5. **Health Check 및 Monitoring**

### 5.1. **Flower**
- Celery Task를 실시간으로 모니터링할 수 있는 대시보드입니다.
- 설치:
  ```bash
  pip install flower
  ```
- 실행:
  ```bash
  celery -A your_project flower
  ```

### 5.2. **Dead Letter Queue**
- 실패한 Task를 별도의 Dead Letter Queue로 보내고 분석할 수 있습니다.
- RabbitMQ나 Redis에서 Dead Letter 설정을 통해 비정상 Task를 관리합니다.

---

## 6. **Worker 프로세스 자동 종료**

Celery Worker가 메모리 누수 등의 이유로 불안정해질 수 있으므로, 일정 Task를 처리한 후 Worker를 자동으로 재시작하도록 설정합니다.

```bash
celery -A your_project worker --max-tasks-per-child=100
```

- **설명**:
  - Worker 프로세스가 최대 100개의 Task를 처리한 후 자동으로 종료 및 재시작됩니다.
  - 이는 메모리 누수나 Worker 불안정을 예방할 수 있습니다.

---

## 7. **Retry 및 Deadlock 방지**
Task 간 **Deadlock**을 방지하기 위해 Task 내부에서 Timeout이나 Lock을 구현하세요.

```python
from celery.utils.log import get_task_logger
import redis

logger = get_task_logger(__name__)

@shared_task
def my_task():
    client = redis.StrictRedis()
    lock = client.lock("my_task_lock", timeout=300)  # 5분

    if not lock.acquire(blocking=False):
        logger.warning("Task is already running.")
        return

    try:
        # Task Logic
        pass
    finally:
        lock.release()
```

---

### **추천 설정**
1. Task 단위 Timeout:
   ```python
   CELERY_TASK_TIME_LIMIT = 300
   CELERY_TASK_SOFT_TIME_LIMIT = 270
   ```
2. Worker 안정성:
   ```python
   CELERY_ACKS_LATE = True
   CELERY_TASK_REJECT_ON_WORKER_LOST = True
   CELERY_WORKER_PREFETCH_MULTIPLIER = 1
   ```
3. Worker 자동 재시작:
   ```bash
   celery -A your_project worker --max-tasks-per-child=100
   ```


---

[목록으로](https://shiwoo-park.github.io/blog)

