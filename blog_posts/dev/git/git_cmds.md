---
layout: post
title: "자주쓰는 git commands"
date: 2020-08-06
categories: [git, commands]
---

# 자주쓰는 git commands

> 날짜: 2020-08-06


### Basic

내용 | 명령어
--- | ---
Repo 불러오기 | `git clone REPO_URL`
상태 확인 | `git status`
코드 변경사항 확인 | `git diff`
Remote 로부터 최신 정보 불러오기 (현재 코드 상태 불변) | `git fetch`
Remote 로부터 최신 정보 불러오기 (현재 코드 상태 변경) | `git pull`
이미 존재하는 TARGET_BRANCH 브랜치로 갈아타기 | `git checkout TARGET_BRANCH`
특정 파일 staging | `git add FILE_PATH`
특정 파일 unstaging | `git reset HEAD FILE_PATH`
모든 변경된 파일 staging | `git add -A`
모든 변경 사항 초기화(=unstaging) | `git reset --hard`
메세지와 함께 스테이징된 변경사항 커밋 | `git commit -m 'some message'`
현재 브랜치 커밋 로그 보기 (최신순) | `git log`
Remote 로 현재까지 커밋된 내용 저장 | `git push`
TARGET_BRANCH 를 현재 브랜치로 merge | `git merge TARGET_BRANCH`
현재 브랜치명 보기 | `git branch --show-current`
현재 태그 hash 보기 | `git rev-parse HEAD`

### Advanced - rebase, reset

내용 | 명령어
--- | ---
마지막 커밋 이후 수정사항 전체 초기화 | `git reset --hard`
최근 1회의 커밋에 대한 Hard 리셋 (=수정사항 날아감) | `git reset --hard HEAD~1`
최근 1회의 커밋에 대한 강제 리셋  (=수정사항 "안" 날아감) | `git reset --soft HEAD~1`
TARGET_BRANCH 를 현재 브랜치로 rebase | `git rebase TARGET_BRANCH`
최근 4개 커밋을 재배치 | `git rebase -i HEAD~4`

### Advanced - tag

내용 | 명령어
--- | ---
태그달기 | `git tag -a TAG_NAME -m MESSAGE`
로컬 태그를 remote 에 동기화 | `git push origin TAG_NAME`
모든 local tag 삭제 | `git tag -d $(git tag -l)`
Remote tag 조회 | `git ls-remote --tags origin`
Remote tag 삭제 | `git push --delete origin TAG_NAME`
모든 remote tag 삭제 | `git push origin --delete $(git tag -l) `


### Advanced - credential

내용 | 명령어
--- | ---
credential 정보 영구저장 (mac, linux) | `git config credential.helper 'store'`
credential 정보 삭제 (mac, linux) | `git config --global --unset credential.helper`
credential 정보 영구저장 (windows) | `git credential-manager install`
credential 정보 삭제 (windows) | `git credential-manager uninstall`
현재 폴더의 git repo credential 정보만 리셋 | `git config --local credential.helper ""`


### Advanced - config

내용 | 명령어
--- | ---
Local Git 이 tracking 하는 remote repo URL 최초세팅 | `git remote add REPO_URL`
Local Git 이 tracking 하는 remote repo URL  | `git remote set-url origin REPO_URL`
Local Git 이 tracking 하는 remote 설정 조회 | `git remote -v`
Local Git 의 코드를 원격 repo master 브랜치로 매핑 | `git push --set-upstream origin master`
Local Git - Global config 등록 | `git config --global user.email "woozin23@gmail.com"`
Local Git - Global config 삭제 | `git config --unset --global user.email`
Local Git - 현재 Repo config 등록 | `git config user.name "silva.podo"`
Local Git - 현재 Repo config 삭제 | `git config --unset user.name`


### Advanced - gitsubmodule

내용 | 명령어
--- | ---
git submodule 추가 | `git submodule add -b {BRANCH} {REPO_URL} {TARGET_DIR}`
submodule 상태 조회 | `git submodule status`
최초 submodule 불러오기 지정된 SHA hash 에 따라 로드됨 | `git submodule update --init --recursive`
submodule 을 remote main 브랜치의 HEAD 로 update | `git submodule update --recursive --remote`
update submodule | `git pull --recurse-submodules`
submodule 비활성화 | `git submodule deinit -f {SUBMODULE_NAME}`


### Advanced - etc

내용 | 명령어
--- | ---
Remote 와 repo 정보 동기화 (삭제된 브랜치 포함) | `git fetch -p`
현재 버전에서 NEW_BRANCH 라는 브랜치 명으로 branch out 하기(=새 브랜치 만들기) | `git checkout -b NEW_BRANCH`
v1.0.3 이라는 tag 가 달린 코드버전으로 NEW_BRANCH 만들어서 갈아타기 | `git checkout v1.0.3 -b NEW_BRANCH`
Remote 브랜치 삭제 | `git push origin --delete TARGET_BRANCH`
브랜치 일괄삭제 전 확인 | `git branch -r \| grep "origin/RC\/5.3.3..*" \| sed 's/origin\///'`
브랜치 일괄삭제 | `git branch -r \| grep "origin/RC\/5.4.0..*" \| sed 's/origin\///' \| xargs git push origin --delete`

- Tracking 하는 remote 브랜치가 삭제된 로컬 브랜치 클린업

```bash
git for-each-ref --format '%(refname:short) %(upstream:track)' |
awk '$2 == "[gone]" {print $1}' |
xargs git branch -D
```

---

[목록으로](https://shiwoo-park.github.io/blog)
