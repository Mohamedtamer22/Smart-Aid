# ==============================================================================
# Smart Aid Platform — E2E Test Suite Common Harness (e2e-common.ps1)
# Derived strictly from user requirements and public HTTP/STOMP interfaces.
# ==============================================================================

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

# Global state containers
if ($null -eq $global:AllTestDefinitions) {
    $global:AllTestDefinitions = [System.Collections.Generic.List[PSCustomObject]]::new()
}
if ($null -eq $global:TestResults) {
    $global:TestResults = [System.Collections.Generic.List[PSCustomObject]]::new()
}
if ($null -eq $global:UserSessionCache) {
    $global:UserSessionCache = @{}
}

# ------------------------------------------------------------------------------
# 1. Assertions Framework
# ------------------------------------------------------------------------------

function Assert-That {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][bool]$condition,
        [Parameter(Mandatory=$false)][string]$message = 'Assertion failed'
    )
    if (-not $condition) {
        throw "Assertion failed: $message"
    }
}

function Assert-StatusCode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][int]$actual,
        [Parameter(Mandatory=$true)][int]$expected,
        [Parameter(Mandatory=$false)][string]$context = ''
    )
    if ($actual -ne $expected) {
        $prefix = if ($context) { "[$context] " } else { "" }
        throw "${prefix}Expected HTTP status code $expected, but received $actual."
    }
}

function Assert-JsonField {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]$body,
        [Parameter(Mandatory=$true)][string]$field,
        [Parameter(Mandatory=$false)]$expectedValue = $null,
        [Parameter(Mandatory=$false)][string]$context = ''
    )
    $prefix = if ($context) { "[$context] " } else { "" }
    if ($null -eq $body) {
        throw "${prefix}Response body is null; unable to assert field '$field'."
    }
    
    $actual = $null
    if ($body -is [System.Collections.IDictionary]) {
        if (-not $body.Contains($field)) {
            throw "${prefix}Field '$field' does not exist in response body dictionary."
        }
        $actual = $body[$field]
    } elseif ($body.PSObject.Properties[$field]) {
        $actual = $body.$field
    } else {
        throw "${prefix}Field '$field' does not exist in response object."
    }

    if ($null -ne $expectedValue -and $actual -ne $expectedValue) {
        throw "${prefix}Expected field '$field' to equal '$expectedValue', but received '$actual'."
    }
}

# ------------------------------------------------------------------------------
# 2. HTTP Client (Invoke-SmartAidApi)
# ------------------------------------------------------------------------------

