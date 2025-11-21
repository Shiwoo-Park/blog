# Jekyll Build Script (Manual Build)

# UTF-8 encoding settings
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Change to project root
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptPath

Write-Host "Building Jekyll site..." -ForegroundColor Green
Write-Host ""

# Build Jekyll site
bundle exec jekyll build --baseurl=''

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Build completed successfully!" -ForegroundColor Green
    Write-Host "Output directory: _site" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}

