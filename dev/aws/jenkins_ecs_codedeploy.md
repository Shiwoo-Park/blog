# Jenkins를 사용하여 AWS ECS Fargate 에 배포하기 (ECR, CodeDeploy, HTTPS, 로드 밸런서)

## 간단 요약

### 전제조건
- 배포하려는 프로젝트가 도커기반으로 동작 가능하도록 설정되어있어야 함.
- 사용하려는 도매인을 구매한 상태이어야 함.
- 사용하려는 AWS VPC 네트워크가 IGW(인터넷 게이트웨이) 를 포함하여 생성된 상태이어야 함
- 로드밸런서, ECS 서비스(어플리케이션) 용 보안그룹이 생성되어있어야 함. 

###  1. 도메인 세팅
- 사용하려는 도메인을 AWS Route53 에 등록하고
- AWS Certificate Manager 에 해당 도메인의 인증서를 생성

### 2. EC2
- 타겟그룹 생성
- 로드밸런서 생성
- Route53 에서 도메인에 ALB 를 연결

### 3. ECR
- 레포 생성
- ECR에 Dockerizing 된 서비스 이미지 업로드

### 4. ECS
- 클러스터 생성
- 태스크 정의 생성
- 생성한 태스크로 서비스 생성

### 5. Code Deploy
- 자동으로 생성된 어플리케이션 & 배포그룹을 그대로 사용하거나 안사용할거면 삭제
- 만일 삭제했다면 내가 사용할 어플리케이션 & 배포그룹 생성

### 6. Jenkins
- item 추가 > pipeline 활용
- 배포용 파이프라인 스크립트 추가
- 배포 진행 (최초 배포 브랜치는 임의 입력해야함)


## 기타 세부 절차

### 1. **AWS 설정 준비**
#### 1.1 **AWS IAM Role 생성**
- ECS 태스크 실행, CodeDeploy 배포, ECR 이미지 푸시를 위한 IAM 역할을 생성하고 필요한 권한을 부여합니다.
    - **ECR**: `AmazonEC2ContainerRegistryFullAccess`
    - **ECS**: `AmazonECS_FullAccess`
    - **CodeDeploy**: `AWSCodeDeployRole`
    - **ACM (인증서 발급)**: `AWSCertificateManagerFullAccess`
  
#### 1.2 **ECR (Elastic Container Registry) 설정**
- ECR 리포지토리를 생성하여 컨테이너 이미지를 저장할 수 있도록 설정합니다.
    - **AWS CLI**를 통해 ECR 리포지토리를 생성:
      ```bash
      aws ecr create-repository --repository-name your-repo-name --region your-region
      ```

### 2. **Jenkins 구성**
#### 2.1 **Jenkins 설치 및 플러그인 설정**
- Jenkins에서 AWS와 상호작용할 수 있도록 AWS 관련 플러그인 설치.
    - **AWS Credentials** 플러그인
    - **Amazon EC2** 플러그인
    - **Pipeline** 플러그인
    - **Git** 플러그인
    - **Docker** 플러그인

#### 2.2 **AWS 자격 증명 구성**
- **Jenkins**에서 AWS IAM 자격 증명을 구성하여 Jenkins가 AWS ECR, ECS, CodeDeploy 등과 상호작용할 수 있도록 합니다. Jenkins 관리 → **Credentials** → **Global credentials**에 AWS 자격 증명을 등록합니다.

### 3. **HTTPS 인증서 및 도메인 설정**
#### 3.1 **도메인 설정 (Route 53)**
- 도메인을 **Route 53**에서 설정하거나 외부 도메인을 사용 중인 경우 Route 53에 추가하여 관리합니다.
- 도메인의 DNS 설정이 로드 밸런서와 올바르게 연결되도록 설정해야 합니다.

#### 3.2 **ACM (AWS Certificate Manager)로 HTTPS 인증서 발급**
- AWS ACM을 사용하여 HTTPS를 위한 인증서를 발급합니다.
    - **AWS Console**에서 **Certificate Manager**로 이동하여 인증서를 발급.
    - 도메인 검증이 완료되면 인증서가 활성화됩니다.

