---
layout: post
title: "Devops work"
date: 2024-12-13
categories: [devops, linux, commands]
---
## linux command - 디스크 정리

```shell
# 대용량 파일 및 디렉토리 찾기 (Top 20)
sudo du -h / | sort -rh | head -n 20

# 패키지 캐시 정리
sudo yum clean all

# 저널로그 삭제 (7일 이상된)
sudo journalctl --vacuum-time=7d

# 디스크 사용량 분석도구 설치 & 활용
sudo yum install ncdu
sudo ncdu /
```

## nextjs

```shell
yarn cache clean
yarn build
yarn build -d
yarn start

pm2 start ecosystem.confiVVg.js
pm2 stop myapp-web  # 애플리케이션 중지
pm2 restart myapp-web  # 애플리케이션 재시작
pm2 delete myapp-web  # 애플리케이션 삭제
```

## nginx

### nginx - server manage

```shell
nginx -V
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl reload nginx
sudo systemctl restart nginx
sudo systemctl status nginx

ln -s /var/log/nginx/access.log nginx_access.log
ln -s /var/log/nginx/error.log nginx_error.log
```


### nginx config

```shell
upstream dodopharm-web-dev {
    server 127.0.0.1:4000;
}

server {
    listen 80;
    server_name www.dev.dodopharmdev.com;

    location / {
        proxy_pass http://dodopharm-web-dev;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## git

```shell
git for-each-ref --format '%(refname:short) %(upstream:track)' |
awk '$2 == "[gone]" {print $1}' |
xargs git branch -D

git rebase -i HEAD~4
```

## terraform

```shell
terraform init
terraform plan
terraform apply
terraform refresh
terraform show

terraform state rm aws_instance.ecs_instance  # 연결 해제 (AWS 콘솔에서 수동 삭제)
terraform import aws_instance.ecs_instance i-0c1e69863aa1bc0f1  # 임의 연결

# 특정 리소스만 제거
terraform destroy \
  -target=aws_instance.ecs_instance \
  -target=aws_ecs_service.ecs_service \
  -target=aws_ecs_task_definition.ecs_task

```

## AWS - Code Deploy

```shell
sudo service codedeploy-agent status

sudo service codedeploy-agent start

sudo -i
vi /var/log/aws/codedeploy-agent/codedeploy-agent.log
```

## my-service

```shell
sudo systemctl stop api-v2
```