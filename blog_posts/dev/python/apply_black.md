---
layout: post
title: "파이썬 자동 코드포매터 black 적용하기"
date: 2024-03-08
categories: [python, formatting, tooling]
---

# 파이썬 자동 코드포매터 black 적용하기

> 날짜: 2024-03-08

먼저 black 설치방법 이후, IDE 별로 그 적용 방법을 설명한다.

## black 설치

1. 파이썬을 설치한다.
2. `pip install black`
3. 해당 파이썬 환경의 bin 폴더에 가보면 `black` 실행파일이 있을것이다.

## Pycharm

1. 설정에 black 이라고 있음.
2. black 실행파일 지정
3. On save 체크 > OK

## Visual studio Code

### 1단계: Black 설치하기

먼저 Black을 설치해야 합니다. 이를 위해 터미널을 열고 다음 pip 명령어를 실행합니다:

```bash
pip install black
```

또는 프로젝트의 가상 환경 내에서 Black을 설치하려면, 해당 가상 환경을 활성화한 후 위 명령어를 실행합니다.

### 2단계: Visual Studio Code 설정 조정하기

VS Code에서 Black을 자동으로 실행하도록 설정하려면, 다음 단계를 따르세요:

1. **VS Code 설정 열기**: `File` > `Preferences` > `Settings`를 선택하거나 (`Ctrl + ,` 단축키 사용) 검색창에 'settings.json'을 입력하여 직접 설정 파일을 열 수 있습니다.
2. **Python 포매팅 설정**: `settings.json` 파일에서 다음 설정을 추가하거나 수정합니다:

```json
{
  "python.formatting.provider": "black",
  "editor.formatOnSave": true,
  "[python]": {
    "editor.codeActionsOnSave": {
      "source.organizeImports": true
    }
  },
  "python.formatting.blackArgs": ["--line-length", "88"],
  "python.formatting.blackPath": "black의 설치 경로"
}
```

- `python.formatting.provider`: 포매터로 Black을 사용하도록 설정합니다.
- `editor.formatOnSave`: 파일 저장 시 자동으로 포맷을 적용합니다.
- `[python]`: Python 파일에 대한 설정을 지정합니다.
- `python.formatting.blackArgs`: Black에 전달할 추가 인수를 설정합니다. 예를 들어, 줄 길이를 조정할 수 있습니다.
- `python.formatting.blackPath`: Black이 설치된 경로를 지정합니다. Black이 환경 변수에 추가되어 있다면 이 옵션은 생략 가능합니다.

설정 후 VS Code를 재시작하여 변경사항을 적용합니다.

---

[목록으로](https://shiwoo-park.github.io/blog)
