# ============================================================================
# Jekyll Local Server Startup Script (PowerShell)
# ============================================================================
#
# Description:
#   Jekyll 로컬 개발 서버를 시작하는 PowerShell 스크립트입니다.
#   로컬 개발 환경에 최적화된 옵션으로 서버를 실행합니다:
#   - Draft 포스트 포함 (--drafts)
#   - 미래 날짜 포스트 포함 (--future)
#   - 자동 새로고침 활성화 (--livereload)
#   - 로컬 호스트만 접근 가능 (--host=127.0.0.1)
#   - 빈 baseurl (--baseurl='')
#   프로젝트 루트 디렉토리로 이동한 후 다음 작업을 수행합니다:
#   1. Bundler 설치 여부 확인
#   2. 의존성 설치/업데이트 (production 그룹 제외)
#   3. Jekyll 서버 시작 (http://localhost:4000/)
#
# Usage:
#   프로젝트 홈 폴더에서 실행:
#     .\scripts\start_jekyll.ps1
#
#   또는 scripts 폴더에서 실행:
#     .\start_jekyll.ps1
#
#   PowerShell 실행 정책 문제가 있을 경우:
#     powershell -ExecutionPolicy Bypass -File .\scripts\start_jekyll.ps1
#
# Requirements:
#   - Ruby와 Bundler가 설치되어 있어야 합니다.
#   - Gemfile이 프로젝트 루트에 있어야 합니다.
#
# Troubleshooting:
#   "Could not find gem 'github-pages'" 에러가 발생할 경우:
#     bundle install --without production
#
# Server:
#   - URL: http://localhost:4000/
#   - Host: 127.0.0.1
#   - Port: 4000
#   - Base URL: '' (empty for local development)
#   - 중지: Ctrl+C
#
# Notes:
#   - 로컬 개발 환경에서는 production 그룹(github-pages)을 제외하여 설치합니다.
#   - UTF-8 인코딩을 사용하여 한글 출력을 지원합니다.
#   - Draft 포스트와 미래 날짜 포스트가 기본적으로 포함됩니다.
#   - 파일 변경 시 자동으로 페이지가 새로고침됩니다 (LiveReload).
#
# ============================================================================

# UTF-8 encoding settings
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
if ($PSVersionTable.PSVersion.Major -ge 5) {
    [Console]::InputEncoding = [System.Text.Encoding]::UTF8
}
try {
    chcp 65001 | Out-Null
} catch {
    # Ignore chcp failure
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Starting Jekyll Local Server" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Change to project root (parent of scripts folder)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $scriptDir
Set-Location $projectRoot

# Check if Bundler is installed
if (-not (Get-Command bundle -ErrorAction SilentlyContinue)) {
    Write-Host "Bundler is not installed." -ForegroundColor Red
    Write-Host "Please install it with: gem install bundler" -ForegroundColor Yellow
    exit 1
}

# Check dependencies
# 로컬 개발 환경에서는 production 그룹(github-pages) 제외
if (-not (Test-Path "Gemfile.lock")) {
    Write-Host "Installing dependencies (excluding production group)..." -ForegroundColor Yellow
    bundle install --without production
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install dependencies" -ForegroundColor Red
        exit 1
    }
} else {
    # Gemfile.lock이 있지만 production 그룹이 설치되어 있는지 확인
    # 로컬에서는 production 그룹 제외하여 설치
    Write-Host "Updating dependencies (excluding production group)..." -ForegroundColor Yellow
    bundle install --without production
}

Write-Host "Starting Jekyll server..." -ForegroundColor Green
Write-Host ""
Write-Host "Access URL:" -ForegroundColor Cyan
Write-Host "   http://localhost:4000/" -ForegroundColor White
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow
Write-Host ""

# Run Jekyll server with local development options
# Options:
#   --baseurl=''        : Empty baseurl for local development
#   --host=127.0.0.1    : Only accessible from localhost
#   --port=4000         : Port number
#   --drafts            : Include draft posts
#   --future            : Include posts with future dates
#   --livereload        : Enable automatic page reload on file changes
# Run Jekyll directly - Ctrl+C will work properly
bundle exec jekyll serve --baseurl='' --host=127.0.0.1 --port=4000 --drafts --future --livereload

