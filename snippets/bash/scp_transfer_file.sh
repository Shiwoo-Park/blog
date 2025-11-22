#!/bin/bash

# bastion 서버에서 실행하는 스크립트 (구 서버로부터 백업파일들을 다운로드 받아와서 신규 서버로 전송)

scp -i /home/ec2-user/.aws/my-aws-key.pem ec2-user@10.50.111.11:/home/ec2-user/gitlab_backups/* .
scp -i /home/ec2-user/.aws/my-aws-key.pem /home/ec2-user/gitlab-backups/* ec2-user@10.50.222.22:/home/ec2-user/gitlab_backups
