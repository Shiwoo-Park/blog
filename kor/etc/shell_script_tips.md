
# 유용한 shell script tips

> 날짜: 2021-01-08

쉘 스크립트 작성 시, 종종 쓰이는 기본적인 문법들과 각종 팁들을 모아보았습니다.

## 기본 문법

#### 조건문

#### 반복문

#### 함수


## 각종 꿀팁

`BASH_FILE_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"`

현재 스크립트가 들어있는 폴더의 절대 경로 얻기

`set -e`

스크립트에 이 명령어를 넣으면 이 라인 이후에 실행되는 명령어의 결과 exit code 가 0 이 아닌것이 하나라도 나오면 곧바로 제어 흐름을 중단처리 한다 (= 에러발생)



---

[목록으로](https://github.com/Shiwoo-Park/blog/tree/master/kor)
