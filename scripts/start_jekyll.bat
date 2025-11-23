@echo off
REM ============================================================================
REM Jekyll Local Server Startup Script (Batch)
REM ============================================================================
REM
REM Description:
REM   Jekyll 로컬 개발 서버를 시작하는 배치 스크립트입니다.
REM   로컬 개발 환경에 최적화된 옵션으로 서버를 실행합니다:
REM   - Draft 포스트 포함 (--drafts)
REM   - 미래 날짜 포스트 포함 (--future)
REM   - 자동 새로고침 활성화 (--livereload)
REM   - 로컬 호스트만 접근 가능 (--host=127.0.0.1)
REM   - 빈 baseurl (--baseurl='')
REM   서버는 http://localhost:4000/ 에서 실행됩니다.
REM
REM Usage:
REM   프로젝트 홈 폴더에서 실행:
REM     .\scripts\start_jekyll.bat
REM
REM   또는 scripts 폴더에서 실행:
REM     .\start_jekyll.bat
REM
REM   더 나은 Ctrl+C 처리를 위해 PowerShell 스크립트를 직접 실행하는 것을 권장:
REM     powershell -ExecutionPolicy Bypass -File .\scripts\start_jekyll.ps1
REM     또는: .\scripts\start_jekyll.ps1
REM
REM Requirements:
REM   - Ruby와 Bundler가 설치되어 있어야 합니다.
REM   - Gemfile이 프로젝트 루트에 있어야 합니다.
REM
REM Server:
REM   - URL: http://localhost:4000/
REM   - 중지: Ctrl+C
REM
REM ============================================================================

cd /d "%~dp0\.."
powershell -ExecutionPolicy Bypass -File "%~dp0start_jekyll.ps1"

