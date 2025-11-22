---
layout: post
title: "Django Celery Dockerfile"
date: 2024-01-01
categories: [docker, dockerfile, django, celery, python]
---

Django Celery 워커를 위한 Dockerfile입니다. 멀티 스테이지 빌드를 사용하여 최적화된 이미지를 생성합니다.

---

## 1. Dockerfile 내용

```dockerfile
# 베이스 이미지 선택 (Python 3.12)
FROM python:3.12-slim AS builder

# 시스템 패키지 설치 (postgresql)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    python3-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 작업 디렉토리 생성
WORKDIR /app

# Python 패키지 설치
COPY requirements.txt /app/
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir --prefer-binary -r requirements.txt

# 멀티 스테이지 빌드 ==================
FROM python:3.12-slim


# 환경 변수 정의
ARG SERVICE_ENV="local"
ARG USERNAME="appuser"
ARG LOG_LEVEL="INFO"
ARG CELERY_QUEUE="celery-queue-${SERVICE_ENV}"
ARG CELERY_OPTION="--concurrency=1"

ENV SERVICE_ENV=${SERVICE_ENV}
ENV USERNAME=${USERNAME}
ENV LOG_LEVEL=${LOG_LEVEL}
ENV CELERY_QUEUE=${CELERY_QUEUE}
ENV CELERY_OPTION=${CELERY_OPTION}

# 최종 스테이지에 필요한 시스템 패키지 설치 (postgresql, ps, vi)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    procps \
    vim \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Global 환경 변수 설정
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV DJANGO_SETTINGS_MODULE=root_app.settings.default
ENV PATH="/usr/local/bin:$PATH"

WORKDIR /app

COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY . /app/
COPY ./deploy/dockerfiles/service_celery/entrypoint.sh /app/

# 환경별 설정 파일 복사 (.env)
COPY dotenv/${SERVICE_ENV}.conf /app/.env
RUN rm -rf /root/.cache /tmp/*

# Celery 사용자 및 그룹 생성 (보안 강화)
RUN groupadd -r ${USERNAME} && useradd -r -g ${USERNAME} ${USERNAME}
RUN chown -R ${USERNAME}:${USERNAME} /app
USER ${USERNAME}


RUN chmod +x /app/entrypoint.sh
CMD ["/bin/sh", "-c", "exec /app/entrypoint.sh ${LOG_LEVEL} ${CELERY_QUEUE} ${CELERY_OPTION}"]
```

---

## 2. 주요 특징

- **멀티 스테이지 빌드**: 빌드 단계와 런타임 단계를 분리하여 이미지 크기 최적화
- **환경 변수 설정**: Celery 큐, 로그 레벨, 옵션 등을 환경 변수로 설정
- **보안 강화**: 전용 사용자로 Celery 워커 실행
- **Entrypoint 스크립트**: Celery 워커를 안전하게 시작/종료하는 스크립트 사용