### 4. **ECS Fargate 및 로드 밸런서 설정**

#### 4.1 **ECS 클러스터 및 서비스 생성**
- **Fargate** 모드를 사용하여 ECS 클러스터를 생성합니다.
- 태스크 정의를 생성하여 컨테이너 환경을 설정합니다.
    - **Network mode**는 `awsvpc`로 설정.
    - 필요한 **Port Mappings**(예: 80, 443)을 설정합니다.
    - **Task Role** 및 **Execution Role**도 설정하여 적절한 권한을 부여합니다.
    
#### 4.2 **로드 밸런서 생성 (ALB)**
- **Application Load Balancer(ALB)**를 생성하여, ECS 서비스와 연결합니다.
    - HTTPS를 지원하도록 **HTTPS 리스너(443 포트)**를 설정하고, ACM에서 발급한 인증서를 연결합니다.
    - ALB의 **Target Group**에 ECS Fargate의 태스크가 포함되도록 설정합니다.

#### 4.3 **ECS 서비스에 ALB 연결**
- ECS 서비스를 생성할 때, **로드 밸런서**를 연결하여 트래픽이 ALB를 통해 컨테이너로 전달되도록 설정합니다.
- **Health Check**가 제대로 설정되어 있는지 확인합니다.

### 5. **CodeDeploy 설정**
#### 5.1 **CodeDeploy 애플리케이션 및 배포 그룹 생성**
- **CodeDeploy**에서 ECS 서비스를 대상으로 배포할 애플리케이션과 배포 그룹을 설정합니다.
    - 애플리케이션을 생성하고, ECS와 연동되도록 **배포 그룹**을 설정합니다.
    - Target Group과 ECS Fargate 서비스가 올바르게 연결되어 있는지 확인합니다.

### 6. **Jenkins 파이프라인 구성**

#### 6.1 **Jenkins Pipeline 스크립트 작성**
- Jenkins에서 사용할 **Jenkinsfile**을 작성합니다. 파이프라인의 주요 단계는 다음과 같습니다:
  1. **Git Clone**: 소스 코드 다운로드
  2. **Docker Build & Push to ECR**: 도커 이미지를 빌드하고 ECR에 푸시
  3. **ECS 서비스 업데이트**: ECS 서비스 태스크 정의 업데이트
  4. **CodeDeploy 배포**: 새 태스크 정의로 CodeDeploy를 사용하여 배포

