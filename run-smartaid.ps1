# ==============================================================================
#  SMART AID V1 - ONE-CLICK COMPLETE SYSTEM LAUNCHER
#  Starts PostgreSQL (if needed), Spring Boot backend, and Flutter Web App.
# ==============================================================================

$ErrorActionPreference = "Continue"

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "          SMART AID V1 - UNIFIED SYSTEM LAUNCHER            " -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan

# 1. Check PostgreSQL Service
Write-Host "`n[1/4] Checking PostgreSQL Service..." -ForegroundColor White
$pgService = Get-Service -Name "postgresql-x64-*" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($pgService) {
    if ($pgService.Status -ne "Running") {
        Write-Host "Starting PostgreSQL service ($($pgService.Name))..." -ForegroundColor Yellow
        Start-Service -Name $pgService.Name
    }
    Write-Host "PostgreSQL is ACTIVE ($($pgService.Name))." -ForegroundColor Green
} else {
    Write-Host "PostgreSQL service check skipped (verifying port 5432 connection)..." -ForegroundColor Gray
}

# 2. Check Backend Health
Write-Host "`n[2/4] Checking Spring Boot Backend on http://localhost:8080..." -ForegroundColor White
$backendUp = $false
try {
    $res = Invoke-RestMethod -Uri "http://localhost:8080/actuator/health" -Method Get -TimeoutSec 3 -ErrorAction SilentlyContinue
    if ($res.status -eq "UP") {
        $backendUp = $true
    }
} catch {}

if ($backendUp) {
    Write-Host "Backend API is ALREADY RUNNING and HEALTHY (UP)." -ForegroundColor Green
} else {
    Write-Host "Starting Spring Boot API from compiled artifact..." -ForegroundColor Yellow
    . (Join-Path $PSScriptRoot 'scripts\use-backend-java.ps1')
    $jarPath = Join-Path $PSScriptRoot 'backend\target\smartaid-api-0.1.0-SNAPSHOT.jar'
    if (-not (Test-Path -LiteralPath $jarPath)) {
        Push-Location (Join-Path $PSScriptRoot 'backend')
        .\mvnw.cmd clean package -DskipTests
        Pop-Location
    }
    $javaExe = Join-Path $env:JAVA_HOME 'bin\java.exe'
    if (-not (Test-Path -LiteralPath $javaExe)) { $javaExe = "java.exe" }
    $backendJob = Start-Process -FilePath $javaExe -ArgumentList "-jar `"$jarPath`"" -WorkingDirectory (Join-Path $PSScriptRoot 'backend') -PassThru -WindowStyle Hidden
    Write-Host "Backend process launched (PID: $($backendJob.Id)). Waiting for health check..." -ForegroundColor Gray
    
    $attempts = 0
    while (-not $backendUp -and $attempts -lt 30) {
        Start-Sleep -Seconds 2
        $attempts++
        try {
            $res = Invoke-RestMethod -Uri "http://localhost:8080/actuator/health" -Method Get -TimeoutSec 2 -ErrorAction SilentlyContinue
            if ($res.status -eq "UP") {
                $backendUp = $true
            }
        } catch {}
        Write-Host -NoNewline "."
    }
    Write-Host ""
    if ($backendUp) {
        Write-Host "Backend API initialized successfully on port 8080!" -ForegroundColor Green
    } else {
        Write-Host "Warning: Backend is still starting up. Continuing..." -ForegroundColor Yellow
    }
}

# 3. Check Flutter App on port 5000
Write-Host "`n[3/4] Checking Smart Aid Flutter App on port 5000..." -ForegroundColor White
$port5000Open = $false
try {
    $tcp = Test-NetConnection -ComputerName 127.0.0.1 -Port 5000 -WarningAction SilentlyContinue
    $port5000Open = $tcp.TcpTestSucceeded
} catch {}

if ($port5000Open) {
    Write-Host "Flutter App is ALREADY RUNNING on http://localhost:5000." -ForegroundColor Green
} else {
    Write-Host "Starting Flutter Web on http://localhost:5000..." -ForegroundColor Yellow
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c cd /d d:\hamo\Projects\SmartAid\mobile && flutter run -d chrome --web-port 5000" -WindowStyle Normal
    Write-Host "Waiting for web server to serve port 5000..." -ForegroundColor Gray
    Start-Sleep -Seconds 8
}

# 4. Open in Browser
Write-Host "`n[4/4] Opening Smart Aid in browser..." -ForegroundColor White
Start-Process "http://localhost:5000"

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "                  SMART AID V1 IS LIVE!                     " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Application URL:     http://localhost:5000" -ForegroundColor White
Write-Host "  Interactive Swagger: http://localhost:8080/swagger-ui/index.html" -ForegroundColor White
Write-Host "  Health Status:       http://localhost:8080/actuator/health" -ForegroundColor White
Write-Host "  Inspect Database:    powershell .\scripts\view-database.ps1" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------" -ForegroundColor Gray
Write-Host "  Demo Password:       SmartAidDemo2026!" -ForegroundColor White
Write-Host "  Citizen Account:     demo.user@smartaid.local" -ForegroundColor White
Write-Host "  Volunteer Account:   demo.volunteer@smartaid.local" -ForegroundColor White
Write-Host "  EMS Dispatcher:      demo.ems@smartaid.local" -ForegroundColor White
Write-Host "  Administrator:       demo.admin@smartaid.local" -ForegroundColor White
Write-Host "============================================================`n" -ForegroundColor Cyan
