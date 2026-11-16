# ==============================================================================
# Smart Aid Platform — Master E2E Automated Test Suite Runner
# Executes and verifies all 4 Tiers of automated tests:
#   Tier 1: Feature Coverage (120 Tests)
#   Tier 2: Boundary & Corner Cases (120 Tests)
#   Tier 3: Pairwise Cross-Feature Interactions (24 Tests)
#   Tier 4: Complex Clinical & Operational Scenarios (12 Tests)
# Grand Total: 276 Tests
# ==============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('All', '1', '2', '3', '4')]
    [string]$Tier = 'All',

    [Parameter(Mandatory=$false)]
    [string]$BaseUrl = 'http://localhost:8080',

    [Parameter(Mandatory=$false)]
    [switch]$DryRun,

    [Parameter(Mandatory=$false)]
    [string]$ReportPath = "target/e2e-results.json",

    [Parameter(Mandatory=$false)]
    [switch]$FailFast
)

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "             SMART AID MASTER 4-TIER E2E TEST SUITE RUNNER                " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "  Target BaseUrl : $BaseUrl" -ForegroundColor White
Write-Host "  Selected Tier  : $Tier" -ForegroundColor White
Write-Host "  Dry-Run Mode   : $DryRun" -ForegroundColor White
Write-Host "  Report Path    : $ReportPath" -ForegroundColor White
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host ""

# Reset state containers
$global:AllTestDefinitions = [System.Collections.Generic.List[PSCustomObject]]::new()
$global:TestResults        = [System.Collections.Generic.List[PSCustomObject]]::new()
$global:UserSessionCache   = @{}
$global:DryRunActive       = [bool]$DryRun
$global:TestRunnerActive   = $true
$isDryRun                  = [bool]$DryRun

$e2eDir = Join-Path $PSScriptRoot 'e2e'

# Load common harness
$commonScript = Join-Path $e2eDir 'e2e-common.ps1'
if (-not (Test-Path $commonScript)) {
    Write-Host "[FATAL] Cannot locate common test harness at: $commonScript" -ForegroundColor Red
    exit 2
}
. $commonScript

# Load and register all 4 tiers
$tierScripts = @(
    (Join-Path $e2eDir 'tier1-features.ps1'),
    (Join-Path $e2eDir 'tier2-boundaries.ps1'),
    (Join-Path $e2eDir 'tier3-cross-feature.ps1'),
    (Join-Path $e2eDir 'tier4-scenarios.ps1')
)

foreach ($script in $tierScripts) {
    if (-not (Test-Path $script)) {
        Write-Host "[FATAL] Missing tier script: $script" -ForegroundColor Red
        exit 2
    }
    . $script
}

Write-Host "[REGISTRY] Total tests registered across all tiers: $($global:AllTestDefinitions.Count)" -ForegroundColor Green

# Environment verification (if not dry run)
if (-not $isDryRun -and -not $global:DryRunActive) {
    Write-Host "[ENV CHECK] Verifying backend availability at $BaseUrl/actuator/health..." -ForegroundColor Yellow
    try {
        $health = Invoke-SmartAidApi -method 'GET' -path '/actuator/health' -baseUrl $BaseUrl -timeoutSeconds 5
        if ($health.StatusCode -ne 200 -or $health.Body.status -ne 'UP') {
            Write-Host "[ENV ERROR] Smart Aid backend is not UP (HTTP $($health.StatusCode)). Please run scripts\start-demo.ps1." -ForegroundColor Red
            exit 2
        }
        Write-Host "[ENV OK] Smart Aid backend health is UP." -ForegroundColor Green
    } catch {
        Write-Host "[ENV ERROR] Failed to connect to Smart Aid backend at $BaseUrl. $_" -ForegroundColor Red
        exit 2
    }
}

# Execute selected tests
Execute-RegisteredTests -tierFilter $Tier -DryRun:$global:DryRunActive -baseUrl $BaseUrl

# Print summary table
Print-TestSummary

# Export audit JSON report
$exportedReport = Export-TestResultsJson -outputPath $ReportPath

# Check exit code criteria
$failedCount = @($global:TestResults | Where-Object { $_.Status -eq 'FAIL' }).Count
if ($failedCount -gt 0) {
    Write-Host "[RESULT] Execution finished with $failedCount failed assertions." -ForegroundColor Red
    exit 1
}

Write-Host "[RESULT] 100% of executed tests PASSED successfully." -ForegroundColor Green
exit 0
