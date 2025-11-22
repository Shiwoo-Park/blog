---
layout: post
title: "SCP 파일 전송 스크립트"
date: 2024-01-01
categories: [bash, scp, file-transfer, devops]
---

Bastion 서버에서 실행하는 스크립트로, 구 서버로부터 백업 파일들을 다운로드 받아 신규 서버로 전송합니다.

---

## 1. 스크립트 내용

```bash
#!/bin/bash

# bastion 서버에서 실행하는 스크립트 (구 서버로부터 백업파일들을 다운로드 받아와서 신규 서버로 전송)

scp -i /home/ec2-user/.aws/my-aws-key.pem ec2-user@10.50.111.11:/home/ec2-user/gitlab_backups/* .
scp -i /home/ec2-user/.aws/my-aws-key.pem /home/ec2-user/gitlab-backups/* ec2-user@10.50.222.22:/home/ec2-user/gitlab_backups
```

---

## 2. 주요 기능

- **원격 서버에서 파일 다운로드**: 구 서버(10.50.111.11)에서 백업 파일 다운로드
- **신규 서버로 파일 전송**: 다운로드한 파일을 신규 서버(10.50.222.22)로 전송
- **SSH 키 인증**: AWS 키 파일을 사용한 안전한 파일 전송

