---
layout: post
title: "GitLab 백업 스크립트"
date: 2024-01-01
categories: [bash, gitlab, backup, devops]
---

GitLab 서버에서 전체 데이터를 백업하는 스크립트입니다. DB, Redis, 인증 등의 모든 데이터를 포함하여 백업합니다. 슈퍼 유저 콘솔에서 실행해야 합니다.

---

## 1. 스크립트 내용

```bash
#!/bin/bash

# ###############################
# 구 gitlab 서버에서 데이터 백업
# - 슈퍼 유저 콘솔에서 실행 (sudo -i)
# - DB, redis, 인증 등의 모든 데이터 포함
# ###############################

# 설정 변수
BACKUP_DIR="/home/ec2-user/gitlab_backups"
GITLAB_BACKUP_DIR="/var/opt/gitlab/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RETENTION_DAYS=30

echo "[INFO] GitLab 전체 백업 스크립트 실행 시작: $(date)"

# ec2-user 홈 디렉토리에 백업 폴더 생성 (없으면 생성)
if [ ! -d "$BACKUP_DIR" ]; then
    echo "[INFO] 백업 폴더 생성: $BACKUP_DIR"
    sudo mkdir -p "$BACKUP_DIR"
    sudo chown ec2-user:ec2-user "$BACKUP_DIR"
fi

# GitLab 서비스 중지 (데이터 정합성을 위해)
echo "[INFO] GitLab 서비스를 일시 중지합니다..."
sudo gitlab-ctl stop

echo "[INFO] 백업을 위해 필요한 GitLab 서비스 일부는 구동..."
sudo gitlab-ctl start postgresql
sudo gitlab-ctl start redis
sudo gitlab-ctl start gitaly

# GitLab 전체 백업 (DB + 저장소 + 설정 파일)
echo "[INFO] GitLab 백업 생성 중..."
sudo gitlab-backup create SKIP=uploads,builds,artifacts,lfs,registry,pages
if [ $? -ne 0 ]; then
    echo "[ERROR] GitLab 백업 생성 실패!"
    sudo gitlab-ctl start  # 실패 시 GitLab 재시작
    exit 1
fi

# GitLab 중요한 디렉토리 추가 백업
echo "[INFO] GitLab 설정 및 사용자 데이터 백업..."
sudo tar -czvf "$BACKUP_DIR/gitlab_config_backup.tar.gz" /etc/gitlab
sudo tar -czvf "$BACKUP_DIR/gitlab_secrets_backup.tar.gz" /var/opt/gitlab/gitlab-rails/etc

# GitLab 서비스 재시작
echo "[INFO] GitLab 서비스를 다시 시작합니다..."
sudo gitlab-ctl start

# 가장 최근 생성된 백업 파일 찾기
LATEST_BACKUP=$(ls -t "$GITLAB_BACKUP_DIR"/*.tar | head -1)
if [ -z "$LATEST_BACKUP" ]; then
    echo "[ERROR] 백업 파일을 찾을 수 없습니다."
    exit 1
fi
echo "[INFO] 생성된 백업 파일: $LATEST_BACKUP"

# 백업 파일을 지정된 디렉토리로 이동
echo "[INFO] 백업 파일 이동..."
sudo cp "$LATEST_BACKUP" $BACKUP_DIR
BACKUP_FILE=`basename $LATEST_BACKUP`
sudo chown ec2-user:ec2-user "$BACKUP_DIR/*"

# 오래된 백업 파일 정리 (7일 이상 된 파일 삭제)
echo "[INFO] ${RETENTION_DAYS}일 이상 된 백업 파일 삭제..."
find "$BACKUP_DIR" -type f -name "*.tar" -mtime +$RETENTION_DAYS -exec rm -f {} \;

echo "[INFO] GitLab 전체 백업 완료"
echo "- 백업 파일 DIR: $BACKUP_DIR/*"
echo "- 백업 파일 PATH: $BACKUP_DIR/$LATEST_BACKUP"
echo "- 완료 시간: $(date)"
```

---

## 2. 주요 기능

- **전체 데이터 백업**: DB, 저장소, 설정 파일 포함
- **서비스 안전 중지**: 데이터 정합성을 위해 서비스 중지 후 백업
- **자동 정리**: 30일 이상 된 백업 파일 자동 삭제
- **에러 처리**: 백업 실패 시 서비스 재시작 및 에러 메시지 출력

