# AWS - ECR 에 이미지 푸시하기

> 날짜: 2024-06-06

[목록으로](https://shiwoo-park.github.io/blog)

---

## 처음 ECS 환경 세팅 시

- 클러스터 생성
- 태스크 생성 (이때 이미지가 필요함)
- 최초 생성 시, 더미 이미지를 사용해서 인프라가 제대로 동작하는지만을 먼저 확인하는 경우가 일반적
- 동일한 이미지를 용도에 따라 2개 이상의 태그(롤백용 식별자, lastest) 로 태깅하고 ECR 에 여러번 푸시 해준다.
  - 이때 이미지는 동일한 것을 사용하므로 디스크를 2배로 먹지 않고 단순히 포인터만 여러개 생김.

## 스크립트

```shell
#!/bin/bash

set -e

# 변수 설정
REPO_NAME="my-ecr-repo"
ACCOUNT_ID=${AWS_ACCOUNT_ID:-"your-default-account-id"}
REGION="ap-northeast-2"

# 고유 식별자 생성 (예: 타임스탬프 + Git short hash)
TIMESTAMP=$(date +%Y%m%d%H%M%S)
GIT_HASH=$(git rev-parse --short HEAD)
UNIQUE_TAG="${TIMESTAMP}-${GIT_HASH}"

# ECR 리포지토리 생성 (이미 존재하는 경우 무시)
aws ecr create-repository --repository-name ${REPO_NAME} || true

# 도커 이미지 빌드
docker build -t ${REPO_NAME}:${UNIQUE_TAG} .

# ECR 로그인
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

# 이미지에 태그 지정 (고유 식별자와 'latest' 모두)
docker tag ${REPO_NAME}:${UNIQUE_TAG} ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:${UNIQUE_TAG}
docker tag ${REPO_NAME}:${UNIQUE_TAG} ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:latest

# ECR에 이미지 푸시 (두 태그 모두)
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:${UNIQUE_TAG}
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:latest

echo "Image pushed successfully with tags:"
echo "  - ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:${UNIQUE_TAG}"
echo "  - ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:latest"
```

---

[목록으로](https://shiwoo-park.github.io/blog)
