@echo off
REM For better Ctrl+C handling, run PowerShell script directly:
REM   powershell -ExecutionPolicy Bypass -File start_jekyll.ps1
REM Or just: .\start_jekyll.ps1
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File "%~dp0start_jekyll.ps1"

