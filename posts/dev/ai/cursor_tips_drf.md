---
layout: post
title: "Python + Django + DRF 레거시 거대 프로젝트에 Cursor 를 최대한 잘 활용하는 방법"
date: 2025-11-05
categories: [ai]
---
## 개요

Cursor는 AI 기반 코드 에디터로, 레거시 대형 프로젝트에서 "검색·맥락 파악·리팩토링 자동화"를 중심으로 효율성을 높일 수 있습니다.

Django/DRF + PostgreSQL + Celery 같은 복잡한 백엔드 스택에서 특히 유용합니다.

---

## 1. 기본 기능 활용

### 1.1 코드 탐색

**기본 단축키:**
- `⌘P` (Quick Open): 파일명으로 빠르게 파일 열기
- `⌘⇧P` (Command Palette): 모든 명령 실행
- `⌘클릭` 또는 `F12`: 정의로 이동 (Go to Definition)
- `⇧⌘F12`: 모든 참조 찾기 (Find All References)
- `⇧⌘F`: 전체 파일에서 텍스트 검색

**실제 사용 예시:**

**파일 검색:**
1. `⌘P` 누르기
2. `models.py` 입력 → `apps/users/models.py` 파일 바로 열기

**함수/클래스 정의 찾기:**
1. `create_order` 함수명에 커서 두기
2. `⌘클릭` 또는 `F12` → 함수 정의 위치로 이동

**사용처 찾기:**
1. `User` 모델 클래스명에 커서 두기
2. `⇧⌘F12` → `User`를 사용하는 모든 파일 목록 표시

**텍스트 검색:**
1. `⇧⌘F` 누르기
2. `@transaction.atomic` 입력 → 프로젝트 전체에서 해당 데코레이터 사용처 검색

### 1.2 AI 기반 리팩토링 및 문맥 이해

**사용 방법:**
1. 코드 블록 선택 또는 파일 열기
2. `⌘L` (Mac) 또는 `Ctrl+L` (Windows)로 AI 채팅 창 열기
3. 자연어로 질문 또는 요청 입력

**실제 사용 예시:**

**리팩토링:**
```
선택: 함수 전체 선택
입력: "Refactor this function to remove side effects"
결과: 사이드 이펙트 제거된 순수 함수로 변경 제안
```

**문맥 설명:**
```
파일: views.py 열기
입력: "Explain this file in context of payment flow"
결과: 결제 플로우에서의 역할과 관련 파일 연결 설명
```

**사용처 찾기:**
```
선택: User 모델 클래스명에 커서
입력: "Find where this model is used in serializers or views"
결과: User를 사용하는 모든 Serializer, View 파일 목록
```

**연결 구조 파악:**
```
파일: models.py에서 User 모델 선택
입력: "Explain this model->serializer->view chain"
결과: User 모델 → UserSerializer → UserViewSet 연결 구조 자동 분석
```

**자동 컨텍스트 수집:**
- AI가 질문에 필요한 관련 파일을 자동으로 찾아 컨텍스트에 포함
- 예: "Explain this model->serializer->view chain" 입력 시 관련 serializer.py, views.py 자동 포함

### 1.3 Git 연동

**사용 방법:**

**Partial Commit (부분 커밋):**
1. Source Control 패널 (`⌘⇧G`) 열기
2. 변경된 파일에서 원하는 라인만 선택
3. 우클릭 → "Stage Selected Lines" 선택
4. 커밋 메시지 작성 후 커밋

**AI Commit Message 생성:**
1. Source Control 패널에서 변경사항 확인
2. AI 채팅 (`⌘L`) 열기
3. 입력: `/explain changes` 또는 "Generate commit message for these changes"
4. 생성된 커밋 메시지 확인 후 적용

**실제 사용 예시:**

**부분 커밋:**
```
파일: views.py에서 5개 함수 수정
→ 2개 함수만 선택하여 "feat: Add user filtering" 커밋
→ 나머지 3개는 별도 커밋으로 분리
```

**AI 커밋 메시지:**
```
변경사항: User 모델에 email 필드 추가, Serializer 수정
AI 입력: "Generate commit message for BE-1234"
결과: "feat(BE-1234): Add email field to User model and update serializer"
```

---

## 2. 프로젝트 설정

### 2.1 워크스페이스 설정

**설정 파일 위치:**
프로젝트 루트에 `.cursor` 폴더 생성 후 `config.json` 파일 추가

**설정 파일 예시 (`.cursor/config.json`):**

