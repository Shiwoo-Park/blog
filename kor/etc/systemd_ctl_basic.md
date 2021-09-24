# Linux 의 init 시스템: systemd 와 systemctl 간단 사용법

> 날짜: 2021-09-24

대부분의 리눅스 시스템에서는 다양한 프로세스를 Service 라는 이름으로 띄울 수 있는 systemd 라는 init system 과
그리고 이를 관리하기위한 도구인 systemctl 을 가지고 있다.

이 포스팅에서는 !!! 이게 뭐하는 건지, 어떻게 사용하는지 간단하게 알아본다

영어 잘하는분은 제가 참고한 [원서](https://www.digitalocean.com/community/tutorials/how-to-use-systemctl-to-manage-systemd-services-and-units)를 참고하시기 바랍니당 ㅎㅎㅎ


## 정의

### systemd
일부 리눅스 배포판에서 유닉스 시스템 V나 BSD init 시스템 대신 사용자 공간을 부트스트래핑하고 최종적으로 모든 프로세스들을 관리하는 init 시스템이다. systemd라는 이름 뒤에 추가된 d는 유닉스에서의 데몬(daemon)을 나타낸다. GNU LGPL 버전 2.1 이상으로 허가된 자유 및 오픈 소스 소프트웨어로 출시되었다. systemd의 기본 목표들 가운데 하나는 모든 배포판들에 대하여 기본 리눅스 구성과 서비스 동작을 통일하는 것이다.
2015년을 기준으로 수많은 리눅스 배포판들은 systemd를 자신들의 기본 init 시스템으로 채택하고 있다. systemd의 채택이 증가되어 기능이 복잡해졌을뿐 아니라 배포판들이 채택을 강요받게 되면서 소프트웨어가 유닉스 철학을 위반했다는 비평을 받기에 이르렀다.

### systemctl
리눅스의 systemd 와 service manager 를 컨트롤 하기위한 도구. 서비스의 상태 진단, 설정변경, 구동과 중단 등의 전반적인 관리 기능을 제공한다.


## 단일 서비스의 구동/중단, Enable/Disable, Reload

서비스를 구동하고 멈추는 명령어, 서비스 설정 다시 읽어오는 등의 명령어를 정리하였다. 매우 심플하다.

서비스 enable 과 disable 이라는 개념이 있는데, 여기서 서비스를 enable 했다는 것은 특정 프로그램을 최초 시스템(서버 혹은 PC)가 부팅된 후에 자동으로 시작할지 여부를 결정하는 것이다. (컴퓨터를 켜면 자동실행 옵션 같은거라고 생각하면 됨)

```shell
# 서비스 구동
sudo systemctl start application.service
sudo systemctl start application

# 서비스 정지
sudo systemctl stop application.service

# 재시작
sudo systemctl restart application.service

# 설정 다시 불러오기
sudo systemctl reload application.service

# 재시작 + 설정 리로드
sudo systemctl reload-or-restart application.service

# 서비스 Enable 하고 Disable 하기 (= 최초 구동시 자동실행 여부 결정)
sudo systemctl enable application.service
sudo systemctl disable application.service

# 특정 서비스 Mask (완전이 구동 불가능한 상태) 하기
sudo systemctl mask nginx.service  # 마스크 적용
sudo systemctl unmask nginx.service  # 마스크 해제
```


## 단일 서비스의 점검 및 Unit file 설정

Service 는 Unit File 이라는 것으로 설정을 가지고 있다.
그래서 Service 를 관리하기 위해서는 Unit file의 사용법을 기본적으로 알아야 한다.

```shell
# 서비스 상태 표시
systemctl status application.service

# 서비스의 Unit File 표시
systemctl cat atd.service

# 서비스의 의존성 표시
systemctl list-dependencies sshd.service

# 서비스 Unit File 의 설정 상태 표시
systemctl show sshd.service

# 서비스 Unit File 편집
sudo systemctl edit nginx.service  # override.conf 를 만들어서 기존 설정값 덮어쓰기
sudo systemctl edit --full nginx.service  # 현재 설정파일을 직접 변경

# override 후 기존 설정파일 삭제 
# (/etc/... 에 없으면 /lib/... 에 있을거임)

sudo rm /etc/systemd/system/nginx.service.d

# 편집한 설정파일 반영
sudo systemctl daemon-reload
```

## System 상태 점검

모든 서비스를 대상으로 상태를 고루 점검하고 싶을때 사용하는 명령어. Unit 목록을 조회한다

```shell
systemctl list-units  # Active 한 것들만 보기

systemctl list-units --all  # 전체 조회

systemctl list-units --all --state=inactive  # Inactive 한 것들만 보기

systemctl list-units --type=service  # Service 만 보기

systemctl list-unit-files  # 모든 Unit File 보기
```

---

[목록으로](https://shiwoo-park.github.io/blog/kor)
