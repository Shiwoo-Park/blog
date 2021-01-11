# 유용한 shell script tips

> 날짜: 2021-01-08

자주 사용되는 명령어 라기보다는 좀 어려운 스크립트 작성 시, 써먹기 좋은 명령어들을 모았습니다.

## 프로세스, CPU, 메모리 등

`top`

- 현재 프로세스별 CPU, Memory 사용량등을 알 수 있다.
- 프로그램을 킨 상태에서 아래 단축키 사용 가능
  - shift + m : 메모리 사용량 순으로 프로세스 정렬
  - shift + p : CPU 사용량 순으로 프로세스 정렬
  - ctrl + s : 실시간 업데이트 중지
  - ctrl + q : 실시간 업데이트 재시작

`sar -P`

CPU 별로 현재 부하 상태를 체크하기 위한 명령어 (사용자별로 CPU 점유율, I/O 사용률 등을 볼 수 있다.)

`cat /etc/*-release | uniq`

현재 사용하고 있는 OS 종류와 버전을 볼 수 있다.

`ps -eo user,pid,ppid,rss,size,vsize,pmem,pcpu,time,cmd --sort -rss | head -n 11`

각 프로세스별로 가장 메모리 사용량이 많은 것들 상위 11개를 조회

`pstree -u`

현재 프로세스들의 요약을 볼 수 있음 (괄호안에는 해당 프로세스의 실행자 표시)

## 파일 또는 텍스트

`diff a.txt b.txt`

a 와 b 파일의 내부적으로 서로 다른 부분을 출력해준다. '<' 표시는 좌측 파일내용, '>' 표시는 우측파일 내용이다.

`grep -r -n -i '문자열' path/`

특정 '문자열'을 포함하는 파일을 path 내부에서 찾는다

`cat <파일> | grep '문자열' | wc -l`

해당파일안에 문자열을 포함한 총 라인 수 출력

`cat <파일> | egrep --regexp=^0[[:digit:]]+$ | wc -l`

해당파일안에 REGEX와 일치하는 총 라인 수 출력

`find /path1 -name '문자열' | xargs cp --target-directory=/path2`

path1 내부에 파일명에 '문자열'을 포함하는 파일을 모두 path2로 복사

`grep -n <문자열> <찾을 파일들>`

해당 문자열이 포함된 파일과 해당 라인(+번호)을 보여준다.

`echo 'someletters_12345_moreleters.ext' | cut -d'_' -f 2`

입력받은 문자열에서 일부를 잘라낼 수 있다. 위의 경우에는 12345 가 잘려나온다.

`diff <(echo 'SAMPLE1') <(echo 'SAMPLE2')`

입력받은 2개의 문자열의 동일 여부를 확인 할 수 있다.

## 유틸리티

`nohup ./exeFile.sh arg1 arg2 ... &`

백그라운드로 해당 exeFile.sh를 실행시키면서 stdout으로 나오는 로그는 해당 폴더에 nohup.out으로 출력된다.

`chown -R {user}:{group} {path}`

path 의 user와 group 지정하기

`ssh username@111.222.333.444 -p9999`

username 이라는 사용자로 111.222.333.444 IP를 가진 서버의 9999포트로 ssh 접속을 시도 (ssh의 default포트번호는 22임)

`export PS1='$(whoami)@$(hostname):$(pwd)'`

shell 커서의 앞 표시 부분을 자신이 원하는 형태로 변환할 수 있다.

## 디스크

`df -h`

파일시스템 사용 상태 확인

`du -sh {PATH}`

해당 PATH 예하 파일들의 디스크 사용량을 볼 수 있다.

`du -h -d {DEPTH} {PATH}`

해당 PATH 예하 파일들의 용량정보를 디렉토리 DEPTH 만큼마다 구분하여 보여준다.
DEPTH 를 너무 높게 하면 서버에 무리를 줄 수 있으므로 주의할것.

`sudo du -hsx * | sort -rh | head -n 10`

현재 PATH 에서 디스크 사용량이 제일 많은 PATH TOP 10 출력

## 포트

`netstat -vanp`

현재 동작중인 모든 포트(소켓)의 이름과 상태를 확인한다

`netstat -natp`

현재 포트별 네트워크 연결상태 확인

`netstat -natp | grep LISTEN`

현재 연결이 가능한 서버에서 수신 대기중인 포트들

`netstat -vanp --tcp | grep 8000`

8000 번 TCP 포트의 사용정보를 조회 (프로세스 ID 포함)

`sudo lsof -i TCP:7777`

특정포트를 사용하는 프로세스 pid 확인 (여기서는 7777)

`sudo fuser -k 7777/tcp`

특정포트(예제는 7777)를 사용하는 프로세스 kill

`cat /etc/services | grep '{포트번호 or 프로그램명}'`

시스템의 각 포트가 어떤 어플리케이션에게 할당되어있는지 볼 수 있음. ( 파란 부분을 붙여서 특정 부분을 찾아 보는것을 추천)

## 쉘 스크립트 작성 시 꿀팁

`BASH_FILE_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"`

현재 스크립트가 들어있는 폴더의 절대 경로 얻기

---

[목록으로](https://github.com/Shiwoo-Park/blog/tree/master/kor)
