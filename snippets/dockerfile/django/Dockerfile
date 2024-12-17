# 베이스 이미지 선택 (Python 3.12)
FROM python:3.12-slim AS builder

# 시스템 패키지 설치
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
ARG SERVICE_ENV=local
ENV SERVICE_ENV=${SERVICE_ENV}

# 최종 스테이지에 PostgreSQL 클라이언트 설치
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
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

# 환경별 설정 파일 복사 (.env)
COPY dotenv/${SERVICE_ENV}.conf /app/.env
RUN rm -rf /root/.cache /tmp/*

# Celery 사용자 및 그룹 생성 (보안 강화)
RUN groupadd -r jack && useradd -r -g jack jack
RUN chown -R jack:jack /app
USER jack

# 포트 노출
EXPOSE 8000

# Gunicorn 설정 파일 경로 설정
RUN if [ -f /app/jack/gunicorn_config/${SERVICE_ENV}.py ]; then \
        cp /app/jack/gunicorn_config/${SERVICE_ENV}.py /app/gunicorn_config.py; \
    else \
        cp /app/jack/gunicorn_config/base.py /app/gunicorn_config.py; \
    fi

# Gunicorn 실행
CMD ["gunicorn", "--config", "gunicorn_config.py", "root_app.wsgi:application"]
