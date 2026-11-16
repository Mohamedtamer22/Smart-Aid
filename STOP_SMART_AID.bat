@echo off
title Smart Aid - Stop All Services
echo Stopping Smart Aid services (Angular ECC on 4200, Spring Boot on 8080, PostgreSQL on 5432)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "foreach ($port in @(4200, 8080, 5432)) { Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique | ForEach-Object { Stop-Process -Id $_ -Force -ErrorAction SilentlyContinue } }; & 'C:\Program Files\PostgreSQL\18\bin\pg_ctl.exe' stop -D 'C:\Program Files\PostgreSQL\18\data' -m fast 2>$null"
echo Done. All Smart Aid services stopped.
pause
