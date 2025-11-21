---
layout: post
title: "Celery 워커 구동 명령어 옵션 살펴보기"
date: 2024-11-29
categories: [python, celery]
---

# Celery 워커 구동 명령어 옵션 살펴보기

> 날짜: 2024-11-29

[목록으로](https://shiwoo-park.github.io/blog)

---

Celery 워커를 실행할 때 사용할 수 있는 다양한 옵션과 그 용법을 정리했습니다. 아래는 **`celery worker`** 명령어의 주요 옵션과 활용 예제입니다.

---

## **1. 기본 구문**
```bash
celery -A <app_name> worker [옵션]
```

- **`-A`**: Celery 애플리케이션 이름을 지정 (필수).
- **`worker`**: 워커 프로세스를 실행.

---

## **2. 주요 옵션**

### **a. 일반 설정**

| **옵션**                     | **설명**                                                                 | **예제**                                |
|-------------------------------|--------------------------------------------------------------------------|-----------------------------------------|
| **`-A` `<app>`**              | Celery 애플리케이션 이름 지정                                            | `-A myapp`                              |
| **`-l` `<loglevel>`**         | 로그 레벨 설정 (`debug`, `info`, `warning`, `error`, `critical`)         | `-l info`                               |
| **`--workdir` `<path>`**      | 워커가 실행될 디렉터리 지정                                               | `--workdir /home/myapp`                 |
| **`--uid` `<user_id>`**       | 워커 프로세스 실행 시 사용자 ID를 지정                                    | `--uid celeryuser`                      |
| **`--gid` `<group_id>`**      | 워커 프로세스 실행 시 그룹 ID를 지정                                      | `--gid celerygroup`                     |
| **`--hostname` `<name>`**     | 워커의 호스트 이름 지정 (`%h` = 호스트, `%n` = 워커 고유 이름)           | `--hostname=worker1@%h`                |

---

### **b. 태스크 동작 제어**

| **옵션**                     | **설명**                                                                 | **예제**                                |
|-------------------------------|--------------------------------------------------------------------------|-----------------------------------------|
| **`-Q` `<queue_names>`**      | 워커가 처리할 큐 이름(들)을 지정 (`,`로 구분)                              | `-Q default,priority`                   |
| **`-X` `<task_names>`**       | 워커가 처리하지 않을 태스크 이름(들)을 지정                                | `-X myapp.tasks.ignore_task`            |
| **`-I` `<task_names>`**       | 워커가 처리할 태스크 이름(들)을 지정                                      | `-I myapp.tasks.only_task`              |
| **`--autoscale` `<max,min>`** | 워커 프로세스의 자동 스케일링 (`최대,최소` 개수)                          | `--autoscale=10,3`                      |
| **`-c` `<concurrency>`**      | 워커의 병렬 처리 프로세스 수 설정 (기본은 CPU 코어 수)                     | `-c 4`                                  |
| **`--without-gossip`**        | gossip 메시징 비활성화                                                   | `--without-gossip`                      |
| **`--without-mingle`**        | 워커가 다른 워커와 초기 연결을 하지 않음                                  | `--without-mingle`                      |
| **`--without-heartbeat`**     | 워커의 heartbeat 메시지 비활성화                                         | `--without-heartbeat`                   |

---

### **c. 로깅 및 디버깅**

| **옵션**                     | **설명**                                                                 | **예제**                                |
|-------------------------------|--------------------------------------------------------------------------|-----------------------------------------|
| **`-l` `<loglevel>`**         | 로그 레벨 설정 (`debug`, `info`, `warning`, `error`, `critical`)         | `-l debug`                              |
| **`--logfile` `<file>`**      | 로그를 특정 파일에 저장                                                 | `--logfile=/var/log/celery/worker.log`  |
| **`--detach`**                | 백그라운드에서 워커 실행                                                 | `--detach`                              |
| **`--pidfile` `<file>`**      | 워커의 PID 파일 경로 설정                                               | `--pidfile=/var/run/celery/%n.pid`      |
| **`--statedb` `<file>`**      | 워커 상태를 저장하는 데이터베이스 파일 경로                              | `--statedb=/var/lib/celery/worker.db`   |

---

### **d. 워커 성능 제어**

| **옵션**                     | **설명**                                                                 | **예제**                                |
|-------------------------------|--------------------------------------------------------------------------|-----------------------------------------|
| **`--prefetch-multiplier`**   | 한 번에 가져올 태스크 수 설정                                            | `--prefetch-multiplier=1`               |
| **`--max-tasks-per-child`**   | 워커 프로세스가 처리할 최대 태스크 수 (초과 시 프로세스 재시작)           | `--max-tasks-per-child=100`             |
| **`--time-limit`**            | 태스크 실행의 **hard time limit** 설정 (초 단위)                         | `--time-limit=300`                      |
| **`--soft-time-limit`**       | 태스크 실행의 **soft time limit** 설정 (초 단위)                         | `--soft-time-limit=250`                 |
| **`--pool` `<pool_type>`**    | 워커의 실행 풀 유형 지정 (`prefork`, `solo`, `threads`, `eventlet` 등)    | `--pool=threads`                        |

---

### **e. 고급 옵션**

| **옵션**                     | **설명**                                                                 | **예제**                                |
|-------------------------------|--------------------------------------------------------------------------|-----------------------------------------|
| **`--events`**                | 태스크 이벤트 전송 활성화                                                | `--events`                              |
| **`--queues` `<queues>`**     | 처리할 큐 이름 지정 (쉼표로 구분)                                         | `--queues=queue1,queue2`                |
| **`--exclude-queues`**        | 처리하지 않을 큐 이름 지정                                               | `--exclude-queues=queue3`               |
| **`--without-mingle`**        | 워커 초기 연결 동기화를 비활성화                                         | `--without-mingle`                      |
| **`--without-gossip`**        | 워커 간 상태 교환(gossip) 비활성화                                       | `--without-gossip`                      |

---

## **3. 예제**

### **a. 단일 큐에서 워커 실행**
```bash
celery -A myapp worker -Q high_priority -l info
```

### **b. 병렬 프로세스 제한**
```bash
celery -A myapp worker -c 4
```

### **c. 자동 스케일링**
```bash
celery -A myapp worker --autoscale=10,3
```

### **d. 태스크 시간 제한 설정**
```bash
celery -A myapp worker --time-limit=300 --soft-time-limit=250
```

### **e. 로그 파일 출력**
```bash
celery -A myapp worker --logfile=/var/log/celery/worker.log --pidfile=/var/run/celery/worker.pid
```

---

## **4. 실전에서의 팁**

1. **성능 튜닝**:
   - 태스크 실행 수와 워커 프로세스 병렬 처리 수를 조정하여 최적의 성능을 확보하세요.
   - `--prefetch-multiplier=1`로 설정하면 워커가 한 번에 태스크를 하나씩 처리합니다.

2. **안정성**:
   - `--max-tasks-per-child` 옵션을 사용하여 워커 프로세스를 주기적으로 재시작하면 메모리 누수 문제를 방지할 수 있습니다.

3. **디버깅**:
   - 문제 발생 시 `-l debug` 옵션으로 디버깅 정보를 확인하세요.
   - 이벤트 모니터링을 활성화하려면 `--events`를 추가합니다.

4. **모니터링**:
   - Flower와 같은 Celery 대시보드를 사용하여 워커 상태를 실시간으로 확인하세요.

---

[목록으로](https://shiwoo-park.github.io/blog)

