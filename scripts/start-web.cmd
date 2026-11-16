@echo off
title Smart Aid - Angular ECC Dashboard (4200)
cd /d "%~dp0..\web-dashboard"
npx ng serve --host 0.0.0.0 --port 4200
