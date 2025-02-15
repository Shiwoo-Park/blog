# 🛠 **Sentry 소개 및 설치 방법**

> 날짜: 2025-02-15

[목록으로](https://shiwoo-park.github.io/blog)

---

### 📌 Sentry란?
Sentry는 **애플리케이션 모니터링 및 버그 트래킹**을 위한 도구로, **실시간 오류 감지, 성능 모니터링 및 배포 추적**이 가능합니다.  
**Django, Flask, FastAPI, Node.js, React, iOS, Android 등 다양한 플랫폼을 지원**하며, 로그뿐만 아니라 **트레이스, 성능, 배포 정보**까지 한 번에 관리할 수 있습니다.

---

## 🚀 **1. Sentry 주요 기능**
✅ **오류 감지**: 예외 발생 시 자동으로 에러를 수집하고 Slack, 이메일, Discord 등으로 알림 전송  
✅ **성능 모니터링**: API 응답 속도, 쿼리 속도 등 성능 데이터 분석  
✅ **릴리즈 및 배포 추적**: 버전별 에러 추적 및 배포 상태 모니터링  
✅ **트레이스 기능**: 특정 요청의 실행 흐름을 추적 가능 (Django, FastAPI 지원)  
✅ **인사이트 대시보드**: 대시보드에서 모든 오류와 성능 문제를 한눈에 확인  

---

## ⚙️ **2. Sentry 설치 및 연동 방법 (Django 기준)**

### ✅ **2.1 Sentry 계정 생성 및 프로젝트 설정**
1. [Sentry 공식 웹사이트](https://sentry.io/)에 가입
2. `Create Project` 클릭
3. 플랫폼 선택 (`Django` 선택)
4. 생성된 프로젝트에서 `DSN(데이터 소스 네임)` 확인 (API 키 역할)

---

### ✅ **2.2 Django 프로젝트에 Sentry 설치**
#### 1️⃣ Sentry SDK 설치
```bash
pip install --upgrade sentry-sdk
```

#### 2️⃣ `settings.py`에 Sentry 설정 추가
```python
import sentry_sdk
from sentry_sdk.integrations.django import DjangoIntegration

sentry_sdk.init(
    dsn="https://your-dsn@sentry.io/project-id",  # Sentry에서 제공하는 DSN 입력
    integrations=[DjangoIntegration()],
    traces_sample_rate=1.0,  # 0.0 ~ 1.0 (트레이스 샘플링 비율, 1.0이면 모든 요청 기록)
    send_default_pii=True,  # 사용자 정보 수집 허용 (GDPR 준수 필요)
)
```

#### 3️⃣ 에러 발생 시 자동 감지 테스트
```python
from django.http import HttpResponse

def trigger_error(request):
    division_by_zero = 1 / 0  # 에러 발생 코드
    return HttpResponse("This won't be reached")
```

- Django 서버 실행 후 `/trigger-error/` 요청 시 **Sentry에 에러가 자동 보고됨**

---

## 🔥 **3. Sentry 주요 기능 활용**

### ✅ **3.1 Slack & Email 알림 설정**
1. Sentry → `Settings` → `Integrations` → Slack 선택
2. 알림을 받을 채널 선택 후 연결
3. 이메일 알림도 같은 메뉴에서 설정 가능

---

### ✅ **3.2 성능 모니터링 설정**
Sentry는 기본적으로 **Django, FastAPI, Flask의 성능 데이터를 자동으로 수집**합니다.  
별도 설정 없이 API 응답 시간, 쿼리 실행 속도 등을 확인할 수 있습니다.

추가적으로, 수동으로 특정 블록의 성능을 측정하려면:
```python
from sentry_sdk import start_transaction

def my_view(request):
    with start_transaction(op="task", name="my_slow_function"):
        slow_function()
    return HttpResponse("Done")
```

---

### ✅ **3.3 특정 예외 무시하기**
로그에서 불필요한 오류를 제외하려면 `ignore_errors` 설정 사용:
```python
sentry_sdk.init(
    dsn="https://your-dsn@sentry.io/project-id",
    integrations=[DjangoIntegration()],
    ignore_errors=[ZeroDivisionError, KeyError],  # 특정 예외 무시
)
```

---

### ✅ **3.4 사용자 정보 로그 추가**
로그에 사용자 정보를 추가하려면:
```python
from sentry_sdk import configure_scope

def my_view(request):
    with configure_scope() as scope:
        scope.set_user({"id": request.user.id, "email": request.user.email})
    raise Exception("사용자 관련 에러 발생")
```
Sentry에서 **사용자별 오류 분석 가능**

---

## 🛠 **4. Self-Hosting 방식 (On-Premise)**
### 📌 **클라우드가 아닌 자체 서버에서 Sentry 운영하기**
Sentry는 기본적으로 **SaaS (Cloud)** 서비스이지만, `On-Premise` 설치도 가능

### ✅ **4.1 Docker를 이용한 설치**
```bash
git clone https://github.com/getsentry/self-hosted.git sentry
cd sentry
./install.sh  # 설치 시작
docker compose up -d  # 실행
```

### ✅ **4.2 실행 후 웹페이지 접속**
```bash
http://localhost:9000
```
- 자체 호스팅한 Sentry 웹 UI 접속 가능

---

## 🔥 **5. 결론**
✔️ **Django, FastAPI, Flask, Node.js 등 다양한 플랫폼에서 활용 가능**  
✔️ **실시간 에러 감지 & 성능 모니터링 가능**  
✔️ **Slack, Email 연동을 통해 빠른 장애 대응 가능**  
✔️ **배포 트래킹 기능으로 특정 버전에서 발생한 문제 추적 가능**  
✔️ **SaaS(클라우드) & 자체 호스팅(On-Premise) 모두 지원**  

> **대규모 서비스에서 장애 감지 및 모니터링을 자동화하고 싶다면 Sentry는 필수 도구입니다!** 🚀

---

[목록으로](https://shiwoo-park.github.io/blog)

