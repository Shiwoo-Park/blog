---
layout: post
title: "GitLab 복원 스크립트"
date: 2024-01-01
categories: [bash, gitlab, restore, devops]
---

신규 GitLab 서버에서 백업된 데이터를 복구하기 위한 스크립트입니다. 백업 파일을 사용하여 GitLab 서버를 복원합니다.

---

## 1. 스크립트 내용

```bash
#!/bin/bash

# ###############################
# 신규 gitlab 서버에서 데이터 복구를 위해 실행
# ###############################

set -e

# 설정 변수
BACKUP_DIR="/home/ec2-user/gitlab_backups"
GITLAB_BACKUP_DIR="/var/opt/gitlab/backups"
LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/*.tar | head -1)

echo "[INFO] GitLab 복원 스크립트 실행 시작: $(date)"

# 1️⃣ GitLab 서비스 중지
echo "[INFO] GitLab 서비스를 중지합니다..."
sudo gitlab-ctl stop

echo "[INFO] 백업을 위해 필요한 GitLab 서비스 일부는 구동..."
sudo gitlab-ctl start postgresql
sudo gitlab-ctl start redis
sudo gitlab-ctl start gitaly

# 2️⃣ 기존 백업 파일을 GitLab 복원 디렉토리로 이동
echo "[INFO] 최신 백업 파일을 복원 디렉터리로 이동..."
sudo cp "$LATEST_BACKUP" "$GITLAB_BACKUP_DIR/"
sudo chown git:git "$GITLAB_BACKUP_DIR/"*.tar

# 3️⃣ GitLab 설정 및 secrets 복원
echo "[INFO] GitLab 설정 및 secrets 파일을 복원합니다..."
sudo tar -xzvf "$BACKUP_DIR/gitlab_config_backup.tar.gz" -C /
sudo tar -xzvf "$BACKUP_DIR/gitlab_secrets_backup.tar.gz" -C /

# 4️⃣ GitLab 데이터 복원
BACKUP_FILE_NAME=$(basename "$LATEST_BACKUP")
echo "[INFO] GitLab 백업 파일 복원 중..."
BACKUP_NAME=$(basename "$BACKUP_FILE_NAME" .tar | sed 's/_gitlab_backup//')
echo "BACKUP_NAME=$BACKUP_NAME"
sudo gitlab-backup restore BACKUP="$BACKUP_NAME"

# 5️⃣ GitLab 설정 파일 external_url 수정 (필요한 경우 도메인 변경)
#echo "[INFO] GitLab 도메인 설정 업데이트..."
#sudo sed -i 's|http://gitlab-ce-v2-357625712.ap-northeast-2.elb.amazonaws.com|http://gitlab.barodev.com|g' /etc/gitlab/gitlab.rb

# 6️⃣ GitLab 서비스 재설정 및 재시작
echo "[INFO] GitLab 서비스를 다시 시작합니다..."
sudo gitlab-ctl reconfigure
sudo gitlab-ctl restart

echo "[INFO] GitLab 복원 완료!"
echo "[INFO] 완료 시간: $(date)"
```

---

## 2. 주요 기능

- **서비스 안전 중지**: 복원을 위해 서비스 중지
- **백업 파일 복원**: 최신 백업 파일을 사용하여 데이터 복원
- **설정 파일 복원**: GitLab 설정 및 secrets 파일 복원
- **서비스 재시작**: 복원 후 서비스 재설정 및 재시작

