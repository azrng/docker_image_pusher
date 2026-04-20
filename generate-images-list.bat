@echo off
setlocal

powershell -ExecutionPolicy Bypass -File "%~dp0scripts\generate-images-list.ps1" %*
exit /b %errorlevel%
