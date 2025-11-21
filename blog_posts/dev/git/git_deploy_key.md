---
layout: post
title: "서버에 git deploy key 활용가능하도록 등록하기"
date: 2020-07-10
categories: [git, ssh, deployment]
---

# 서버에 git deploy key 활용가능하도록 등록하기

> 날짜: 2020-07-10

만일 git 으로 코드관리를 하고, 서버에 배포할때 ssh 를 활용한다면 git 의 deploy key 를 등록하여 사용하는것이 앞으로의 유지보수에 매우 편리하다

이를 어떻게 등록할 수 있는지 순차적으로 알아본다.

1. 서버에서 ssh 용 rsa key 생성

```
cd ~/.ssh

ssh-keygen
# 여기서 프롬프트가 진행되는데 중간에 키 저장할 파일명 입력하라고 하면 id_rsa_{MY_PROJ_NAME} 이라고 짓자
# 그리고 passphrase 입력하라고 뜨는데, 매번 git fetch, pull 등을 할때 자동으로 되길 원한다면 그냥 엔터(미입력) 누르자
# 키 생성이 끝나면 id_rsa_{MY_PROJ_NAME}, id_rsa_{MY_PROJ_NAME}.pub 이라는 2개 파일이 나옴

cat id_rsa_{MY_PROJ_NAME}.pub
# 공개키 인데 이것을 복사한다
```

2. Git repo > settings > deploy keys > Add deploy key 에서 위에서 복사한 값을 붙여넣은뒤 저장

3. 서버에 ssh config 설정 추가

```
Host MY_PROJ_NAME.github.com
     HostName MY_PROJ_NAME.github.com
     User git
     IdentityFile ~/.ssh/id_rsa_{MY_PROJ_NAME}
     IdentitiesOnly yes
```

---

[목록으로](https://shiwoo-park.github.io/blog)
