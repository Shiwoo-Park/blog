# Jekyll Local Server Startup Script

# Could not find gem 'github-pages' 에러날 경우, 
# bundle install --without production

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

# Change to project root
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

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

# Run Jekyll server with empty baseurl for local development
# Note: Use single quotes and equals sign for empty baseurl
# Run Jekyll directly - Ctrl+C will work properly
bundle exec jekyll serve --baseurl='' --host=127.0.0.1 --port=4000

