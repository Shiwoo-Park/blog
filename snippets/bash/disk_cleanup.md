---
layout: post
title: "디스크 정리 스크립트"
date: 2024-01-01
categories: [bash, linux, devops, cleanup]
---

Linux 서버에서 디스크 공간을 확보하기 위한 정리 스크립트입니다. 사용하지 않는 Docker 리소스, 오래된 시스템 로그, YUM 캐시를 제거합니다.

---

## 1. 스크립트 내용

```bash
#!/bin/bash

# Disk cleanup script for Linux servers
# Removes unused Docker resources, old system logs, and YUM cache to free up disk space

echo "====== Start Clean Disk ======"
df -h

# Docker Cleanup
docker container prune -f
docker image prune -f
docker volume prune -f
docker network prune -f
docker system prune -a --volumes -f

# Jenkins Cleanup
#sudo rm -rf /var/lib/jenkins/workspace/*
#sudo rm -rf /var/lib/jenkins/jobs/*/builds/*
#sudo rm -rf /var/lib/jenkins/.cache/*

# System Logs Cleanup
sudo journalctl --vacuum-time=7d
#sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

# YUM Package Cleanup
sudo yum clean all

echo "====== Clean Disk complete!!! ======"
df -h
```

---

## 2. 주요 기능

- **Docker 정리**: 사용하지 않는 컨테이너, 이미지, 볼륨, 네트워크 제거
- **시스템 로그 정리**: 7일 이상 된 시스템 로그 제거
- **YUM 캐시 정리**: 패키지 관리자 캐시 제거
- **임시 파일 정리**: `/var/tmp` 디렉토리 정리

