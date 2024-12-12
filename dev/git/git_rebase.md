# git rebase (시작점 재설정하기)

> 날짜: 2024-04-09

- rebase 는 말그대로 base 를 재설정 하는 작업이다.
- 여기서 base 란 내가 작업하는 브랜치가 최초로 생성된 시점의 코드형상 (주로 develop 브랜치)을 말한다.
- rebase 를 사용하는 이유는 내가 피쳐브랜치에서 작업하는 커밋들 사이에 base 브랜치에서의 커밋들이 섞여들지 않도록 하여 깔끔하게 유지하기 위해서다. (기존에 merge를 쓰는 사람들이라면 이것을 알것이다.)
- rebase 를 하는 시점은 base 브랜치에서 다른 작업자들에 의해 변경사항(=커밋)이 추가되었을때 특히, 내 코드와 conflict 를 일으킬때 진행한다.
- rebase 를 하게되면 반드시 force push 하여 remote 브랜치형상을 로컬 상태로 덮어씌워줘야 한다.

## develop -> feature 브랜치 rebase 하는법

```shell
# develop 최신화
git checkout develop
git fetch origin
git pull origin develop

# 피쳐로 돌아와서 rebase 시작
git checkout feature-branch-name
git rebase develop

# conflict 발생 시, 직접 열어서 수정
git status
vi conflict_file

# 수정이 끝나면 모든 파일에 대해 add 처리 
git add .
git rebase --continue

# 변경사항 강제로 remote 반영 (force push)
git push origin --force
# Remote tracking branch 가 설정이 안되어있다면
git push origin feature-branch-name --force
```

## 기타 명령어

```shell
# rebase 취소하기
git rebase --abort

# conflict 내용 자세히 보기
git diff
```

---

[목록으로](https://shiwoo-park.github.io/blog)
