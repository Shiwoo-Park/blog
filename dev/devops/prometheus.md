# 프로메테우스 개념 및 사용법

> 날짜: 2025-02-23

[목록으로](https://shiwoo-park.github.io/blog)

---

## 🔹 **프로메테우스(Prometheus)란?**
**Prometheus**는 **시계열 데이터(time-series data)를 수집하고 분석하는 모니터링 도구**야.  
특히 **Kubernetes, Docker, Microservices 환경**에서 많이 사용돼.  

✅ **특징**  
- **Pull 방식**으로 메트릭 수집  
- **PromQL**이라는 쿼리 언어 지원  
- **Exporter**를 통해 다양한 시스템을 모니터링 가능  
- **Grafana**와 연동해서 데이터 시각화 가능  
- **알람(AlertManager)** 기능 내장  

---

## 🔥 **프로메테우스 동작 방식**
1️⃣ **Exporter**:  
   - 서버, 애플리케이션, DB 등의 메트릭을 수집하는 모듈 (예: `node_exporter`, `redis_exporter`)  

2️⃣ **Prometheus Server**:  
   - `Exporter`에서 **Pull 방식**으로 메트릭을 가져와 저장  

3️⃣ **PromQL**:  
   - Prometheus의 쿼리 언어로 데이터를 분석하고 시각화  

4️⃣ **Grafana**:  
   - Prometheus의 데이터를 시각화하는 도구  

5️⃣ **AlertManager**:  
   - 특정 조건에 따라 알람을 설정하고 전송 (예: 슬랙, 이메일, PagerDuty)  

---

## 🔹 **Prometheus 설치 및 사용 방법**
### 1️⃣ **Prometheus 설치 (Docker 사용)**
```bash
docker run -d --name=prometheus -p 9090:9090 \
    -v $(pwd)/prometheus.yml:/etc/prometheus/prometheus.yml \
    prom/prometheus
```

👆 `prometheus.yml` 설정 파일이 필요해.

---

### 2️⃣ **Prometheus 설정 파일 예제 (`prometheus.yml`)**
```yaml
global:
  scrape_interval: 10s  # 10초마다 데이터 수집

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
```
👆  
- `scrape_interval`: 데이터를 몇 초마다 가져올지 설정  
- `targets`: 모니터링할 대상 (예: `node_exporter`, `redis_exporter`)  

---

### 3️⃣ **Exporter 추가 (서버 모니터링)**
서버 리소스를 모니터링하려면 **`node_exporter`**를 실행해야 해.  
```bash
docker run -d --name=node_exporter -p 9100:9100 prom/node-exporter
```
👆 이렇게 실행하면, Prometheus가 `localhost:9100`에서 CPU, 메모리 등의 메트릭을 가져와.

---

### 4️⃣ **PromQL 기본 쿼리 예제**
- 현재 CPU 사용량:  
  ```promql
  node_cpu_seconds_total{mode="idle"}
  ```
- 5분 동안의 평균 CPU 사용률:  
  ```promql
  avg(rate(node_cpu_seconds_total{mode="idle"}[5m]))
  ```
- 특정 HTTP 요청 수 조회 (예: `/api/v1`):  
  ```promql
  http_requests_total{handler="/api/v1"}
  ```

---

### 5️⃣ **Grafana 연동 (데이터 시각화)**
Grafana를 실행하고 Prometheus를 데이터 소스로 추가하면 **시각적인 대시보드**를 만들 수 있어.
```bash
docker run -d --name=grafana -p 3000:3000 grafana/grafana
```
👆 웹 브라우저에서 `http://localhost:3000`에 접속하면 Grafana UI를 볼 수 있음.  
데이터 소스로 **Prometheus (`http://localhost:9090`)** 를 추가하면 모니터링 대시보드를 만들 수 있어.


## 📌 **정리**
✅ **Prometheus는 시계열 데이터 모니터링 도구**  
✅ **Exporter를 통해 다양한 시스템을 모니터링**  
✅ **Pull 방식으로 데이터를 수집하여 저장**  
✅ **Grafana와 연동하면 실시간 대시보드 생성 가능**  
✅ **AlertManager로 특정 이벤트 감지 시 알람 전송 가능**


## [보너스] Django 애플리케이션 메트릭 Prometheus에 보내기

### 🔹 **1-1. `django-prometheus` 설치**
```bash
pip install django-prometheus
```

### 🔹 **1-2. Django 설정 파일 (`settings.py`) 수정**
```python
INSTALLED_APPS = [
    'django_prometheus',
    # 기존 앱들...
]

MIDDLEWARE = [
    'django_prometheus.middleware.PrometheusBeforeMiddleware',
    # 기존 미들웨어...
    'django_prometheus.middleware.PrometheusAfterMiddleware',
]
```
👆 **설명**  
- `django-prometheus`를 설치하면 Django에서 기본적인 HTTP 요청, DB 쿼리, 캐시 등의 메트릭을 제공함.

---

### 🔹 **1-3. `urls.py`에 Prometheus 엔드포인트 추가**
```python
from django.urls import path, include
from django_prometheus import exports

urlpatterns = [
    path("metrics/", exports.ExportToDjangoView.as_view(), name="prometheus-metrics"),
]
```
👆 `GET /metrics/` 엔드포인트를 Prometheus가 `scrape`하여 데이터를 가져갈 수 있도록 설정.

---

### 🔹 **1-4. Prometheus에서 Django 메트릭 수집 설정 (`prometheus.yml`)**
```yaml
scrape_configs:
  - job_name: 'django'
    static_configs:
      - targets: ['localhost:8000']
```
👆 `localhost:8000/metrics/` 를 `scrape` 하여 Django 애플리케이션의 메트릭을 가져감.

---

[목록으로](https://shiwoo-park.github.io/blog)





















