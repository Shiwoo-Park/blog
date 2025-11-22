---
layout: post
title: "Terraform 기본지식"
date: 2024-12-13
categories: [devops, terraform, iac]
---
**Terraform**은 HashiCorp에서 개발한 **Infrastructure as Code (IaC)** 도구로, 클라우드 인프라를 코드로 정의하고 관리할 수 있게 해줍니다. Terraform은 다양한 클라우드 제공자(AWS, Azure, GCP 등) 및 온프레미스 환경을 지원하며, 인프라 리소스를 선언적으로 정의하고 이를 자동으로 생성, 수정, 삭제합니다.

**주요 용도**:
- 클라우드 리소스(AWS EC2, RDS, S3 등) 생성 및 관리
- 인프라의 버전 관리
- 복잡한 인프라 아키텍처를 코드로 일관되게 재사용
- 멀티 클라우드 환경 관리

---

## 간단 사용법

- 폴더에서 main.tf 파일을 기본으로 시작
- 기본적으로는 다중폴더의 main.tf 상호 연결 불가

### 프로젝트 구조

```
terraform/
  ㄴ main.tf          = 리소스가 선언되는 메인 파일
  ㄴ outputs.tf       = 출력 확인용 파일
  ㄴ variables.tf     = main.tf 에서 var 로 참조할 변수선언 (default 지정)
  ㄴ terraform.tfvars = variables.tf 에서 선언한 변수의 값을 지정 (default 덮어씀)
```

### 테라폼 프로젝트 gitignore 파일

```
# Terraform 상태 파일 및 백업파일
*.swp
*.tfstate
*.tfstate.*
*.backup
.terraform/
.terraform.lock.hcl
```

### 명령어

```shell
# 기본 명령어
terraform --version
terraform init  # 프로젝트 초기화
terraform plan  # 실행계획 확인
terraform apply  # 변경사항 반영 (저장)

# 응용 명령어
terraform output  # 테라폼 outputs.tf 출력
terraform refresh  # AWS 실제 상태와 동기화
terraform show  # 테라폼과 실제 상태간의 불일치 확인
TF_LOG=DEBUG terraform plan # 실행계획 확인 (상세)
terraform destroy  # 테라폼으로 생성한 모든 리소스 삭제

# 고급 명령어

# 이미 원격에 만들어져있는 공용 리소스를 테라폼 관리 대상으로 import
terraform import aws_ecr_repository.ecr baro-api-v2-celery
terraform import aws_iam_instance_profile.ecs baro-api-v2-celery-ecs-instance-profile

# 테라폼에서 생성한 리소스의 수동관리 
terraform state rm aws_instance.ecs_instance  # 연결 해제 (AWS 콘솔에서 수동 삭제)
terraform import aws_instance.ecs_instance i-0c1e69863aa1bc0f1  # 임의 연결

# 특정 리소스만 제거
terraform destroy \
  -target=aws_instance.ecs_instance \
  -target=aws_ecs_service.ecs_service \
  -target=aws_ecs_task_definition.ecs_task
```

## 사용시 주의사항
1. **State 파일 관리**:
   - Terraform은 인프라 상태를 `.tfstate` 파일에 저장합니다. 이 파일은 민감한 정보를 포함할 수 있으므로 버전 관리 시스템에 업로드하지 말고, S3 및 DynamoDB를 사용해 원격 관리하세요.

2. **DRY 원칙 준수**:
   - 반복되는 코드를 줄이기 위해 **모듈**과 **변수**를 적극 활용하세요.

3. **병렬 작업 주의**:
   - 여러 사용자가 동시에 작업하면 상태 파일 충돌이 발생할 수 있으므로 원격 상태 관리와 `terraform lock` 설정을 사용하세요.

4. **리소스 변경 시 영향 분석**:
   - 리소스 변경이 다른 리소스에 영향을 미칠 수 있으므로 `terraform plan`으로 항상 변경 내용을 확인하세요.

5. **환경 분리**:
   - 개발(dev), 스테이징(stage), 프로덕션(prod) 환경을 분리하고, 각각 별도의 상태 파일과 구성으로 관리하세요.

