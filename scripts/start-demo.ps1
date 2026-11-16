[CmdletBinding()]
param(
    [switch]$OpenApi
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$backendRoot = Join-Path $projectRoot 'backend'
$environmentFile = Join-Path $projectRoot '.env'

if (-not (Test-Path -LiteralPath $environmentFile)) {
    throw 'Missing .env. Copy .env.example, configure native PostgreSQL credentials, and run this script again.'
}

# Mirror non-secret local settings into this process. Spring Boot also loads .env;
# this lets the launcher validate configured ports without printing credentials.
Get-Content -LiteralPath $environmentFile | ForEach-Object {
    if ($_ -match '^\s*([^#=\s]+)\s*=\s*(.*?)\s*$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
    }
}

. (Join-Path $PSScriptRoot 'use-backend-java.ps1')

$databasePort = if ($env:DB_PORT) { [int]$env:DB_PORT } else { 5432 }
$backendPort = if ($env:BACKEND_PORT) { [int]$env:BACKEND_PORT } else { 8080 }
$healthUrl = "http://localhost:$backendPort/actuator/health"

foreach ($commandName in 'java', 'flutter') {
    if (-not (Get-Command $commandName -ErrorAction SilentlyContinue)) {
        throw "Missing required native command: $commandName"
    }
}

if (-not (Test-NetConnection -ComputerName localhost -Port $databasePort -InformationLevel Quiet -WarningAction SilentlyContinue)) {
    throw "PostgreSQL is not accepting connections on localhost:$databasePort. Start the native PostgreSQL service first."
}

$env:SMARTAID_DEMO_SEED = 'true'
$env:SMARTAID_TOMCAT_NIO2 = 'true'

try {
    $health = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 3
    if ($health.status -ne 'UP') { throw 'Health endpoint did not report UP.' }
    Write-Host 'Smart Aid API is already healthy on port 8080.' -ForegroundColor Green
} catch {
    $portInUse = Get-NetTCPConnection -LocalPort $backendPort -State Listen -ErrorAction SilentlyContinue
    if ($portInUse) {
        throw "Port $backendPort is already in use but Smart Aid health is unavailable. Stop the conflicting process or repair the API before retrying."
    }

    Write-Host 'Starting native Smart Aid API with the fictional demo scenario...' -ForegroundColor Cyan
    Start-Process -FilePath $env:ComSpec -ArgumentList '/d', '/c', '.\\mvnw.cmd spring-boot:run' -WorkingDirectory $backendRoot -WindowStyle Hidden | Out-Null

    $deadline = (Get-Date).AddSeconds(75)
    do {
        Start-Sleep -Seconds 2
        try {
            $health = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 3
        } catch {
            $health = $null
        }
    } while (($null -eq $health -or $health.status -ne 'UP') -and (Get-Date) -lt $deadline)

    if ($null -eq $health -or $health.status -ne 'UP') {
        throw 'Smart Aid did not become healthy within 75 seconds. Run backend\\.mvnw.cmd spring-boot:run in a visible terminal to inspect the local log.'
    }
}

Write-Host "Smart Aid demo is ready: http://localhost:$backendPort/swagger-ui/index.html" -ForegroundColor Green
Write-Host 'Use only the fictional local accounts in docs/demo-runbook.md.' -ForegroundColor Yellow

if ($OpenApi) {
    Start-Process "http://localhost:$backendPort/swagger-ui/index.html"
}
