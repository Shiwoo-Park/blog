---
layout: post
title: "리눅스용 세션 분할 도구: screen"
date: 2024-12-03
categories: [devops, linux, tools]
---
아래는 `screen` 명령어의 사용법을 **명령어, 용도, 예시** 위주로 정리한 내용입니다.

### 1. **screen 목록 확인**
#### **명령어**
```bash
screen -ls
```
#### **용도**
현재 실행 중인 모든 `screen` 세션의 목록을 확인합니다. 세션 이름과 상태(Attached/Detached)를 확인할 수 있습니다.

#### **예시**
```bash
$ screen -ls
There are screens on:
    1234.dev_celery   (Detached)
    5678.prod_celery  (Attached)
2 Sockets in /run/screen/S-user.
```

---

### 2. **특정 screen 세션에 접속**
#### **명령어**
```bash
screen -R {name}
```
#### **용도**
지정된 이름의 `screen` 세션에 접속합니다. 세션이 Detached 상태일 때만 사용할 수 있습니다.

#### **예시**
```bash
screen -R dev_celery
```
- 이름이 `dev_celery`인 Detached 상태의 세션에 접속합니다.

---

### 3. **Attached 상태의 screen을 Detached 후 접속**
#### **명령어**
```bash
screen -R -D {name}
```
#### **용도**
이미 다른 터미널에서 접속(Attached 상태)된 `screen` 세션을 강제로 Detached 상태로 변경한 후 접속합니다.

#### **예시**
```bash
screen -R -D dev_celery
```
- 다른 사용자가 사용 중인 `dev_celery` 세션을 강제로 Detached 시키고, 본인이 접속합니다.

---

### 4. **screen 세션 종료**
#### **명령어**
```bash
screen -X -S {name} kill
```
#### **용도**
지정된 이름의 `screen` 세션을 종료합니다. 세션 내의 모든 프로세스도 종료됩니다.

#### **예시**
```bash
screen -X -S dev_celery kill
```
- `dev_celery` 세션과 그 안에서 실행 중인 프로세스를 종료합니다.

---

### 5. **새 창 생성**
#### **명령어**
```plaintext
Ctrl + a + c
```
#### **용도**
현재 `screen` 세션 내에서 새 창을 생성합니다. 새 창은 동일한 세션에서 작업을 분리하여 실행할 수 있게 해줍니다.

#### **예시**
- Celery 워커 로그를 유지한 채 다른 작업을 위해 Bash 쉘을 새로 엽니다.
  - 기존 창: Celery 실행 중
  - 새 창: 파일 편집, 디버깅 등

---

### 추가 명령어
#### **창 전환**
```plaintext
Ctrl + a + n
```
- 다음 창으로 전환합니다.

```plaintext
Ctrl + a + p
```
- 이전 창으로 전환합니다.

#### **현재 창에서 종료**
```plaintext
exit
```
- 현재 창에서 실행 중인 작업을 종료하고, 창을 닫습니다.  
  세션 내 다른 창은 유지됩니다.

---

### 사용 사례
1. **Celery 워커와 디버깅 병행**:
   - `screen -S celery_dev`로 세션 생성 후, Celery 워커 실행.
   - `Ctrl + a + c`로 새 창 생성 후 디버깅 명령 실행.

2. **강제 접속**:
   - 이미 사용 중인 세션에 강제로 접속하려면 `screen -R -D`.

3. **세션 종료**:
   - Celery 워커 실행 세션을 종료할 경우 `screen -X -S celery_dev kill`.

> `screen`은 멀티태스킹 및 작업 관리에 강력한 도구이므로 세션 이름을 명확히 지정하고 작업 단위를 잘 나눠 관리하면 효율성이 크게 향상됩니다.
