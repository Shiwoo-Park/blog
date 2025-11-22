---
layout: post
title: "복잡한 Celery 서버 배포 스크립트"
date: 2024-01-01
categories: [bash, celery, deploy, devops]
---

복잡한 Celery 서버 배포를 위한 스크립트 모음입니다. Jenkins 서버에서 실행하는 배포 스크립트와 Celery 서버에서 실행되는 스크립트를 포함합니다.

---

## 1. Jenkins 서버 스크립트

### 1-1. celery_specs.sh

서버 그룹과 worker_spec 매핑을 정의하는 스크립트입니다.

```bash
#!/bin/bash

# 서버 그룹과 worker_spec 매핑
# K: worker_spec, V: server list

declare -A test_server_groups=(
  ["dev_pizza:1,dev_drink:1"]="
    silva-dev-celery-2a
  "
  ["stage_pizza_zz:1,stage_pizza_xx:1,stage_pizza_yy:1,stage_drink_kt:1,stage_drink_coke:1,stage_drink_etc:1"]="
    silva-stage-celery-2a
  "
  ["pizza_zz:1,pizza_xx:1,pizza_yy:1"]="
    drink-coke-celery-2c-00
  "
  ["default:1,base:1,dbconn:1,myaaa:1,mybbb:1"]="
    drink-coke-celery-2c-00
  "
  ["myccc:1,myddd:1,myeee:1"]="
    drink-coke-celery-2c-00
  "
)

declare -A prod_server_groups=(
  ["pizza_zz:1,pizza_xx:1,pizza_yy:1"]="
    silva-pizza-celery-2a
    silva-pizza-celery-2c
  "
  ["default:1,base:1,dbconn:1,myaaa:1"]="
    silva-drink-celery-2a-01
    silva-drink-celery-2a-02
    silva-drink-celery-2c-01
    silva-drink-celery-2c-02
  "
  ["mybbb:2"]="
    silva-drink-celery-2a-03
    silva-drink-celery-2a-04
    silva-drink-celery-2a-05
    silva-drink-celery-2a-06
    silva-drink-celery-2a-07
    silva-drink-celery-2a-08
    silva-drink-celery-2c-03
    silva-drink-celery-2c-04
    silva-drink-celery-2c-05
    silva-drink-celery-2c-06
    silva-drink-celery-2c-07
    silva-drink-celery-2c-08
  "
  ["myccc:2"]="
    drink-coke-celery-2a-01
    drink-coke-celery-2a-02
    drink-coke-celery-2a-03
    drink-coke-celery-2a-04
    drink-coke-celery-2a-05
    drink-coke-celery-2a-06
    drink-coke-celery-2c-01
    drink-coke-celery-2c-02
    drink-coke-celery-2c-03
    drink-coke-celery-2c-04
    drink-coke-celery-2c-05
    drink-coke-celery-2c-06
  "
  ["myddd:2"]="
    drink-coke-celery-2a-07
    drink-coke-celery-2a-08
    drink-coke-celery-2a-09
    drink-coke-celery-2a-10
    drink-coke-celery-2a-11
    drink-coke-celery-2a-12
    drink-coke-celery-2c-07
    drink-coke-celery-2c-08
    drink-coke-celery-2c-09
    drink-coke-celery-2c-10
    drink-coke-celery-2c-11
    drink-coke-celery-2c-12
  "
  ["myeee:2"]="
    drink-coke-celery-2a-13
    drink-coke-celery-2a-14
    drink-coke-celery-2a-15
    drink-coke-celery-2a-16
    drink-coke-celery-2a-17
    drink-coke-celery-2a-18
    drink-coke-celery-2c-13
    drink-coke-celery-2c-14
    drink-coke-celery-2c-15
    drink-coke-celery-2c-16
    drink-coke-celery-2c-17
    drink-coke-celery-2c-18
  "
)
```

### 1-2. deploy.sh (Jenkins 배포 스크립트)

Jenkins 서버에서 실행되는 배포 스크립트입니다.

