
# 유용한 shell script tips

> 날짜: 2020-12-09

자주 사용되는 명령어 라기보다는 좀 어려운 스크립트 작성 시, 써먹기 좋은 명령어들을 모았습니다.

내용 | 명령어
--- | ---
현재 스크립트가 들어있는 폴더의 절대 경로 얻기 | `BASH_FILE_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"`

---

[목록으로](https://github.com/Shiwoo-Park/blog/tree/master/kor)
