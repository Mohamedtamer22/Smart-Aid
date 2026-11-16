<##
.SYNOPSIS
Builds an optimized, production-ready Smart Aid Android release APK.

.DESCRIPTION
Compiles Flutter into AOT (Ahead-of-Time) native machine code with bytecode
shrinking, reducing APK size from ~190MB down to ~30MB and maximizing
runtime execution performance.
##>

[CmdletBinding()]
param(
    [string]$ApiUrl
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$mobileRoot = Join-Path $projectRoot 'mobile'
$nativeTemp = Join-Path $env:SystemRoot 'Temp'

if (-not (Test-Path -LiteralPath $nativeTemp)) {
    throw "The Windows temporary directory was not found: $nativeTemp"
}

$previousTemp = $env:TEMP
$previousTmp = $env:TMP
$env:TEMP = $nativeTemp
$env:TMP = $nativeTemp

try {
    Push-Location $mobileRoot
    try {
        & flutter pub get
        if ($LASTEXITCODE -ne 0) {
            throw "Flutter dependency resolution failed with exit code $LASTEXITCODE."
        }

        if (-not $ApiUrl) {
            $tunnelFile = Join-Path $projectRoot 'tunnel_url.txt'
            if (Test-Path -LiteralPath $tunnelFile) {
                $savedTunnel = (Get-Content -LiteralPath $tunnelFile -Raw).Trim()
                if ($savedTunnel -match '^https://') {
                    $ApiUrl = $savedTunnel
                    Write-Host "Discovered active online Tunnel URL from tunnel_url.txt: $ApiUrl" -ForegroundColor Green
                }
            }
        }

        if (-not $ApiUrl) {
            # Auto-detect active host IPv4 address
            $defaultRoute = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue | Select-Object -First 1
            $activeIp = $null
            if ($defaultRoute) {
                $activeIp = (Get-NetIPAddress -InterfaceIndex $defaultRoute.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -First 1).IPAddress
            }
            if (-not $activeIp) {
                $activeIp = '192.168.100.181'
            }
            $ApiUrl = "http://${activeIp}:8080"
        }

        Write-Host "Targeting host API URL: $ApiUrl" -ForegroundColor Cyan

        Write-Host "Compiling native AOT Release APK..." -ForegroundColor Cyan
        & flutter build apk --release --no-pub --dart-define=API_BASE_URL=$ApiUrl
        if ($LASTEXITCODE -ne 0) {
            throw "Flutter Android release build failed with exit code $LASTEXITCODE."
        }
    } finally {
        Pop-Location
    }
} finally {
    $env:TEMP = $previousTemp
    $env:TMP = $previousTmp
}

$apk = Join-Path $mobileRoot 'build\app\outputs\flutter-apk\app-release.apk'
if (-not (Test-Path -LiteralPath $apk)) {
    throw "Flutter completed without producing the expected release APK: $apk"
}

$rootApk = Join-Path $projectRoot 'SmartAid-V1.apk'
Copy-Item -LiteralPath $apk -Destination $rootApk -Force

$apkInfo = Get-Item -LiteralPath $apk
Write-Host "Android Release APK built: $($apkInfo.FullName) ($([math]::Round($apkInfo.Length / 1MB, 1)) MB)" -ForegroundColor Green
Write-Host "Updated Project Root: $rootApk" -ForegroundColor Green