```bash
#!/bin/bash

# jenkins 서버 배포 스크립트
# host: ip-10-50-125-111.ap-northeast-2.compute.internal
# user: jenkins
# path: /var/lib/jenkins/scripts/deploy_api_v1_drink_celery.sh

SCRIPT_DIR=$(dirname "$(realpath "$0")")
VALID_TARGETS=("dev" "stage" "prod_test_pizza" "prod_test_drink_1" "prod_test_drink_2" "prod")
VALID_MODES=("debug" "deploy")

# 입력 인수 최소 개수 확인
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <target> [mode] [branch]"
    echo "- target: 배포 환경 (${VALID_TARGETS[*]})"
    echo "  - dev|stage|prod: 각 일반 배포 환경"
    echo "  - prod_test_pizza: 운영테스트 서버에 피자 관련 워커만 배포"
    echo "  - prod_test_drink_1: 운영테스트 서버에 음료 관련 카테고리 1 (etc,myaaa,mybbb) 워커만 배포"
    echo "  - prod_test_drink_2: 운영테스트 서버에 음료 관련 카테고리 2 (myccc,myddd,myeee) 워커만 배포"
    echo "- mode: 배포 모드 (${VALID_MODES[*]}) (기본값: debug)"
    echo "- branch: 배포 브랜치 (기본값: master)"
    echo "[Examples]"
    echo "  개발환경 배포  : $0 dev deploy feature/BE-1234_my_work"
    echo "  스테이지 배포  : $0 stage deploy release/1215_pm"
    echo "  운영 테스트   : $0 prod_test deploy feature/BE-1234_my_work"
    echo "  운영 가짜 배포 : $0 prod"
    echo "  운영 배포     : $0 prod deploy"
    exit 1
fi

# 입력 인수 값 검증
target=$1
mode=${2:-"debug"}
branch=${3:-"master"}

# target 유효성 검사
if [[ ! " ${VALID_TARGETS[*]} " =~ " $target " ]]; then
    echo "Error: Invalid target '$target'. Valid options are: ${VALID_TARGETS[*]}"
    exit 1
fi

# mode 유효성 검사
if [[ ! " ${VALID_MODES[*]} " =~ " $mode " ]]; then
    echo "Error: Invalid mode '$mode'. Valid options are: ${VALID_MODES[*]}"
    exit 1
fi

echo "Target: $target"
echo "Mode: $mode"
echo "Branch: $branch"
echo "위 배포 스펙을 확인하세요 (3초 대기) - 잘못되었을시 Ctrl+C "
sleep 3

# drink celery server group 정보를 불러온다.
. ${SCRIPT_DIR}/celery_specs.sh

# 배포할 worker_spec 필터링
env=$target  # 환경별 settings.ini 파일 복사에 활용
filtered_worker_specs=()

if [[ "$target" == "prod" ]]; then
  # prod: 모든 worker_spec 배포
  filtered_worker_specs=("${!prod_server_groups[@]}")
else
  # dev, stage, prod_test: 특정 worker_spec 필터링
  case $target in
    "dev")
      env="develop"
      filtered_worker_specs=("dev_pizza:1,dev_drink:1")
      ;;
    "stage")
      filtered_worker_specs=("stage_pizza_zz:1,stage_pizza_xx:1,stage_pizza_yy:1,stage_drink_kt:1,stage_drink_coke:1,stage_drink_etc:1")
      ;;
    # 운영 테스트 서버 (3가지)
    "prod_test_pizza")
      env="prod"
      filtered_worker_specs=("pizza_zz:1,pizza_xx:1,pizza_yy:1")
      ;;
    "prod_test_drink_1")
      env="prod"
      filtered_worker_specs=("default:1,base:1,dbconn:1,myaaa:1,mybbb:1")
      ;;
    "prod_test_drink_2")
      env="prod"
      filtered_worker_specs=("myccc:1,myddd:1,myeee:1")
      ;;
    *)
      echo "Error: Unsupported environment '$target'. Use one of: ${VALID_TARGETS[*]}"
      exit 1
      ;;
  esac
fi

get_server_group() {
  if [[ "$target" == "prod" ]]; then
    echo "${prod_server_groups[$1]}"
  else
    echo "${test_server_groups[$1]}"
  fi
}

# 배포 로직
for worker_spec in "${filtered_worker_specs[@]}"; do
  echo "===================================================="
  echo "Starting deployment for worker_spec: $worker_spec"

  servers=$(get_server_group "$worker_spec")

  # 서버별로 배포 실행
  for server in $servers; do
    # AWS CLI로 프라이빗 IP 조회
    private_ip=$(aws ec2 describe-instances \
      --filters "Name=tag:Name,Values=${server}" \
      --query "Reservations[].Instances[].PrivateIpAddress" \
      --output text)

    # 프라이빗 IP가 없을 경우 에러 처리
    if [ -z "$private_ip" ]; then
      echo "Error: Could not find private IP for $server"
      continue
    fi

    echo "----------------------------------------------------"
    echo "[START] Connecting to [$server] ($private_ip) ..."
    deploy_cmd="sudo /home/baro/api/bin/deploy.sh $env $branch $worker_spec"
    echo "[CMD] ${deploy_cmd}"

    # 배포 명령어 실행
    if [ $mode == "debug" ]; then  # 디버그 모드일때는 hostname 만 출력
      ssh -i /var/lib/jenkins/.aws/silva-aws-key.pem -o StrictHostKeyChecking=no ec2-user@"$private_ip" "hostname"
    elif [ $mode == "deploy" ]; then
      ssh -i /var/lib/jenkins/.aws/silva-aws-key.pem -o StrictHostKeyChecking=no ec2-user@"$private_ip" $deploy_cmd
    else
      echo "[FAILED] Invalid mode=${mode}"
    fi

    echo "[FINISHED] server=${server}, branch=${branch}, worker_spec=${worker_spec}"
  done
  echo "----------------------------------------------------"
  echo "Deployment for worker_spec: $worker_spec completed."
done

echo "===================================================="
echo "All deployments completed: branch=${branch}"
```

