---
layout: post
title: "MSA 환경에서의 버그 트래킹"
date: 2025-02-24
categories: [devops, msa, monitoring]
---
MSA 환경에서 버그 트래킹 및 모니터링을 구축하려면 **분산 시스템의 특성**을 고려한 모니터링 체계를 구성해야 한다. 주요 구성 요소와 유의할 점을 설명해줄게.

---

## 🔍 1. MSA 환경에서 버그 트래킹 및 모니터링 구성 방법

### 1️⃣ 로그 수집 및 분석
- **로그 중앙화**: 서비스마다 개별 로그를 남기지 말고 중앙 로그 시스템(e.g., **ELK Stack, Loki+Promtail, AWS CloudWatch, Datadog**)을 활용
- **분산 트레이싱**: 요청이 여러 서비스(API Gateway → Service A → Service B)로 흐르므로 **Trace ID**를 부여하여 추적(e.g., **Jaeger, OpenTelemetry, AWS X-Ray**)
- **로그 포맷 통일**: JSON 기반 로그 형식으로 **서비스 이름, Trace ID, 요청 ID, 사용자 ID** 등 포함

📌 **추천 기술 스택**
- **로그 수집**: Promtail, Fluent Bit, Filebeat
- **로그 저장/조회**: Loki, Elasticsearch, CloudWatch
- **트레이싱**: OpenTelemetry, Jaeger, Zipkin, AWS X-Ray

---

### 2️⃣ 실시간 메트릭 및 알람 설정
- **서비스별 성능 모니터링**: API 응답 시간, 에러율, 트래픽 패턴을 실시간으로 확인
- **알람 설정**: 특정 임계치를 초과하면 알림(e.g., **Slack, PagerDuty, Opsgenie** 연동)
- **사용자 경험 모니터링**: 프론트엔드까지 포함해 **APM (Application Performance Monitoring)** 구축(e.g., **New Relic, Datadog APM, AWS CloudWatch Synthetics**)

📌 **추천 기술 스택**
- **메트릭 수집**: Prometheus, AWS CloudWatch, Datadog
- **시각화**: Grafana, Kibana
- **알람**: Alertmanager, AWS SNS, Slack Webhook

---

### 3️⃣ 예외 및 에러 트래킹
- **중앙화된 예외 처리 시스템 구축**: 각 서비스에서 발생하는 예외를 하나의 시스템에서 관리
- **오류 자동 수집**: Sentry, Rollbar, Datadog 같은 SaaS 기반 도구 활용
- **Slack/Webhook 연동**: 주요 에러 발생 시 Slack 또는 Jira 이슈 생성 자동화

📌 **추천 기술 스택**
- **예외 수집**: Sentry, Rollbar, Bugsnag
- **이슈 트래킹**: Jira, Trello, ClickUp

---

## ⚠️ 2. 유의할 점

### ✅ 1️⃣ Trace ID 관리 (분산 트레이싱 필수)
- 서비스 간 API 호출 시 **Trace ID를 Request Header**로 전달하여 요청 흐름 추적 가능하게 해야 함
- Django/Flask 같은 백엔드 프레임워크에서는 **Middleware로 자동 설정 가능**

📌 **예시 (Django DRF)**
```python
from django.utils.deprecation import MiddlewareMixin
import uuid

class TraceMiddleware(MiddlewareMixin):
    def process_request(self, request):
        request.trace_id = request.headers.get('X-Trace-ID', str(uuid.uuid4()))

    def process_response(self, request, response):
        response['X-Trace-ID'] = getattr(request, 'trace_id', 'N/A')
        return response
```
---

### ✅ 2️⃣ 로그 레벨 전략
- DEBUG 로그는 개발 환경에서만 사용하고, 프로덕션에서는 INFO/ERROR 수준만 남김
- **로그 필터링**을 설정하여 PII(개인 정보) 유출 방지

📌 **예시 (Django)**
```python
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'file': {
            'level': 'ERROR',
            'class': 'logging.FileHandler',
            'filename': '/var/log/app/error.log',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['file'],
            'level': 'ERROR',
            'propagate': True,
        },
    },
}
```
---

### ✅ 3️⃣ 서비스 헬스 체크 & 장애 대응
- **프로메테우스의 `probe` 또는 AWS ALB의 `HealthCheck` 활용**
- 장애 감지 후 **자동 스케일링(Auto Scaling Group) 또는 ECS Task 재시작** 설정 필요

📌 **헬스 체크 엔드포인트 예제 (Django)**
```python
from django.http import JsonResponse

def health_check(request):
    return JsonResponse({"status": "ok"}, status=200)
```

- **알람 설정 필수**: 장애 발생 시 PagerDuty, Slack으로 알람 전송

---

## 🚀 결론

1. **로그 중앙화** (Loki, Elasticsearch, CloudWatch Logs) → `Trace ID 포함`
2. **실시간 모니터링 & 알람** (Prometheus, Datadog, Alertmanager) → `에러 감지`
3. **분산 트레이싱** (OpenTelemetry, Jaeger, AWS X-Ray) → `서비스 흐름 추적`
4. **예외 추적** (Sentry, Rollbar) → `자동 이슈 생성`
5. **헬스 체크 & 장애 대응** (K8s, ASG, ECS) → `자동 복구`

