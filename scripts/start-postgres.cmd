@echo off
title Smart Aid - PostgreSQL
if not exist "C:\Program Files\PostgreSQL\18\data" (
    echo Error: PostgreSQL data directory not found at "C:\Program Files\PostgreSQL\18\data"
    pause
    exit /b 1
)
"C:\Program Files\PostgreSQL\18\bin\postgres.exe" -D "C:\Program Files\PostgreSQL\18\data" -h 127.0.0.1 -p 5432
