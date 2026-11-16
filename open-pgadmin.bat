@echo off
title Launch pgAdmin 4 - Smart Aid Database GUI
echo Launching pgAdmin 4...
start "" "C:\Program Files\PostgreSQL\18\pgAdmin 4\runtime\pgAdmin4.exe"
echo.
echo Connection parameters for Smart Aid:
echo Host:     127.0.0.1
echo Port:     5432
echo Database: smartaid
echo Username: smartaid_user
echo Password: smartaid-local-only-rotate-before-production-91!
echo.
timeout /t 5
