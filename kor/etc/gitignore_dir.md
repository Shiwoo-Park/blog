# 헤깔리는 gitignore 의 directory 설정

> 날짜: 2020-07-15

gitignore 에서 특정 directory 에 대한 ignore 처리를 하려고 보면...

몇가지 경우의 수가 생긴다. 어떻게 설정하는지 한번 보자

유의 하며 봐야 하는 몇가지 사항은 아래와 같다.

- 무시 처리하고자 하는 폴더의 정확한 depth 가 지정되어야 하는지 아닌지
- 폴더인지 파일인지 (폴더라면 맨 마지막에 / 를 빼먹지 말아야 함)

### 무시 방식에 따른 gitignore 설정 예제

```bash
# 프로젝트 홈폴더 레벨의 이름이 aaa 인 폴더 및 하위 파일들
/aaa/

# 프로젝트 홈폴더 레벨의 이름이 bbb 인 폴더 or 파일
/bbb

# depth 상관없이 이름이 ccc 인 폴더 및 하위 파일들
ccc/
**/ccc/

# depth 상관없이 이름이 ddd 인 폴더 or 파일들
ddd

# 중간 depth 상관없이 특정 폴더(eee) 하위의 특정 폴더(fff) 및 하위파일들
eee/**/fff/

# [추가 꿀팁] ttt 폴더는 ignore 하되 그 안의 empty.txt 라는 파일은 무시하지 않도록
/ttt/
!/ttt/empty.txt
```

---

[목록으로](https://github.com/Shiwoo-Park/blog/tree/master/kor)
