[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$environmentFile = Join-Path $projectRoot '.env'

if (-not (Test-Path -LiteralPath $environmentFile)) {
    throw 'Missing .env. Configure native local development before cleaning E2E test records.'
}

Get-Content -LiteralPath $environmentFile | ForEach-Object {
    if ($_ -match '^\s*([^#=\s]+)\s*=\s*(.*?)\s*$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
    }
}

$backendPort = if ($env:BACKEND_PORT) { [int]$env:BACKEND_PORT } else { 8080 }
$baseUrl = "http://localhost:$backendPort"
$demoPassword = 'SmartAidDemo2026!'
$e2ePassword = 'SmartAidE2E2026!'

function Assert-That([bool]$condition, [string]$message) {
    if (-not $condition) { throw "E2E cleanup assertion failed: $message" }
}

function Invoke-Api([string]$method, [string]$path, $body = $null, [string]$accessToken = $null) {
    $request = @{
        Method = $method
        Uri = "$baseUrl$path"
        UseBasicParsing = $true
    }
    if ($null -ne $body) {
        $request.ContentType = 'application/json'
        $request.Body = $body | ConvertTo-Json -Depth 5 -Compress
    }
    if ($null -ne $accessToken) {
        $request.Headers = @{ Authorization = "Bearer $accessToken" }
    }
    $statusCode = 200
    $content = $null
    try {
        $response = Invoke-WebRequest @request
        $statusCode = [int]$response.StatusCode
        $content = if ($response.Content -is [byte[]]) {
            [System.Text.Encoding]::UTF8.GetString($response.Content)
        } else {
            [string]$response.Content
        }
    } catch [System.Net.WebException] {
        $webResp = $_.Exception.Response
        if ($null -ne $webResp) {
            $statusCode = [int]$webResp.StatusCode
            $reader = [System.IO.StreamReader]::new($webResp.GetResponseStream())
            $content = $reader.ReadToEnd()
            $reader.Dispose()
        } else {
            throw $_
        }
    }
    $parsed = $null
    if (-not [string]::IsNullOrWhiteSpace($content)) {
        try { $parsed = $content | ConvertFrom-Json } catch { $parsed = $content }
    }
    return ,([pscustomobject]@{ StatusCode = $statusCode; Body = $parsed })
}

function Get-Session([string]$email, [string]$userCredential) {
    $session = Invoke-Api 'POST' '/api/auth/login' @{ email = $email; password = $userCredential }
    Assert-That ($session.StatusCode -eq 200) "Login must succeed for the tagged local test account $email."
    return $session.Body
}

$health = Invoke-Api 'GET' '/actuator/health'
Assert-That ($health.StatusCode -eq 200 -and $health.Body.status -eq 'UP') 'Smart Aid API must be healthy.'

$ems = Get-Session 'demo.ems@smartaid.local' $demoPassword
$volunteer = Get-Session 'demo.volunteer@smartaid.local' $demoPassword
$cancelledMissions = @()
$activeMission = Invoke-Api 'GET' '/api/volunteers/missions/active' $null $volunteer.accessToken

if ($activeMission.StatusCode -eq 200) {
    $missionIncident = Invoke-Api 'GET' ("/api/ems/incidents/{0}" -f $activeMission.Body.incident.id) $null $ems.accessToken
    if ($missionIncident.StatusCode -eq 200 -and $missionIncident.Body.notes -match '^E2E_AUTOMATED_') {
        $missionCancellation = Invoke-Api 'PATCH' ("/api/volunteers/missions/{0}" -f $activeMission.Body.id) @{ status = 'CANCELLED' } $volunteer.accessToken
        Assert-That ($missionCancellation.StatusCode -eq 200) 'An interrupted fictional E2E mission must be cancellable.'
        $cancelledMissions += $activeMission.Body.id
    }
}

$dashboard = Invoke-Api 'GET' '/api/ems/dashboard' $null $ems.accessToken
Assert-That ($dashboard.StatusCode -eq 200) 'EMS dashboard must be available for E2E cleanup.'
$cancelledIncidents = @()

foreach ($summary in @($dashboard.Body.incidents)) {
    $detail = Invoke-Api 'GET' ("/api/ems/incidents/{0}" -f $summary.id) $null $ems.accessToken
    if ($detail.StatusCode -ne 200 -or $detail.Body.notes -notmatch '^E2E_AUTOMATED_([a-f0-9]{12})$') { continue }

    $reporterEmail = "e2e.$($matches[1])@smartaid.local"
    $reporter = Get-Session $reporterEmail $e2ePassword
    $cancellation = Invoke-Api 'PATCH' ("/api/incidents/{0}/status" -f $summary.id) @{
        status = 'CANCELLED'
        reason = 'Cleanup of interrupted fictional E2E test scenario'
    } $reporter.accessToken
    Assert-That ($cancellation.StatusCode -eq 200 -and $cancellation.Body.status -eq 'CANCELLED') "Tagged E2E incident $($summary.id) must be cancelled."
    $cancelledIncidents += $summary.id
}

[pscustomobject]@{
    result = 'PASS'
    cancelledFictionalE2eMissions = $cancelledMissions.Count
    cancelledFictionalE2eIncidents = $cancelledIncidents.Count
} | ConvertTo-Json