---

## 2. Celery 서버에서 실행되는 스크립트

### 2-1. deploy.sh (배포 entrypoint)

배포 스크립트의 전체 배포 프로세스를 실행하는 entrypoint입니다.

```bash
#!/bin/bash

# 배포 스크립트: 전체 배포 프로세스를 실행
set -e

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <env> <branch> <worker_spec>"
    echo "- env: dev|stage|prod"
    echo "- worker_spec: \"{worker_name}:{screen_count}\"  (콤마로 구분하여 여러개 입력 가능)"
    echo "- worker_name: dev_pizza|dev_drink"
    echo "- worker_name: stage_pizza_zz|stage_pizza_xx|stage_pizza_yy|stage_drink_kt|stage_drink_coke|stage_drink_etc"
    echo "- worker_name: pizza_zz|pizza_xx|pizza_yy|default|base|dbconn|myaaa|mybbb|myccc|myddd|myeee"
    echo "- Examples:"
    echo "  $0 feature/BE-1234 stage1:1,stage2:1"
    echo "  $0 feature/BE-1234 dev:2"
    exit 1
fi

env=$1  # settings.ini 파일 복사에 사용
branch=$2  # 코드 형상 불러올때 사용
worker_spec=$3  # 워커 구동 옵션 및 스크린 개수에 사용

SCRIPT_DIR=$(dirname "$(realpath "$0")")
cd "$SCRIPT_DIR"

# 로그 저장
LOG_FILE="/var/log/api-v1-celery-deploy.log"
exec > >(tee -a "${LOG_FILE}") 2>&1
echo "==== Logging to [${LOG_FILE}] ===="

# 프로젝트 설정
echo "==== Start project setup ===="
. ${SCRIPT_DIR}/project_setup.sh "$env" "$branch"
echo "Finished project setup"

# 워커 실행
echo "==== Start celery workers by screen ===="
. ${SCRIPT_DIR}/run_workers.sh "$worker_spec"
echo "Finished run celery workers"

echo "==== api-v1 drink celery 배포 완료: branch=${branch} ===="

# 마지막에 배포 이후 현황 조회
echo "Celery Process List..."
ps -ef | grep "Baropharm worker"
echo "-------------------------------------------------------"
echo "Worker Screens..."
screen -ls

exit 0
```

