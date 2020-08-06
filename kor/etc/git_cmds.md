# 자주쓰는 git commands

> 날짜: 2020-08-06


### load and save

Repo 불러오기
`git clone REPO_URL`

Repo의 최신 상태 정보 불러오기 (코드 상태 안바뀜)
`git fetch`

현재 브랜치의 최신 정보를 불러오기 (코드 상태 변경됨)
`git pull`

특정 파일 staging
`git add FILE_PATH`

모든 변경사항 staging 하기
`git add -A`

짧은 커밋메세지와 함께 커밋하기
`git commit -m 'my commit message'

Remote 로 커밋된 코드 저장하기
`git push`


### monitoring

상태 확인
`git status`

코드 변경사항 확인
`git diff`


### checkout

이미 존재하는 target_branch 브랜치로 갈아타기
`git checkout target_branch`

현재 버전에서 new_branch 라는 브랜치 명으로 branch out 하기(=새 브랜치 만들기)
`git checkout -b new_branch`

v1.0.3 이라는 tag 가 달린 코드버전으로 new_branch 만들어서 갈아타기
`git checkout v1.0.3 -b new_branch`

### merge
target_branch 를 현재 사용중인 브랜치로 merge 하기
`git merge target_branch`



to be coninued...

---

[목록으로](https://github.com/Shiwoo-Park/blog/tree/master/kor)
