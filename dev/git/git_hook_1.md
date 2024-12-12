# Git hook 을 이용해 커밋메시지에 prefix 달기

> 날짜: 2024-03-11

### 브랜치 생성 규칙 정하기

- feature 브랜치명 포맷: `feature/PROJ-123_desc`
- hotfix 브랜치명 포맷: `hotfix/BUG-123_desc`
- 위와 같은 브랜치 생성 규칙이 있을 경우, `PROJ-123` 과 `BUG-123` 은 작업을 대표하는 티켓 코드로서 커밋메시지에 남겼을때 히스토리 추적에 활용가능한 이점이 있다.
- Git 훅을 사용하여 커밋 메시지에 자동으로 티켓 코드를 추가하는 스크립트를 설정할 수 있다.
- Git에는 커밋이 이루어질 때마다 특정 스크립트를 실행할 수 있는 `prepare-commit-msg`라는 훅이 있습니다. 이를 활용하여 브랜치 이름에서 티켓 코드를 추출하고, 이를 커밋 메시지에 자동으로 추가하는 방법을 적용할 수 있습니다.

### 단계별 방법

1. **Git 훅 스크립트 생성**: 프로젝트의 `.git/hooks` 디렉토리 안에 `prepare-commit-msg` 파일을 생성합니다. 만약 이미 존재한다면, 해당 파일에 로직을 추가합니다.
2. **스크립트에 실행 권한 부여**: 생성한 스크립트에 실행 권한을 부여해야 합니다. 터미널에서 다음 명령어를 실행합니다:

```bash
chmod +x .git/hooks/prepare-commit-msg
```

3. **스크립트 구현**: `vi .git/hooks/prepare-commit-msg` 으로 스크립트를 열고 다음 내용을 구현합니다. 이 스크립트는 브랜치 이름을 확인하고, 브랜치 이름에 따라 커밋 메시지에 티켓 코드를 자동으로 추가합니다.

```bash
#!/bin/sh

# 현재 브랜치 이름을 가져옵니다.
BRANCH_NAME=$(git branch --show-current)

# 티켓 코드의 prefix 리스트를 정의합니다. (JIRA 프로젝트 코드)
PREFIXES=("DEV" "BE")

# 티켓 코드를 초기화합니다.
TICKET_CODE=""

# 각 prefix에 대해 루프를 돌며 티켓 코드를 찾습니다.
for PREFIX in "${PREFIXES[@]}"; do
  MATCH=$(echo $BRANCH_NAME | grep -oE "${PREFIX}-[0-9]+" || true)
  if [ -n "$MATCH" ]; then
    TICKET_CODE=$MATCH
    break
  fi
done

# 티켓 코드가 존재하고, 커밋 메시지가 이미 티켓 코드를 포함하고 있지 않다면, 커밋 메시지를 수정합니다.
if [ -n "$TICKET_CODE" ] && ! grep -qE "^$TICKET_CODE" "$1"; then
  # 커밋 메시지 파일의 내용을 임시 파일에 복사합니다.
  cp "$1" "$1.tmp"
  # 커밋 메시지 파일을 업데이트합니다.
  echo "$TICKET_CODE $(cat "$1.tmp")" > "$1"
  # 임시 파일을 제거합니다.
  rm "$1.tmp"
fi
```

이 스크립트는 브랜치 이름을 기반으로 티켓 코드를 추출하고, 해당 코드가 커밋 메시지에 이미 포함되어 있지 않은 경우에만 커밋 메시지의 맨 앞에 티켓 코드를 추가합니다.

---

[목록으로](https://shiwoo-park.github.io/blog)