### 2-2. celery.yaml (Promtail 설정파일)

Celery 서버용 Promtail 설정 파일입니다.

```yaml
# promtail config for Celery server
# - prod setting (EC2 ASG)

server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /home/ec2-user/promtail/positions.yaml

clients:
  - url: http://10.50.100.59:3100/loki/api/v1/push

scrape_configs:
  - job_name: api-v1-celery-ENV
    static_configs:
      - targets:
          - localhost:9080
        labels:
          service: api-v1-celery-ENV
          name: api-v1-celery
          instance: HOSTNAME
          environment: ENV
          __path__: /home/ec2-user/api-v1/logs/silva-api-v1.log
```

### 2-3. project_setup.sh (서버별 setup)

프로젝트 설정 스크립트로, Git 업데이트 및 의존성 설치를 담당합니다.

```bash
#!/bin/bash

# 프로젝트 설정 스크립트: Git 업데이트 및 의존성 설치
set -e

env=$1
branch=${2:-master}
repo_dir="/home/baro/api"
venv_dir="${repo_dir}/venv"

echo "==== Load repository code [branch=${branch}] ===="
sudo sh -c "
  set -e
  cd ${repo_dir}
  git fetch -p
  git reset --hard
  git checkout ${branch}
  git pull
  if [ -f settings.ini ]; then
    rm -f settings.ini
  fi
  cp settings.${env}.ini settings.ini
  git status
"
echo "done"

echo "==== Install pip packages ===="
sudo sh -c "
  set -e
  ${venv_dir}/bin/pip install -r ${repo_dir}/requirements.txt
"
echo "done"

echo "==== Setup Promtail for Grafana ===="

promtail_config_path="/home/ec2-user/promtail/promtail-local-config.yaml"
sudo sh -c "
  set -e
  cp ${repo_dir}/deploy/promtail_local_config/celery.yaml ${promtail_config_path}
  sed -i 's/ENV/${env}/g' ${promtail_config_path}
  sed -i 's/HOSTNAME/${HOSTNAME}/g' ${promtail_config_path}
  chown ec2-user:ec2-user ${promtail_config_path}
  service promtail restart
"

cat ${promtail_config_path} | grep service

# 정상 부팅되었는지 확인
promtail_status=$(sudo service promtail status | grep -i 'running')
if [ -z "$promtail_status" ]; then
  echo "Error: Promtail service is not running!" >&2
  exit 1
fi
```

### 2-4. run_workers.sh (서버별 celery 워커 구동 및 종료)

지정된 스펙에 따라 Celery 워커를 실행하는 스크립트입니다.

