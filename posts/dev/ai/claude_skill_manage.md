---
layout: post
title: "스킬 엔지니어링: 좋은 스킬 만들기부터 팀 전체 배포까지"
date: 2026-08-20
categories: [dev, ai]
description: "Claude Code 스킬(SKILL.md) 작성 원칙부터 온디맨드 로딩 예산 관리, 자가개선 루프, 프로젝트-개인-회사 단위 배포까지 공식 문서로 검증한 스킬 관리 노하우를 정리했습니다."
keywords: "Claude Code, Skill, SKILL.md, 스킬 엔지니어링, description 트리거, progressive disclosure, skillListingBudgetFraction, 플러그인 마켓플레이스, 스킬 배포"
image: "/resources/og-dev.png"
---

> [하네스 엔지니어링 시리즈](/blog/posts/dev/ai/good_harness_tips_2/)에서 스킬을 "온디맨드로 로드되는 절차 지식"으로 다뤘습니다. 이 글은 그 스킬 자체에만 집중합니다 — 어떻게 작성하고, 어떻게 다듬고, 어떻게 팀 전체로 넓히는가.

`.claude/skills/`에 파일 몇 개를 쌓아두는 것과, **실제로 필요한 순간에 정확히 호출되고 팀 전체가 공유하는 스킬 체계**를 만드는 것은 다른 일입니다. 이 글은 그 격차를 메우는 방법을 정리합니다.

---

## 1. 스킬이란, 관리가 필요한 이유

### 1-1. 온디맨드 로딩과 커맨드의 통합

스킬은 `SKILL.md` 파일 하나로 시작합니다. 세션이 시작될 때는 **이름과 `description`만** 컨텍스트에 올라가고, 본문은 실제로 호출될 때 로드됩니다. 그래서 긴 참고 자료를 스킬에 넣어도 평소 비용이 거의 없습니다([하네스 2편](/blog/posts/dev/ai/good_harness_tips_2/)에서 다룬 3층 지식 구조의 2층입니다).

