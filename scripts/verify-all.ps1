[CmdletBinding()]
param(
    [switch]$SkipLiveDemo
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$backendRoot = Join-Path $projectRoot 'backend'
$mobileRoot = Join-Path $projectRoot 'mobile'

. (Join-Path $PSScriptRoot 'use-backend-java.ps1')

function Invoke-Checked([scriptblock]$command, [string]$name) {
    & $command
    if ($LASTEXITCODE -ne 0) {
        throw "$name failed with exit code $LASTEXITCODE."
    }
}

Push-Location $backendRoot
try {
    Invoke-Checked { .\mvnw.cmd test } 'Backend tests'
} finally {
    Pop-Location
}

Push-Location $mobileRoot
try {
    Invoke-Checked { dart format --output=none --set-exit-if-changed lib test } 'Dart formatting'
    Invoke-Checked { flutter analyze } 'Flutter analysis'
    Invoke-Checked { flutter test } 'Flutter tests'
} finally {
    Pop-Location
}

if (-not $SkipLiveDemo) {
    & (Join-Path $PSScriptRoot 'start-demo.ps1')
    & (Join-Path $PSScriptRoot 'verify-demo.ps1')
}

Write-Host 'Smart Aid verification completed successfully.' -ForegroundColor Green