```bash
#!/bin/bash

# 워커 실행 스크립트: 지정된 스펙에 따라 Celery 워커 실행
set -e
set -o pipefail

worker_spec=$1  # 워커 구동 스펙 (ex: stage1:1,stage2:1)
proj_dir="/home/baro/api"
venv_dir="${proj_dir}/venv"
celery_app="Baropharm"
LOG_FILE="/var/log/api-v1-celery-deploy.log"

# 워커 설정
declare -A workers=(
  # K: celery 워커스펙 명(스크린명 prefix)
  # V: celery 구동 스펙

  # ===== test =====
  ["dev_pizza"]=".celery_app_pizza -Q develop,default -l info --autoscale 6,3"
  ["dev_drink"]=".celery_app_drink -Q develop,default -l info --autoscale 6,3"
  # pizza celery 
  ["stage_pizza_zz"]=".celery_app_pizza worker -Q login,get_center -l info --autoscale 2,1"
  ["stage_pizza_xx"]=".celery_app_pizza worker -Q get_center_coke,login_coke -l info --autoscale 2,1"
  ["stage_pizza_yy"]=".celery_app_pizza worker -Q login_dbconn -l info --autoscale 2,1"
  # drink celery
  ["stage_drink_kt"]=".celery_app_drink worker -Q default,base,mybbb -l info --autoscale 2,1"
  ["stage_drink_coke"]=".celery_app_drink worker -Q myccc,myddd,myeee,myaaa -l info --autoscale 2,1"
  ["stage_drink_etc"]=".celery_app_drink worker -Q dbconn -l info --autoscale 2,1"

  # ===== prod =====
  # pizza celery (피자 용)
  ["pizza_zz"]=".celery_app_pizza worker -Q login,get_center -l info" 
  ["pizza_xx"]=".celery_app_pizza worker -Q get_center_coke,login_coke -l info" 
  ["pizza_yy"]=".celery_app_pizza worker -Q login_dbconn -l info"
  # drink celery (음료 용)
  ["default"]=".celery_app_drink worker -Q default -l info -c 1"
  ["base"]=".celery_app_drink worker -Q base -l info --autoscale 6,3"
  ["dbconn"]=".celery_app_drink worker -Q dbconn -l info -c 3"
  ["myaaa"]=".celery_app_drink worker -Q myaaa -c 2"
  ["mybbb"]=".celery_app_drink worker -Q mybbb -c 1"
  ["myccc"]=".celery_app_drink worker -Q myccc -c 1"
  ["myddd"]=".celery_app_drink worker -Q myddd -c 1"
  ["myeee"]=".celery_app_drink worker -Q myeee -c 1"
)

start_worker() {
  local worker_name=$1
  local instance_num=$2
  local screen_name="${worker_name}-${instance_num}"

  # Worker Stop
  # - 정확히 특정 screen 하위 celery main process pid 를 찾아내서
  # - 프로세스에 SIGTERM 신호를 보낸다 (celery warm shutdown 유도)
  if [ $(screen -ls | grep ${screen_name} | wc -l) -gt 0 ]; then
    local screen_pid=$(screen -ls | grep ${screen_name} | awk '{print $1}' | cut -d'.' -f1)
    local start_cmd_pid=$(ps -eo pid,ppid | awk -v spid=$screen_pid '$2 == spid {print $1}')
    local celery_main_pid=$(ps -eo pid,ppid | awk -v cpid=$start_cmd_pid '$2 == cpid {print $1}')
    local stop_command="kill -SIGTERM $celery_main_pid"
    echo "[CMD] ${stop_command}"
    # Warm shutdown 시도
    if ! sudo bash -c "${stop_command}" 2>&1 | tee -a "${LOG_FILE}"; then
      # Force kill 처리
      sudo screen -S "$screen_name" -X quit
      echo "[스크린=${screen_name}] 강제 종료됨 (Graceful stop 실패)"
    else
      echo "[스크린=${screen_name}] 정상 종료됨"
    fi
  else
    echo "[스크린=${screen_name}] 찾을 수 없음 (Skip)"
  fi

  local start_command="cd ${proj_dir}; ${venv_dir}/bin/celery -A ${celery_app}${workers[$worker_name]} -n ${screen_name}-%h"
  echo "[CMD] ${start_command}"
  sudo screen -dmS "$screen_name" bash -c "${start_command}" # celery kill 동시에 screen 종료
  #sudo screen -dmS "$screen_name" bash -c "${start_command}; exec bash" # celery 를 kill 해도 screen 에 머무르기
  echo "[스크린=${screen_name}] 구동 완료"
}

# 워커 스펙 처리 (default:1,base:1,dbconn:1,myaaa:1)
echo "==== Start celery workers ===="
IFS=',' read -ra specs <<< "$worker_spec"  # 쉼표로 구분된 워커 스펙 분리
for spec in "${specs[@]}"; do
  IFS=':' read -r worker_name instance_count <<< "$spec"

  if [ -z "${workers[$worker_name]}" ]; then
    echo "알 수 없는 worker [$worker_name]. Skipping..."
    continue
  fi

  # instance_count가 없으면 기본값 1
  instance_count=${instance_count:-1}

  # 지정된 수만큼 screen 실행
  for i in $(seq 1 "$instance_count"); do
    start_worker "$worker_name" "$i"
  done
done

echo "==== Celery workers started ===="
```

