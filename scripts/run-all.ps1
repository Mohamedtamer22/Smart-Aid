[CmdletBinding()]
param(
    [switch]$NoBrowser
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$backendRoot = Join-Path $projectRoot 'backend'
$webRoot = Join-Path $projectRoot 'web-dashboard'
$envFile = Join-Path $projectRoot '.env'
$scriptsRoot = $PSScriptRoot

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "       SMART AID - ONE-CLICK FULL-STACK LAUNCHER (V2)       " -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan

# Load .env
if (Test-Path -LiteralPath $envFile) {
    Get-Content -LiteralPath $envFile | ForEach-Object {
        if ($_ -match '^\s*([^#=\s]+)\s*=\s*(.*?)\s*$') {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
        }
    }
}

$dbPort = 5432
$apiPort = 8080
$webPort = 4200

function Test-PortOpen([int]$port) {
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $async = $client.BeginConnect('127.0.0.1', $port, $null, $null)
        $ok = $async.AsyncWaitHandle.WaitOne(600, $false)
        if ($ok -and $client.Connected) {
            $client.EndConnect($async)
            $client.Close()
            return $true
        }
        $client.Close()
        return $false
    } catch {
        return $false
    }
}

# 1. PostgreSQL 18
Write-Host "`n[1/3] Checking PostgreSQL 18 on port $dbPort..." -ForegroundColor Yellow
if (Test-PortOpen $dbPort) {
    Write-Host "  OK: PostgreSQL is already running on 127.0.0.1:$dbPort" -ForegroundColor Green
} else {
    $pgCmd = Join-Path $scriptsRoot 'start-postgres.cmd'
    if (-not (Test-Path -LiteralPath $pgCmd)) {
        throw "PostgreSQL launcher not found at: $pgCmd"
    }
    Write-Host "  Starting PostgreSQL 18..." -ForegroundColor Cyan
    Start-Process -FilePath $pgCmd -WindowStyle Minimized | Out-Null
    $deadline = (Get-Date).AddSeconds(20)
    while (-not (Test-PortOpen $dbPort) -and (Get-Date) -lt $deadline) {
        Start-Sleep -Milliseconds 500
    }
    if (-not (Test-PortOpen $dbPort)) {
        throw "PostgreSQL failed to start on port $dbPort within 20 seconds."
    }
    Write-Host "  OK: PostgreSQL 18 started on 127.0.0.1:$dbPort" -ForegroundColor Green
}

# 2. Spring Boot API
Write-Host "`n[2/3] Checking Spring Boot Backend API on port $apiPort..." -ForegroundColor Yellow
$healthUrl = "http://localhost:$apiPort/actuator/health"
$apiReady = $false
try {
    $h = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 2 -ErrorAction SilentlyContinue
    if ($h.status -eq 'UP') { $apiReady = $true }
} catch {}

if ($apiReady) {
    Write-Host "  OK: Spring Boot API is already healthy at http://localhost:$apiPort" -ForegroundColor Green
} else {
    $backendCmd = Join-Path $scriptsRoot 'start-backend.cmd'
    Write-Host "  Starting Spring Boot API (Java 21 + Demo Seed)..." -ForegroundColor Cyan
    Start-Process -FilePath $backendCmd -WindowStyle Minimized | Out-Null

    $deadline = (Get-Date).AddSeconds(90)
    do {
        Start-Sleep -Seconds 2
        try {
            $h = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 2 -ErrorAction SilentlyContinue
            if ($h.status -eq 'UP') { $apiReady = $true }
        } catch {}
    } while (-not $apiReady -and (Get-Date) -lt $deadline)

    if (-not $apiReady) {
        throw "Spring Boot API did not become healthy within 90 seconds. Check the minimized console window."
    }
    Write-Host "  OK: Spring Boot API is UP at http://localhost:$apiPort" -ForegroundColor Green
}

# 3. Angular ECC Web Dashboard
Write-Host "`n[3/3] Checking Angular ECC Web Dashboard on port $webPort..." -ForegroundColor Yellow
$webUrl = "http://localhost:$webPort"
if (Test-PortOpen $webPort) {
    Write-Host "  OK: Angular ECC Dashboard is already running at $webUrl" -ForegroundColor Green
} else {
    $webCmd = Join-Path $scriptsRoot 'start-web.cmd'
    Write-Host "  Starting Angular ECC Web Dashboard..." -ForegroundColor Cyan
    Start-Process -FilePath $webCmd -WindowStyle Minimized | Out-Null

    $deadline = (Get-Date).AddSeconds(60)
    while (-not (Test-PortOpen $webPort) -and (Get-Date) -lt $deadline) {
        Start-Sleep -Seconds 2
    }
    if (-not (Test-PortOpen $webPort)) {
        throw "Angular ECC Dashboard did not open port $webPort within 60 seconds."
    }
    Write-Host "  OK: Angular ECC Dashboard is LIVE at $webUrl" -ForegroundColor Green
}

# Detect LAN IP
$lanIp = '192.168.100.180'
try {
    $route = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($route) {
        $detected = (Get-NetIPAddress -InterfaceIndex $route.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -First 1).IPAddress
        if ($detected) { $lanIp = $detected }
    }
} catch {}

Write-Host "`n============================================================" -ForegroundColor Green
Write-Host "            ALL SMART AID SERVICES ARE RUNNING!             " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  ECC Web Dashboard (Local) : http://localhost:$webPort" -ForegroundColor White
Write-Host "  ECC Web Dashboard (LAN)   : http://${lanIp}:$webPort" -ForegroundColor White
Write-Host "  Backend API / Swagger UI  : http://localhost:$apiPort/swagger-ui/index.html" -ForegroundColor White
Write-Host "  Mobile APK Server Target  : http://${lanIp}:$apiPort" -ForegroundColor White
Write-Host "  Android APK File          : $projectRoot\SmartAid-V2.apk" -ForegroundColor White
Write-Host "`n  Demo Password (All 9 Roles): SmartAidDemo2026!" -ForegroundColor Yellow
Write-Host "  Admin: demo.admin@smartaid.local | EMS: demo.ems@smartaid.local" -ForegroundColor Gray
Write-Host "  Hospital: demo.hospital@smartaid.local | Citizen: demo.user@smartaid.local" -ForegroundColor Gray
Write-Host "  Volunteer: demo.volunteer@smartaid.local | Pharmacist: demo.pharmacist@smartaid.local" -ForegroundColor Gray
Write-Host "  Blood Bank: demo.bloodbank@smartaid.local | Lab: demo.lab@smartaid.local | Doctor: demo.doctor@smartaid.local" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Green

if (-not $NoBrowser) {
    Start-Process $webUrl
}
