---
layout: post
title: "DevOps 업무 - 나만의 꿀팁"
date: 2024-12-14
categories: [devops, tips]
---

# DevOps 업무 - 나만의 꿀팁

> 날짜: 2024-12-14

[목록으로](https://shiwoo-park.github.io/blog)

---

## Docker

- 이미지 빌드 후, 태깅할때는 보통 용도별로 2개의 태그를 찍는다
  - Symbol 태그:  특정 목적을 상징하며 주로 배포할때 최근 이미지 or 특정환경 배포대상 이미지등을 구분. 고정된 ECR 이미지 URI로 배포할때 편함. (이미지 태그 계속바뀌면 태스크 정의 계속 갱신해줘야해서 힘듬)
    - ex. `latest, dev, prod`
  - ID 로 사용할 태그: 빌드 이미지의 고유 식별자로써 활용. 과거 특정 이미지로 롤백해야할때 유용함
    - ex. 빌드 날짜 `20241215_131215`, 젠킨스 빌드 ID `13`
- 배포 환경 구분
  - 이미지 빌드 시점에 `ARG` 를 활용하여 배포 환경 구분이 가능
  - AWS 인프라 각 레이어에서 제공하는 환경변수 설정 기능을 활용해 `ENV` 를 얻어와서 동적으로 배포 환경 구분도 가능
- 빌드타임 과 런타임 차이
  - 빌드타임=`docker build`, 런타임=`docker run`
  - 대부분의 `Dockerfile` 에 들어가는 내용들은 마지막에 어플리케이션을 실행하는 명령어를 제외하고는 빌드타임에 실행됨.
  - ARG 로 선언된 변수를 CMD 에서 참조 불가
    - 빌드타임 SET: `ARG -> RUN`
    - 런타임 SET: `ENV -> CMD`


## jenkins

- Slack 알림 설정에서 잘 살펴보면 배포 완료 후 commit history 를 출력해주는 옵션이 있다. (`include_commit_info`)
- 입력 파라미터로 Git branch 를 지정할때 branch filter 설정을 regex 로 해두면 배포 대상 브랜치 컨벤션 관리가 가능하다 (특히 공용 서버인 경우)
  - ex. `^(main|release/.+|hotfix/.+)$`
- Git Repo 를 연결해두면 배포 스크립트 실행 전, 배포할 repo 코드 버전을 정확히 땡겨오기 때문에 **브랜치를 명시**하거나 동적 브랜치를 지원하도록 설정하면 관리가 편하다.
- 도커 이미지 빌드서버(젠킨스)와 이미지를 실행시킬 서버(AWS ECS EC2)의 CPU 아키텍쳐가 같아야 한다.
  - 아키텍쳐가 다른경우 `docker buildx build` 명령어를 사용하면 해결 가능
  - ex) `docker buildx build --platform linux/amd64,linux/arm64 -t my-image:latest .`
- 배포를 많이 하게되면 데이터가 계속 쌓이기 때문에 디스크 용량을 적정수준으로 유지하기 위해서는 아래의 장치들을 이용하는게 좋다.
  - 배포 내역은 최대 N 개 이상 보관하지 않기.
  - 배포 스크립트에 ECR push 가 끝났다면 도커 이미지를 정리해주는 명령어 추가.
    ```bash
    docker image prune -a --force
    
    # 필요에 따라 컨테이너 or 네트워크도 정리 
    docker container prune -f
    docker network prune -f
    ```

## AWS

- ECS 롤링 업데이트 배포 시, 
  - **minHealthyPercent**와 **maxPercent** 설정에 따라 최소 컨테이너 수는 다를 수 있으나, `기본적으로 최소 2개 이상의 컨테이너로 운영`하는 것이 권장됨. (하나씩 내리고 올리고)
  - Code Deploy 사용 불가
  - 컨테이너 교체 시, `docker stop` 으로 컨테이너가 내려가기때문에 그 안에서 동작하는 어플리케이션이 `Gracefully shutdown` 되기위한 준비를 `Dockerfile` 에서 잘 챙겨야 한다.
- ECS 블루/그린 배포 시, 
  - ALB, 2개의 타겟그룹 (서로다른 AZ면 좋음) 이 필요
  - Code Deploy 사용 가능
- ECS EC2 클러스터 사용 시,
  - ECS EC2 클러스터의 전체 가용 자원은 클러스터에 포함된 EC2 인스턴스들의 가용 자원 합계로 결정됨.
  - 전체 가용 인스턴스 자원의 10% 는 HOST SERVER 가 사용할 수 있도록 한다. (=컨테이너 자원에 미포함)

---

[목록으로](https://shiwoo-park.github.io/blog)