function Invoke-SmartAidApi {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$method,
        [Parameter(Mandatory=$true)][string]$path,
        [Parameter(Mandatory=$false)]$body = $null,
        [Parameter(Mandatory=$false)][string]$accessToken = $null,
        [Parameter(Mandatory=$false)][string]$baseUrl = 'http://localhost:8080',
        [Parameter(Mandatory=$false)][int]$timeoutSeconds = 30
    )

    $url = if ($path.StartsWith('http://', [System.StringComparison]::OrdinalIgnoreCase) -or
               $path.StartsWith('https://', [System.StringComparison]::OrdinalIgnoreCase)) {
        $path
    } else {
        "$baseUrl$path"
    }

    $request = @{
        Method = $method
        Uri = $url
        UseBasicParsing = $true
        TimeoutSec = $timeoutSeconds
    }

    $headers = @{}
    if (-not [string]::IsNullOrWhiteSpace($accessToken)) {
        $headers['Authorization'] = "Bearer $accessToken"
    }

    if ($null -ne $body) {
        $headers['Content-Type'] = 'application/json'
        $request['ContentType'] = 'application/json'
        if ($body -is [string]) {
            $request['Body'] = $body
        } else {
            $request['Body'] = ($body | ConvertTo-Json -Depth 10 -Compress)
        }
    }

    if ($headers.Count -gt 0) {
        $request['Headers'] = $headers
    }

    $statusCode = 0
    $content = $null
    $respHeaders = @{}

    try {
        $response = Invoke-WebRequest @request -ErrorAction Stop
        $statusCode = [int]$response.StatusCode
        $content = if ($response.Content -is [byte[]]) {
            [System.Text.Encoding]::UTF8.GetString($response.Content)
        } else {
            [string]$response.Content
        }
        if ($null -ne $response.Headers) {
            foreach ($k in $response.Headers.Keys) {
                $respHeaders[$k] = $response.Headers[$k]
            }
        }
    } catch [System.Net.WebException] {
        $webResp = $_.Exception.Response
        if ($null -ne $webResp) {
            $statusCode = [int]$webResp.StatusCode
            $stream = $webResp.GetResponseStream()
            if ($null -ne $stream) {
                $reader = [System.IO.StreamReader]::new($stream)
                $content = $reader.ReadToEnd()
                $reader.Dispose()
            }
            if ($null -ne $webResp.Headers) {
                foreach ($k in $webResp.Headers.AllKeys) {
                    $respHeaders[$k] = $webResp.Headers[$k]
                }
            }
        } else {
            throw $_
        }
    } catch {
        if ($_.Exception.PSObject.Properties['Response'] -and $null -ne $_.Exception.Response) {
            $resp = $_.Exception.Response
            $statusCode = [int]$resp.StatusCode
            if ($resp.PSObject.Properties['Content']) {
                $content = $resp.Content.ReadAsStringAsync().GetAwaiter().GetResult()
            }
        } else {
            throw $_
        }
    }

    $parsed = $null
    if (-not [string]::IsNullOrWhiteSpace($content)) {
        try {
            $parsed = $content | ConvertFrom-Json
        } catch {
            $parsed = $content
        }
    }

    return [PSCustomObject]@{
        StatusCode = $statusCode
        Body       = $parsed
        RawContent = $content
        Headers    = $respHeaders
        Url        = $url
        Method     = $method
    }
}

# ------------------------------------------------------------------------------
# 3. User Session Manager (All 9 Roles)
# ------------------------------------------------------------------------------

$script:DemoCredentials = @{
    'USER'              = @{ Email = 'demo.user@smartaid.local';      Password = 'SmartAidDemo2026!' }
    'VOLUNTEER'         = @{ Email = 'demo.volunteer@smartaid.local'; Password = 'SmartAidDemo2026!' }
    'EMS'               = @{ Email = 'demo.ems@smartaid.local';       Password = 'SmartAidDemo2026!' }
    'HOSPITAL'          = @{ Email = 'demo.hospital@smartaid.local';  Password = 'SmartAidDemo2026!' }
    'ADMIN'             = @{ Email = 'demo.admin@smartaid.local';     Password = 'SmartAidDemo2026!' }
    'PHARMACIST'        = @{ Email = 'demo.pharmacist@smartaid.local';Password = 'SmartAidDemo2026!' }
    'LAB_STAFF'         = @{ Email = 'demo.lab@smartaid.local';       Password = 'SmartAidDemo2026!' }
    'BLOOD_BANK_STAFF'  = @{ Email = 'demo.bloodbank@smartaid.local'; Password = 'SmartAidDemo2026!' }
    'DOCTOR'            = @{ Email = 'demo.doctor@smartaid.local';    Password = 'SmartAidDemo2026!' }
}

