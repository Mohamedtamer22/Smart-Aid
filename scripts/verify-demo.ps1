[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$environmentFile = Join-Path $projectRoot '.env'

if (-not (Test-Path -LiteralPath $environmentFile)) {
    throw 'Missing .env. Configure native local development before verifying the demo.'
}

Get-Content -LiteralPath $environmentFile | ForEach-Object {
    if ($_ -match '^\s*([^#=\s]+)\s*=\s*(.*?)\s*$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
    }
}

$backendPort = if ($env:BACKEND_PORT) { [int]$env:BACKEND_PORT } else { 8080 }
$baseUrl = "http://localhost:$backendPort"
$demoPassword = 'SmartAidDemo2026!'

function Get-DemoSession([string]$email) {
    $response = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/auth/login" -ContentType 'application/json' -Body (@{
            email = $email
            password = $demoPassword
        } | ConvertTo-Json)
    return $response
}

function Get-Authorized([string]$accessToken, [string]$path) {
    return Invoke-RestMethod -Uri "$baseUrl$path" -Headers @{ Authorization = "Bearer $accessToken" }
}

$health = Invoke-RestMethod -Uri "$baseUrl/actuator/health"
if ($health.status -ne 'UP') { throw 'Smart Aid health is not UP. Run scripts\\start-demo.ps1 first.' }

$citizen = Get-DemoSession 'demo.user@smartaid.local'
$volunteer = Get-DemoSession 'demo.volunteer@smartaid.local'
$ems = Get-DemoSession 'demo.ems@smartaid.local'
$citizenIncidents = @((Get-Authorized $citizen.accessToken '/api/incidents/mine') | ForEach-Object { $_ })
$volunteerDashboard = Get-Authorized $volunteer.accessToken '/api/volunteers/dashboard'
$emsDashboard = Get-Authorized $ems.accessToken '/api/ems/dashboard'
$cardiacIncident = @($emsDashboard.incidents | Where-Object { $_.emergencyType -eq 'CARDIAC' } | Select-Object -First 1)

if ($citizen.user.roles -notcontains 'USER') { throw 'Citizen role check failed.' }
if ($volunteer.user.roles -notcontains 'VOLUNTEER') { throw 'Volunteer role check failed.' }
if ($ems.user.roles -notcontains 'EMS') { throw 'EMS role check failed.' }
if (-not $volunteerDashboard.profile.dispatchEligible) { throw 'Volunteer dispatch eligibility check failed.' }
if ($cardiacIncident.Count -ne 1) { throw 'Expected one seeded cardiac incident in the EMS dashboard.' }

$recommendations = @((Get-Authorized $ems.accessToken ("/api/smart-er/incidents/{0}/recommendations" -f $cardiacIncident[0].id)) | ForEach-Object { $_ })
if ($recommendations.Count -lt 2) { throw 'Expected at least two fictional Smart ER comparison candidates.' }

$unauthenticatedStatus = try {
    (Invoke-WebRequest -Uri "$baseUrl/api/ems/dashboard" -UseBasicParsing).StatusCode
} catch [System.Net.WebException] {
    [int]$_.Exception.Response.StatusCode
} catch {
    $_.Exception.Response.StatusCode.value__
}
if ($unauthenticatedStatus -ne 401) { throw "Unauthenticated EMS access was not rejected with 401. Got: $unauthenticatedStatus" }

[pscustomobject]@{
    health                   = $health.status
    citizenIncidentCount     = $citizenIncidents.Count
    volunteerDispatchEligible = $volunteerDashboard.profile.dispatchEligible
    emsActiveIncidents       = $emsDashboard.activeIncidents
    smartErComparisonCount   = $recommendations.Count
    unauthenticatedEmsStatus = $unauthenticatedStatus
} | ConvertTo-Json
