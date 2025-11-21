@echo off
powershell -ExecutionPolicy Bypass -Command "cd '%~dp0'; bundle exec jekyll build --baseurl=''"