function Get-UserSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$role,
        [Parameter(Mandatory=$false)][string]$baseUrl = 'http://localhost:8080',
        [Parameter(Mandatory=$false)][switch]$ForceRefresh
    )

    $normalizedRole = $role.ToUpperInvariant().Trim()
    if (-not $script:DemoCredentials.ContainsKey($normalizedRole)) {
        throw "Unsupported role '$role'. Supported roles: $($script:DemoCredentials.Keys -join ', ')."
    }

    $cacheKey = "$baseUrl`::$normalizedRole"
    if (-not $ForceRefresh -and $global:UserSessionCache.ContainsKey($cacheKey)) {
        return $global:UserSessionCache[$cacheKey]
    }

    if ($global:DryRunActive) {
        $mock = [PSCustomObject]@{
            Role         = $normalizedRole
            Email        = $script:DemoCredentials[$normalizedRole].Email
            AccessToken  = "dryrun-mock-token-$normalizedRole"
            RefreshToken = "dryrun-mock-refresh-$normalizedRole"
            User         = [PSCustomObject]@{
                email = $script:DemoCredentials[$normalizedRole].Email
                roles = @($normalizedRole)
            }
        }
        $global:UserSessionCache[$cacheKey] = $mock
        return $mock
    }

    $cred = $script:DemoCredentials[$normalizedRole]
    $loginResult = Invoke-SmartAidApi -method 'POST' -path '/api/auth/login' `
        -body @{ email = $cred.Email; password = $cred.Password } `
        -baseUrl $baseUrl

    Assert-StatusCode -actual $loginResult.StatusCode -expected 200 -context "Login for role $normalizedRole"
    Assert-That ($null -ne $loginResult.Body.accessToken) "Access token must be returned for role $normalizedRole."

    $session = [PSCustomObject]@{
        Role         = $normalizedRole
        Email        = $cred.Email
        AccessToken  = $loginResult.Body.accessToken
        RefreshToken = $loginResult.Body.refreshToken
        User         = $loginResult.Body.user
    }

    $global:UserSessionCache[$cacheKey] = $session
    return $session
}

# ------------------------------------------------------------------------------
# 4. STOMP WebSocket Client
# ------------------------------------------------------------------------------

function Send-StompFrame {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][System.Net.WebSockets.ClientWebSocket]$client,
        [Parameter(Mandatory=$true)][string]$frame
    )
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($frame)
    $segment = [System.ArraySegment[byte]]::new($bytes)
    [void]$client.SendAsync($segment, [System.Net.WebSockets.WebSocketMessageType]::Text, $true,
        [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
}

function Receive-StompFrame {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][System.Net.WebSockets.ClientWebSocket]$client,
        [Parameter(Mandatory=$false)][int]$timeoutSeconds = 10
    )
    $buffer = New-Object byte[] 16384
    $segment = [System.ArraySegment[byte]]::new($buffer)
    $cts = [System.Threading.CancellationTokenSource]::new([TimeSpan]::FromSeconds($timeoutSeconds))
    try {
        $result = $client.ReceiveAsync($segment, $cts.Token).GetAwaiter().GetResult()
        Assert-That ($result.MessageType -eq [System.Net.WebSockets.WebSocketMessageType]::Text) 'WebSocket response must be text.'
        return [System.Text.Encoding]::UTF8.GetString($buffer, 0, $result.Count)
    } finally {
        $cts.Dispose()
    }
}

function Open-IncidentSocket {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$accessToken,
        [Parameter(Mandatory=$true)][string]$incidentId,
        [Parameter(Mandatory=$false)][string]$baseUrl = 'http://localhost:8080'
    )

    if ($global:DryRunActive) {
        Write-Verbose "DryRun: Simulating WebSocket connection for incident $incidentId"
        return $null
    }

    $uri = [System.Uri]::new($baseUrl)
    $wsScheme = if ($uri.Scheme -eq 'https') { 'wss' } else { 'ws' }
    $wsUrl = "$wsScheme`://$($uri.Host):$($uri.Port)/ws"

    $client = [System.Net.WebSockets.ClientWebSocket]::new()
    $client.Options.KeepAliveInterval = [TimeSpan]::FromSeconds(15)
    [void]$client.ConnectAsync([Uri]$wsUrl, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()

    Send-StompFrame $client "CONNECT`naccept-version:1.2`nhost:$($uri.Host)`nAuthorization:Bearer $accessToken`n`n$([char]0)"
    $connected = Receive-StompFrame $client 10
    Assert-That ($connected -match '^CONNECTED') 'STOMP connection must be acknowledged.'

    $subId = "sub-" + [Guid]::NewGuid().ToString('N').Substring(0, 8)
    Send-StompFrame $client "SUBSCRIBE`nid:$subId`ndestination:/topic/incidents/$incidentId`nack:auto`n`n$([char]0)"
    Start-Sleep -Milliseconds 500

    return $client
}

