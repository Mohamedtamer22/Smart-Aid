@echo off
title Smart Aid - Launcher
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\run-all.ps1"
if %ERRORLEVEL% neq 0 (
    echo.
    echo [ERROR] Launcher encountered an error.
)
echo.
pause
