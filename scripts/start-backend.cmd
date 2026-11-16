@echo off
title Smart Aid - Spring Boot API (8080)
cd /d "%~dp0..\backend"
powershell -NoProfile -ExecutionPolicy Bypass -Command ". '%~dp0use-backend-java.ps1'; $env:SMARTAID_DEMO_SEED='true'; $env:SMARTAID_TOMCAT_NIO2='true'; .\mvnw.cmd spring-boot:run"
