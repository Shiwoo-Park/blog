---
layout: post
title: "Django Celery Entrypoint"
date: 2024-01-01
categories: [bash, celery, docker, entrypoint]
---

Django Celery 워커의 Docker 컨테이너 entrypoint 스크립트입니다. Celery 워커를 안전하게 시작하고 종료 시그널을 처리합니다.

---

## 1. 스크립트 내용

```bash
#!/bin/bash

set -e

LOG_LEVEL=$1
QUEUES=$2
OPTIONS=$3

echo "[START] entrypoint.sh"
echo "Arguments: -l ${LOG_LEVEL} -Q ${QUEUES} ${OPTIONS}"

# 종료 시그널 핸들러 등록
function handle_shutdown {
    echo "-----------------------------------------------------"
    echo "SIGTERM received, Shutting down celery gracefully..."
    if [ -n "$CELERY_PID" ]; then
        kill -SIGTERM "$CELERY_PID"
        wait "$CELERY_PID"
    fi
    exit 0
}

trap 'handle_shutdown' SIGTERM

# Celery 워커 실행
celery -A my_app worker -l "${LOG_LEVEL}" -Q "${QUEUES}" ${OPTIONS} &
CELERY_PID=$!  # Celery 프로세스의 PID 저장

# Celery 프로세스가 종료될 때까지 대기
wait "$CELERY_PID"
```

---

## 2. 주요 기능

- **안전한 종료**: SIGTERM 시그널을 받으면 Celery 워커를 graceful하게 종료
- **프로세스 관리**: Celery 프로세스의 PID를 추적하여 안전하게 종료
- **인자 전달**: 로그 레벨, 큐, 옵션을 인자로 받아 Celery 워커 실행

