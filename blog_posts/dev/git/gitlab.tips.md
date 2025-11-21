---
layout: post
title: "GitLab을 효과적으로 사용하기 위한 몇 가지 꿀팁과 Best Practice"
date: 2024-08-15
categories: [git, gitlab, best-practice]
---

# GitLab을 효과적으로 사용하기 위한 몇 가지 꿀팁과 Best Practice

> 날짜: 2024-08-15

[목록으로](https://shiwoo-park.github.io/blog)

---


### 1. **Merge Request (MR) Templates 사용**
   - 프로젝트에서 자주 사용하는 MR 설명을 템플릿으로 만들어두면, 리뷰어가 중요 정보를 놓치지 않고 MR을 검토할 수 있습니다.
   - 예시 템플릿에는 작업 내용, 테스트 계획, 영향받는 서비스, 관련 티켓 등을 포함하면 좋습니다.

### 2. **Branch Naming Convention**
   - 일관된 브랜치 네이밍 규칙을 정해두면 브랜치 관리가 훨씬 수월해집니다.
   - 예: `feature/`, `bugfix/`, `hotfix/` 등의 접두사를 사용하고, JIRA 티켓 번호를 포함하여 브랜치를 쉽게 추적 가능하도록 합니다. 예시: `feature/JIRA-1234-add-login`.

### 3. **Pipeline Efficiency 개선**
   - CI/CD 파이프라인에서 불필요한 단계를 제거하고, 캐시를 활용해 빌드 속도를 개선합니다. GitLab에서는 캐시 및 아티팩트를 활용해 반복적인 빌드를 최적화할 수 있습니다.
   - 필요할 경우 병렬 빌드를 설정해 파이프라인 실행 시간을 단축할 수 있습니다.

### 4. **Protected Branches**
   - 주요 브랜치(예: `main`, `develop`)는 Protected Branch로 설정해 직접 푸시를 방지하고, 반드시 MR을 통해서만 병합되도록 합니다. 이를 통해 코드 품질을 높이고 실수를 방지할 수 있습니다.

### 5. **Code Owners 설정**
   - 특정 파일이나 디렉토리에 대한 코드 오너를 설정해 해당 영역의 변경 사항이 반드시 관련 담당자의 검토를 받도록 할 수 있습니다.
   - 이는 팀 내에서 코드의 소유권을 명확히 하고, 중요한 변경 사항이 제대로 검토되도록 보장합니다.

### 6. **Merge Request Approval Rules**
   - 특정 유형의 작업(예: 보안 관련 코드)에는 추가 검토자 또는 관리자 승인이 필요하도록 MR Approval Rules을 설정합니다. 이를 통해 더 나은 코드 품질과 보안을 유지할 수 있습니다.

### 7. **GitLab Runner 설정 최적화**
   - 필요에 따라 GitLab Runner를 특정 프로젝트에 맞게 최적화하고, 적절한 태그를 사용해 파이프라인에서 올바른 Runner를 선택하도록 합니다.
   - 또한, Runner의 자원을 효율적으로 활용할 수 있도록 스케일링 옵션을 고려합니다.

### 8. **자동화된 Release 관리**
   - GitLab의 CI/CD를 활용해 자동화된 릴리스 프로세스를 설정합니다. 태그를 기준으로 빌드, 테스트, 배포까지 자동으로 진행되도록 설정하면 배포 속도와 일관성을 높일 수 있습니다.

### 9. **GitLab CI/CD Variables 관리**
   - 환경별로 다른 설정값을 관리할 때는 GitLab CI/CD Variables를 사용합니다. 이를 통해 민감한 정보를 안전하게 관리하고, 파이프라인 실행 시 필요한 변수들을 쉽게 적용할 수 있습니다.

### 10. **Security & Compliance**
   - GitLab의 보안 스캐너 기능을 활용해 정기적으로 코드에서 보안 취약점을 검사하고, 코드 커버리지와 보안 준수 상태를 모니터링합니다.
   - 이를 통해 보안성을 높이고, 규정을 준수할 수 있습니다.

---

[목록으로](https://shiwoo-park.github.io/blog)
