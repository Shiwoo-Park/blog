---
layout: post
title: "Windows 에서 nano 설치하고 사용하기"
date: 2024-06-16
categories: [tools, editor, windows]
---

# Windows 에서 nano 설치하고 사용하기

> 날짜: 2024-06-16

[목록으로](https://shiwoo-park.github.io/blog)

---

Windows에서 터미널에서 간단히 사용할 수 있는 텍스트 편집기를 찾고 계시다면, `nano`를 추천합니다. `nano`는 사용하기 쉬운 터미널 기반 텍스트 편집기로, vi보다 접근성이 높습니다. 다음은 Windows에서 `nano`를 설치하고 사용하는 방법입니다.

### Windows에서 `nano` 설치 및 사용

1. **Chocolatey 설치**: Windows의 패키지 관리자입니다. 이미 설치되어 있다면 이 단계를 건너뛰어도 됩니다.
   - PowerShell을 관리자 권한으로 열고 다음 명령을 실행합니다:
     ```powershell
     Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
     ```

2. **nano 설치**: Chocolatey를 사용하여 `nano`를 설치합니다.
   - PowerShell에서 다음 명령을 실행합니다:
     ```powershell
     choco install nano
     ```

3. **nano 사용**:
   - 설치가 완료되면, 터미널에서 `nano` 명령어를 사용하여 파일을 편집할 수 있습니다.
     ```sh
     nano 파일이름
     ```

### `nano` 기본 사용법

- 파일 열기: `nano 파일이름`
- 저장: `Ctrl + O`, 파일 이름을 확인하고 Enter
- 종료: `Ctrl + X`
- 도움말 보기: `Ctrl + G`
- 저장 (Write Out) : `Ctrl + O`
- 종료 : `Ctrl + X`
- 현재 줄 잘라내기 (Cut) : `Ctrl + K`
- 붙여넣기 (Uncut) : `Ctrl + U`
- 검색 (Where Is) : `Ctrl + W`
- 현재 커서 위치 정보 표시 (Show Position) : `Ctrl + C`
- 도움말 보기 (Get Help) : `Ctrl + G`
- 정렬 (Justify) : `Ctrl + J`
- 특정 행으로 이동 (Go to Line) : `Ctrl + _`

`nano`는 직관적이고 사용하기 쉬운 편집기입니다. `Ctrl` 키와 다른 키를 조합하여 다양한 명령을 실행할 수 있습니다. 특히, 간단한 편집 작업을 위해 `vi`보다 더 쉽게 사용할 수 있습니다.

---

[목록으로](https://shiwoo-park.github.io/blog)