```groovy
pipeline {
    agent any

    environment {
        // 개발환경 및 서버타입 지정
        DEPLOY_ENV = "dev"
        DEPLOY_ENV = "stage"
        LAUNCH_TYPE = "FARGATE_SPOT"

        DEPLOY_ENV = "prod"
        LAUNCH_TYPE = "FARGATE"

        BUILD_ID = "${env.BUILD_ID}"
        BRANCH = "${params.BRANCH}"

        GIT_CREDENTIAL_ID = "silva"
        GIT_URL = "https://github.com/silva/silva-web.git"
        S3_BUCKET_NAME = "silva-bucket"

        AWS_REGION = "ap-northeast-2"
        ACCOUNT_ID = "123123123123"
        ECR_REPO_URI = "123123123123.dkr.ecr.ap-northeast-2.amazonaws.com"
        ECR_REPO_NAME = "silva-web-${DEPLOY_ENV}"
        CLUSTER_NAME = "silva-web"
        SERVICE_NAME = "silva-web-${DEPLOY_ENV}"
        CODE_DEPLOY_APP_NAME = "silva-web-ecs"
        CODE_DEPLOY_GROUP_NAME = "silva-web-${DEPLOY_ENV}"
    }

    stages {
        stage('AWS ECR Login'){
            steps {
                script {
                    sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO_URI}"
                }
            }
        }
        
        stage('Git Clone') {
            steps {
                git branch: BRANCH,
                credentialsId: GIT_CREDENTIAL_ID,
                url: GIT_URL
                
                script {
                    sh "rm -rf .git"
                    sh "cp dotenv/${DEPLOY_ENV}.conf .env"
                    sh "echo \"\nBUILD_ID=${BUILD_ID}\nDEPLOY_ENV=${DEPLOY_ENV}\" >> .env"
                }
            }
        }
        
        stage('Docker Build') {
            steps {
                script {
                    sh "docker build -t ${SERVICE_NAME}:${BUILD_ID} ."
                }
            }
        }
        
        stage('ECR Push') {
            steps {
                script {
                    sh "docker tag ${SERVICE_NAME}:${BUILD_ID} ${ECR_REPO_URI}/${ECR_REPO_NAME}:${BUILD_ID}"
                    sh "docker tag ${SERVICE_NAME}:${BUILD_ID} ${ECR_REPO_URI}/${ECR_REPO_NAME}:latest"
                    sh "docker push ${ECR_REPO_URI}/${ECR_REPO_NAME}:${BUILD_ID}"
                    sh "docker push ${ECR_REPO_URI}/${ECR_REPO_NAME}:latest"
                }
            }
        }
        
        stage('Clean Docker Image') {
            steps {
                script {
                    sh "docker rmi -f ${SERVICE_NAME} ${ECR_REPO_URI}/${ECR_REPO_NAME}:${BUILD_ID}"

                }
            }
        }
        
        stage ('Upload Appspec') {
            steps {
                script {
                    // 최신 태스크 정의를 불러와서 재활용
                    def NEW_TASK_DEFINITION = sh(
                        script: """
                            aws ecs list-task-definitions \
                            --family-prefix ${SERVICE_NAME} \
                            --region ${AWS_REGION} \
                            --sort DESC \
                            --query 'taskDefinitionArns[0]' \
                            --output text
                        """,
                        returnStdout: true
                    ).trim()
                    echo "Latest Task Definition: ${NEW_TASK_DEFINITION}"

                    sh """
                        cat > ${BUILD_ID}.yaml<<-EOF
version: 1
Resources:
  - TargetService:
      Type: AWS::ECS::Service
      Properties:
        TaskDefinition: ${NEW_TASK_DEFINITION}
        LoadBalancerInfo:
          ContainerName: ${SERVICE_NAME}
          ContainerPort: 80
        CapacityProviderStrategy:
          - CapacityProvider: ${LAUNCH_TYPE}
            Weight: 1
EOF"""
                    sh "aws s3 cp ${BUILD_ID}.yaml s3://${S3_BUCKET_NAME}/${SERVICE_NAME}/appspec/${BUILD_ID}.yaml"
                }
            }
        }

        stage ('Deploy') {
            steps {
                script {
                    sh"""
                        aws deploy create-deployment \
                        --application-name ${CODE_DEPLOY_APP_NAME} \
                        --deployment-group-name ${CODE_DEPLOY_GROUP_NAME} \
                        --region ${AWS_REGION} \
                        --s3-location bucket=${S3_BUCKET_NAME},bundleType=YAML,key=${SERVICE_NAME}/appspec/${BUILD_ID}.yaml \
                        --output json > deployment.json
                    """
                    def DEPLOYMENT = readJSON file: './deployment.json'
                    
                    RESULT = "Pending"
                    
                    while( "$RESULT" != "Succeeded") {
                        sleep(10)
                        
                        RESULT = sh(
                            script:"aws deploy get-deployment \
                            --query \"deploymentInfo.status\" \
                            --region ${AWS_REGION} \
                            --deployment-id ${DEPLOYMENT.deploymentId}",
                            returnStdout: true
                        ).trim().replaceAll("\"", "")
                        
                        echo "${RESULT}"
                        
                        if ("$RESULT" == "Failed") {
                            throw new Exception("CodeDeploy Failed")
                            break
                        }
                        
                        if ("$RESULT" == "Stopped") {
                            throw new Exception("CodeDeploy Stopped")
                            break
                        }
                    }
                }
            }
        }
    }
}
```

### 7. **배포 및 테스트**
- Jenkins에서 파이프라인을 실행하여 ECR에 이미지를 푸시하고, CodeDeploy를 통해 ECS 서비스로 배포합니다.
- 배포가 완료된 후, HTTPS를 통해 로드 밸런서가 올바르게 작동하는지 테스트합니다.
