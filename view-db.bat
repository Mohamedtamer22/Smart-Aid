@echo off
title Smart Aid V1 - Database Inspector
powershell -ExecutionPolicy Bypass -File "%~dp0scripts\view-database.ps1"
pause
