# AWS - AWS EC2 Auto Scaling Group 템플릿 교체 과정

> 날짜: 2024-09-06

[목록으로](https://shiwoo-park.github.io/blog)

---

최근 회사에서 진행한 **api-v2** 프로젝트의 EC2 Auto Scaling Group의 템플릿 교체 작업을 정리해 보았습니다. 

해당 작업은 인프라의 성능 및 안정성을 강화하기 위해 수행되었습니다. 아래는 주요 작업 과정입니다.

## 작업 과정 요약

### 1. 운영 인스턴스 하나 분리
   - 신규 템플릿에 필요한 설정을 진행하기위해 기존에 동작하는 운영 인스턴스에서 한마리를 뜯어냅니다.
   - Auto Scaling Group 에서 인스턴스 하나 분리 (ID 기억필수 !!!)
   - EC2 대상그룹에서 동일한 ID 의 인스턴스 등록 취소 (=트래픽이 안오게 됨)

### 2. Enabled Service Unit 점검 (최초 서버 구동시 자동실행되는 데몬 들)
- 분리된 인스턴스에서 현재 활성화된 서비스들이 정상적으로 작동하는지 확인합니다.
  - `systemctl list-unit-files --type=service --state=enabled`
- 필요없는 service 는 disable 처리
  - `sudo systemctl disable datadog-agent.service`

### 3. Pyenv에서 미사용 버전 제거
   - 불필요한 Python 버전을 `pyenv`에서 제거하여 시스템 리소스를 최적화합니다.
   - `pyenv uninstall 3.7.13`

### 4. Grafana 로그 수집용 Promtail 설정 변경
   - **수집 데이터** 및 **로그 전송 대상 서버** 변경 작업을 수행합니다.
     - a. 수집 데이터 설정 변경
     - b. 로그를 전송하는 대상 서버 변경

### 5. Yum Update
   - 인스턴스의 패키지 및 의존성을 최신 버전으로 유지하기 위해 `yum update`를 수행합니다.

### 6. api-v2에서 사용하는 파이썬 가상환경 설정 및 패키지 설치
   - api-v2 서비스가 사용하는 가상환경 설정 및 필요한 패키지 설치 작업을 수행합니다.
   - 이미 패키지가 설치되어있으면 배포 속도 향상

### 7. API-v2 서비스 구동 및 운영 환경 대상 그룹 등록
   - API-v2 서비스를 시작하고, 운영 환경에서 해당 인스턴스를 대상 그룹에 등록하여 트래픽 테스트를 진행합니다.
   - 트래픽이 정상적으로 처리되는지 확인합니다.

### 8. AMI 이미지 생성
   - API-v2 인스턴스의 설정을 완료한 후 새로운 AMI 이미지를 생성합니다.
     - 생성된 이미지 이름: `api-v2-20240905-3`

### 9. Auto Scaling Group 에서 템플릿 수정 (새 버전)

- 새로 생성한 AMI 이미지를 기반으로 Auto Scaling Group 템플릿을 수정합니다.
  - 이때 **Service** 태그를 추가하여 Grafana에서 모니터링할 수 있도록 설정합니다.

### 10. Auto Scaling Group 에서 시작 템플릿 변경 

- latest 로 적용되어있으면 손 안대도 됨
- 만일 수동 설정인 경우 신규 버전을 지정

## 결론

이번 작업을 통해 API-v2 프로젝트의 인프라를 최적화하고, 새로운 AMI 이미지를 사용하여 Auto Scaling Group 템플릿을 교체했습니다. 

이를 통해 인스턴스의 안정성과 성능을 높였으며, 로그 및 서비스 모니터링 환경을 강화했습니다.


---

[목록으로](https://shiwoo-park.github.io/blog)
