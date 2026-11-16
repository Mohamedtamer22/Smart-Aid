$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot

. (Join-Path $PSScriptRoot 'use-backend-java.ps1')

if (-not (Test-Path -LiteralPath (Join-Path $projectRoot 'backend\mvnw.cmd'))) {
  throw 'Smart Aid Maven Wrapper was not found at backend\mvnw.cmd.'
}

foreach ($commandName in 'java', 'flutter') {
  if (-not (Get-Command $commandName -ErrorAction SilentlyContinue)) {
    throw "Missing required native command: $commandName"
  }
  Write-Host "Found $commandName"
}
Write-Host 'Found backend Maven Wrapper'

$psql = Get-Command psql -ErrorAction SilentlyContinue
if (-not $psql) {
  $psql = Get-ChildItem 'C:\Program Files\PostgreSQL' -Filter 'psql.exe' -Recurse -ErrorAction SilentlyContinue |
    Select-Object -First 1
}
if (-not $psql) {
  Write-Warning 'psql was not found. You can still provision the database through the native pgAdmin Query Tool.'
} else {
  Write-Host 'Found native PostgreSQL client'
}
Write-Host 'No container runtime is required or used by Smart Aid.'
