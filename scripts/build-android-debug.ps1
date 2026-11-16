<##
.SYNOPSIS
Builds a local Smart Aid Android debug APK.

.DESCRIPTION
Keeps Flutter's Android build native and repeatable on Windows. Android Gradle tooling can
mis-handle the short (8.3) temporary directory returned by some shells, so this launcher
uses the normal Windows temporary directory for this process only.
##>

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

        # Auto-detect active host IPv4 address
        $defaultRoute = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue | Select-Object -First 1
        $activeIp = $null
        if ($defaultRoute) {
            $activeIp = (Get-NetIPAddress -InterfaceIndex $defaultRoute.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -First 1).IPAddress
        }
        if (-not $activeIp) {
            $activeIp = '172.16.0.160'
        }
        $targetApiUrl = "http://${activeIp}:8080"
        Write-Host "Targeting host API URL: $targetApiUrl" -ForegroundColor Cyan

        & flutter build apk --debug --no-pub --dart-define=API_BASE_URL=$targetApiUrl
        if ($LASTEXITCODE -ne 0) {
            throw "Flutter Android build failed with exit code $LASTEXITCODE."
        }
    } finally {
        Pop-Location
    }
} finally {
    $env:TEMP = $previousTemp
    $env:TMP = $previousTmp
}

$apk = Join-Path $mobileRoot 'build\app\outputs\flutter-apk\app-debug.apk'
if (-not (Test-Path -LiteralPath $apk)) {
    throw "Flutter completed without producing the expected APK: $apk"
}

$rootApk = Join-Path $projectRoot 'SmartAid-V1.apk'
Copy-Item -LiteralPath $apk -Destination $rootApk -Force

$apkInfo = Get-Item -LiteralPath $apk
Write-Host "Android debug APK built: $($apkInfo.FullName) ($([math]::Round($apkInfo.Length / 1MB, 1)) MB)" -ForegroundColor Green
Write-Host "Copied to Project Root: $rootApk" -ForegroundColor Green
