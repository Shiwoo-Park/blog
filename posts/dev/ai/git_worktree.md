---
layout: post
title: "Git Worktree: 여러 브랜치를 동시에 작업하는 방법"
date: 2025-11-11
categories: [git, productivity]
---

## 💡 개념

`git worktree`는 **하나의 Git 저장소에서 여러 작업 디렉터리를 동시에 관리**할 수 있게 하는 기능입니다. 즉, 하나의 리포지토리에서 서로 다른 브랜치를 동시에 checkout할 수 있게 해줍니다.

기존에는 `git checkout`으로 브랜치를 전환해야 했지만, worktree를 사용하면 각 브랜치를 별도의 디렉터리에서 동시에 작업할 수 있습니다.

---

## 🎯 왜 사용하는가?

### 일반적인 문제 상황

- PR 리뷰를 하려면 현재 작업 중인 브랜치를 잠시 멈추고 다른 브랜치로 전환해야 함
- Hotfix를 긴급히 처리해야 하는데, 현재 작업 중인 코드를 커밋하기 애매한 상황
- 여러 브랜치의 코드를 동시에 비교하거나 테스트해야 할 때
- AI 코드 어시스턴트(Cursor 등)에서 여러 브랜치 버전을 동시에 분석하고 싶을 때

### Worktree의 장점

- **브랜치 간 전환 비용 제로**: `git checkout` 없이 각 브랜치를 독립적으로 작업
- **병렬 작업 가능**: 여러 브랜치에서 동시에 개발, 테스트, 리뷰 진행
- **독립적인 환경**: 각 worktree는 별도의 디렉터리이므로 서로 영향을 주지 않음
- **CI/CD 활용**: 브랜치별 빌드/테스트를 병렬로 실행 가능

---

## ⚙️ 기본 사용법

### 1. 새 worktree 추가

```bash
# 기존 브랜치를 worktree로 추가
git worktree add ../feature-branch feature/new-api

# 새 브랜치를 생성하면서 worktree 추가
git worktree add -b feature/new-api ../feature-branch
```

**설명:**

- `../feature-branch`: 새로 생성될 디렉터리 경로 (상대 또는 절대 경로 가능)
- `feature/new-api`: 연결할 브랜치 이름
- `-b` 옵션: 브랜치가 없으면 자동 생성

### 2. worktree 목록 확인

```bash
git worktree list
```

**출력 예시:**

```
/Users/user/project    abc123 [main]
/Users/user/feature    def456 [feature/new-api]
/Users/user/hotfix     ghi789 [hotfix/critical]
```

### 3. worktree 제거

```bash
# 방법 1: remove 명령어 사용 (권장)
git worktree remove ../feature-branch

# 방법 2: prune 사용 (이미 삭제된 디렉터리 정리)
git worktree prune
```

**주의사항:**

- worktree 디렉터리를 직접 삭제하면 `.git/worktrees`에 잔존 정보가 남을 수 있음
- `git worktree remove`를 사용하면 깔끔하게 정리됨

### 4. 기타 유용한 명령어

```bash
# worktree의 상태 확인
git worktree list --porcelain

# 특정 worktree에서 작업 중인 브랜치 확인
cd ../feature-branch && git branch
```

---

## 🚀 실무 활용 예시

### 예시 1: PR 리뷰와 개발 병행

```bash
# 메인 프로젝트: 현재 개발 중인 브랜치
cd /path/to/project
git checkout feature/my-work

# PR 리뷰용 worktree 생성
git worktree add ../project-pr-review feature/colleague-pr

# 이제 두 터미널에서 동시에 작업 가능
# - /path/to/project: 내 작업 계속 진행
# - /path/to/project-pr-review: PR 코드 리뷰
```

### 예시 2: Hotfix 긴급 처리

```bash
# 현재 작업 중인 브랜치 유지
cd /path/to/project
git checkout feature/ongoing-work

# Hotfix용 worktree 생성
git worktree add ../project-hotfix hotfix/critical-bug

# Hotfix 작업 진행 (메인 작업은 그대로 유지)
cd ../project-hotfix
# ... hotfix 작업 ...
git commit -m "fix: critical bug"
git push origin hotfix/critical-bug
```

### 예시 3: 여러 브랜치 동시 테스트

```bash
# 개발 브랜치
git worktree add ../project-dev develop

# 스테이징 브랜치
git worktree add ../project-staging staging

# 프로덕션 브랜치
git worktree add ../project-prod main

# 각 디렉터리에서 독립적으로 서버 실행 및 테스트
# - ../project-dev: 개발 서버 (포트 8000)
# - ../project-staging: 스테이징 서버 (포트 8001)
# - ../project-prod: 프로덕션 서버 (포트 8002)
```

### 예시 4: CI/CD에서 병렬 빌드

```yaml
# .gitlab-ci.yml 예시
test:
  script:
    - git worktree add ../test-branch $CI_COMMIT_REF_NAME
    - cd ../test-branch
    - npm install
    - npm test
  parallel:
    matrix:
      - BRANCH: [feature/a, feature/b, feature/c]
```

