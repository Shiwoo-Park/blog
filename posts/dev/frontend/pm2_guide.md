---
layout: post
title: "js 프로세스 관리도구: pm2 간단 매뉴얼"
date: 2024-06-06
categories: [frontend, nodejs, pm2]
---
Next.js 앱을 PM2로 구동하려면, PM2를 사용하여 Next.js 애플리케이션을 시작하도록 설정할 수 있습니다. 

PM2는 프로세스 관리를 위한 도구로, Node.js 애플리케이션을 손쉽게 관리하고 모니터링할 수 있게 해줍니다.

### 1. PM2 설치

먼저 PM2를 글로벌로 설치합니다. 이는 한 번만 설치하면 됩니다.

```sh
npm install -g pm2
```

### 2. PM2 설정

Next.js 애플리케이션을 PM2로 구동하려면 `ecosystem.config.js` 파일을 생성하여 PM2 설정을 정의할 수 있습니다.

```sh
touch ecosystem.config.js
```

### 3. ecosystem.config.js 파일 설정

`ecosystem.config.js` 파일을 열고 다음과 같이 설정합니다:

```javascript
module.exports = {
  apps: [
    {
      name: 'myapp-web', // 앱 이름
      script: 'yarn', // 실행할 명령어
      args: 'start', // yarn 명령어의 인자
      env: {
        NODE_ENV: 'production', // 환경 변수 설정
        PORT: 4000, // 애플리케이션 포트 설정
      },
    },
  ],
};
```

### 4. PM2로 Next.js 애플리케이션 시작

PM2를 사용하여 Next.js 애플리케이션을 시작합니다.

```sh
pm2 start ecosystem.config.js
```

### 5. PM2 로그 보기 및 모니터링

PM2는 로그를 관리하고, 애플리케이션 상태를 모니터링할 수 있습니다.

```sh
pm2 logs myapp-web  # 로그 보기
pm2 monit  # 애플리케이션 모니터링
```

### 6. PM2 관리 명령어

PM2는 다양한 관리 명령어를 제공합니다.

```sh
pm2 stop myapp-web  # 애플리케이션 중지
pm2 restart myapp-web  # 애플리케이션 재시작
pm2 delete myapp-web  # 애플리케이션 삭제
```

### PM2와 Next.js 통합 예제

위의 설정을 종합하면 다음과 같은 구조가 됩니다:

#### 1. `ecosystem.config.js` 파일

```javascript
module.exports = {
  apps: [
    {
      name: 'myapp-web',
      script: 'yarn',
      args: 'start',
      env: {
        NODE_ENV: 'production',
        PORT: 4000,
      },
    },
  ],
};
```
m
#### 2. PM2 명령어 사용

```sh
pm2 start ecosystem.config.js  # PM2로 애플리케이션 시작
pm2 logs myapp-web  # 애플리케이션 로그 보기
pm2 monit  # 애플리케이션 모니터링
pm2 stop myapp-web  # 애플리케이션 중지
pm2 restart myapp-web  # 애플리케이션 재시작
pm2 delete myapp-web  # 애플리케이션 삭제
```

이와 같이 설정하면 PM2를 사용하여 Next.js 애플리케이션을 효율적으로 관리하고 모니터링할 수 있습니다. PM2의 장점을 활용하여 애플리케이션의 안정성과 가용성을 높일 수 있습니다.
