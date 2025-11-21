---
layout: post
title: "AWS Code Deploy - 배포 시, 환경 구분하기 (환경변수 넘기기)"
date: 2024-07-29
categories: [aws, codedeploy, deployment]
---

# AWS Code Deploy - 배포 시, 환경 구분하기 (환경변수 넘기기)

> 날짜: 2024-07-29

[목록으로](https://shiwoo-park.github.io/blog)

---

보통 서비스를 배포할때 개발, 스테이징, 운영 등의 환경구분이 필요합니다.

AWS CodeDeploy를 사용하여 배포할 때 환경별로 다른 환경 변수를 지정하고, 애플리케이션에서 이를 동적으로 로드하는 방법에는 여러 가지가 있습니다. 주요 방법들을 소개해드리겠습니다

## AWS Systems Manager Parameter Store 사용
- 각 환경에 대한 파라미터를 Parameter Store에 저장합니다.
- 애플리케이션 시작 시 Parameter Store에서 값을 읽어옵니다.
- 장점: 중앙 집중식 관리, 버전 관리, 암호화 지원

```javascript
const AWS = require('aws-sdk');
const ssm = new AWS.SSM();

async function getParameter(name) {
   const { Parameter } = await ssm.getParameter({ Name: name, WithDecryption: true }).promise();
   return Parameter.Value;
}
```

## 환경 변수 파일 사용

- 각 환경에 대한 .env 파일을 생성합니다.
- CodeDeploy 스크립트에서 적절한 .env 파일을 선택하여 복사합니다.
- dotenv와 같은 라이브러리를 사용하여 .env 파일을 로드합니다.

```javascript
// CodeDeploy 스크립트에서
cp /path/to/env_files/.env.${DEPLOYMENT_GROUP_NAME} .env

// 애플리케이션에서
require('dotenv').config();
```

## AWS Secrets Manager 사용

- 민감한 정보를 Secrets Manager에 저장합니다.
- 애플리케이션 시작 시 Secrets Manager에서 값을 읽어옵니다.
- 장점: 자동 로테이션, 세밀한 접근 제어

```javascript
const AWS = require('aws-sdk');
const secretsManager = new AWS.SecretsManager();

async function getSecret(secretName) {
   const data = await secretsManager.getSecretValue({ SecretId: secretName }).promise();
   return JSON.parse(data.SecretString);
}
```

## CodeDeploy 환경 변수 사용
- CodeDeploy 애플리케이션 설정에서 환경 변수를 정의합니다.
- 애플리케이션에서 process.env를 통해 접근합니다.
- 장점: CodeDeploy 콘솔에서 직접 관리 가능

```javascript
const databaseUrl = process.env.DATABASE_URL;
```

## 구성 파일 사용
- 각 환경에 대한 JSON 또는 YAML 구성 파일을 생성합니다.
- CodeDeploy 스크립트에서 적절한 구성 파일을 선택합니다.
- 애플리케이션에서 구성 파일을 로드합니다.

```javascript
const fs = require('fs');
const config = JSON.parse(fs.readFileSync(`config.${process.env.NODE_ENV}.json`));
```

## AWS AppConfig 사용

- 동적 구성 관리를 위해 AppConfig를 사용합니다.
- 애플리케이션 실행 중에도 구성을 업데이트할 수 있습니다.
- 장점: 실시간 구성 업데이트, A/B 테스팅 지원

```javascript
const AWS = require('aws-sdk');
const appconfig = new AWS.AppConfig();

async function getConfiguration(applicationId, environmentId, configurationProfileId) {
   const { Content } = await appconfig.getConfiguration({
      Application: applicationId,
      Environment: environmentId,
      Configuration: configurationProfileId,
      ClientId: 'MyClientId'
   }).promise();
   return JSON.parse(Content.toString());
}
```

각 방법은 장단점이 있으므로, 프로젝트의 요구사항, 보안 정책, 관리의 편의성 등을 고려하여 선택하시면 좋습니다. 

대규모 프로젝트의 경우 Parameter Store나 Secrets Manager를 사용하는 것이 관리와 보안 측면에서 유리할 수 있습니다. 작은 프로젝트라면 .env 파일이나 구성 파일을 사용하는 것이 간단하고 직관적일 수 있습니다.

---

[목록으로](https://shiwoo-park.github.io/blog)
