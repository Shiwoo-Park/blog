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