```json
{
  "project": "your-project-name",
  "language": "python",
  "framework": "django",
  "context": {
    "include": [
      "apps/*/models.py",
      "apps/*/serializers.py",
      "apps/*/views/*.py",
      "apps/*/tasks.py",
      "apps/*/tests/**/*.py"
    ],
    "exclude": [
      "migrations/**",
      "venv/**",
      "**/__pycache__/**",
      "**/settings/*.py"
    ]
  },
  "ai_assistant": {
    "max_context_files": 6,
    "default_prompt_tone": "concise",
    "enable_auto_context": true
  },
  "editor": {
    "default_linter": "ruff",
    "formatter": "black",
    "tab_size": 4,
    "auto_save": true
  }
}
```

**설정 방법:**
1. 프로젝트 루트에 `.cursor` 폴더 생성
2. `config.json` 파일 생성 후 위 내용 복사
3. 프로젝트 이름과 경로 패턴을 실제 프로젝트에 맞게 수정
4. Cursor 재시작 또는 프로젝트 다시 열기

**설정 의도:**
- Django 앱 구조 자동 인식 (`apps/*/…`)
- 마이그레이션, 캐시 등 불필요한 파일 제외하여 인덱싱 속도 향상
- 자동 컨텍스트 수집으로 관련 파일 탐색 속도 개선

### 2.2 성능 최적화 설정

**설정 접근 방법:**
1. `⌘,` (Mac) 또는 `Ctrl+,` (Windows)로 Settings 열기
2. 검색창에 "Performance" 입력
3. 또는 메뉴: `Cursor → Settings → Performance`

**권장 설정값:**

| 설정 항목 | 권장값 | 설명 |
|---------|--------|------|
| **Index large repos asynchronously** | ✅ 체크 | 대형 프로젝트 비동기 인덱싱 (UI 블로킹 방지) |
| **Enable LSP cache persistence** | ✅ 체크 | LSP 캐시 영구 저장 (재시작 후에도 캐시 유지) |
| **Limit contextual file search depth** | `3` | 컨텍스트 파일 검색 깊이 제한 |
| **AI contextual memory window** | `6 files` | AI가 기억할 파일 수 |
| **Background analysis threads** | `4` | 백그라운드 분석 스레드 수 |

**추가 최적화 팁:**

**`.cursorignore` 파일 생성:**
프로젝트 루트에 `.cursorignore` 파일 생성 후 다음 내용 추가:
```
migrations/
__pycache__/
*.log
venv/
.env
*.pyc
.DS_Store
```

**인덱스 재생성:**
- 처음 프로젝트 열 때: `⌘⇧P` → "Rebuild Index" 실행
- 인덱싱 속도 느릴 때: "Index large repos asynchronously" 활성화 확인

---

## 3. 커스텀 명령 및 프롬프트

### 3.1 커스텀 명령 생성

**생성 방법 (두 가지):**

**방법 1: UI에서 생성**
1. `⌘⇧P` → "Cursor: Add Custom Command" 입력
2. 또는 `⌘,` → Settings → Commands → "+ New Command"
3. 명령 이름, 프롬프트, 컨텍스트 입력

**방법 2: 파일로 생성**
프로젝트 루트에 `.cursor/commands.json` 파일 생성 후 JSON 형식으로 추가

#### Django 모델 분석

```json
{
  "name": "Explain Model Relations",
  "prompt": "Explain how this Django model relates to other models (FK, M2M, reverse relations). Include referenced serializer and view usage if available.",
  "context": "models.py"
}
```

**사용 방법:**
1. `apps/users/models.py` 파일 열기
2. `⌘⇧P` → "Explain Model Relations" 명령 선택
3. 또는 명령 목록에서 직접 실행

**결과 예시:**
```
User 모델 분석:
- ForeignKey: Profile (OneToOne), Order (ManyToOne)
- 역참조: user.orders.all(), user.profile
- 사용처: UserSerializer, UserViewSet, OrderSerializer
```

#### DRF Serializer 최적화

```json
{
  "name": "Optimize DRF Serializer",
  "prompt": "Review this DRF serializer for unnecessary field duplication or nested performance issues. Suggest improvements for read/write separation and validation handling.",
  "context": "serializers.py"
}
```

**감지 항목:**
- 중첩 시리얼라이저 과다 사용
- 불필요한 `depth` 사용
- read/write 분리 누락

#### Celery Task 분석

```json
{
  "name": "Analyze Celery Task",
  "prompt": "Explain this Celery task: what the side effects are, what database or cache it touches, and how to make it idempotent and retry-safe.",
  "context": "tasks.py"
}
```

#### ORM 최적화 탐색

```json
{
  "name": "Find ORM Bottlenecks",
  "prompt": "Find potential ORM bottlenecks or N+1 queries in this Django view or queryset. Suggest prefetch/select_related improvements.",
  "context": "views.py"
}
```

