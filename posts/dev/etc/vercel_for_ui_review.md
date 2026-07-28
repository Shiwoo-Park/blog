---
layout: post
title: "개발-기획 협업을 위한 Vercel Setup 방법"
date: 2026-07-28
categories: [vercel, collaboration, frontend, devops]
description: "기획·디자인 리뷰를 스크린샷 왕복 없이 끝내는 Vercel 셋업 가이드. GitHub repo 연결부터 Preview 자동 배포, Production에 Vercel Toolbar Comments 붙이기, zoom 충돌 트러블슈팅까지 실전 정리."
keywords: "Vercel, Vercel Toolbar, Vercel Comments, Preview 배포, UI 리뷰, 기획 협업, Next.js 배포, vercel link, 자동 배포"
image: "/resources/og-dev.png"
---

기획자·디자이너에게 화면을 확인받는 과정은 대체로 이렇게 흘러간다.
개발자가 로컬에서 화면을 띄우고, 스크린샷을 찍고, Slack에 올리고,
"세 번째 카드 여백이 좀 넓어요"라는 답을 받고, 그게 어느 화면 어느 카드인지 다시 되묻는다.

이 왕복을 없애는 가장 값싼 방법이 **Vercel Preview 배포 + Vercel Toolbar Comments**다.
팀원은 URL 하나만 열면 되고, 코멘트는 **화면 위 그 위치에** 남는다.
이 글은 그 셋업을 처음부터 끝까지 따라갈 수 있게 정리한 개발자용 가이드다.

---

## 1. 왜 Vercel인가

UI 리뷰 도구로 Vercel을 쓰는 이유는 딱 두 가지다.

**첫째, 브랜치 push만으로 URL이 생긴다.**
별도 CI 설정, 서버, 도메인 작업이 없다. `git push`하면 그 브랜치 전용 Preview URL이 발급된다.

**둘째, 코멘트가 화면 좌표에 붙는다.**
Vercel Toolbar의 Comments 모드는 배포된 페이지 위에 직접 핀을 꽂는 방식이다.
"어느 화면의 무엇"을 설명할 필요가 없어진다. 스레드는 이메일·Slack으로 연결된다.

> **전제**: Comments는 모든 Preview 배포에서 **모든 플랜 기본 활성화**이고 무료다.
> 단 **참여자 전원이 Vercel 계정을 가지고 있어야** 코멘트를 남길 수 있다. 이 제약이 뒤에서 중요해진다.

---

## 2. 기본 셋업 (10분)

### 2-1. 사전 확인

```bash
# 1) GitHub remote가 잡혀 있는지
git remote -v

# 2) 배포 기준 브랜치(main)에 최신 코드가 있는지
git branch
git status
```

Vercel 계정은 **GitHub 계정으로 로그인**하는 편이 좋다. repo 연동 권한이 자동으로 처리된다.

### 2-2. 프로젝트 Import

```
Vercel Dashboard → Add New → Project → Import Git Repository
```

처음이면 `Connect GitHub`으로 권한을 허용하고, 대상 repo를 선택한 뒤 `Import`를 누른다.

### 2-3. 빌드 설정

| 설정 항목 | 값 |
|---|---|
| Framework Preset | 자동 감지 (Next.js 등) |
| **Root Directory** | 프론트엔드 코드가 있는 디렉터리 |
| Build Command | `npm run build` (기본값) |
| Output Directory | `.next` (기본값) |
| Install Command | `npm install` (기본값) |
| Environment Variables | mock 데이터만 쓴다면 없음 |

> ⚠️ **가장 흔한 첫 실패 원인은 Root Directory다.**
> 모노repo이거나 프론트엔드가 `app/`, `frontend/`, `web/` 같은 하위 디렉터리에 있으면
> **반드시 그 경로를 지정**해야 한다. 루트에 `package.json`이 없어 빌드가 즉시 깨진다.
> 나중에 바꾸려면 `Project Settings → General → Root Directory → Edit`.

`Deploy`를 누르면 클론 → `npm install` → `npm run build` → URL 발급 순으로 진행된다. 보통 2~3분.

---

## 3. 자동 배포가 동작하는 방식

추가 설정은 필요 없다. repo를 연결한 순간부터 아래처럼 동작한다.

