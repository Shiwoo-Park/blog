---
layout: post
title: "vi 에서 syntax highlight 사용하기"
date: 2024-05-07
categories: [tools, editor, vim]
---
macOS에서 `vi` (혹은 보통 `vim`으로도 알려져 있습니다)를 사용할 때 syntax highlighting(문법 강조)를 활성화하고 싶다면, 몇 가지 간단한 설정을 추가하면 됩니다. macOS에는 기본적으로 `vim`이 설치되어 있으며, 이는 `vi` 명령어로도 실행될 수 있습니다. 다음 단계를 통해 syntax highlighting을 설정할 수 있습니다:

### 1. `.vimrc` 파일 설정
`vim`은 사용자의 홈 디렉토리에 위치한 `.vimrc` 파일을 통해 구성을 읽습니다. 이 파일을 편집하거나 생성하여 syntax highlighting을 활성화할 수 있습니다.

1. 터미널을 열고, 다음 명령어를 입력하여 `.vimrc` 파일을 엽니다 (파일이 없는 경우 새로 생성됩니다):
   ```bash
   vi ~/.vimrc
   ```
   
2. `.vimrc` 파일에 다음 설정을 추가합니다:
   ```vim
   syntax on
   ```
   이 명령은 `vim`에서 문법 강조를 활성화하라는 지시입니다.

3. 파일을 저장하고 종료합니다:
   - `ESC` 키를 누르고
   - `:wq`를 입력하고 `Enter`를 누릅니다.

### 2. 추가 설정 (선택 사항)
더 나은 사용 경험을 위해 `.vimrc` 파일에 추가할 수 있는 몇 가지 설정입니다:
- **색상 테마 설정**: `colorscheme` 명령을 사용하여 vim의 색상 테마를 변경할 수 있습니다.
   ```vim
   colorscheme desert
   ```
- **라인 번호 표시**:
   ```vim
   set number
   ```
- **자동 들여쓰기 활성화**:
   ```vim
   set autoindent
   ```
- **탭을 공백으로 변환**:
   ```vim
   set expandtab
   ```
- **탭 및 공백 크기 설정**:
   ```vim
   set tabstop=4
   set shiftwidth=4
   set softtabstop=4
   ```

이 설정들은 `vim`에서 편집하는 파일들의 가독성과 편집 편의성을 높여줍니다.

### 3. 변경 사항 적용
변경한 `.vimrc` 파일 설정을 적용하기 위해 새로운 `vim` 세션을 시작하거나 기존 세션을 재시작합니다. 이제 `vim`에서 파일을 열면 syntax highlighting이 적용된 것을 볼 수 있습니다.

위 단계를 통해 macOS에서 `vim`을 사용할 때 syntax highlighting 및 기타 유용한 설정을 활성화할 수 있습니다.