---

## 🤖 AI 코드 어시스턴트와 함께 사용하기

### Cursor 활용

**시나리오**: 여러 브랜치의 코드를 Cursor에서 동시에 분석하고 싶을 때

```bash
# 메인 프로젝트 (Cursor로 열기)
cd /path/to/project
cursor .

# 비교할 브랜치를 worktree로 추가
git worktree add ../project-compare feature/alternative-approach

# 새 Cursor 창에서 비교 브랜치 열기
cursor ../project-compare
```

**장점:**

- 각 worktree를 독립적인 프로젝트로 인식
- 브랜치 간 코드 비교가 쉬움
- LLM이 각 브랜치의 컨텍스트를 명확히 구분
- "이 브랜치와 저 브랜치의 차이점을 설명해줘" 같은 요청이 가능

### Claude / ChatGPT 활용

**시나리오**: 여러 브랜치 버전의 코드를 비교 분석

```bash
# 각 브랜치를 worktree로 준비
git worktree add ../v1 feature/v1-approach
git worktree add ../v2 feature/v2-approach

# 각 worktree의 코드를 파일로 추출하여 AI에 제공
# 예: "v1과 v2의 차이점을 분석해줘" 하면서 각각의 파일을 첨부
```

### 실무 워크플로우 예시

```bash
# 1. 메인 작업 브랜치
cd /path/to/project
git checkout feature/my-feature

# 2. 리뷰 요청받은 PR 브랜치를 worktree로 추가
git worktree add ../review-pr-123 feature/pr-123

# 3. Cursor에서 두 프로젝트 동시에 열기
cursor . ../review-pr-123

# 4. Cursor에게 요청:
# "feature/pr-123 브랜치의 변경사항을 리뷰해주고,
#  내 feature/my-feature 브랜치와 충돌 가능성이 있는지 확인해줘"
```

---

## ⚠️ 주의사항

### 1. 같은 브랜치는 여러 worktree에 사용 불가

```bash
# ❌ 불가능: 같은 브랜치를 여러 worktree에 사용
git worktree add ../worktree1 feature/branch
git worktree add ../worktree2 feature/branch  # 에러 발생!

# ✅ 해결: 다른 브랜치 사용 또는 새 브랜치 생성
git worktree add ../worktree2 feature/branch-temp
```

### 2. Worktree 간 파일 충돌 주의

- 같은 파일을 여러 worktree에서 동시에 수정하면 나중에 merge 시 충돌 발생 가능
- 가능하면 서로 다른 파일/모듈을 작업하거나, 작업 전에 커뮤니케이션

### 3. 원격 브랜치 동기화

```bash
# 각 worktree에서 독립적으로 fetch/pull 가능
cd ../feature-branch
git fetch origin
git pull origin feature/new-api
```

### 4. Worktree 제거 시 주의

```bash
# ✅ 올바른 방법
git worktree remove ../feature-branch

# ❌ 잘못된 방법 (잔존 정보 남을 수 있음)
rm -rf ../feature-branch
git worktree prune  # 수동 정리 필요
```

---

## 💡 고급 활용 팁

### 1. Worktree 자동 정리 스크립트

```bash
#!/bin/bash
# cleanup-worktrees.sh

# 사용하지 않는 worktree 자동 정리
git worktree prune

# 특정 패턴의 worktree 일괄 제거
for wt in $(git worktree list --porcelain | grep "worktree" | awk '{print $2}'); do
    if [[ $wt == *"temp-"* ]]; then
        git worktree remove "$wt"
    fi
done
```

### 2. Worktree별 환경 변수 설정

```bash
# 각 worktree에서 다른 환경 변수 사용
cd ../project-dev
export ENV=development
export PORT=8000

cd ../project-staging
export ENV=staging
export PORT=8001
```

### 3. Docker Compose와 함께 사용

```yaml
# docker-compose.dev.yml (개발 worktree용)
version: "3.8"
services:
  app:
    build: .
    volumes:
      - .:/app
    environment:
      - ENV=development
```

```yaml
# docker-compose.staging.yml (스테이징 worktree용)
version: "3.8"
services:
  app:
    build: .
    volumes:
      - .:/app
    environment:
      - ENV=staging
```

---

## ✅ 정리

| 항목          | 요약                                                           |
| ------------- | -------------------------------------------------------------- |
| **핵심 개념** | 하나의 repo에서 여러 작업 디렉토리 운영                        |
| **주요 명령** | `git worktree add`, `git worktree list`, `git worktree remove` |
| **장점**      | 브랜치 간 전환 없이 병렬 작업 가능, 독립적인 환경 확보         |
| **실무 활용** | PR 리뷰, Hotfix, 멀티 환경 테스트, CI/CD 병렬화                |
| **AI 활용**   | Cursor에서 여러 브랜치 동시 분석, 코드 비교, 컨텍스트 분리     |
