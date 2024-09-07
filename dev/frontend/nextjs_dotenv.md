# Next.js 에서의 .env 파일 로드 방식

> 날짜: 2024-07-19

[목록으로](https://shiwoo-park.github.io/blog)

---

Next.js에서 .env 파일을 읽어들이는 시점은 애플리케이션의 빌드 및 실행 과정에 따라 다릅니다. 주요 시점은 다음과 같습니다:

1. 빌드 시점:
   - `next build` 명령을 실행할 때 .env 파일이 처리됩니다.
   - 이 때 `NEXT_PUBLIC_` 접두사가 붙은 환경 변수들이 클라이언트 사이드 번들에 포함됩니다.

2. 서버 시작 시점:
   - `next start` 또는 `next dev` 명령으로 서버를 시작할 때 .env 파일이 로드됩니다.
   - 서버 사이드에서 사용되는 모든 환경 변수가 이 때 처리됩니다.

3. getServerSideProps 실행 시:
   - 서버 사이드 렌더링 중 `getServerSideProps`가 실행될 때마다 환경 변수에 접근할 수 있습니다.

4. API 라우트 실행 시:
   - API 라우트 핸들러가 실행될 때 환경 변수에 접근할 수 있습니다.

5. 클라이언트 사이드:
   - `NEXT_PUBLIC_` 접두사가 붙은 환경 변수는 클라이언트 사이드 코드에서도 사용 가능합니다.

Next.js는 내부적으로 다음과 같은 우선순위로 .env 파일을 로드합니다:

1. `.env.$(NODE_ENV).local`
2. `.env.local` (NODE_ENV가 test일 때는 무시됨)
3. `.env.$(NODE_ENV)`
4. `.env`

여기서 `$(NODE_ENV)`는 `development`, `production`, `test` 중 하나입니다.

환경 변수 로딩의 실제 구현은 Next.js의 내부 코드에서 이루어집니다. 주로 `next/dist/lib/load-env-config.js` 파일에서 처리됩니다. 이 모듈은 Next.js의 서버 시작 과정에서 호출되어 환경 변수를 로드하고 `process.env`에 주입합니다.

주의할 점:
- 빌드 후에 환경 변수를 변경하면, 서버를 재시작해야 변경사항이 적용됩니다.
- 클라이언트 사이드에서 사용할 환경 변수는 반드시 `NEXT_PUBLIC_` 접두사를 붙여야 합니다.
- Docker 컨테이너 내에서 실행할 때는, 컨테이너 실행 시 환경 변수를 주입하거나 .env 파일을 직접 복사해야 할 수 있습니다.

환경 변수 관리는 애플리케이션의 보안과 유연성에 중요하므로, Next.js의 환경 변수 처리 메커니즘을 잘 이해하고 활용하는 것이 중요합니다.

---

[목록으로](https://shiwoo-park.github.io/blog)