| Git 이벤트 | Vercel 동작 |
|---|---|
| `main`에 push / merge | **Production 배포** (고정 URL) |
| 그 외 브랜치 push | **Preview 배포** (브랜치별 임시 URL) |
| Pull Request 생성 | Preview 배포 + **PR에 URL 자동 코멘트** |
| 같은 브랜치에 추가 commit | 해당 브랜치 재배포 |

- **Production**: `https://<project>.vercel.app` — 고정. 팀원에게 상시 공유할 주소
- **Preview**: `https://<project>-<branch>-<hash>.vercel.app` — 브랜치별. 리뷰 중인 작업물 주소

기준 브랜치나 배포 스킵 조건을 바꾸려면 `Project Settings → Git`
(Production Branch, Ignored Build Step)에서 조정한다.

---

## 4. 팀원 초대와 권한 — Hobby의 함정

여기서 플랜을 먼저 확인해야 한다. **협업 목적이라면 Hobby로는 안 된다.**

| 플랜 | 가격 | 협업 관점 |
|---|---|---|
| **Hobby** | 무료 | **Developer seat 1명**. 팀원 초대 불가, Viewer seat 없음 |
| **Pro** | $20/user/월 | Developer 추가 가능, **Viewer는 무제한 무료**, 외부 협업자 초대 가능 |
| **Enterprise** | 협의 | 게스트/팀 접근 제어, SCIM 등 |

기획자·디자이너는 배포 권한이 필요 없으므로 **Pro의 무제한 무료 Viewer seat**로 넣으면 된다.
즉 실제 비용은 "개발자 수 × $20" 수준으로 잡히고, 리뷰어를 늘려도 추가 과금이 없다.

### 4-1. 초대 절차

```
Dashboard → Settings → Members → Invite Member
```

이메일 또는 GitHub username을 넣고 역할을 정한다.

- **Owner**: 삭제·결제 포함 전체 권한
- **Member**: 배포·설정 관리
- **Viewer**: 읽기 전용 — 리뷰어에게 적합

특정 프로젝트만 열어주려면 팀 전체가 아니라 `Project Settings → Members → Invite to Project`를 쓴다.

### 4-2. 팀 외부 인원에게 보여줘야 한다면

외주 디자이너처럼 팀에 넣기 어려운 인원은 **Preview 배포 공유(외부 협업자 초대)** 기능을 쓴다.
단 이 기능도 **Pro/Enterprise 전용**이고, 초대받은 사람 역시 Vercel 계정이 필요하다.
"링크만 있으면 로그인 없이 코멘트"는 불가능하다.

---

## 5. Comments 툴바 켜기

Comments는 **Preview 배포에서는 기본 동작**한다. 별도 작업 없이 툴바가 자동 주입된다.
문제는 **Production(`main` 배포)에는 툴바가 기본 주입되지 않는다**는 점이다.
상시 공유용 고정 URL에서 코멘트를 받으려면 아래 두 방식 중 하나를 골라야 한다.

| 방식 | 팀원 부담 | 적합한 상황 |
|---|---|---|
| **① 브라우저 확장** | 각자 확장 설치 + Vercel 로그인 | 코드 변경 없이 끝내고 싶을 때 |
| **② `@vercel/toolbar` 패키지 주입** | 없음 (URL만 열면 됨) | 리뷰어가 비개발자라 설치를 시키기 어려울 때 |

두 방식 모두 **프로젝트 설정에서 Production 툴바를 허용**해야 동작한다.

```
Project Settings → General → Vercel Toolbar → Production: On
```

`Default`로 두면 팀 레벨 설정을 따라간다. 팀 레벨이 Off면 안 보이므로 **On으로 명시**하는 편이 안전하다.
팀 레벨에서 잠겨 있으면 `Team Settings → General → Vercel Toolbar`에서 프로젝트 오버라이드를 허용한다.

### 5-1. ① 브라우저 확장 방식

