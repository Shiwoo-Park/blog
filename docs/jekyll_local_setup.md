# Jekyll 로컬 환경 설정 가이드

## Windows 환경에서 Jekyll 실행하기

### 방법 1: RubyInstaller 사용 (권장)

#### 1단계: Ruby 설치

1. **RubyInstaller 다운로드**
   - https://rubyinstaller.org/downloads/ 접속
   - **Ruby+Devkit 3.2.x (x64)** 버전 다운로드 (WITH DEVKIT 버전 필수)
   - 설치 시 "Add Ruby executables to your PATH" 체크

2. **설치 확인**
   ```powershell
   ruby -v
   # 예: ruby 3.2.0 (2023-12-25 revision 5124f9ac75) [x64-mingw-ucrt]
   ```

#### 2단계: Bundler 설치

```powershell
gem install bundler
```

#### 3단계: 의존성 설치

프로젝트 루트 디렉토리에서:

```powershell
bundle install
```

**문제 발생 시:**
- `ridk install` 실행 (RubyInstaller DevKit 설정)
- 또는 `gem install bundler --force` 재시도

#### 4단계: Jekyll 서버 실행

```powershell
bundle exec jekyll serve
```

또는

```powershell
bundle exec jekyll serve --baseurl ""
```

**접속:**
- http://localhost:4000/blog 접속
- `--baseurl ""` 옵션 사용 시: http://localhost:4000 접속

---

### 방법 2: WSL (Windows Subsystem for Linux) 사용

WSL이 설치되어 있다면 Linux 환경에서 실행하는 것이 더 안정적입니다.

#### 1단계: WSL에서 Ruby 설치

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install ruby-full build-essential zlib1g-dev

# RubyGems 환경 변수 설정
echo '# Install Ruby Gems to ~/gems' >> ~/.bashrc
echo 'export GEM_HOME="$HOME/gems"' >> ~/.bashrc
echo 'export PATH="$HOME/gems/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

#### 2단계: Bundler 설치

```bash
gem install bundler
```

#### 3단계: 의존성 설치

```bash
bundle install
```

#### 4단계: Jekyll 서버 실행

```bash
bundle exec jekyll serve --host 0.0.0.0
```

**접속:**
- Windows 브라우저에서 http://localhost:4000/blog 접속

---

## 빠른 시작 스크립트

### Windows PowerShell 스크립트

프로젝트 루트에 `start_jekyll.ps1` 파일 생성:

```powershell
# start_jekyll.ps1
Write-Host "Jekyll 서버 시작 중..." -ForegroundColor Green

# 의존성 확인
if (-not (Get-Command bundle -ErrorAction SilentlyContinue)) {
    Write-Host "Bundler가 설치되지 않았습니다. 설치 중..." -ForegroundColor Yellow
    gem install bundler
}

# 의존성 설치 (처음 한 번만)
if (-not (Test-Path "Gemfile.lock")) {
    Write-Host "의존성 설치 중..." -ForegroundColor Yellow
    bundle install
}

# Jekyll 서버 실행
Write-Host "Jekyll 서버 실행 중... (http://localhost:4000/blog)" -ForegroundColor Green
bundle exec jekyll serve --baseurl ""
```

**실행 방법:**
```powershell
.\start_jekyll.ps1
```

---

## 주요 명령어

### Jekyll 서버 실행

```powershell
# 기본 실행
bundle exec jekyll serve

# baseurl 없이 실행 (로컬 테스트용)
bundle exec jekyll serve --baseurl ""

# 포트 변경
bundle exec jekyll serve --port 4001

# 자동 재빌드 비활성화 (빌드만)
bundle exec jekyll build

# 프로덕션 모드 (최적화)
JEKYLL_ENV=production bundle exec jekyll serve
```

### 빌드만 실행 (서버 없이)

```powershell
bundle exec jekyll build
```

빌드된 파일은 `_site/` 디렉토리에 생성됩니다.

---

## 문제 해결

### 1. "Could not locate Gemfile" 오류

**원인:** 프로젝트 루트 디렉토리가 아닌 곳에서 실행

**해결:**
```powershell
cd B:\repos-my\blog
bundle exec jekyll serve
```

### 2. "bundler: command not found" 오류

**원인:** Bundler 미설치

**해결:**
```powershell
gem install bundler
```

### 3. "jekyll: command not found" 오류

**원인:** Jekyll이 설치되지 않았거나 bundle을 통해 실행하지 않음

**해결:**
```powershell
bundle install
bundle exec jekyll serve
```

### 4. 포트 4000이 이미 사용 중

**해결:**
```powershell
bundle exec jekyll serve --port 4001
```

### 5. Windows에서 인코딩 오류

**해결:**
```powershell
$env:LC_ALL="en_US.UTF-8"
bundle exec jekyll serve
```

또는 PowerShell 프로필에 추가:
```powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
```

### 6. "Liquid Exception" 오류

**원인:** Front Matter 형식 오류

**해결:**
- 각 마크다운 파일의 Front Matter 형식 확인
- YAML 문법 오류 확인 (들여쓰기, 따옴표 등)

---

## 유용한 옵션

### 자동 재빌드 비활성화

```powershell
bundle exec jekyll serve --no-watch
```

### 상세 로그 출력

```powershell
bundle exec jekyll serve --verbose
```

### 특정 호스트에서 접근 허용

```powershell
bundle exec jekyll serve --host 0.0.0.0
```

---

## 다음 단계

1. **로컬에서 테스트**
   - http://localhost:4000/blog 접속
   - 포스트들이 제대로 표시되는지 확인
   - Google Tag Manager가 작동하는지 확인

2. **변경사항 확인**
   - 마크다운 파일 수정 후 자동으로 재빌드됨
   - 브라우저 새로고침으로 변경사항 확인

3. **프로덕션 빌드 테스트**
   ```powershell
   bundle exec jekyll build
   ```
   - `_site/` 디렉토리에 생성된 파일 확인

---

## 참고 자료

- [Jekyll 공식 문서](https://jekyllrb.com/docs/)
- [RubyInstaller 다운로드](https://rubyinstaller.org/downloads/)
- [Jekyll Windows 설치 가이드](https://jekyllrb.com/docs/installation/windows/)

