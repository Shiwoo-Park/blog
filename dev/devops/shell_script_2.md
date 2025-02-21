
# Shell Script: favorite snippets - Advanced

> 날짜: 2024-06-25

[목록으로](https://shiwoo-park.github.io/blog)

---

### 현재 스크립트가 들어있는 폴더의 절대 경로 얻기
- `BASH_FILE_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"`

### 명령어 실행 중 에러 발생시 에러 발생 종료 처리
- `set -e`
- 스크립트에 이 명령어를 넣으면 이 라인 이후에 실행되는 명령어의 결과 exit code 가 0 이 아닌것이 하나라도 나오면 곧바로 제어 흐름을 중단처리 한다 (= 에러발생)

### stdout, stderr file append + 콘솔 출력
- `./my_batch.sh 2>&1 | tee -a output.log`
- 스크립트를 실행했을때 stdout 과 stderr 를 콘솔에 표시함과 동시에 output.log 파일로도 저장할 수 있도록 해준다.

### grep 으로 특정 프로세스 찾아서 죽이기
- `kill $(ps aux | grep 'ssh-agent' | awk '{print $2}')`
- 위 예제에서는 ssh-agent 를 모조리 강제 종료 처리한다

### 입력값 받아서 파라미터로 저장하기
- `read -p "최근 몇 개의 커밋을 리셋 하시겠습니까? " N`
- `git reset --soft HEAD~$N`

### scp 를 이용하여 A 서버로부터 파일 받아와서 B 서버로 보내기

```shell
scp -i /home/ssm-user/.aws/my-aws-key.pem ec2-user@10.50.222.22:/home/ec2-user/gitlab_backups/* .
scp -i /home/ssm-user/.aws/my-aws-key.pem /home/ssm-user/gitlab-backups/* ec2-user@10.50.333.3:/home/ec2-user/gitlab_backups
```

### 특정 포트 사용하는 프로세스 죽이기

```shell
#!/bin/bash

# 종료할 포트 목록
ports=(3000 3030)  # 여기에 원하는 포트를 추가하세요

# 각 포트를 순회하면서 프로세스를 종료
for port in "${ports[@]}"; do
echo "포트 $port 를 검사 중입니다..."

# 포트를 사용하는 프로세스 찾기
pid=$(lsof -t -i:$port)

if [ -z "$pid" ]; then
    echo "포트 $port 를 사용하는 프로세스를 찾을 수 없습니다."
else
    echo "포트 $port 를 사용하는 프로세스 PID: $pid"
    # 프로세스 강제 종료
    kill -9 $pid
    echo "프로세스 $pid 를 강제 종료했습니다."
fi
done
```

---

[목록으로](https://shiwoo-park.github.io/blog)