**예시:**
```python
# 감지 예시
users = User.objects.all()
for user in users:
    print(user.profile.bio)  # N+1 쿼리 발생

# 개선 제안
users = User.objects.select_related('profile').all()
```

#### 테스트 자동 생성

```json
{
  "name": "Generate Pytest for View",
  "prompt": "Generate pytest-django test cases for this DRF view using pytest-factoryboy and RequestFactory. Cover both success and failure cases.",
  "context": "views.py"
}
```

### 3.2 빠른 프롬프트 명령어

**사용 방법:**
1. `⌘L` (Mac) 또는 `Ctrl+L` (Windows)로 AI 채팅 창 열기
2. 아래 명령어를 입력하거나 직접 자연어로 질문

**자주 사용하는 프롬프트 패턴:**

| 명령어 | 사용 위치 | 결과 |
|--------|----------|------|
| `//explain flow` | models.py에서 실행 | 모델 ↔ 시리얼라이저 ↔ 뷰 연결 분석 |
| `//find usage` | 클래스 선택 후 | 해당 모델을 참조하는 모든 파일 탐색 |
| `//refactor atomic` | service 함수 선택 후 | `transaction.atomic()` 적용 형태로 리팩토링 제안 |
| `//generate test` | APIView 선택 후 | pytest-django 기반 테스트 초안 생성 |
| `//summarize diff` | Git diff 탭에서 | 커밋 요약 자동 생성 (Jira 형식 포함 가능) |

**실제 사용 예시:**

**연결 구조 분석:**
```
파일: models.py에서 User 모델 선택
AI 입력: "//explain flow"
결과: User 모델 → UserSerializer → UserViewSet 연결 구조 설명
```

**사용처 찾기:**
```
클래스: User 선택
AI 입력: "//find usage"
결과: User를 import/사용하는 모든 파일 목록 (serializers.py, views.py, tasks.py 등)
```

**테스트 생성:**
```
APIView: UserViewSet 선택
AI 입력: "//generate test"
결과: pytest-django 기반 테스트 코드 자동 생성
```

---

## 4. 실전 워크플로우

### 4.1 Plan Mode 활용

**사용 방법:**
1. AI 채팅 (`⌘L`) 열기
2. "Plan Mode" 활성화 또는 "Create a plan for..." 프롬프트 사용
3. 복잡한 작업 요구사항 입력

**실제 사용 예시:**

**대형 리팩토링 계획:**
```
AI 입력: "Create a plan for: 슬로우 쿼리 탐색 + 카운팅 기능 추가"
```

**결과:**
```
1단계: 로깅 설정 확인 및 슬로우 쿼리 로그 분석
2단계: N+1 쿼리 발생 위치 식별
3단계: select_related/prefetch_related 적용
4단계: 카운팅 기능 API 설계 및 구현
5단계: 테스트 작성 및 성능 테스트
6단계: 배포 전 리뷰 체크리스트
```

**장점:**
- 레거시 복잡도에서 시행착오 감소
- 작업 순서 명확화로 효율성 향상
- 팀 내 작업 공유 용이

### 4.2 샌드박스 터미널로 안전한 실험

