---
layout: post
title: "자주쓰는 docker 명령어 모음"
date: 2020-12-23
categories: [devops, docker]
---
### 즐겨찾기

명령어 | 내용
--- | ---
특정 컨테이너 쉘 실행 | `docker exec -it CONTAINER /bin/bash`
컨테이너에서 django shell_plus 실행 | `docker exec -it python manage.py shell_plus`
도커 컴포즈 종료 및 관련 모든 이미지 및 볼륨 삭제 | `docker-compose down --rmi all -v`
미사용 도커 리소스 정리 | `docker system prune -a`



### Basic

명령어 | 내용
--- | ---
docker run | Docker 이미지를 기반으로 컨테이너를 실행합니다.
docker build | Dockerfile을 사용하여 Docker 이미지를 빌드합니다.
docker ps | 실행 중인 Docker 컨테이너 목록을 표시합니다.
docker stop | 실행 중인 Docker 컨테이너를 중지합니다.
docker pull | Docker 이미지를 Docker Hub 또는 다른 레지스트리에서 가져옵니다.
docker rm | 중지된 Docker 컨테이너를 삭제합니다.
docker images | 시스템에 있는 Docker 이미지 목록을 표시합니다.
docker rmi | Docker 이미지를 삭제합니다.
docker exec | 실행 중인 Docker 컨테이너 내에서 명령어를 실행합니다.
docker-compose | 여러 컨테이너를 정의하고 실행하기 위한 Docker Compose를 사용합니다.

### Image 관련

내용 | 명령어
--- | ---
이미지 목록보기 | `docker images` or `docker images -a`
이미지 빌드하기 | `docker build -f {도커파일 path} --tag {프로젝트명}:{태그} {프로젝트 path}`
이미지 검사 | `docker image inspect {이미지명}`
이미지 레이어 보기 | `docker image inspect --format "{{ json .RootFS.Layers }}" {이미지명}`
이미지 삭제 | `docker rmi {DOCKER_IMAGE}`
이미지 강제 삭제 (컨테이너가 존재해도) | `docker rmi -f {DOCKER_IMAGE}`
미사용 이미지 일괄 제거 | `docker image prune -a`
도커 이미지를 복사 (repository 와 태그를 변경해준다) | `docker tag {복사할_도커_image_tag} {도커허브 Repo URL}:{tag}`
태그 또는 repository 가 유효하지 않은 이미지들 삭제 | <code>docker rmi $(docker images &#124; grep "^" &#124; awk "{print $3}")</code>

### Container 관련

내용 | 명령어
--- | ---
실행중 컨테이너 목록 | `docker ps` or `docker container ls` or `docker container ls -a`
전체 컨테이너 목록 (정지된 컨테이너들 포함) | `docker ps -a`
컨테이너 실행 | `docker run {컨테이너 ID}`
컨테이너 정지 | `docker stop {컨테이너 ID}`
컨테이너 목록 | `docker container ls`
컨테이너 목록(전체) | `docker container ls -a`
컨테이너 삭제 | `docker rm {컨테이너_ID} ( , {컨테이너2_ID} ... )`
미사용 컨테이너 일괄 삭제 | `docker container prune`
컨테이너 강제중지 | `docker rm -f {컨테이너 ID}`
정지된 컨테이너 목록 | <code>docker ps -a &#124; grep Exit</code>
정지된 컨테이너(들) 띄우기, 시작하기 | `docker start [OPTIONS] CONTAINER [CONTAINER...]`
컨테이너 shell 접속 하기 | `docker exec -it {container ID} /bin/bash`
모든 정지된 컨테이너 삭제 (Remove all stopped containers) | `docker rm $(docker ps -a -q)`

### Miscellaneous

내용 | 명령어
--- | ---
도커 로그 확인 | `docker events &`
도커 허브 접근 인증 | `docker login {DOCKER_HUB_URL}`
Docker Registry(Hub) 에서 도커 이미지 다운받기 | `docker pull {IMAGE_URL/NAME:TAG}`
Run Web Server By Docker | `docker run -d -p 8888:8888 --name py-web-server -h my-web-server py-web-server:v1`
Build a Docker image with the web server (in Dockerfile Dir) | `docker build -t py-web-server:v1 .`
Rebuild the Docker image and tag it with its future registry name that includes gcr.io as the hostname and the project ID as a prefix | `docker build -t "gcr.io/${GCP_PROJECT}/py-web-server:v1" .`
Push the image to gcr.io| `docker push gcr.io/${GCP_PROJECT}/py-web-server:v1`
