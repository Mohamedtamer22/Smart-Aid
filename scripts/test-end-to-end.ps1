[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$environmentFile = Join-Path $projectRoot '.env'

if (-not (Test-Path -LiteralPath $environmentFile)) {
    throw 'Missing .env. Configure native local development before running the end-to-end test.'
}

Get-Content -LiteralPath $environmentFile | ForEach-Object {
    if ($_ -match '^\s*([^#=\s]+)\s*=\s*(.*?)\s*$') {
        [Environment]::SetEnvironmentVariable($matches[1], $matches[2], 'Process')
    }
}

$backendPort = if ($env:BACKEND_PORT) { [int]$env:BACKEND_PORT } else { 8080 }
$baseUrl = "http://localhost:$backendPort"
$webSocketUrl = "ws://localhost:$backendPort/ws"
$runId = [Guid]::NewGuid().ToString('N').Substring(0, 12)
$testEmail = "e2e.$runId@smartaid.local"
$testPassword = 'SmartAidE2E2026!'
$testNotes = "E2E_AUTOMATED_$runId"
$socket = $null
$incidentId = $null
$userAccess = $null
$incidentResolved = $false
$missionId = $null
$volunteerAccess = $null

function Assert-That([bool]$condition, [string]$message) {
    if (-not $condition) { throw "E2E assertion failed: $message" }
}

function Invoke-Api([string]$method, [string]$path, $body = $null, [string]$accessToken = $null) {
    $request = @{
        Method = $method
        Uri = "$baseUrl$path"
        UseBasicParsing = $true
    }
    if ($null -ne $body) {
        $request.ContentType = 'application/json'
        $request.Body = $body | ConvertTo-Json -Depth 8 -Compress
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
    $result = Invoke-Api 'POST' '/api/auth/login' @{ email = $email; password = $userCredential }
    Assert-That ($result.StatusCode -eq 200) "Login must succeed for $email."
    return $result.Body
}

function Send-StompFrame([System.Net.WebSockets.ClientWebSocket]$client, [string]$frame) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($frame)
    $segment = [System.ArraySegment[byte]]::new($bytes)
    [void]$client.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true,
        [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
}

function Receive-StompFrame([System.Net.WebSockets.ClientWebSocket]$client, [int]$timeoutSeconds = 10) {
    $buffer = New-Object byte[] 16384
    $segment = [System.ArraySegment[byte]]::new($buffer)
    $timeout = [System.Threading.CancellationTokenSource]::new([TimeSpan]::FromSeconds($timeoutSeconds))
    try {
        $result = $client.ReceiveAsync($segment, $timeout.Token).GetAwaiter().GetResult()
        Assert-That ($result.MessageType -eq [System.Net.WebSockets.WebSocketMessageType]::Text) 'WebSocket response must be text.'
        return [System.Text.Encoding]::UTF8.GetString($buffer, 0, $result.Count)
    } finally {
        $timeout.Dispose()
    }
}

function Open-IncidentSocket([string]$accessToken, [string]$incidentId) {
    $client = [System.Net.WebSockets.ClientWebSocket]::new()
    $client.Options.KeepAliveInterval = [TimeSpan]::FromSeconds(15)
    [void]$client.ConnectAsync([Uri]$webSocketUrl, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
    Send-StompFrame $client "CONNECT`naccept-version:1.2`nhost:localhost`nAuthorization:Bearer $accessToken`n`n$([char]0)"
    $connected = Receive-StompFrame $client
    Assert-That ($connected -match '^CONNECTED') 'STOMP connection must be acknowledged.'
    Send-StompFrame $client "SUBSCRIBE`nid:e2e-$runId`ndestination:/topic/incidents/$incidentId`nack:auto`n`n$([char]0)"
    # Spring's local simple broker does not issue SUBSCRIBE receipts. Allow its
    # asynchronous inbound channel to register the subscription, then verify
    # the meaningful outcome: delivery of a real status-change event.
    Start-Sleep -Milliseconds 750
    return $client
}

try {
    & (Join-Path $PSScriptRoot 'start-demo.ps1')
    Write-Host 'E2E: validating health, authentication, and role boundaries...'
    $health = Invoke-Api 'GET' '/actuator/health'
    Assert-That ($health.StatusCode -eq 200 -and $health.Body.status -eq 'UP') 'API health must be UP.'

    Assert-That ((Invoke-Api 'GET' '/api/users/me').StatusCode -eq 401) 'Unauthenticated profile access must return 401.'
    $registration = Invoke-Api 'POST' '/api/auth/register' @{ email = $testEmail; password = $testPassword; displayName = 'Automated E2E User' }
    Assert-That ($registration.StatusCode -eq 201) 'Registration must return 201.'
    Assert-That ($registration.Body.user.roles -contains 'USER') 'New user must have the USER role.'
    Assert-That ((Invoke-Api 'POST' '/api/auth/register' @{ email = $testEmail; password = $testPassword; displayName = 'Duplicate User' }).StatusCode -eq 409) 'Duplicate email must return 409.'
    Assert-That ((Invoke-Api 'POST' '/api/auth/login' @{ email = $testEmail; password = 'incorrect-password' }).StatusCode -eq 401) 'Invalid credentials must return 401.'

    $refresh = Invoke-Api 'POST' '/api/auth/refresh' @{ refreshToken = $registration.Body.refreshToken }
    Assert-That ($refresh.StatusCode -eq 200) 'Refresh token rotation must return 200.'
    Assert-That ((Invoke-Api 'POST' '/api/auth/refresh' @{ refreshToken = $registration.Body.refreshToken }).StatusCode -eq 401) 'Replayed refresh token must return 401.'
    $userAccess = $refresh.Body.accessToken
    $userRefresh = $refresh.Body.refreshToken

    $me = Invoke-Api 'GET' '/api/users/me' $null $userAccess
    Assert-That ($me.StatusCode -eq 200 -and $me.Body.email -eq $testEmail) 'Authenticated user profile must match the registered user.'
    Assert-That ((Invoke-Api 'GET' '/api/ems/dashboard' $null $userAccess).StatusCode -eq 403) 'USER role must not access the EMS dashboard.'

    $medical = Invoke-Api 'PUT' '/api/medical-profile' @{ bloodType = 'O+'; allergies = 'E2E only'; medications = 'None'; emergencyNotes = 'Fictional local test data'; sharingConsent = $true } $userAccess
    Assert-That ($medical.StatusCode -eq 200 -and $medical.Body.bloodType -eq 'O+') 'Medical profile update must persist.'
    Assert-That ((Invoke-Api 'GET' '/api/medical-profile' $null $userAccess).StatusCode -eq 200) 'Medical profile retrieval must succeed.'

    $contact = Invoke-Api 'POST' '/api/emergency-contacts' @{ fullName = 'E2E Contact'; relationship = 'Test'; phone = '+201000000000'; primary = $true } $userAccess
    Assert-That ($contact.StatusCode -eq 201) 'Emergency-contact creation must return 201.'
    $contactId = $contact.Body.id
    $updatedContact = Invoke-Api 'PUT' "/api/emergency-contacts/$contactId" @{ fullName = 'E2E Contact'; relationship = 'Verified test contact'; phone = '+201000000000'; primary = $true } $userAccess
    Assert-That ($updatedContact.StatusCode -eq 200 -and $updatedContact.Body.relationship -eq 'Verified test contact') 'Emergency-contact update must persist.'
    Assert-That ((Invoke-Api 'DELETE' "/api/emergency-contacts/$contactId" $null $userAccess).StatusCode -eq 204) 'Emergency-contact deletion must return 204.'

    Write-Host 'E2E: creating a fictional SOS and validating notifications...'
    $incident = Invoke-Api 'POST' '/api/incidents' @{ emergencyType = 'CARDIAC'; location = @{ latitude = 30.045; longitude = 31.236 }; notes = $testNotes; triage = @{ conscious = $false; breathing = $true; severeBleeding = $false; chestPain = $true; fall = $false; trafficAccident = $false } } $userAccess
    Assert-That ($incident.StatusCode -eq 201 -and $incident.Body.status -eq 'SEARCHING') 'Manual SOS must be server-confirmed as SEARCHING.'
    $incidentId = $incident.Body.id
    $detail = Invoke-Api 'GET' "/api/incidents/$incidentId" $null $userAccess
    Assert-That ($detail.StatusCode -eq 200 -and @($detail.Body.timeline).Count -ge 2) 'Incident detail must contain initial timeline events.'
    $notifications = @((Invoke-Api 'GET' '/api/notifications' $null $userAccess).Body | ForEach-Object { $_ })
    $emergencyNotification = $notifications | Where-Object { $_.type -eq 'EMERGENCY_ALERT' } | Select-Object -First 1
    Assert-That ($null -ne $emergencyNotification) 'Confirmed SOS must create a notification.'
    Assert-That ((Invoke-Api 'PATCH' ("/api/notifications/{0}/read" -f $emergencyNotification.id) $null $userAccess).StatusCode -eq 200) 'Notification mark-read must succeed.'

    Write-Host 'E2E: validating authenticated real-time volunteer dispatch...'
    $socket = Open-IncidentSocket $userAccess $incidentId
    $volunteer = Get-Session 'demo.volunteer@smartaid.local' 'SmartAidDemo2026!'
    $volunteerAccess = $volunteer.accessToken
    $activeMission = Invoke-Api 'GET' '/api/volunteers/missions/active' $null $volunteer.accessToken
    Assert-That ($activeMission.StatusCode -eq 404) 'Demo volunteer must not have a pre-existing active mission.'
    $volunteerProfile = Invoke-Api 'GET' '/api/volunteers/me' $null $volunteer.accessToken
    Assert-That ($volunteerProfile.StatusCode -eq 200 -and $volunteerProfile.Body.dispatchEligible) 'Demo volunteer must be eligible.'
    $nearby = @((Invoke-Api 'GET' '/api/volunteers/incidents/nearby' $null $volunteer.accessToken).Body | ForEach-Object { $_ })
    Assert-That ($null -ne ($nearby | Where-Object { $_.incident.id -eq $incidentId } | Select-Object -First 1)) 'New cardiac incident must be visible to the eligible volunteer.'
    $mission = Invoke-Api 'POST' "/api/volunteers/incidents/$incidentId/accept" $null $volunteerAccess
    Assert-That ($mission.StatusCode -eq 200 -and $mission.Body.status -eq 'ACCEPTED') 'Volunteer acceptance must create an active mission.'
    $missionId = $mission.Body.id
    $incidentEvent = Receive-StompFrame $socket
    Assert-That ($incidentEvent -match 'MESSAGE' -and $incidentEvent -match 'RESPONDER_ASSIGNED') 'Authorized STOMP subscriber must receive the responder assignment event.'
    Assert-That ((Invoke-Api 'POST' "/api/volunteers/incidents/$incidentId/accept" $null $volunteerAccess).StatusCode -eq 409) 'Second acceptance must be rejected.'
    Assert-That ((Invoke-Api 'PATCH' ("/api/volunteers/missions/{0}" -f $missionId) @{ status = 'ARRIVED' } $volunteerAccess).StatusCode -eq 200) 'Volunteer arrival must be recorded.'

    Write-Host 'E2E: validating EMS control-center workflow and Smart ER...'
    $ems = Get-Session 'demo.ems@smartaid.local' 'SmartAidDemo2026!'
    $emsDashboard = Invoke-Api 'GET' '/api/ems/dashboard' $null $ems.accessToken
    Assert-That ($emsDashboard.StatusCode -eq 200) 'EMS dashboard must be available to EMS.'
    Assert-That ($null -ne (@($emsDashboard.Body.incidents) | Where-Object { $_.id -eq $incidentId } | Select-Object -First 1)) 'New incident must appear in EMS operations.'
    $emsAssigned = Invoke-Api 'POST' "/api/ems/incidents/$incidentId/assign" $null $ems.accessToken
    Assert-That ($emsAssigned.StatusCode -eq 200 -and $emsAssigned.Body.incident.status -eq 'EMS_ASSIGNED') 'EMS assignment must update the incident.'
    $smartEr = @((Invoke-Api 'GET' "/api/smart-er/incidents/$incidentId/recommendations" $null $ems.accessToken).Body | ForEach-Object { $_ })
    Assert-That ($smartEr.Count -ge 2) 'Cardiac Smart ER must return a comparison set.'
    Assert-That ((Invoke-Api 'PATCH' ("/api/volunteers/missions/{0}" -f $missionId) @{ status = 'COMPLETED' } $volunteerAccess).StatusCode -eq 200) 'Volunteer completion must be recorded.'

    foreach ($status in 'HOSPITAL_SELECTED', 'AT_HOSPITAL', 'RESOLVED') {
        $transition = Invoke-Api 'PATCH' "/api/incidents/$incidentId/status" @{ status = $status; reason = "E2E automated transition: $status" } $ems.accessToken
        Assert-That ($transition.StatusCode -eq 200 -and $transition.Body.status -eq $status) "EMS transition to $status must succeed."
    }
    $resolved = Invoke-Api 'GET' "/api/incidents/$incidentId" $null $userAccess
    Assert-That ($resolved.StatusCode -eq 200 -and $resolved.Body.incident.status -eq 'RESOLVED') 'Reporter must see the resolved incident.'
    $incidentResolved = $true
    Assert-That (@($resolved.Body.timeline).Count -ge 6) 'Resolved incident must retain its audit timeline.'
    $postResolutionDashboard = Invoke-Api 'GET' '/api/ems/dashboard' $null $ems.accessToken
    Assert-That ($null -eq (@($postResolutionDashboard.Body.incidents) | Where-Object { $_.id -eq $incidentId } | Select-Object -First 1)) 'Resolved incident must leave the active EMS dashboard.'

    Assert-That ((Invoke-Api 'POST' '/api/auth/logout' @{ refreshToken = $userRefresh }).StatusCode -eq 204) 'Logout must return 204.'
    Assert-That ((Invoke-Api 'POST' '/api/auth/refresh' @{ refreshToken = $userRefresh }).StatusCode -eq 401) 'Logged-out refresh token must be rejected.'

    [pscustomobject]@{
        result = 'PASS'
        runId = $runId
        incidentId = $incidentId
        verified = @('health', 'registration', 'refresh-rotation', 'rbac', 'medical-profile', 'contacts-crud', 'sos', 'notifications', 'volunteer-mission', 'websocket', 'ems', 'smart-er', 'timeline', 'logout')
    } | ConvertTo-Json -Depth 4
} finally {
    if ($null -ne $missionId -and $null -ne $volunteerAccess -and -not $incidentResolved) {
        try {
            [void](Invoke-Api 'PATCH' "/api/volunteers/missions/$missionId" @{ status = 'CANCELLED' } $volunteerAccess)
        } catch {
            Write-Warning "Could not automatically close fictional E2E mission $missionId."
        }
    }
    if ($null -ne $incidentId -and $null -ne $userAccess -and -not $incidentResolved) {
        try {
            $cleanup = Invoke-Api 'PATCH' "/api/incidents/$incidentId/status" @{ status = 'CANCELLED'; reason = 'Automatic cleanup after an interrupted fictional E2E scenario' } $userAccess
            if ($cleanup.StatusCode -eq 200) { Write-Host "Cleaned up interrupted fictional E2E incident $incidentId." -ForegroundColor Yellow }
        } catch {
            Write-Warning "Could not automatically clean up fictional E2E incident $incidentId."
        }
    }
    if ($null -ne $socket) {
        try {
            if ($socket.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
                [void]$socket.CloseOutputAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, 'E2E complete', [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
            }
        } catch {
        } finally {
            try { $socket.Dispose() } catch {}
        }
    }
}
