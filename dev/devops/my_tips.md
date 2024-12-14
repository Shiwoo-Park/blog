# DevOps 업무 - 나만의 꿀팁

> 날짜: 2024-12-14

[목록으로](https://shiwoo-park.github.io/blog)

---

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
