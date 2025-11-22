---
layout: post
title: "Django Gunicorn 설정"
date: 2024-01-01
categories: [django, python, gunicorn, config]
---

운영환경용 Gunicorn 설정 파일입니다. 워커 프로세스 개수, 스레드, 타임아웃 등의 설정을 포함합니다.

---

## 1. 설정 파일 내용

```python
# 운영환경용 gunicorn 설정 파일
import multiprocessing

# 바인드 주소
bind = "0.0.0.0:8000"

# 워커 프로세스 개수 (CPU 코어 수 기반 계산)
workers = (multiprocessing.cpu_count() * 2) + 1

# 스레드 개수
threads = 2

# 요청 처리 후 워커 재시작 설정 (500~550 사이에 재시작됨)
max_requests = 2000  # 워커가 N개의 요청을 처리한 후 재시작
max_requests_jitter = 500  # 재시작 요청 횟수에 N개의 랜덤 지터 추가

# 로그 설정
accesslog = "-"  # 액세스 로그: 표준 출력
errorlog = "-"  # 에러 로그: 표준 출력
loglevel = "warning"

# 타임아웃 설정
timeout = 30
```

---

## 2. 주요 설정 설명

- **workers**: CPU 코어 수의 2배 + 1로 자동 계산
- **threads**: 각 워커당 스레드 개수
- **max_requests**: 메모리 누수 방지를 위한 워커 재시작 설정
- **timeout**: 요청 처리 타임아웃 시간 (초)

