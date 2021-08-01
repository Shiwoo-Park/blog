# SSH 각종 Tip 모음

> 날짜: 2021-08-01


### SSH 로 remote 서버 암호 없이 접속하기

- 클라이언트 컴퓨터(로컬)에서 `ssh-key` 를 발급한뒤, 공개키를 복사한다
```
cd ~/.ssh

ssh-keygen
# Enter file in which to save the key (/home/silva/.ssh/id_rsa): id_rsa_target (target 대신 의미있는 name 을 입력해준다)
# Enter passphrase (empty for no passphrase): (ENTER)
# Enter same passphrase again: (ENTER)

cat id_rsa_target.pub
# 표시되는 텍스트 전체 복사
```
- remote 서버 접속 후, ssh 접속을 허용할 client 의 공개키를 등록해준다.
```
vi ~/.ssh/authorized_keys
# 아까 복사한 공개키 붙여넣기 후 저장 & 종료
```
- 클라이언트에서 ssh 접속을 시도해본다 (곧바로 접속되어야 정상)


### 서버 Host명을 지정하여 빠르게 ssh 접속하기 (config 파일)

예를들어 ssh 접속하고자 하는 서버 스펙이 아래와 같다고 해보자
- IP: `192.168.1.12`
- User: `deploy`
- Path of key file: `~/.ssh/id_rsa_deploy`

SSH 접속 설정을 기록하는 파일 `~/.ssh/config` 에 아래와 같이 미리 해당 스펙을 등록할 수 있다.
```
Host rainbow
    User deploy
    HostName 192.168.1.12
    IdentityFile ~/.ssh/id_rsa_deploy
```

이렇게 설정을 하게되면 `ssh rainbow` 명령어로 해당서버 SSH 접속이 가능하다

+ config 파일의 `권한(chmod)은 반드시 400` 이어야 함


[목록으로](https://shiwoo-park.github.io/blog/kor)
