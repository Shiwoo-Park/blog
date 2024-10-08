# Linux 에서 유저 전환하는 방법

> 날짜: 2024-05-14

[목록으로](https://shiwoo-park.github.io/blog)

---

Linux 시스템에서 사용자를 변경하려면 여러 방법이 있습니다. 다음은 가장 일반적으로 사용되는 몇 가지 방법입니다:

### 1. `su` (Switch User) 명령어 사용
`su` 명령어는 한 사용자에서 다른 사용자로 전환할 때 사용됩니다. 가장 흔히 `root` 사용자로 전환할 때 사용하지만, 어떤 사용자로도 전환할 수 있습니다.

**사용법:**
```bash
su - username
```
여기서 `username`은 전환하고 싶은 대상 사용자의 이름입니다. `-` 옵션은 사용자의 환경을 완전히 로드합니다 (예를 들어, 해당 사용자의 홈 디렉토리로 이동하고, 해당 사용자의 로그인 쉘을 시작합니다).

**예시:**
```bash
su - root
```
이 명령은 `root` 사용자로 전환합니다.

### 2. `sudo` 명령어 사용
`sudo`는 특정 명령을 다른 사용자의 권한으로 실행할 때 사용됩니다. `sudo` 다음에 `su`를 사용하여 다른 사용자로 전환할 수도 있습니다.

**사용법:**
```bash
sudo su - username
```
이렇게 하면 비밀번호를 입력할 때 현재 사용자의 비밀번호를 사용할 수 있고, `root` 권한을 가지고 있을 경우 다른 사용자로 전환할 수 있습니다.

**예시:**
```bash
sudo su - root
```
이 명령은 현재 사용자가 `sudo` 권한을 가지고 있을 경우 `root` 사용자로 전환합니다.

### 3. `sudo`와 사용자 전환 결합
특정 명령을 다른 사용자로 실행하고 싶을 때, `sudo`와 `-u` 옵션을 사용할 수 있습니다.

**사용법:**
```bash
sudo -u username command
```
여기서 `username`은 명령을 실행할 사용자이고 `command`는 실행할 명령입니다.

**예시:**
```bash
sudo -u root whoami
```
이 명령은 `root` 사용자로 `whoami` 명령을 실행합니다.

### 안전성 고려
- `root` 사용자로 전환하는 것은 많은 위험을 수반하므로 신중하게 사용해야 합니다.
- 가능하면 `sudo`를 사용하여 필요한 명령만 `root` 권한으로 실행하는 것이 안전합니다.

이러한 방법을 사용하여 Linux 시스템에서 쉽게 사용자를 전환할 수 있습니다. 각 방법의 적절한 사용 시나리오에 따라 선택하세요.

---

[목록으로](https://shiwoo-park.github.io/blog)