6. **프로바이더 버전 관리**:
   - 프로바이더와 Terraform 버전을 명시적으로 설정해 불필요한 업데이트로 인한 오류를 방지하세요.
   ```hcl
   terraform {
     required_providers {
       aws = {
         source  = "hashicorp/aws"
         version = "~> 5.0"
       }
     }
     required_version = ">= 1.5.0"
   }
   ```

## Terraform 모듈을 활용한 코드 재사용 방법

Terraform 모듈은 반복적으로 사용하는 코드 블록을 재사용 가능하게 만들어 인프라 관리의 효율성을 높여줍니다.

### **모듈 사용 방법**
1. **모듈 정의**  
   모듈 디렉토리를 생성하고, 필요한 리소스를 정의합니다.
   - 디렉토리 구조:
     ```
     my-module/
     ├── main.tf   # 리소스 정의
     ├── variables.tf # 입력 변수 정의
     ├── outputs.tf   # 출력 변수 정의
     ```

   - `main.tf` 예:
     ```hcl
     resource "aws_instance" "example" {
       ami           = var.ami
       instance_type = var.instance_type

       tags = {
         Name = var.name
       }
     }
     ```

   - `variables.tf` 예:
     ```hcl
     variable "ami" {
       description = "AMI ID"
       type        = string
     }

     variable "instance_type" {
       description = "Instance type"
       type        = string
       default     = "t2.micro"
     }

     variable "name" {
       description = "Instance name"
       type        = string
     }
     ```

   - `outputs.tf` 예:
     ```hcl
     output "instance_id" {
       value = aws_instance.example.id
     }
     ```

2. **모듈 호출**
   모듈을 사용하는 프로젝트에서 모듈을 호출합니다.
   ```hcl
   module "example_instance" {
     source        = "./my-module" # 모듈 경로 (로컬)
     ami           = "ami-12345678"
     instance_type = "t2.micro"
     name          = "ExampleInstance"
   }
   ```

   `source` 값은 로컬 디렉토리, Git URL, Terraform Registry 등에서 가져올 수 있습니다.

3. **모듈 업데이트**
   모듈 정의를 변경하면 이를 사용하는 모든 프로젝트에서 변경 사항을 적용하려면 `terraform apply`를 실행해야 합니다.

---

## Terraform의 원격 상태 관리와 팀 협업 방법

Terraform은 `.tfstate` 파일을 원격으로 관리하여 상태 충돌 방지 및 협업 효율성을 높일 수 있습니다.

### **원격 상태 관리 설정 방법**
1. **S3 버킷 및 DynamoDB 테이블 생성**
   - S3는 `.tfstate` 파일 저장에 사용, DynamoDB는 상태 잠금(lock)에 사용.
   ```bash
   aws s3api create-bucket --bucket terraform-state-bucket --region ap-northeast-2
   aws dynamodb create-table \
     --table-name terraform-lock-table \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --billing-mode PAY_PER_REQUEST
   ```

2. **Terraform 백엔드 구성**
   `backend` 블록을 사용해 원격 상태를 설정합니다.
   ```hcl
   terraform {
     backend "s3" {
       bucket         = "terraform-state-bucket"
       key            = "dev/terraform.tfstate" # 환경별로 경로 구분
       region         = "ap-northeast-2"
       dynamodb_table = "terraform-lock-table"
       encrypt        = true
     }
   }
   ```

3. **초기화**
   원격 상태 관리 설정을 적용하려면 프로젝트 디렉토리에서 `terraform init`을 실행합니다.
   ```bash
   terraform init
   ```

---

### **팀 협업을 위한 팁**
1. **환경 분리**:
   - `dev`, `stage`, `prod` 환경별로 S3 키를 다르게 설정하여 충돌 방지.
   ```hcl
   key = "${terraform.workspace}/terraform.tfstate"
   ```

2. **워크스페이스 활용**:
   Terraform 워크스페이스를 사용해 동일한 코드를 환경별로 다르게 적용.
   ```bash
   terraform workspace new dev
   terraform workspace select dev
   ```

3. **코드 리뷰 프로세스**:
   - Git과 Terraform Plan 파일을 연동해 코드 변경 시 변경 사항을 PR로 공유.

4. **CI/CD 통합**:
   - GitLab CI, GitHub Actions, Jenkins 등을 이용해 Terraform 작업을 자동화.

5. **상태 파일 암호화**:
   - S3 버킷에 암호화를 활성화하여 민감한 정보를 보호.

