# Shell Script - Basics

> 날짜: 2021-01-08

[목록으로](https://shiwoo-park.github.io/blog)

---

쉘 스크립트 작성 시, 종종 쓰이는 기본적인 문법들과 각종 팁들을 모아보았습니다.

## 기본 문법

### 조건문 (=Conditional)

#### 기본 구조

```bash
if [ 조건절 ]; then
    실행절
elif [ 조건절 ]; then
    실행절
else
    실행절
fi
```

#### 다양한 조건절

연산자 | 설명 (True인 경우)
--- | ---
`-n 문자열` | 문자열의 길이가 0보다 클 때
`-z 문자열` | 문자열의 길이가 0일 때
`-d 디렉토리` |  해당 디렉토리가 존재할 때
`-e 파일` | 해당 파일이 존재할 때
`! 명제` | 명제가 거짓일 때
`문자열1 = 문자열2` | 두 문자열이 서로 같을 때
`문자열 != 문자열2` | 두 문자열이 서로 다를 때
`정수1 -eq 정수2` | 두 정수가 서로 같을 때
`정수1 -gt 정수2` | 정수1이 정수2보다 클 때
`정수1 -lt 정수2` | 정수1이 정수2보다 작을 때

#### Example

```bash
input=$1
if [ $input -eq 10 ]; then
    echo "equal !!!"
else
    echo "not equal ..."
fi

if [ -z "$1" ]; then
    echo "First argument is empty"
fi

if [ -n "$1" ]; then
    echo "First argument exists"
fi

if [ $# -eq 0 ]; then
    echo "No arguments supplied"
fi
```

### 반복문 (=Iteration)

```bash
# Multiple element iteration
for NAME in "ME" "YOU" "THEM" "ALL"; do
    echo "Name is ${NAME}"
done


# Numeric iteraion
NUM_SEQUENCE=$(seq 0 9)
for i in $NUM_SEQUENCE; do
    echo "Running loop seq "$i
done


# List iteration -------------------
PLANETS=( "EARTH" "MARS" "VINUS" )

for PLANET in ${PLANETS[@]}; do
    echo "This is ${PLANET}"
done

for (( i=0; i<${#PLANETS[@]}; i++ )); do
    echo "Planet #$i is ${PLANETS[i]}"
done
```

### 함수

#### 기본 구조

```bash
함수명()
{
    함수내용
}
```

#### Basic example

```bash
# declare
hey(){
  echo "hey!!!!"
}

# call
hey
```

#### Example with parameter

You can use `${ARG_NUMBER}` in the function

```bash
hey(){
  echo "hey $1 !!!! let's $2"
}

# call with param
hey "silva" "go home"
```

---

[목록으로](https://shiwoo-park.github.io/blog)
