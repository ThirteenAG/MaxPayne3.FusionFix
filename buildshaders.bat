@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\buildshaders.ps1" %*
exit /b %ERRORLEVEL%