[Vercel Browser Extension](https://vercel.com/docs/vercel-toolbar/browser-extension)을 설치하고
vercel.com에 로그인해 두면, 팀이 소유한 도메인에서 툴바가 뜬다. 코드는 건드리지 않는다.
대시보드의 `Visit` 버튼 드롭다운 → `Visit with Toolbar`로 툴바가 켜진 링크를 바로 보낼 수도 있다.

### 5-2. ② 패키지 주입 방식

리뷰어에게 확장 설치를 요구하기 어렵다면 패키지를 앱에 심는다.

```bash
npm i @vercel/toolbar
vercel link
```

Next.js App Router 기준 구현은 다음과 같다.

```tsx
// src/components/dev/StaffToolbar.tsx
'use client';

import { VercelToolbar } from '@vercel/toolbar/next';

function useIsEmployee() {
  // 실제 인증 라이브러리로 교체
  return false;
}

export function StaffToolbar() {
  const isEmployee = useIsEmployee();
  return isEmployee ? <VercelToolbar /> : null;
}
```

```tsx
// src/app/layout.tsx
import { Suspense } from 'react';
import { StaffToolbar } from '@/components/dev/StaffToolbar';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ko">
      <body>
        {children}
        <Suspense fallback={null}>
          <StaffToolbar />
        </Suspense>
      </body>
    </html>
  );
}
```

Vercel 공식 권고는 위처럼 **`useIsEmployee()`로 팀원에게만 조건부 주입**하는 것이다.
그러지 않으면 모든 방문자에게 툴바가 로드되고, Vercel 계정이 없는 사람이 클릭하면 로그인 화면이 뜬다.

> **인증 시스템이 없는 UI 프리뷰라면?**
> 판별할 근거가 없으니 조건부 주입이 불가능하다. 이때는 **"이 URL은 팀 내부 전용"**이라는 전제로
> 게이팅 없이 주입하는 선택이 현실적이다. 대신 성격이 외부 공개로 바뀌는 순간
> 아래 6장의 로그인 프롬프트 이슈를 반드시 다시 검토해야 한다.
> 안전하게 가려면 `Project Settings → Deployment Protection`으로 URL 자체를 막는 방법도 있다.

### 5-3. 로컬 dev에서도 툴바를 쓰려면

로컬 개발 서버에 툴바를 띄우려면 두 가지가 **모두** 있어야 한다.

1. `next.config.mjs`의 `withVercelToolbar()` 플러그인 래핑
2. `vercel link`로 생성되는 `.vercel/project.json`

```js
// next.config.mjs
import withVercelToolbar from '@vercel/toolbar/plugins/next';

const nextConfig = { /* ... */ };

export default withVercelToolbar()(nextConfig);
```

`.vercel/`은 `.gitignore` 대상이므로 **clone한 팀원은 각자 `vercel link`를 실행해야 한다.**
없으면 dev 서버 콘솔에 `configuration is missing` 경고가 뜨고 툴바가 나타나지 않는다.

> Preview·Production은 `vercel.live`에서 스크립트를 직접 로드하므로 이 플러그인·링크와 무관하다.
> Production만 쓸 거라면 이 절은 건너뛰어도 된다.

---

## 6. 운영 주의사항

셋업이 끝난 뒤 실제로 부딪히는 것들이다.

- **비(非) 팀원에게 로그인 프롬프트가 보일 수 있다.**
  패키지를 무조건 주입하면 툴바 스크립트가 방문자 전원에게 로드된다.
  Vercel 계정이 없는 사람이 툴바를 클릭하면 로그인 화면이 뜬다.
  외부 공개 URL이라면 상시 켜두지 말 것.
- **Production 코멘트 알림은 자동 발송되지 않는다.**
  Preview 코멘트는 PR 소유자·스레드 참여자에게 메일이 가지만, Production은 다르다.
  코멘트 작성 시 담당자를 `@`로 직접 멘션하거나
  `Integrations → Vercel for Slack`을 붙여야 놓치지 않는다.
- **CSP를 쓴다면 `vercel.live`를 허용해야 한다.**
  Content-Security-Policy 헤더가 없다면 할 일이 없지만, 도입했다면
  `script-src` / `connect-src` / `img-src` / `frame-src` / `style-src` / `font-src`에
  `https://vercel.live`를, 실시간 통신용으로 `wss://ws-us3.pusher.com`을 추가해야 한다.
- **E2E 테스트가 툴바에 걸린다면** 요청 헤더에 `x-vercel-skip-toolbar: 1`을 넣으면 비활성화된다.
- **피드백 수집이 끝나면 끄자.** `Project Settings → General → Vercel Toolbar → Production: Off`.
  완전히 제거하려면 `layout.tsx`에서 툴바 컴포넌트를 삭제하고 재배포한다.

---

## 7. 실전 트러블슈팅: 툴바가 화면 밖으로 도망가는 현상

패키지 주입까지 끝냈는데 툴바가 엉뚱한 데 있는 경우가 있다. 실제로 겪은 사례다.

### 7-1. 증상

브라우저 폭에 따라 툴바가 **화면 밖으로 사라지거나 컨텐츠 한가운데에 파묻혔다.**
넓은 모니터에서 특히 심했고, 창 폭을 줄이면 위치가 또 달라졌다.

### 7-2. 원인: `html { zoom }`

해당 프로젝트는 디자인 시스템 저작 비례를 유지하려고 `html`에 **CSS `zoom`** 을 걸고 있었다.
(기준 캔버스 1150px, 0.75~1.5배 사이로 스케일)

```css
html { zoom: clamp(0.75, calc(100vw / 1150px), 1.5); }
```

`zoom`은 하위 `position: fixed` 요소의 **크기와 뷰포트 오프셋을 모두 배율만큼 곱한다.**
툴바는 `<body>` 하위에 `<vercel-live-feedback>` 엘리먼트로 주입되므로 이 배율을 그대로 상속받는다.

| 브라우저 폭 | zoom | 툴바 위치 |
|---|---|---|
| 1725px+ | 1.5 | 기준점이 1.5배 안쪽 → **컨텐츠 안쪽으로 파묻힘** |
| 1150px | 1.0 | 정상 |
| 860px | 0.75 | 기준점이 0.75배 → **하단 밖으로 벗어남** |

앱 자체 레이아웃에는 `height: calc(100vh / var(--zoom))` 같은 역보정이 이미 있었지만,
툴바는 우리 코드가 아니라 `vercel.live` 스크립트가 그리므로 역보정 대상에서 빠져 있었다.

### 7-3. 해결: zoom 상쇄 CSS 한 줄

```css
vercel-live-feedback { zoom: calc(1 / var(--zoom, 1)); }
```

- **위치 지정은 하지 않는다(못 한다).** 툴바 내부는 `closed` shadow DOM이라 외부 CSS가 닿지 않는다.
  `inset` / `bottom` 오버라이드는 무효다.
- **`zoom`은 상속되는 속성**이라 호스트 엘리먼트에 걸면 shadow DOM 내부까지 상쇄된다.
- 배율만 정상으로 돌려놓으면 위치는 툴바가 알아서 처리한다.
  툴바는 `--window-width` / `--window-height`를 JS로 실측하고,
  드래그한 위치를 `localStorage`(`vercel-toolbar-position`)에 저장한다.

### 7-4. 확인했지만 원인이 아니었던 것들

검색하면 흔히 나오는 진단들인데, 이 케이스에는 해당하지 않았다.

| 흔한 진단 | 실제 |
|---|---|
| `overflow: hidden` / `transform`이 fixed를 깬다 | 코드베이스에 `overflow-x` 없음, `html`·`body`에 `transform` 없음 |
| 앱 z-index가 툴바를 덮는다 | 앱 최대 z-index는 200. 툴바가 훨씬 높음 |
| `<VercelToolbar position="top-right" />`로 옮긴다 | **그런 prop은 없다.** 타입은 Next `<Script>` props만 받는다 |
| `transform: scale()`로 `zoom`을 대체한다 | **더 나쁘다.** `transform`은 fixed의 containing block을 새로 만들어 툴바가 뷰포트 기준을 잃는다 |

### 7-5. 운영 팁과 리스크

- 툴바는 **좌상단으로 드래그**해두는 편이 안전하다. 하단은 푸터·뷰포트 경계와 겹치기 쉽다.
- 이전에 드래그한 좌표가 zoom이 곱해진 값으로 `localStorage`에 남아 있을 수 있다.
  수정 후에도 위치가 어색하면 **한 번 다시 드래그**해 좌표를 새로 저장한다.
- 근본 해결책으로 "페이지를 고정 너비로 전환"도 검토했지만 **보류**했다.
  `zoom`을 없애면 모바일 반응형과 PC/모바일 컴포넌트 전환이 함께 깨져 전체 화면 회귀 검증이 필요하다.
  툴바 하나를 위한 비용으로는 과하다고 판단했다.
- **리스크**: `vercel-live-feedback`는 Vercel의 내부 엘리먼트명이다(`@vercel/toolbar` 0.2.7 기준 실측).
  Vercel이 이름을 바꾸면 이 CSS는 무효화되고 원래 증상으로 돌아간다(앱이 깨지는 건 아니다).
  툴바 위치가 다시 이상해지면 이 셀렉터가 아직 유효한지부터 확인할 것.

---

## 8. 협업 워크플로우

### 8-1. 리뷰 사이클

```bash
# 1. 작업 브랜치에서 화면 구현
git checkout -b feature/new-screen
git add .
git commit -m "feat: 새 화면 추가"
git push origin feature/new-screen
```

→ **Preview 배포 자동 생성.** PR이 없어도 브랜치 push만으로 URL이 나온다.
이 URL을 기획자에게 보내면 리뷰가 시작된다.

```bash
# 2. 코멘트 반영 → 같은 브랜치에 push (같은 URL이 갱신됨)
# 3. PR 생성 시 Vercel이 PR에 Preview URL을 자동 코멘트
# 4. 리뷰 완료 후 merge
git checkout main
git merge feature/new-screen
git push origin main
```

→ **Production 배포 자동 실행.** 상시 공유 URL이 갱신된다.

핵심은 **"수정했습니다"라고 말할 때 새 링크를 보내지 않아도 된다는 점**이다.
브랜치 URL은 고정이므로 기획자는 같은 탭을 새로고침하면 된다.
새 배포가 올라오면 화면 우하단에 새로고침 안내 모달이 뜬다.

### 8-2. 빌드가 실패했을 때

1. `Project → Deployments → 최신 배포 → Building` 탭에서 로그 확인
2. 로컬에서 `npm run build`로 재현
3. 흔한 원인 세 가지
   - **Root Directory 설정 누락** (2-3 참조) — 압도적 1위
   - 타입 오류 → `npx tsc --noEmit`으로 사전 확인
   - `package-lock.json` 미커밋으로 인한 의존성 불일치

### 8-3. 셋업 체크리스트

- [ ] Vercel 계정 생성 (GitHub 로그인 권장)
- [ ] GitHub repo Import
- [ ] **Root Directory 지정** ⚠️
- [ ] 첫 배포 성공 및 Production URL 확인
- [ ] 플랜 확인 — 리뷰어 초대가 필요하면 Pro (Viewer seat 무료)
- [ ] 팀원 초대 및 역할 지정 (리뷰어 = Viewer)
- [ ] 브랜치 push → Preview URL 발급 확인
- [ ] Production 툴바가 필요하면: `Toolbar → Production: On` + 확장 or 패키지 주입
- [ ] 로컬 dev에서 툴바 쓸 팀원: 각자 `vercel link`
- [ ] 툴바 위치 확인 — 브라우저 폭 860 / 1150 / 1800px로 바꿔가며 (7장)
- [ ] Comments 테스트: 코멘트 등록 → 알림 도착 확인 (Production은 Slack 연동 권장)
- [ ] 팀원에게 URL 공유

---

## 핵심요약

- **Preview 배포**는 브랜치 push만으로 URL이 생기고, **Comments**로 화면 위에 직접 피드백을 받는다. 스크린샷 왕복이 사라진다.
- 첫 배포 실패의 대부분은 **Root Directory 미지정**이다. 모노repo·하위 디렉터리 구조면 반드시 지정한다.
- **Hobby는 Developer seat 1명으로 팀원 초대가 불가하다.** 협업하려면 Pro($20/user/월), 리뷰어는 무료 Viewer seat로 넣는다.
- Comments는 **참여자 전원에게 Vercel 계정이 필요**하다. 외부 인원 초대는 Pro/Enterprise 전용.
- Preview는 툴바가 자동 주입되지만 **Production은 아니다.** 브라우저 확장(설치 부담) 또는 `@vercel/toolbar` 패키지 주입(코드 변경) 중 선택하고, `Settings → General → Vercel Toolbar → Production: On`을 반드시 켠다.
- `html`에 CSS `zoom`을 쓰는 프로젝트는 툴바 위치가 깨진다. `vercel-live-feedback { zoom: calc(1 / var(--zoom, 1)); }` 한 줄로 상쇄한다. shadow DOM이 `closed`라 위치 오버라이드는 불가능하다.
