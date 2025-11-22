---
layout: post
title: "pyenv 설치 준비 스크립트 in AWS-EC2 인스턴스"
date: 2021-01-08
categories: [aws, ec2, python]
---
```shell
#!/bin/bash
# pyenv 를 aws ec2 에 설치하기 위한 스크립트

set -e

echo "OS Spec 확인"
cat /etc/os-release

# [유저=ec2-user] pyenv 에서 필요한 패키지 설치 ===============
sudo yum groupinstall -y "Development Tools"
sudo yum install -y bzip2-devel ncurses-devel libffi-devel readline-devel openssl11-devel xz-devel sqlite sqlite-devel

# 배포 시, pyenv 를 사용하게될 유저(silva)로 전환
sudo su - silva << 'EOF'

# [유저=silva] pyenv 설치 ===============
if [ ! -d "$HOME/.pyenv" ]; then
  echo "Installing pyenv..."
  git clone https://github.com/pyenv/pyenv.git ~/.pyenv
  git clone https://github.com/pyenv/pyenv-virtualenv.git ~/.pyenv/plugins/pyenv-virtualenv
else
  echo "pyenv is already installed"
fi

# [유저=silva] pyenv init ===============
if ! grep -q 'export PYENV_ROOT="$HOME/.pyenv"' ~/.bashrc; then
  echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
  echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
  echo 'eval "$(pyenv init --path)"' >> ~/.bashrc
  echo 'eval "$(pyenv init -)"' >> ~/.bashrc
  echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bashrc
fi

# 쉘 재로드
exec "$SHELL"
EOF

echo "silva 유저 기준으로 pyenv 설치 및 설정이 완료되었습니다."
```