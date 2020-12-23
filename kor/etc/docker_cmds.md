
# Basic docker script

> 날짜: 2020-12-23

자주 사용되는 명령어 라기보다는 좀 어려운 스크립트 작성 시, 써먹기 좋은 명령어들을 모았습니다.


### Basic

내용 | 명령어
--- | ---
도커 로그 확인 | `docker events &`
이미지 목록보기 | `docker images`
이미지 빌드하기 | `docker build -f {도커파일 path} --tag {프로젝트명}:{태그} {프로젝트 path}`
이미지 삭제 | `docker rmi {DOCKER_IMAGE}`
컨테이너 실행 | `docker run {컨테이너 ID}`
실행중 컨테이너 목록 | `docker ps` or `docker container ls` or `docker container ls -a`
전체 컨테이너 목록 (정지된 컨테이너들 포함) | `docker ps -a`
컨테이너 정지 | `docker stop {컨테이너 ID}`
컨테이너 삭제 | `docker rm {컨테이너_ID} ( , {컨테이너2_ID} ... )`


### Image 관련

내용 | 명령어
--- | ---
이미지 검사 | `docker image inspect {이미지명}`
이미지 레이어 보기 | `docker image inspect --format "{{ json .RootFS.Layers }}" {이미지명}`
이미지 강제 삭제 (컨테이너가 존재해도) | `docker rmi -f {DOCKER_IMAGE}`
도커 이미지를 복사 (repository 와 태그를 변경해준다) | `docker tag {복사할_도커_image_tag} {도커허브 Repo URL}:{tag}`
태그 또느 repository 가 유효하지 않은(=<none>) 이미지들 삭제 | `docker rmi $(docker images | grep "^<none>" | awk "{print $3}")`

### Container 관련

내용 | 명령어
--- | ---
컨테이너 목록 | `docker container ls`
컨테이너 강제중지 | `docker rm -f {컨테이너 ID}`
정지된 컨테이너 목록 | `docker ps -a | grep Exit`
정지된 컨테이너(들) 띄우기, 시작하기 | `docker start [OPTIONS] CONTAINER [CONTAINER...]`
컨테이너 shell 접속 하기 | `docker exec -it {container ID} /bin/bash`
모든 정지된 컨테이너 삭제 (Remove all stopped containers) | `docker rm $(docker ps -a -q)`

### Miscellaneous

내용 | 명령어
--- | ---
도커 허브 접근 인증 | `docker login {DOCKER_HUB_URL}`
Docker Registry(Hub) 에서 도커 이미지 다운받기 | `docker pull {IMAGE_URL/NAME:TAG}`
Run Web Server By Docker | `docker run -d -p 8888:8888 --name py-web-server -h my-web-server py-web-server:v1`
Build a Docker image with the web server (in Dockerfile Dir) | `docker build -t py-web-server:v1 .`
Rebuild the Docker image and tag it with its future registry name that includes gcr.io as the hostname and the project ID as a prefix | `docker build -t "gcr.io/${GCP_PROJECT}/py-web-server:v1" .`
Push the image to gcr.io| `docker push gcr.io/${GCP_PROJECT}/py-web-server:v1`

---

[목록으로](https://github.com/Shiwoo-Park/blog/tree/master/kor)
