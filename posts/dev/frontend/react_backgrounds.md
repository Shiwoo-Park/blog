---
layout: post
title: "React 공부를 위한 배경지식"
date: 2020-11-19
categories: [frontend, react]
---
최근에 시간날때 틈틈히 [실전 리액트 프로그래밍 강좌](https://www.inflearn.com/course/%EC%8B%A4%EC%A0%84-%EB%A6%AC%EC%95%A1%ED%8A%B8-%ED%94%84%EB%A1%9C%EA%B7%B8%EB%9E%98%EB%B0%8D/dashboard) 를 듣고 있다.

강의를 들으면서 리액트 개발을 시작하기 위해 기본적으로 알아야 하는 기초 지식들을 정리해 보았다.

## 개념정리

### Babel

- 공식 js 문법이 아닌 다른 문법(종류 다양)의 js화 하고자 하는 코드를 최적화된 pure js 코드로 뽑아주는 프로그램 (예를들어 JSX 를 pure js 로 변환)
- Plugin : 하나의 기능
- Preset : 특정 주제와 관련된 여러개 plugin 을 모아놓은것

### Webpack

- [가장 큰 이유] js 파일간에 복잡한 의존성을 해결해주는 모듈 시스템을 제공해준다!!! (export, import)
- 파일 내용 기반 해쉬값 추가: 효율적으로 브라우저 캐싱 도움
- 미사용 파일 제거
- js 파일 압축
- JS 에서 css, json, text 파일등을 일반 모듈처럼 불러오기 제공
- 환경변수 주입
- ... 외에도 매우 다양한 기능 제공

```javascript
// ######## ESM 형식 ########

// file1.js
export default function func1() {}
export function func2() {}
export const var1 = 123;
export let var2 = "hello";

// file2.js
// export default 한것은 자동으로 매핑된다. (myFunc1)
// 나머지는 중괄호를 열어서 읽어들여야 함
import myFunc1, { func2, var1, var2 } from "./file1.js";

// file3.js
import { func2 as myFunc1 } from "./file1.js";
```

### 기타 용어 정리

- JSX: 리액트 앱에서만 사용되는 JS 를 확장한 문법, 결과적으로 React Element 를 생성
- npx {BIN_FILE}: node_modules/bin 안에 있는 바이너리를 실행해줌
- ESM: ES6 에 추가된 문법, 요즘 브라우저에서는 제공해줌, `<script type="module">` 이라고 적어주면 됨
- commonJS : Node 에서 많이 사용되는 문법, 많은 오픈소스가 이 문법으로 제공됨
- polyfill : 오래된 브라우저 지원을 위한 라이브러리
- jest : js 테스팅 라이브러리
- eslint : js 코딩컨벤션 체킹용 라이브러리
- HMR (Hot Module Replacement) : 실시간 개발 변경사항 반영용 라이브러리
- SSR (Server-side rendering) : next.js 를 활용하면 구현 가능, CRA(create-react-app) 를 이용하면 구현이 어렵다

### 가장 dry 한 react 개발환경 셋업

```shellscript
npm init -y
npm install @babel/core @babel/cli @babel/preset-react
npm install webpack webpack-cli react react-dom

# start babel service
npx babel --watch src --out-dir . --presets @babel/preset-react

# Start temporary web server (local files as static mode)
npx serve

# dist 폴더안에 bundling 된 단일 js 파일을 뽑아준다
npx webpack
```

## CRA (create-react-app)

- 상세한 커스터마이징이 필요없고 빠르고 쉽게 리액트 앱을 만들고 싶다면 추천
- SSR 구현이 어려움

### polyfill

- 특정 js 네이티브 함수의 하위 브라우저 지원 여부 파악: [caniuse.com](https://caniuse.com/) 활용
- 하위 브라우저 지원을 하고 싶다면 [core-js](https://github.com/zloirock/core-js) 에서 해당 함수 path 를 찾아서 사용하는 파일에 import 만 해주면 됨 (create-react-app 에서 이미 core-js 를 설치하기때문)

### 환경변수 관련

- 변수 액세스 process.env.{VAR_NAME}
- 환경별로 나누어서 관리하는법 .env.{env_profile} 형식의 파일을 프로젝트 root path 에 위치 시키면 알아서 구동할때 읽어들임
- ex) .env.development, .env.production 등의 파일로 작성
- process.env.NODE_ENV 의 값은 npm serve 일때 development, npm build 일떄 production 으로 자동 세팅이 됨.

### 빌드하면

- 큰 사이즈 이미지: 별도 파일로 떨군다
- 작은 사이즈 이미지: js 파일 안에 내장

### 테스트 파일 관련

- 인식하는 파일 형식: `xxx.test.js, xxx.spec.js`
- **tests** 폴더 밑에 넣으면 전부 테스트 파일로 인식
- 추천하는 방식: `xxx.js 와 xxx.test.js` 파일을 서로 가까이 두어 관리하면 편함

### 기타 Tip

- chrome extension - [react developer tools](https://chrome.google.com/webstore/detail/react-developer-tools/fmkadmapgofadopljbjfkapdkoienihi) 설치하기

```bash
# https 로 로컬에서 서비스 띄우기
HTTPS=true npm start

# 빌드 파일로 서비스 구동하기
npm build
npm install -g serve
serve -s build
```
