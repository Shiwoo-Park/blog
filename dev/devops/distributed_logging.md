# **분산 로깅(Distributed Logging) 개념 및 활용**

> 날짜: 2025-02-17

[목록으로](https://shiwoo-park.github.io/blog)

---

## **1. 분산 로깅이란?**

**분산 로깅(Distributed Logging)**은 **마이크로서비스 아키텍처(MSA)**, **컨테이너 환경(Kubernetes, Docker Swarm)** 또는 **분산 시스템**에서 **여러 개의 서비스와 서버에서 발생하는 로그를 중앙에서 수집하고 관리하는 기법**입니다.

---

## **2. 분산 로깅이 필요한 이유**

### 2.1 마이크로서비스 환경에서의 문제점
- 각 서비스가 **개별적으로 로그를 기록**하기 때문에 **전체 요청 흐름을 추적하기 어려움**
- 장애 발생 시 **어떤 서비스에서 오류가 발생했는지 즉각적으로 파악하기 어려움**
- 컨테이너 기반(Kubernetes) 환경에서는 **서비스가 동적으로 생성/삭제**되므로 **로그 저장 위치가 일정하지 않음**

### 2.2 해결 방법: 중앙 집중형 로깅 시스템
- 모든 서비스에서 발생한 로그를 **중앙 로그 서버**로 보내고, **한 곳에서 검색/분석 가능하도록 관리**
- 특히 MSA 와 같이 하나의 요청이 완전히 처리되기까지 다양한 서비스들을 방문하며 프로세싱이 이루어 지는경우, Trace ID(추적 ID)를 활용하여 하나의 요청(Request)이 여러 서비스에 걸쳐 어떻게 실행되는지 추적

---

## **3. 분산 로깅 아키텍처**

### **대표적인 분산 로깅 시스템**

`Application → Log Aggregator → Storage & Search → Monitoring & Alerting`

| 구성 요소 | 역할 |
|----------|------|
| **Application (Django, Flask, Node.js 등)** | 로그 생성 및 전송 |
| **Log Aggregator (Fluentd, Logstash, Vector 등)** | 로그 수집 및 가공 |
| **Storage & Search (Elasticsearch, Loki, OpenSearch 등)** | 로그 저장 및 검색 |
| **Monitoring & Alerting (Grafana, Kibana, Prometheus, Sentry 등)** | 실시간 모니터링 및 알림 |

---

## **4. 분산 로깅 도구 비교**

| 로깅 도구 | 설명 |
|----------|------|
| **Filebeat + Elasticsearch + Logstash + Kibana (ELK 스택)** | 가장 널리 사용되는 로그 분석 및 모니터링 스택 |
| **Fluentd + Elasticsearch + Kibana (EFK 스택)** | Logstash 대신 Fluentd 사용 (가벼운 로그 수집) |
| **Promtail + Grafana + Loki** | 경량 로그 저장 및 시각화, Promtail과 함께 사용 |
| **OpenTelemetry + Jaeger** | 트레이싱 중심의 분산 로깅 |
| **AWS CloudWatch Logs** | AWS 서비스용 중앙 로그 관리 |
| **Google Cloud Logging (Stackdriver)** | GCP 서비스용 로깅 솔루션 |

---

## **5. 클라우드 기반 분산 로깅 솔루션**

| 서비스 | 설명 |
|--------|------|
| **AWS CloudWatch Logs** | AWS 서비스의 중앙 집중 로깅 |
| **Google Cloud Logging (Stackdriver)** | GCP 환경의 로그 관리 |
| **Azure Monitor Logs** | Azure 서비스에서 사용 |
| **Datadog Logs** | 강력한 로그 분석 및 시각화 기능 제공 |
| **New Relic Logs** | 성능 모니터링과 통합 |

---

[목록으로](https://shiwoo-park.github.io/blog)