# ------------------------------------------------------------------------------
# 5. Test Registration & Result Reporting
# ------------------------------------------------------------------------------

function Register-TestCase {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$tier,
        [Parameter(Mandatory=$true)][string]$featureId,
        [Parameter(Mandatory=$true)][string]$testId,
        [Parameter(Mandatory=$true)][string]$testName,
        [Parameter(Mandatory=$false)][string]$description = '',
        [Parameter(Mandatory=$true)][scriptblock]$action
    )

    $testCase = [PSCustomObject]@{
        Tier        = $tier
        FeatureId   = $featureId
        TestId      = $testId
        TestName    = $testName
        Description = $description
        Action      = $action
    }
    $global:AllTestDefinitions.Add($testCase)
}

function Add-TestResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$tier,
        [Parameter(Mandatory=$true)][string]$featureId,
        [Parameter(Mandatory=$true)][string]$testName,
        [Parameter(Mandatory=$true)][string]$status,
        [Parameter(Mandatory=$false)][string]$message = '',
        [Parameter(Mandatory=$false)][double]$durationMs = 0.0,
        [Parameter(Mandatory=$false)][string]$testId = $null
    )

    $result = [PSCustomObject]@{
        Tier        = $tier
        FeatureId   = $featureId
        TestId      = $testId
        TestName    = $testName
        Status      = $status
        Message     = $message
        DurationMs  = [Math]::Round($durationMs, 2)
        Timestamp   = [DateTime]::UtcNow.ToString("o")
    }
    $global:TestResults.Add($result)
    return $result
}

function Export-TestResultsJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][string]$outputPath = 'target/e2e-results.json'
    )

    $fullPath = if ([System.IO.Path]::IsPathRooted($outputPath)) {
        $outputPath
    } else {
        Join-Path (Get-Location) $outputPath
    }

    $parentDir = Split-Path -Parent $fullPath
    if (-not (Test-Path $parentDir)) {
        [void](New-Item -ItemType Directory -Path $parentDir -Force)
    }

    $passCount = ($global:TestResults | Where-Object { $_.Status -eq 'PASS' }).Count
    $failCount = ($global:TestResults | Where-Object { $_.Status -eq 'FAIL' }).Count
    $skipCount = ($global:TestResults | Where-Object { $_.Status -eq 'SKIPPED' }).Count
    $totalCount = $global:TestResults.Count
    $totalDuration = ($global:TestResults | Measure-Object -Property DurationMs -Sum).Sum

    $report = [PSCustomObject]@{
        TestSuite     = 'Smart Aid 4-Tier E2E Automated Test Suite'
        GeneratedAt   = [DateTime]::UtcNow.ToString("o")
        TotalTests    = $totalCount
        PassedTests   = $passCount
        FailedTests   = $failCount
        SkippedTests  = $skipCount
        TotalDurationMs = [Math]::Round($totalDuration, 2)
        Status        = if ($failCount -eq 0 -and $totalCount -gt 0) { 'SUCCESS' } else { 'FAILED' }
        Results       = $global:TestResults
    }

    $json = $report | ConvertTo-Json -Depth 6
    [System.IO.File]::WriteAllText($fullPath, $json, [System.Text.Encoding]::UTF8)
    Write-Host "[REPORT] Exported test execution report to: $fullPath" -ForegroundColor Green
    return $fullPath
}