**사용 방법:**
1. 터미널 열기: `` ` `` (백틱) 또는 `⌘J`
2. 터미널 우클릭 → "New Sandboxed Terminal" 선택
3. 샌드박스 환경에서 명령 실행

**사용 시나리오:**
- 마이그레이션 실행 전 테스트
- Bulk update 스크립트 검증
- Seed 데이터 생성
- 실험적 코드 실행

**실제 사용 예시:**

**마이그레이션 검증:**
```bash
# 샌드박스 터미널에서 실행
python manage.py migrate --dry-run
python manage.py showmigrations
```

**데이터 로드 테스트:**
```bash
# 샌드박스 터미널에서 실행
python manage.py loaddata fixtures/test_data.json
python manage.py shell
>>> User.objects.count()  # 데이터 확인
```

**주의사항:**
- 샌드박스도 프로젝트 환경과 연결되어 있으므로 DB 작업은 주의 필요
- 프로덕션 DB 연결 시 절대 사용 금지

### 4.3 자연어 검색 활용

**사용 방법:**
1. AI 채팅 (`⌘L`) 열기
2. 자연어로 질문 입력
3. 관련 파일 자동 검색 및 결과 표시

**실제 사용 예시:**

**기능 위치 찾기:**
```
AI 입력: "where is slow query logging implemented?"
결과: 
- settings.py에서 LOGGING 설정 확인
- middleware.py에서 쿼리 로깅 미들웨어 위치
- utils/logging.py에서 실제 구현 코드
```

**성능 병목 찾기:**
```
AI 입력: "Find potential bottlenecks in this Django + PostgreSQL codebase"
결과:
- N+1 쿼리 발생 가능한 뷰 목록
- 인덱스가 필요한 쿼리 제안
- 캐시 미적용 구간 식별
```

**특정 패턴 검색:**
```
AI 입력: "all celery tasks usage"
결과: 
- 모든 tasks.py 파일 목록
- @shared_task 데코레이터 사용 위치
- celery task 호출 위치
```

### 4.4 레거시 리팩토링 워크플로우

**단계별 실전 예시:**

**1단계: 의존 그래프 파악**
```
파일: apps/users/views.py 열기
AI 입력: "Explain this module dependency graph"
결과:
- imports: User 모델, UserSerializer, Order 모델
- 의존성: services/order_service.py, utils/email.py
- 역의존성: api/urls.py에서 이 뷰 사용
```

**2단계: 함수 단위 리팩토링**
```
선택: 복잡한 함수 전체 선택
AI 입력: "Split this function into smaller pure functions"
결과:
- 입력 검증 함수 분리
- 비즈니스 로직 함수 분리
- 응답 생성 함수 분리
```

**3단계: 테스트 보조**
```
선택: 리팩토링된 함수 선택
AI 입력: "Generate pytest for this function using factory fixtures"
결과:
- pytest-django 테스트 코드 생성
- factory-boy 기반 fixture 자동 생성
- 성공/실패 케이스 모두 포함
```

**전체 워크플로우 예시:**
```
1. 모듈 열기 → 의존성 분석
2. 복잡한 함수 식별 → 리팩토링 제안 받기
3. 리팩토링 적용 → 테스트 자동 생성
4. 테스트 실행 → 문제점 수정
```

---

## 5. 팀 공유 설정

### 5.1 Team Commands 활용

**설정 방법:**
1. `⌘,` → Settings → Commands
2. "Team Commands" 탭 선택
3. 팀 공유 명령 추가 (Cursor Pro/Team 플랜 필요)

**공유 명령 예시:**

**1. PostgreSQL DDL 컨벤션:**
```json
{
  "name": "Refactor PostgreSQL DDL",
  "prompt": "Refactor PostgreSQL DDL following our convention: use snake_case for table names, add indexes for foreign keys, include created_at/updated_at timestamps."
}
```

**2. DRF 테스트 생성:**
```json
{
  "name": "Generate DRF Test",
  "prompt": "Generate pytest-django test cases for this DRF viewset using pytest-factoryboy and RequestFactory. Cover both success and failure cases."
}
```

**3. 커밋 메시지 생성:**
```json
{
  "name": "Generate Commit Message",
  "prompt": "Generate commit message summarizing changes for {ticket_id}. Follow format: 'feat({ticket_id}): description' or 'fix({ticket_id}): description'"
}
```

**실제 사용:**
- 팀원 모두가 동일한 명령 사용 가능
- `⌘⇧P` → Team Commands에서 선택

**장점:**
- 코드 스타일 일관성 유지
- 프로젝트 컨벤션 자동 적용
- 새 팀원 온보딩 시간 단축
- 코드 리뷰 품질 향상

---

## 6. 주의사항

### 6.1 필수 검증

- ✅ **사람 리뷰 필수**: AI 제안은 항상 검토 후 적용
- ✅ **백업/브랜치 전략**: 리팩토링 전 브랜치 생성 및 백업
- ✅ **롤백 계획**: 문제 발생 시 빠른 복구 방안 준비

### 6.2 샌드박스 터미널 제한사항

- 완전 격리 환경이 아니므로 DB 마이그레이션, 민감 데이터 작업은 별도 안전절차 필요
- 프로덕션 환경에서는 직접 실행 금지

### 6.3 프롬프트 관리

- 팀 공유 프롬프트는 너무 일반화하지 말 것
- 프로젝트 맥락에 맞게 주기적으로 갱신
- 특수 케이스를 놓치지 않도록 주의

---

## 7. 최신 기능 요약

- **LSP 성능 향상**: Python/TypeScript 대형 프로젝트 대응 개선
- **팀 명령 및 공유 설정**: 중앙 관리 가능
- **Plan Mode**: 사전 계획 및 병렬 플랜 구성
- **샌드박스 터미널**: 격리된 환경에서 명령 실행
- **개선된 검색/인덱싱**: 대형 코드베이스 성능 향상
- **자동 컨텍스트 수집**: 수동 파일 첨부 없이 자동 수집