[공식 문서](https://code.claude.com/docs/en/skills) 기준으로 최근 확인된 중요한 사실이 하나 있습니다. **커스텀 커맨드와 스킬이 사실상 통합됐습니다.**

```
.claude/commands/deploy.md         → /deploy
.claude/skills/deploy/SKILL.md     → /deploy
```

둘 다 같은 커맨드를 만들고 동일하게 동작합니다. 차이는 스킬 쪽이 부가 파일 디렉터리, 프론트매터로 호출 주체를 제어하는 기능, 자동 트리거 기능을 더 가진다는 점입니다. 이름이 같으면 **스킬이 커맨드보다 우선**합니다. 기존 `.claude/commands/` 파일은 그대로 동작하니 마이그레이션이 강제되지는 않습니다.

### 1-2. 스킬이 많아지면 생기는 문제 — 컨텍스트 1% 예산

스킬이 3~4개일 때는 별문제가 없습니다. 문제는 수십 개로 늘어날 때 시작됩니다.

세션 시작 시 로드되는 "스킬 목록"(이름 + `description`)에는 **컨텍스트 창의 1%**라는 고정 예산이 걸려 있습니다. 목록이 이 예산을 넘으면 Claude Code는 **가장 안 쓰는 스킬부터** description을 잘라냅니다. 그 스킬의 트리거 문구가 잘려나가면, 정작 필요한 순간에 호출되지 않습니다.

| 설정 | 역할 |
|---|---|
| `skillListingBudgetFraction` | 예산 비율 조정 (기본 1%, 예: `0.02` = 2%) |
| `skillListingMaxDescChars` | 항목 하나의 최대 글자 수 (기본 1,536자) |
| `skillOverrides`에 `"name-only"` | 특정 스킬을 이름만 노출해 예산을 다른 스킬에 양보 |
| `/doctor` | 목록이 실제로 얼마나 컨텍스트를 먹는지 추정 |

핵심 대응은 **`description` 앞부분에 핵심 트리거 문구를 먼저 쓰는 것**입니다. 잘림은 뒤에서부터 일어나므로, 가장 중요한 트리거 키워드를 앞에 배치하면 예산이 부족해도 살아남습니다.

---

## 2. 좋은 스킬 작성 원칙

[공식 스킬 작성 가이드](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) 기준으로 정리합니다.

### 2-1. `description`은 트리거다

`description`은 문서가 아니라 **호출 조건**입니다. Claude는 수십~수백 개의 스킬 중 이 필드만 보고 고릅니다.

```yaml
# 좋은 예
description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.

# 나쁜 예
description: Helps with documents
```

세 가지 규칙이 있습니다.

- **3인칭으로 쓴다** — "I can help you..."가 아니라 "Processes..."로. description은 시스템 프롬프트에 그대로 삽입되므로 인칭이 섞이면 탐색이 불안정해집니다.
- **무엇을 하는지 + 언제 쓰는지를 함께 쓴다** — 기능 설명만으로는 트리거 조건이 안 됩니다.
- **사용자가 실제로 쓸 문구를 포함한다** — "PDF", "폼 작성" 같은 구체적 키워드가 있어야 매칭됩니다.

가상의 예를 들어보겠습니다. 배포 파이프라인을 운영하는 팀이 릴리즈 노트 작성을 스킬로 만든다면, description은 이런 모습이어야 합니다.

```yaml
name: writing-release-notes
description: 릴리즈 노트를 구성 검토 → 승인 → 작성 단계로 완성하고 CHANGELOG.md 최신 버전 섹션에 추가한다. "릴리즈 노트 써줘", "이번 배포 체인지로그 정리해줘" 같은 요청에 사용.
```

무엇을 하는지(구성 검토→승인→작성→`CHANGELOG.md` 추가)와, 사용자가 실제로 칠 문구("릴리즈 노트 써줘" 등)가 한 줄에 다 들어 있습니다.

### 2-2. 이름 규칙

`name`은 소문자, 숫자, 하이픈만 허용됩니다. 공식 가이드는 **동명사형(gerund)**을 권장합니다.

| 권장 | 지양 |
|---|---|
| `processing-pdfs`, `writing-documentation` | `helper`, `utils`, `tools` (너무 모호) |
| `analyzing-spreadsheets` | `documents`, `data` (너무 광범위) |

동명사형이 아니어도 크게 문제는 없지만, **한 저장소 안에서 패턴을 통일**하는 것이 중요합니다. 예를 들어 위 팀의 배포 관련 스킬을 `committing-changes`, `writing-release-notes`, `writing-hotfix-notes`, `summarizing-incident-reports`처럼 전부 동명사형으로 통일하면, 스킬 목록만 봐도 "이건 무언가를 하는 절차구나"를 바로 알 수 있습니다.

### 2-3. 자유도(freedom)를 작업 성격에 맞춘다

모든 스킬을 세세한 스크립트로 쓸 필요는 없습니다. 작업이 얼마나 "위험하고 변동 없는" 일인지에 따라 자유도를 다르게 줍니다.

| 자유도 | 언제 | 예시 |
|---|---|---|
| **높음** (텍스트 지침) | 여러 접근이 다 정답, 맥락에 따라 판단 필요 | "코드 구조를 분석하고 개선점을 제안하라" |
| **중간** (틀 + 파라미터) | 선호 패턴은 있지만 약간의 변형 허용 | 템플릿 코드에 파라미터만 채우기 |
| **낮음** (정확한 스크립트) | 틀리면 안 되고 순서가 고정됨 | "정확히 이 스크립트만 실행하라, 플래그 추가 금지" |

공식 가이드의 비유가 명확합니다. **"절벽 사이 좁은 다리"**에는 정확한 지시(낮은 자유도)를, **"위험 없는 열린 들판"**에는 방향만 주고 판단은 맡깁니다(높은 자유도). 앞서 예로 든 `committing-changes` 스킬이라면, "변경사항을 확인해 커밋 메시지를 제안하고 반드시 사용자 승인을 받은 뒤에만 커밋한다"는 절차는 낮은 자유도(순서와 승인 단계가 고정)로 못박고, 커밋 메시지를 어떤 문구로 요약할지는 중간 자유도로 맡기는 식으로 설계합니다.

### 2-4. Progressive Disclosure — 본문은 짧게, 참조는 필요할 때만

공식 가이드의 기준은 명확합니다.

- **`SKILL.md` 본문은 500줄 이하**를 목표로 한다
- 넘어가면 별도 참조 파일로 분리한다 (`REFERENCE.md`, `FORMS.md` 등)
- **참조는 `SKILL.md`에서 딱 1단계까지만** — 참조 파일이 또 다른 파일을 참조하면, Claude가 `head -100` 같은 명령으로 일부만 읽고 넘어가는 경우가 생겨 정보가 누락됩니다
- 100줄이 넘는 참조 파일에는 맨 위에 목차를 둔다

앞서 만든 `writing-release-notes`를 확장해 핫픽스 전용 스킬을 만든다면, 이 패턴이 이렇게 적용됩니다.

```markdown
---
name: writing-hotfix-notes
description: 긴급 핫픽스 릴리즈 노트를 작성한다. 기본 절차는 writing-release-notes 스킬을 따르되, 영향 범위와 롤백 절차 항목을 필수로 포함한다. "핫픽스 노트 써줘", "긴급배포 공지 작성해줘" 같은 요청에 사용.
---

기본적인 작성 절차·원칙은 **`writing-release-notes` 스킬**을 따른다.

## 추가로 필수 포함할 항목
- 영향 범위 (어떤 사용자·기능이 영향을 받았는가)
- 롤백 절차 (문제 발생 시 되돌리는 방법)
```

핫픽스 전용 규칙만 자기 파일에 두고, 공통 절차는 `writing-release-notes`를 참조합니다. 두 스킬을 하나로 합쳤다면 본문이 훨씬 길어지고, 일반 릴리즈 노트를 쓸 때도 핫픽스 전용 항목(영향 범위, 롤백 절차)까지 매번 검토해야 했을 상황을 피한 구조입니다.

### 2-5. 실전 검증 — 가상의 배포 팀 스킬 4종 비교

| 스킬 | description 트리거 문구 | 구조 |
|---|---|---|
| `committing-changes` | "커밋해줘", "푸시해줘", "변경사항 정리해서 올려줘" | 단일 파일, 낮은 자유도(승인 절차 고정) |
| `writing-release-notes` | "릴리즈 노트 써줘", "이번 배포 체인지로그 정리해줘" | 단일 파일, 기본 절차 정의 |
| `writing-hotfix-notes` | "핫픽스 노트 써줘", "긴급배포 공지 작성해줘" | `writing-release-notes`를 참조 (2-4의 progressive disclosure) |
| `summarizing-incident-reports` | "인시던트 리포트 써줘", "이번 장애 포스트모템 정리해줘" | 로그·모니터링 조사 단계가 추가된 변형 |

네 스킬 모두 **"사용자가 실제로 칠 말"을 description에 그대로 박아뒀다**는 공통점이 있습니다. 추상적인 기능 설명이 아니라 트리거 문구 나열 — 이게 2-1에서 다룬 원칙이 실제로 지켜지고 있는 증거입니다.

---

## 3. 스킬 다듬기 — 스스로 발전시키기

### 3-1. "Claude A / Claude B" 반복 개발 루프

공식 가이드가 제시하는 스킬 개선 방법론입니다.

```
① Claude A와 함께 스킬 없이 작업 → 반복적으로 주는 맥락·규칙을 포착
② "방금 작업 패턴을 캡처하는 스킬을 만들어줘"라고 Claude A에게 요청
③ Claude A가 만든 스킬을 검토 — 불필요한 설명은 제거 요청
④ 새 세션(Claude B)에 스킬을 로드해 실제 작업 시켜보기
⑤ Claude B가 놓친 부분을 Claude A에게 구체적으로 전달해 개선
⑥ 반복
```

여기서 중요한 건 **관찰 대상이 Claude B의 실제 행동**이라는 점입니다. Claude B가 파일을 예상 밖 순서로 읽거나, 참조 파일을 무시하거나, 같은 섹션을 반복해서 읽는다면 스킬 구조에 문제가 있다는 신호입니다.

### 3-2. 공식 자가기록 패턴 — `/run-skill-generator`, `/verify`

지인이 말한 "스킬이 스스로 발전한다"는 개념은 실제로 Claude Code에 공식 기능으로 있습니다. 다만 동작 방식은 "완전 자율"이 아니라 **절제된 조건부**입니다.

- `/run-skill-generator` — 깨끗한 환경에서 앱을 띄우며 성공한 절차(설치 명령, 환경변수, 실행 스크립트)를 캡처해 `.claude/skills/run-<name>/`에 프로젝트 스킬로 커밋합니다. 이후 `/run`, `/verify` 등 다른 커맨드가 이 레시피를 그대로 따릅니다.
- `/verify`도 자기 레시피를 기록합니다. 기록된 레시피가 없으면 앱을 직접 빌드·구동해보고, 성공한 절차를 `SKILL.md`에 씁니다.

핵심 제약이 하나 있습니다. **Claude는 "실행이 잘못된 방향으로 유도됐을 때만" 기록을 수정합니다** — 실패한 명령이나 빠진 단계가 있을 때만 고칩니다. 매 실행마다 무조건 덮어쓰는 방식이 아니라서, 커밋해도 세션마다 diff가 생기지 않습니다. "AI 쓸수록 스킬이 저절로 좋아진다"는 표현은 정확히는 **"실패했을 때만 자산으로 남는다"**로 이해하는 게 맞습니다 — [하네스 2편의 에스컬레이션 규칙](/blog/posts/dev/ai/good_harness_tips_2/)과 같은 원리입니다.

### 3-3. 외부 생태계에서 가져오기 — skills.sh

직접 만들지 않고 검증된 스킬을 가져오는 경로도 있습니다. [Vercel Labs의 `skills` CLI](https://github.com/vercel-labs/skills)와 스킬 디렉터리 [skills.sh](https://www.skills.sh)가 실제로 운영 중입니다.

```bash
npx skills add vercel-labs/agent-skills
```

Claude Code를 포함해 40개 이상의 에이전트 도구와 호환되는 설치 포맷을 쓰므로, 한 번 잘 만든 스킬을 여러 도구에서 재사용할 수 있습니다. 처음부터 새로 쓰기보다, 비슷한 용도의 스킬이 이미 있는지 먼저 확인하는 것이 효율적입니다.

### 3-4. 스킬이 너무 많아지면

1-2에서 다룬 예산 문제 외에, 물리적으로 스킬이 늘어날 때 쓸 수 있는 구조적 해법이 있습니다.

**모노레포 nested 스킬**: 하위 디렉터리에도 `.claude/skills/`를 둘 수 있습니다. 이 스킬들은 세션 시작 시 전부 로드되지 않고, **Claude가 그 디렉터리의 파일을 실제로 읽거나 수정할 때만** 로드됩니다. 이름이 상위 스킬과 충돌하면 `apps/web:deploy`처럼 경로가 붙은 이름으로 구분됩니다.

```text
project-root/
├── .claude/skills/deploy/SKILL.md          → /deploy
└── apps/web/.claude/skills/deploy/SKILL.md → /apps/web:deploy (충돌 시)
```

이렇게 하면 프론트엔드 작업 중에는 백엔드 전용 스킬이 목록에 없고, 그 반대도 마찬가지입니다. 스킬 수가 늘어나도 **한 시점에 로드되는 목록 자체가 작업 범위만큼만 늘어납니다.**

정리 기준은 단순합니다.

> **description이 잘려도 상관없을 만큼 안 쓰는 스킬인가?** 맞다면 삭제 후보, 자주 쓰는데 트리거가 안 된다면 description을 앞부분부터 다시 쓴다.

---

## 4. 스킬 레벨업: 프로젝트 → 개인 → 회사 전체

### 4-1. 4가지 스코프와 충돌 우선순위

| 스코프 | 위치 | 적용 범위 |
|---|---|---|
| **Enterprise** | 관리 설정(managed settings) 내 `.claude/skills/` | 조직 전체 사용자 |
| **Personal** | `~/.claude/skills/<name>/SKILL.md` | 내 모든 프로젝트 |
| **Project** | `.claude/skills/<name>/SKILL.md` | 이 프로젝트만 |
| **Plugin** | `<plugin>/skills/<name>/SKILL.md` | 플러그인이 켜진 곳 |

같은 이름의 스킬이 여러 스코프에 있으면 [공식 규칙](https://code.claude.com/docs/en/skills)이 명확합니다.

> **Enterprise가 Personal을 이기고, Personal이 Project를 이긴다.**

플러그인 스킬은 `plugin-name:skill-name`으로 네임스페이스가 분리되어 다른 스코프와 충돌하지 않습니다.

여기서 헷갈리지 말아야 할 점이 있습니다. **이 충돌 우선순위와 "승격(promotion)" 흐름은 서로 다른 질문**입니다. 충돌 우선순위는 "같은 이름이 여러 곳에 있을 때 뭐가 이기나"에 대한 답이고, 승격은 "프로젝트에서 시작한 스킬을 언제 개인/회사 스코프로 넓힐까"에 대한 실무 판단입니다. 아래는 후자를 다룹니다.

### 4-2. 프로젝트 전용에서 시작한다

앞서 예로 든 배포 팀이라면, `committing-changes`, `writing-release-notes`, `writing-hotfix-notes`, `summarizing-incident-reports` 네 스킬 모두 해당 서비스 저장소의 `.claude/skills/`에 두고 git으로 커밋하는 게 맞습니다. **그 저장소에서만 의미 있는 규칙**(팀의 conventional commit prefix, `CHANGELOG.md` 포맷, 배포 파이프라인 이름)이 담겨 있기 때문에 프로젝트 스코프가 정확한 선택입니다.

판단 기준: **이 스킬의 내용이 이 프로젝트의 구조·컨벤션에 의존하는가?** 그렇다면 프로젝트에 둡니다.

### 4-3. 개인 전체로 승격하는 기준

반대로 프로젝트 특정 로직이 빠지고, 여러 프로젝트에서 반복적으로 같은 걸 다시 만들고 있다면 개인 스코프(`~/.claude/skills/`)로 옮길 후보입니다.

```
판단 질문
① 이 스킬 내용이 특정 프로젝트의 구조에 의존하지 않는가?
② 최근 2~3개 이상의 다른 프로젝트에서 비슷한 걸 다시 만들었는가?
③ 프로젝트마다 조금씩 다른 부분이 있다면, 그 차이를 파라미터로 뽑아낼 수 있는가?
```

세 질문에 모두 "예"면 승격 후보입니다. 미리 일반화해서 개인 스코프에 두기보다, **실제로 반복되는 아픔을 확인한 뒤에 옮기는 편**이 안전합니다 — 너무 일찍 일반화하면 프로젝트마다 다른 예외 케이스를 스킬 하나로 억지로 수용하게 됩니다.

### 4-4. 회사 전체 배포 — 플러그인과 마켓플레이스

팀 전체가 같은 스킬을 쓰게 하려면 [플러그인](https://code.claude.com/docs/en/plugins-reference)으로 묶습니다.

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json
└── skills/
    ├── code-reviewer/SKILL.md
    └── deploy-checklist/SKILL.md
```

```json
// plugin.json
{
  "name": "team-tools",
  "displayName": "Team Tools",
  "version": "1.0.0",
  "skills": "./skills/",
  "author": { "name": "팀 이름", "email": "team@company.com" }
}
```

배포 방식은 규모에 따라 세 단계로 나뉩니다.

| 규모 | 방식 | 공유 방법 |
|---|---|---|
| 개인/소규모 | 스킬 디렉터리 플러그인 | `~/.claude/skills/`(개인) 또는 `.claude/skills/`(프로젝트, git 체크인) |
| 팀/회사 | 조직 내부 마켓플레이스 | 사내 git 저장소 + `marketplace.json` |
| 외부 공개 | 공식/커뮤니티 마켓플레이스 | npm 또는 공개 git 저장소 |

**팀 배포 절차**는 실제로 이렇게 진행됩니다.

```bash
# 1) 스킬 저장소를 태그로 릴리스
git tag v1.0.0 && git push origin v1.0.0

# 2) 마켓플레이스 등록 (한 번만, 팀 전체가 공유하는 위치에 marketplace.json 배치)
claude marketplace add "https://company.com/marketplaces/company-plugins.json"

# 3) 프로젝트 범위로 설치 → .claude/settings.json에 기록되어 팀 전체가 공유
claude plugin install team-tools --scope project
```

`marketplace.json` 예시:

```json
{
  "name": "company-plugins",
  "plugins": [
    {
      "name": "team-tools",
      "source": "git+https://github.company.com/plugins/team-tools.git#v1.0.0"
    }
  ]
}
```

`--scope project`로 설치하면 `enabledPlugins` 설정이 `.claude/settings.json`에 기록되고, 이 파일이 git에 커밋되므로 **팀원이 저장소를 clone하는 것만으로 같은 스킬을 갖추게 됩니다.** 버전을 올릴 때는 새 태그를 찍고 `claude plugin update`로 갱신합니다.

---

## 5. 스킬 vs 커맨드 vs 서브에이전트

| | 스킬 | 커맨드 | 서브에이전트 |
|---|---|---|---|
| **로딩 시점** | 이름+description만 상시, 본문은 호출 시 | `/name` 입력 시 전체 로드 | 별도 컨텍스트로 스폰 |
| **호출 방식** | 자동 트리거 또는 `/이름` | `/이름`만 | 명시적 스폰 |
| **적합한 내용** | 때때로 하는 절차 | 스킬과 사실상 동일(1-1) | 독립된 역할·권한이 필요한 작업 |
| **컨텍스트 격리** | 메인 대화에 계속 남음 | 메인 대화에 계속 남음 | 스폰된 에이전트 안에만 |

스킬과 커맨드의 경계는 1-1에서 다뤘듯 이제 거의 사라졌습니다. 진짜 갈리는 지점은 **"메인 대화의 컨텍스트를 계속 쓸 것인가, 격리된 컨텍스트에서 처리할 것인가"**입니다. 격리가 필요하면 서브에이전트, 아니면 스킬입니다. 서브에이전트의 가드레일·검증 설계는 [하네스 엔지니어링 1~3편](/blog/posts/dev/ai/good_harness_tips_1/)에서 자세히 다뤘습니다.

---

## 핵심요약

- **스킬과 커맨드는 사실상 통합됐다.** `.claude/commands/*.md`와 `.claude/skills/*/SKILL.md`가 같은 커맨드를 만들며, 이름이 겹치면 스킬이 우선한다.
- **스킬 목록에는 컨텍스트의 1% 예산이 걸려 있다.** 넘치면 안 쓰는 스킬부터 description이 잘린다. 핵심 트리거 문구를 앞에 배치하고, `/doctor`로 예산 소모량을 확인한다.
- **`description`은 문서가 아니라 트리거다.** 3인칭으로, "무엇을 하는지 + 언제 쓰는지 + 사용자가 실제로 칠 문구"를 담는다.
- **Progressive Disclosure**: `SKILL.md`는 500줄 이하, 참조 파일은 1단계 깊이까지만. 위 예시의 `writing-hotfix-notes`가 `writing-release-notes`를 참조하는 구조가 그 실사례다.
- **자가개선은 "실패했을 때만" 기록을 갱신하는 절제된 패턴**이다(`/run-skill-generator`, `/verify`). 매 실행마다 무조건 덮어쓰는 완전 자율 방식이 아니다.
- **모노레포에서는 nested `.claude/skills/`로 스킬 목록을 디렉터리 범위로 좁힐 수 있다.** 세션 시작 시 전부 로드되지 않고, 그 디렉터리에서 작업할 때만 목록에 들어온다.
- **스코프 충돌 우선순위는 Enterprise > Personal > Project**이고, 이것과 "언제 승격시킬까"는 별개의 질문이다. 승격은 프로젝트 특정 로직이 빠지고 반복 사용이 확인된 뒤에 한다.
- **팀 전체 배포는 플러그인 + 조직 내부 마켓플레이스**가 표준 패턴이다. `claude marketplace add` → `claude plugin install --scope project`로 설치하면 `.claude/settings.json`에 기록되어 저장소 clone만으로 팀 전체가 같은 스킬을 갖춘다.
