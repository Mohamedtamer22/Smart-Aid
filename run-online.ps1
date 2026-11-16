# ==============================================================================
#  SMART AID V1 - GLOBAL ONLINE TUNNEL LAUNCHER
#  Starts PostgreSQL, Spring Boot backend, and Cloudflare Public HTTPS Tunnel.
# ==============================================================================

$ErrorActionPreference = 'Continue'
$projectRoot = $PSScriptRoot

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "       SMART AID V1 - ONLINE PUBLIC TUNNEL (ANYWHERE)       " -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan

# 1. Check PostgreSQL
Write-Host "`n[1/3] Checking PostgreSQL Service..." -ForegroundColor White
$pgService = Get-Service -Name "postgresql-x64-*" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($pgService) {
    if ($pgService.Status -ne "Running") {
        Write-Host "Starting PostgreSQL service ($($pgService.Name))..." -ForegroundColor Yellow
        Start-Service -Name $pgService.Name
    }
    Write-Host "PostgreSQL is ACTIVE ($($pgService.Name))." -ForegroundColor Green
}

# 2. Check Backend Health
Write-Host "`n[2/3] Checking Spring Boot Backend on http://localhost:8080..." -ForegroundColor White
$backendUp = $false
try {
    $res = Invoke-RestMethod -Uri "http://127.0.0.1:8080/actuator/health" -Method Get -TimeoutSec 2 -ErrorAction SilentlyContinue
    if ($res.status -eq "UP") { $backendUp = $true }
} catch {}

if ($backendUp) {
    Write-Host "Backend API is ALREADY RUNNING and HEALTHY (UP)." -ForegroundColor Green
} else {
    Write-Host "Starting Spring Boot API from compiled artifact..." -ForegroundColor Yellow
    . (Join-Path $projectRoot 'scripts\use-backend-java.ps1')
    
    $jarPath = Join-Path $projectRoot 'backend\target\smartaid-api-0.1.0-SNAPSHOT.jar'
    if (-not (Test-Path -LiteralPath $jarPath)) {
        Push-Location (Join-Path $projectRoot 'backend')
        .\mvnw.cmd package -DskipTests
        Pop-Location
    }

    $envFile = Join-Path $projectRoot '.env'
    if (Test-Path $envFile) {
        Get-Content $envFile | ForEach-Object {
            if ($_ -match '^\s*([^#=\s]+)\s*=\s*(.*?)\s*$') {
                [Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
            }
        }
    }

    $javaExe = Join-Path $env:JAVA_HOME 'bin\java.exe'
    if (-not (Test-Path -LiteralPath $javaExe)) {
        $javaExe = "java.exe"
    }
    $backendProc = Start-Process -FilePath $javaExe -ArgumentList "-jar `"$jarPath`"" -WorkingDirectory (Join-Path $projectRoot 'backend') -PassThru -WindowStyle Hidden
    Write-Host "Backend process launched with Java 21 (PID: $($backendProc.Id)). Waiting for health check..." -ForegroundColor Gray

    $attempts = 0
    while (-not $backendUp -and $attempts -lt 25) {
        Start-Sleep -Seconds 1
        $attempts++
        try {
            $res = Invoke-RestMethod -Uri "http://127.0.0.1:8080/actuator/health" -Method Get -TimeoutSec 2 -ErrorAction SilentlyContinue
            if ($res.status -eq "UP") { $backendUp = $true }
        } catch {}
        Write-Host -NoNewline "."
    }
    Write-Host ""
    if ($backendUp) {
        Write-Host "Backend API initialized successfully on port 8080!" -ForegroundColor Green
    } else {
        Write-Host "Warning: Backend is still initializing..." -ForegroundColor Yellow
    }
}

# 3. Start Cloudflare Tunnel
Write-Host "`n[3/3] Initializing Cloudflare Public HTTPS Tunnel..." -ForegroundColor White
$cloudflaredPath = 'C:\Program Files (x86)\cloudflared\cloudflared.exe'
if (-not (Test-Path -LiteralPath $cloudflaredPath)) {
    $cmd = Get-Command cloudflared -ErrorAction SilentlyContinue
    if ($cmd) {
        $cloudflaredPath = $cmd.Source
    } else {
        throw "cloudflared binary not found. Run 'winget install --id Cloudflare.cloudflared' first."
    }
}

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $cloudflaredPath
$psi.Arguments = 'tunnel --url http://localhost:8080'
$psi.UseShellExecute = $false
$psi.RedirectStandardError = $true
$psi.RedirectStandardOutput = $true
$tunnelProcess = [System.Diagnostics.Process]::Start($psi)

$tunnelUrl = $null
$deadline = (Get-Date).AddSeconds(20)
while (-not $tunnelProcess.HasExited -and -not $tunnelUrl -and (Get-Date) -lt $deadline) {
    $line = $tunnelProcess.StandardError.ReadLine()
    if ($line -match 'https://([a-zA-Z0-9-]+)\.trycloudflare\.com' -and $matches[1] -ne 'api') {
        $tunnelUrl = $matches[0]
        break
    }
}

if (-not $tunnelUrl) {
    Write-Host "Warning: Could not automatically detect tunnel URL. Check cloudflared." -ForegroundColor Red
} else {
    $tunnelFile = Join-Path $projectRoot 'tunnel_url.txt'
    Set-Content -LiteralPath $tunnelFile -Value $tunnelUrl -Force

    Write-Host "`n============================================================" -ForegroundColor Green
    Write-Host "          SMART AID ONLINE TUNNEL IS ACTIVE!                " -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "  Public HTTPS URL:   $tunnelUrl" -ForegroundColor Cyan
    Write-Host "  Interactive API:    $tunnelUrl/swagger-ui/index.html" -ForegroundColor White
    Write-Host "  Health Endpoint:    $tunnelUrl/actuator/health" -ForegroundColor White
    Write-Host "  Saved in file:      $tunnelFile" -ForegroundColor Yellow
    Write-Host "------------------------------------------------------------" -ForegroundColor Gray
    Write-Host "  HOW TO CONNECT FROM YOUR PHONE (4G/5G or any Wi-Fi):      " -ForegroundColor Yellow
    Write-Host "  1. Copy this URL: $tunnelUrl" -ForegroundColor White
    Write-Host "  2. Open Smart Aid app on your phone." -ForegroundColor White
    Write-Host "  3. Tap the 'Server' icon at the top of the login screen." -ForegroundColor White
    Write-Host "  4. Tap 'Paste URL' -> 'Save'." -ForegroundColor White
    Write-Host "  5. Tap any Demo account (Citizen/Volunteer/EMS) and Login!" -ForegroundColor White
    Write-Host "------------------------------------------------------------" -ForegroundColor Gray
    Write-Host "  Want to build an APK that has this link permanently baked in?" -ForegroundColor Yellow
    Write-Host "  Run: powershell .\scripts\build-android-release.ps1" -ForegroundColor White
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "`nKeep this window OPEN while testing. Press Ctrl+C to stop.`n" -ForegroundColor Gray
}

try {
    while (-not $tunnelProcess.HasExited) {
        $line = $tunnelProcess.StandardError.ReadLine()
        Start-Sleep -Milliseconds 500
    }
} finally {
    if (-not $tunnelProcess.HasExited) {
        $tunnelProcess.Kill()
    }
}