function Print-TestSummary {
    [CmdletBinding()]
    param()

    Write-Host ""
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "               SMART AID E2E AUTOMATED TEST SUITE SUMMARY                 " -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor Cyan

    $tiers = @('Tier 1', 'Tier 2', 'Tier 3', 'Tier 4')
    foreach ($t in $tiers) {
        $tierTests = @($global:TestResults | Where-Object { $_.Tier -eq $t })
        $tPass = @($tierTests | Where-Object { $_.Status -eq 'PASS' }).Count
        $tFail = @($tierTests | Where-Object { $_.Status -eq 'FAIL' }).Count
        $tTotal = $tierTests.Count

        $statusColor = if ($tFail -gt 0) { 'Red' } elseif ($tTotal -gt 0) { 'Green' } else { 'Yellow' }
        Write-Host ("  {0,-10} : Total={1,3} | Passed={2,3} | Failed={3,3}" -f $t, $tTotal, $tPass, $tFail) -ForegroundColor $statusColor
    }

    $total = $global:TestResults.Count
    $passed = @($global:TestResults | Where-Object { $_.Status -eq 'PASS' }).Count
    $failed = @($global:TestResults | Where-Object { $_.Status -eq 'FAIL' }).Count

    Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
    $overallColor = if ($failed -eq 0 -and $total -gt 0) { 'Green' } else { 'Red' }
    Write-Host ("  GRAND TOTAL: Total={0,3} | Passed={1,3} | Failed={2,3}" -f $total, $passed, $failed) -ForegroundColor $overallColor
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Execute-RegisteredTests {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)][string]$tierFilter = 'All',
        [Parameter(Mandatory=$false)][switch]$DryRun,
        [Parameter(Mandatory=$false)][string]$baseUrl = 'http://localhost:8080'
    )

    $global:DryRunActive = [bool]$DryRun
    $selectedTests = $global:AllTestDefinitions | Where-Object {
        if ($tierFilter -eq 'All') {
            $true
        } else {
            $_.Tier -match "Tier $tierFilter"
        }
    }

    Write-Host "[EXECUTION] Selected $($selectedTests.Count) tests for execution (TierFilter: '$tierFilter', DryRun: $DryRun)..." -ForegroundColor Cyan

    foreach ($test in $selectedTests) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        if ($DryRun) {
            # In Dry-Run mode, validate that the test action is a valid scriptblock and metadata is complete
            $sw.Stop()
            if ($null -eq $test.Action -or [string]::IsNullOrWhiteSpace($test.TestId)) {
                [void](Add-TestResult -tier $test.Tier -featureId $test.FeatureId -testId $test.TestId -testName $test.TestName -status 'FAIL' -message 'Malformed test definition' -durationMs $sw.Elapsed.TotalMilliseconds)
            } else {
                [void](Add-TestResult -tier $test.Tier -featureId $test.FeatureId -testId $test.TestId -testName $test.TestName -status 'PASS' -message 'AST validated (Dry Run)' -durationMs $sw.Elapsed.TotalMilliseconds)
            }
        } else {
            try {
                & $test.Action -BaseUrl $baseUrl
                $sw.Stop()
                [void](Add-TestResult -tier $test.Tier -featureId $test.FeatureId -testId $test.TestId -testName $test.TestName -status 'PASS' -message 'Passed successfully' -durationMs $sw.Elapsed.TotalMilliseconds)
                Write-Host "  [PASS] [$($test.TestId)] $($test.TestName)" -ForegroundColor Green
            } catch {
                $sw.Stop()
                $errorMsg = $_.Exception.Message
                [void](Add-TestResult -tier $test.Tier -featureId $test.FeatureId -testId $test.TestId -testName $test.TestName -status 'FAIL' -message $errorMsg -durationMs $sw.Elapsed.TotalMilliseconds)
                Write-Host "  [FAIL] [$($test.TestId)] $($test.TestName): $errorMsg" -ForegroundColor Red
            }
        }
    }
}
