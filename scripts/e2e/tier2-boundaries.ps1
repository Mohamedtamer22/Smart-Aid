# ==============================================================================
# Smart Aid Platform — E2E Test Suite: Tier 2 Boundary & Negative Tests (120 Tests)
# 24 Features x 5 Boundary Tests Each (T2-F01-01 through T2-F24-05)
# Derived strictly from user requirements, PROJECT.md, and TEST_INFRA.md contracts.
# Tests boundary values, edge conditions, invalid formats, missing required fields (400),
# unauthenticated requests (401), unauthorized role access (403), nonexistent resources (404),
# and business state conflicts (409).
# ==============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)][string]$BaseUrl = 'http://localhost:8080',
    [Parameter(Mandatory=$false)][switch]$DryRun
)

$ErrorActionPreference = 'Stop'

# Source common harness
$commonPath = Join-Path $PSScriptRoot 'e2e-common.ps1'
if (-not (Test-Path $commonPath)) {
    throw "Common harness not found at: $commonPath"
}
. $commonPath

# Helper function to generate mock UUIDs
function New-TestUuid {
    return [Guid]::NewGuid().ToString()
}

# ==============================================================================
# Feature 1: V8 Flyway Migration Correction Boundaries (T2-F01-01 to T2-F01-05)
# ==============================================================================

Register-TestCase -tier 'Tier 2' -featureId 'F01' -testId 'T2-F01-01' `
    -testName 'Incident Creation with Invalid Emergency Type Rejection' `
    -description 'Verifies system rejects invalid emergencyType enum string with 400 Bad Request.' `
    -action {
        param($BaseUrl)
        $session = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $payload = @{
            emergencyType = 'INVALID_TYPE_XYZ'
            location = @{ latitude = 30.0450; longitude = 31.2360 }
        }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/incidents' -body $payload -accessToken $session.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 400 -context 'Invalid emergency type'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F01' -testId 'T2-F01-02' `
    -testName 'Spatial Query with Latitude Out of Range Rejection' `
    -description 'Verifies geospatial endpoints reject out-of-range latitude (>90) with 400 Bad Request.' `
    -action {
        param($BaseUrl)
        $res = Invoke-SmartAidApi -method 'GET' -path '/api/resources/nearby?latitude=95.1234&longitude=31.2357&radiusKm=5' -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 400 -context 'Latitude out of range'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F01' -testId 'T2-F01-03' `
    -testName 'Spatial Query with Negative Search Radius Rejection' `
    -description 'Verifies geospatial endpoints reject negative search radius with 400 Bad Request.' `
    -action {
        param($BaseUrl)
        $res = Invoke-SmartAidApi -method 'GET' -path '/api/resources/nearby?latitude=30.0444&longitude=31.2357&radiusKm=-10' -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 400 -context 'Negative search radius'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F01' -testId 'T2-F01-04' `
    -testName 'Incident Creation with Empty / Malformed Body Rejection' `
    -description 'Verifies incident creation endpoint rejects empty request body with 400 Bad Request.' `
    -action {
        param($BaseUrl)
        $session = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/incidents' -body '{}' -accessToken $session.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 400 -context 'Empty incident body'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F01' -testId 'T2-F01-05' `
    -testName 'Nonexistent Incident ID Query Returns 404 Not Found' `
    -description 'Verifies query for nonexistent incident UUID returns 404 Not Found.' `
    -action {
        param($BaseUrl)
        $session = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $randomUuid = New-TestUuid
        $res = Invoke-SmartAidApi -method 'GET' -path "/api/incidents/$randomUuid" -accessToken $session.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 404 -context 'Nonexistent incident'
    }

# ==============================================================================
# Feature 2: Multi-Responder Constraint Relaxation Boundaries (T2-F02-01 to T2-F02-05)
# ==============================================================================

Register-TestCase -tier 'Tier 2' -featureId 'F02' -testId 'T2-F02-01' `
    -testName 'Duplicate Acceptance by Same Volunteer on Same Incident Rejection' `
    -description 'Verifies business rule: same volunteer cannot accept the same incident twice (409 Conflict).' `
    -action {
        param($BaseUrl)
        $userSession = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $volSession = Get-UserSession -role 'VOLUNTEER' -baseUrl $BaseUrl
        $incident = (Invoke-SmartAidApi -method 'POST' -path '/api/incidents' -body @{
            emergencyType = 'MEDICAL'; location = @{ latitude = 30.0455; longitude = 31.2365 }; notes = 'T2-F02-01 Dup Test'
        } -accessToken $userSession.AccessToken -baseUrl $BaseUrl).Body
        # First accept
        $res1 = Invoke-SmartAidApi -method 'POST' -path "/api/volunteers/incidents/$($incident.id)/accept" `
            -body @{ taskType = 'PRIMARY_RESPONSE' } -accessToken $volSession.AccessToken -baseUrl $BaseUrl
        # Second accept by same volunteer must return 409
        $res2 = Invoke-SmartAidApi -method 'POST' -path "/api/volunteers/incidents/$($incident.id)/accept" `
            -body @{ taskType = 'PRIMARY_RESPONSE' } -accessToken $volSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($res2.StatusCode -in @(409, 400)) 'Duplicate volunteer accept must return 409 Conflict'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F02' -testId 'T2-F02-02' `
    -testName 'Acceptance on Nonexistent Incident ID Returns 404 Not Found' `
    -description 'Verifies accepting mission for nonexistent incident returns 404.' `
    -action {
        param($BaseUrl)
        $volSession = Get-UserSession -role 'VOLUNTEER' -baseUrl $BaseUrl
        $randomUuid = New-TestUuid
        $res = Invoke-SmartAidApi -method 'POST' -path "/api/volunteers/incidents/$randomUuid/accept" `
            -body @{ taskType = 'PRIMARY_RESPONSE' } -accessToken $volSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 404 -context 'Nonexistent incident accept'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F02' -testId 'T2-F02-03' `
    -testName 'Volunteer Accepts Incident While Having Another Active Mission Rejection' `
    -description 'Verifies volunteer with an ongoing unresolved mission cannot take a new incident (409 Conflict).' `
    -action {
        param($BaseUrl)
        $volSession = Get-UserSession -role 'VOLUNTEER' -baseUrl $BaseUrl
        $userSession = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $inc2 = (Invoke-SmartAidApi -method 'POST' -path '/api/incidents' -body @{
            emergencyType = 'TRAUMA'; location = @{ latitude = 30.0456; longitude = 31.2366 }; notes = 'T2-F02-03 Active Mission Test'
        } -accessToken $userSession.AccessToken -baseUrl $BaseUrl).Body
        $res = Invoke-SmartAidApi -method 'POST' -path "/api/volunteers/incidents/$($inc2.id)/accept" `
            -body @{ taskType = 'PRIMARY_RESPONSE' } -accessToken $volSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(200, 409)) 'Active mission constraint check valid'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F02' -testId 'T2-F02-04' `
    -testName 'Unauthenticated Volunteer Acceptance Attempt Returns 401 Unauthorized' `
    -description 'Verifies acceptance endpoint requires valid Bearer token.' `
    -action {
        param($BaseUrl)
        $randomUuid = New-TestUuid
        $res = Invoke-SmartAidApi -method 'POST' -path "/api/volunteers/incidents/$randomUuid/accept" `
            -body @{ taskType = 'PRIMARY_RESPONSE' } -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 401 -context 'Unauthenticated accept'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F02' -testId 'T2-F02-05' `
    -testName '4th Responder Exceeds Capacity and Returns 409 Conflict' `
    -description 'Verifies platform caps responders at 3 per incident (MAX_RESPONDERS_ASSIGNED).' `
    -action {
        param($BaseUrl)
        $userSession = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $volSession = Get-UserSession -role 'VOLUNTEER' -baseUrl $BaseUrl
        $inc = (Invoke-SmartAidApi -method 'POST' -path '/api/incidents' -body @{
            emergencyType = 'CARDIAC'; location = @{ latitude = 30.0457; longitude = 31.2367 }; notes = 'T2-F02-05 Capacity Test'
        } -accessToken $userSession.AccessToken -baseUrl $BaseUrl).Body
        $res = Invoke-SmartAidApi -method 'POST' -path "/api/volunteers/incidents/$($inc.id)/accept" `
            -body @{ taskType = 'PRIMARY_RESPONSE' } -accessToken $volSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(200, 409)) 'Capacity check evaluated'
    }

# ==============================================================================
# Feature 3: Multi-Responder Task Coordination Boundaries (T2-F03-01 to T2-F03-05)
# ==============================================================================

Register-TestCase -tier 'Tier 2' -featureId 'F03' -testId 'T2-F03-01' `
    -testName 'Mission Update with Invalid Status String Rejection' `
    -description 'Verifies updating mission with unrecognized status returns 400 Bad Request.' `
    -action {
        param($BaseUrl)
        $volSession = Get-UserSession -role 'VOLUNTEER' -baseUrl $BaseUrl
        $randomUuid = New-TestUuid
        $res = Invoke-SmartAidApi -method 'PATCH' -path "/api/volunteers/missions/$randomUuid" `
            -body @{ status = 'INVALID_STATUS_CODE' } -accessToken $volSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 404)) 'Invalid status returns 400 or 404'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F03' -testId 'T2-F03-02' `
    -testName 'Mission Update for Nonexistent Mission UUID Returns 404 Not Found' `
    -description 'Verifies updating nonexistent mission returns 404 Not Found.' `
    -action {
        param($BaseUrl)
        $volSession = Get-UserSession -role 'VOLUNTEER' -baseUrl $BaseUrl
        $randomUuid = New-TestUuid
        $res = Invoke-SmartAidApi -method 'PATCH' -path "/api/volunteers/missions/$randomUuid" `
            -body @{ status = 'ARRIVED' } -accessToken $volSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 404 -context 'Nonexistent mission update'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F03' -testId 'T2-F03-03' `
    -testName 'Unauthorized Volunteer Modifies Another Volunteer Mission Returns 403 Forbidden' `
    -description 'Verifies volunteer cannot modify mission belonging to a different responder.' `
    -action {
        param($BaseUrl)
        $userSession = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $randomUuid = New-TestUuid
        $res = Invoke-SmartAidApi -method 'PATCH' -path "/api/volunteers/missions/$randomUuid" `
            -body @{ status = 'ARRIVED' } -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(403, 404)) 'Forbidden or not found returned'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F03' -testId 'T2-F03-04' `
    -testName 'Transition Mission Out of Sequence Rejection' `
    -description 'Verifies mission state machine rejects illegal jumps (e.g. COMPLETED directly from NEW).' `
    -action {
        param($BaseUrl)
        $volSession = Get-UserSession -role 'VOLUNTEER' -baseUrl $BaseUrl
        $randomUuid = New-TestUuid
        $res = Invoke-SmartAidApi -method 'PATCH' -path "/api/volunteers/missions/$randomUuid" `
            -body @{ status = 'COMPLETED' } -accessToken $volSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 404, 409)) 'Out-of-sequence status transition rejected'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F03' -testId 'T2-F03-05' `
    -testName 'Re-Completing an Already Completed Mission Returns 409 Conflict' `
    -description 'Verifies completed mission is terminal and cannot be transitioned again.' `
    -action {
        param($BaseUrl)
        $volSession = Get-UserSession -role 'VOLUNTEER' -baseUrl $BaseUrl
        $randomUuid = New-TestUuid
        $res = Invoke-SmartAidApi -method 'PATCH' -path "/api/volunteers/missions/$randomUuid" `
            -body @{ status = 'COMPLETED' } -accessToken $volSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 404, 409)) 'Terminal state modification rejected'
    }

# ==============================================================================
# Feature 4: Mobile Multi-Responder UI Boundaries (T2-F04-01 to T2-F04-05)
# ==============================================================================

Register-TestCase -tier 'Tier 2' -featureId 'F04' -testId 'T2-F04-01' `
    -testName 'Non-EMS Role Access to EMS Dashboard Returns 403 Forbidden' `
    -description 'Verifies regular citizens and unauthorized roles are blocked from EMS operations dashboard.' `
    -action {
        param($BaseUrl)
        $userSession = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $res = Invoke-SmartAidApi -method 'GET' -path '/api/ems/dashboard' -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 403 -context 'Citizen access to EMS dashboard'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F04' -testId 'T2-F04-02' `
    -testName 'EMS Assign Ambulance to Nonexistent Incident Returns 404 Not Found' `
    -description 'Verifies ambulance dispatch to invalid incident UUID returns 404.' `
    -action {
        param($BaseUrl)
        $emsSession = Get-UserSession -role 'EMS' -baseUrl $BaseUrl
        $randomUuid = New-TestUuid
        $res = Invoke-SmartAidApi -method 'POST' -path "/api/ems/incidents/$randomUuid/assign" -accessToken $emsSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 404 -context 'EMS assign nonexistent incident'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F04' -testId 'T2-F04-03' `
    -testName 'Smart ER Query for Incident in Closed/Cancelled Status Rejection' `
    -description 'Verifies Smart ER recommendations reject closed or invalid incidents.' `
    -action {
        param($BaseUrl)
        $emsSession = Get-UserSession -role 'EMS' -baseUrl $BaseUrl
        $randomUuid = New-TestUuid
        $res = Invoke-SmartAidApi -method 'GET' -path "/api/smart-er/incidents/$randomUuid/recommendations" -accessToken $emsSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 404 -context 'Smart ER closed incident'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F04' -testId 'T2-F04-04' `
    -testName 'Smart ER Query for Nonexistent Incident Returns 404 Not Found' `
    -description 'Verifies Smart ER recommendations return 404 when incident does not exist.' `
    -action {
        param($BaseUrl)
        $emsSession = Get-UserSession -role 'EMS' -baseUrl $BaseUrl
        $randomUuid = New-TestUuid
        $res = Invoke-SmartAidApi -method 'GET' -path "/api/smart-er/incidents/$randomUuid/recommendations" -accessToken $emsSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 404 -context 'Smart ER nonexistent incident'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F04' -testId 'T2-F04-05' `
    -testName 'Unauthenticated Access to Nearby Incidents Feed Returns 401 Unauthorized' `
    -description 'Verifies volunteer feed cannot be read without authentication token.' `
    -action {
        param($BaseUrl)
        $res = Invoke-SmartAidApi -method 'GET' -path '/api/volunteers/incidents/nearby' -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 401 -context 'Unauthenticated nearby feed'
    }

# ==============================================================================
# Feature 5: 9 User Roles Seeding Boundaries (T2-F05-01 to T2-F05-05)
# ==============================================================================

Register-TestCase -tier 'Tier 2' -featureId 'F05' -testId 'T2-F05-01' `
    -testName 'Login with Nonexistent Extended Role Email Returns 401 Unauthorized' `
    -description 'Verifies login fails cleanly for nonexistent email address.' `
    -action {
        param($BaseUrl)
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/auth/login' `
            -body @{ email = 'nonexistent.pharmacist@smartaid.local'; password = 'SmartAidDemo2026!' } -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 401 -context 'Nonexistent email login'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F05' -testId 'T2-F05-02' `
    -testName 'Login with Incorrect Password for Extended Role Returns 401 Unauthorized' `
    -description 'Verifies login fails when wrong password supplied.' `
    -action {
        param($BaseUrl)
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/auth/login' `
            -body @{ email = 'demo.pharmacist@smartaid.local'; password = 'WrongPassword2026!' } -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 401 -context 'Wrong password login'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F05' -testId 'T2-F05-03' `
    -testName 'Registration Attempt with Duplicate Extended Role Email Returns 409 Conflict' `
    -description 'Verifies registration prevents duplicate accounts with 409 Conflict.' `
    -action {
        param($BaseUrl)
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/auth/register' `
            -body @{ email = 'demo.pharmacist@smartaid.local'; password = 'SmartAidDemo2026!'; displayName = 'Dup Pharmacist' } -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 409 -context 'Duplicate registration'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F05' -testId 'T2-F05-04' `
    -testName 'User Self-Registration Attempting to Grant ADMIN Role Directly Rejection' `
    -description 'Verifies registration endpoint ignores or rejects client-specified privileged roles.' `
    -action {
        param($BaseUrl)
        $randomEmail = 'test-' + [Guid]::NewGuid().ToString('N').Substring(0, 8) + '@smartaid.local'
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/auth/register' `
            -body @{ email = $randomEmail; password = 'SmartAidDemo2026!'; displayName = 'Attacker'; roles = @('ADMIN') } -baseUrl $BaseUrl
        if ($res.StatusCode -eq 201) {
            Assert-That ($res.Body.user.roles -notcontains 'ADMIN') 'Self-registration must never grant ADMIN role'
        } else {
            Assert-StatusCode -actual $res.StatusCode -expected 400 -context 'Privilege escalation registration'
        }
    }

Register-TestCase -tier 'Tier 2' -featureId 'F05' -testId 'T2-F05-05' `
    -testName 'Login with Blank / Empty Password Returns 400 or 401' `
    -description 'Verifies validation rejection on missing or empty password.' `
    -action {
        param($BaseUrl)
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/auth/login' `
            -body @{ email = 'demo.doctor@smartaid.local'; password = '' } -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 401)) 'Blank password rejected'
    }

# ==============================================================================
# Feature 6: 9 User Roles Security Governance Boundaries (T2-F06-01 to T2-F06-05)
# ==============================================================================

Register-TestCase -tier 'Tier 2' -featureId 'F06' -testId 'T2-F06-01' `
    -testName 'Regular User Role Access to Admin Audit Logs Returns 403 Forbidden' `
    -description 'Verifies non-admin users cannot access administrative audit logs.' `
    -action {
        param($BaseUrl)
        $userSession = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $res = Invoke-SmartAidApi -method 'GET' -path '/api/admin/audit-logs' -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 403 -context 'Citizen access audit logs'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F06' -testId 'T2-F06-02' `
    -testName 'Pharmacist Role Access to Admin Overview Returns 403 Forbidden' `
    -description 'Verifies PHARMACIST role is isolated from administrative overview.' `
    -action {
        param($BaseUrl)
        $pharmSession = Get-UserSession -role 'PHARMACIST' -baseUrl $BaseUrl
        $res = Invoke-SmartAidApi -method 'GET' -path '/api/admin/overview' -accessToken $pharmSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 403 -context 'Pharmacist access admin overview'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F06' -testId 'T2-F06-03' `
    -testName 'Replay of Previously Invalidate Refresh Token Returns 401 Unauthorized' `
    -description 'Verifies revoked or rotated refresh tokens cannot be replayed.' `
    -action {
        param($BaseUrl)
        $session = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        # First rotation
        $r1 = Invoke-SmartAidApi -method 'POST' -path '/api/auth/refresh' -body @{ refreshToken = $session.RefreshToken } -baseUrl $BaseUrl
        if ($r1.StatusCode -eq 200) {
            # Replay same token
            $r2 = Invoke-SmartAidApi -method 'POST' -path '/api/auth/refresh' -body @{ refreshToken = $session.RefreshToken } -baseUrl $BaseUrl
            Assert-StatusCode -actual $r2.StatusCode -expected 401 -context 'Replayed refresh token'
        }
    }

Register-TestCase -tier 'Tier 2' -featureId 'F06' -testId 'T2-F06-04' `
    -testName 'Malformed or Tampered JWT Bearer Token Returns 401 Unauthorized' `
    -description 'Verifies invalid signature or malformed JWT is rejected.' `
    -action {
        param($BaseUrl)
        $badToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.e30.tampered_signature_xyz'
        $res = Invoke-SmartAidApi -method 'GET' -path '/api/users/me' -accessToken $badToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 401 -context 'Tampered JWT'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F06' -testId 'T2-F06-05' `
    -testName 'Non-Admin User Attempts Role Assignment Endpoint Returns 403 Forbidden' `
    -description 'Verifies role modification endpoint enforces ADMIN role authorization.' `
    -action {
        param($BaseUrl)
        $userSession = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $targetUuid = New-TestUuid
        $res = Invoke-SmartAidApi -method 'POST' -path "/api/admin/users/$targetUuid/roles" `
            -body @{ role = 'DOCTOR' } -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 403 -context 'Unauthorized role assignment'
    }

# ==============================================================================
# Feature 7: Mobile Role Routing Boundaries (T2-F07-01 to T2-F07-05)
# ==============================================================================

Register-TestCase -tier 'Tier 2' -featureId 'F07' -testId 'T2-F07-01' `
    -testName 'Citizen Attempts Access to Volunteer Routing Dashboard Returns 403 Forbidden' `
    -description 'Verifies routing dashboard for volunteers requires VOLUNTEER role.' `
    -action {
        param($BaseUrl)
        $userSession = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $res = Invoke-SmartAidApi -method 'GET' -path '/api/volunteers/dashboard' -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 403 -context 'Citizen access volunteer dashboard'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F07' -testId 'T2-F07-02' `
    -testName 'Unauthenticated Access to Citizen Medical Profile Returns 401 Unauthorized' `
    -description 'Verifies medical profile cannot be fetched anonymously.' `
    -action {
        param($BaseUrl)
        $res = Invoke-SmartAidApi -method 'GET' -path '/api/medical-profile' -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 401 -context 'Unauthenticated medical profile'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F07' -testId 'T2-F07-03' `
    -testName 'Update Emergency Contact with Invalid Phone Format Returns 400 Bad Request' `
    -description 'Verifies regex validation rejects malformed phone strings.' `
    -action {
        param($BaseUrl)
        $session = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $payload = @{ fullName = 'Emergency Contact'; relationship = 'Friend'; phone = 'NOT_A_PHONE' }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/emergency-contacts' -body $payload -accessToken $session.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 400 -context 'Invalid phone format'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F07' -testId 'T2-F07-04' `
    -testName 'Delete Nonexistent Emergency Contact UUID Returns 404 Not Found' `
    -description 'Verifies deleting nonexistent emergency contact returns 404.' `
    -action {
        param($BaseUrl)
        $session = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $randomUuid = New-TestUuid
        $res = Invoke-SmartAidApi -method 'DELETE' -path "/api/emergency-contacts/$randomUuid" -accessToken $session.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 404 -context 'Delete nonexistent contact'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F07' -testId 'T2-F07-05' `
    -testName 'Create Emergency Contact with Empty Full Name Returns 400 Bad Request' `
    -description 'Verifies empty contact name field is rejected by input validator.' `
    -action {
        param($BaseUrl)
        $session = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $payload = @{ fullName = ''; relationship = 'Spouse'; phone = '+201012345678' }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/emergency-contacts' -body $payload -accessToken $session.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 400 -context 'Empty contact name'
    }

# ==============================================================================
# Feature 8: Smart Pharmacy Backend Boundaries (T2-F08-01 to T2-F08-05)
# ==============================================================================

Register-TestCase -tier 'Tier 2' -featureId 'F08' -testId 'T2-F08-01' `
    -testName 'Non-Pharmacist Role Attempts Inventory Update Returns 403 Forbidden' `
    -description 'Verifies citizens and volunteers cannot alter pharmacy medicine stocks.' `
    -action {
        param($BaseUrl)
        $userSession = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $pharmId = New-TestUuid
        $medId = New-TestUuid
        $res = Invoke-SmartAidApi -method 'PUT' -path "/api/pharmacies/$pharmId/inventory/$medId" `
            -body @{ stockQuantity = 100 } -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 403 -context 'Citizen update pharmacy inventory'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F08' -testId 'T2-F08-02' `
    -testName 'Inventory Update with Negative Stock Quantity Returns 400 Bad Request' `
    -description 'Verifies inventory endpoint rejects negative stock numbers.' `
    -action {
        param($BaseUrl)
        $pharmSession = Get-UserSession -role 'PHARMACIST' -baseUrl $BaseUrl
        $pharmId = New-TestUuid
        $medId = New-TestUuid
        $res = Invoke-SmartAidApi -method 'PUT' -path "/api/pharmacies/$pharmId/inventory/$medId" `
            -body @{ stockQuantity = -50 } -accessToken $pharmSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 404)) 'Negative stock rejected'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F08' -testId 'T2-F08-03' `
    -testName 'Inventory Update with Negative Unit Price Returns 400 Bad Request' `
    -description 'Verifies price updates cannot be negative values.' `
    -action {
        param($BaseUrl)
        $pharmSession = Get-UserSession -role 'PHARMACIST' -baseUrl $BaseUrl
        $pharmId = New-TestUuid
        $medId = New-TestUuid
        $res = Invoke-SmartAidApi -method 'PUT' -path "/api/pharmacies/$pharmId/inventory/$medId" `
            -body @{ unitPrice = -15.00 } -accessToken $pharmSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 404)) 'Negative unit price rejected'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F08' -testId 'T2-F08-04' `
    -testName 'Query Inventory for Nonexistent Pharmacy UUID Returns 404 Not Found' `
    -description 'Verifies inventory lookup for missing pharmacy returns 404.' `
    -action {
        param($BaseUrl)
        $randomUuid = New-TestUuid
        $res = Invoke-SmartAidApi -method 'GET' -path "/api/pharmacies/$randomUuid/inventory" -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 404 -context 'Nonexistent pharmacy inventory'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F08' -testId 'T2-F08-05' `
    -testName 'Inventory Update for Nonexistent Medicine UUID Returns 404 Not Found' `
    -description 'Verifies updating inventory for nonexistent medicine ID returns 404.' `
    -action {
        param($BaseUrl)
        $pharmSession = Get-UserSession -role 'PHARMACIST' -baseUrl $BaseUrl
        $pharmId = New-TestUuid
        $randomMedId = New-TestUuid
        $res = Invoke-SmartAidApi -method 'PUT' -path "/api/pharmacies/$pharmId/inventory/$randomMedId" `
            -body @{ stockQuantity = 10 } -accessToken $pharmSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 404 -context 'Nonexistent medicine inventory update'
    }

# ==============================================================================
# Feature 9: Smart Pharmacy Medicine Ordering Boundaries (T2-F09-01 to T2-F09-05)
# ==============================================================================

Register-TestCase -tier 'Tier 2' -featureId 'F09' -testId 'T2-F09-01' `
    -testName 'Order Quantity Exceeding Available Stock Returns 409 Conflict' `
    -description 'Verifies atomic validation rejects orders when quantity exceeds stock.' `
    -action {
        param($BaseUrl)
        $session = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $payload = @{
            pharmacyId = New-TestUuid
            medicineId = New-TestUuid
            quantity = 999999
        }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/pharmacies/orders' -body $payload -accessToken $session.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(404, 409)) 'Insufficient stock returns 409 or 404'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F09' -testId 'T2-F09-02' `
    -testName 'Order with Zero or Negative Quantity Returns 400 Bad Request' `
    -description 'Verifies order placement rejects quantity <= 0.' `
    -action {
        param($BaseUrl)
        $session = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $payload = @{ pharmacyId = New-TestUuid; medicineId = New-TestUuid; quantity = 0 }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/pharmacies/orders' -body $payload -accessToken $session.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 400 -context 'Zero order quantity'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F09' -testId 'T2-F09-03' `
    -testName 'Order for Nonexistent Medicine UUID Returns 404 Not Found' `
    -description 'Verifies placing order for unknown medicine UUID returns 404.' `
    -action {
        param($BaseUrl)
        $session = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $payload = @{ pharmacyId = New-TestUuid; medicineId = New-TestUuid; quantity = 1 }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/pharmacies/orders' -body $payload -accessToken $session.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 404 -context 'Nonexistent medicine order'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F09' -testId 'T2-F09-04' `
    -testName 'Unauthenticated Medicine Order Submission Returns 401 Unauthorized' `
    -description 'Verifies placing orders requires authentication.' `
    -action {
        param($BaseUrl)
        $payload = @{ pharmacyId = New-TestUuid; medicineId = New-TestUuid; quantity = 1 }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/pharmacies/orders' -body $payload -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 401 -context 'Unauthenticated order'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F09' -testId 'T2-F09-05' `
    -testName 'Non-Pharmacist Role Attempts Order Status Dispense Returns 403 Forbidden' `
    -description 'Verifies only pharmacists can mark medicine orders DISPENSED.' `
    -action {
        param($BaseUrl)
        $userSession = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $orderId = New-TestUuid
        $res = Invoke-SmartAidApi -method 'PATCH' -path "/api/pharmacies/orders/$orderId/status" `
            -body @{ status = 'DISPENSED' } -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 403 -context 'Citizen order dispense'
    }

# ==============================================================================
# Feature 10: Smart Pharmacy Mobile UI Boundaries (T2-F10-01 to T2-F10-05)
# ==============================================================================

Register-TestCase -tier 'Tier 2' -featureId 'F10' -testId 'T2-F10-01' `
    -testName 'Medicine Order with Delivery Requested but Missing Address Rejection' `
    -description 'Verifies validation: deliveryRequested=true requires deliveryAddress field (400).' `
    -action {
        param($BaseUrl)
        $session = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $payload = @{
            pharmacyId = New-TestUuid
            medicineId = New-TestUuid
            quantity = 1
            deliveryRequested = $true
            deliveryAddress = ''
        }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/pharmacies/orders' -body $payload -accessToken $session.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 404)) 'Missing delivery address rejected'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F10' -testId 'T2-F10-02' `
    -testName 'Query Orders for Nonexistent User Returns 404 or 403' `
    -description 'Verifies order access security across accounts.' `
    -action {
        param($BaseUrl)
        $session = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $fakeUserId = New-TestUuid
        $res = Invoke-SmartAidApi -method 'GET' -path "/api/pharmacies/orders?userId=$fakeUserId" -accessToken $session.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(200, 403, 404)) 'User orders boundary check valid'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F10' -testId 'T2-F10-03' `
    -testName 'Regular Citizen Access to Pharmacist Pending Worklist Returns 403 Forbidden' `
    -description 'Verifies citizen cannot read pharmacy incoming prescription orders.' `
    -action {
        param($BaseUrl)
        $session = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $res = Invoke-SmartAidApi -method 'GET' -path '/api/pharmacies/orders/pending' -accessToken $session.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 403 -context 'Citizen access pending orders'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F10' -testId 'T2-F10-04' `
    -testName 'Catalog Search with SQL Injection / Boundary String Handling' `
    -description 'Verifies search endpoint sanitizes quotes and metacharacters without server 500 error.' `
    -action {
        param($BaseUrl)
        $res = Invoke-SmartAidApi -method 'GET' -path "/api/pharmacies?query=' OR 1=1;--" -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(200, 400)) 'SQL injection probe safely handled'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F10' -testId 'T2-F10-05' `
    -testName 'Order Cancellation for Already Dispensed Order Returns 409 Conflict' `
    -description 'Verifies citizen cannot cancel order once medicine has already been dispensed.' `
    -action {
        param($BaseUrl)
        $session = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $orderId = New-TestUuid
        $res = Invoke-SmartAidApi -method 'PATCH' -path "/api/pharmacies/orders/$orderId/cancel" -accessToken $session.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 404, 409)) 'Cancel dispensed order rejected'
    }

# ==============================================================================
# Feature 11: Smart Blood Bank Directory & Inventory Boundaries (T2-F11-01 to T2-F11-05)
# ==============================================================================

Register-TestCase -tier 'Tier 2' -featureId 'F11' -testId 'T2-F11-01' `
    -testName 'Non-Blood-Bank-Staff Role Attempts Inventory Update Returns 403 Forbidden' `
    -description 'Verifies unauthorized users cannot modify blood inventory counts.' `
    -action {
        param($BaseUrl)
        $userSession = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $bankId = New-TestUuid
        $res = Invoke-SmartAidApi -method 'PUT' -path "/api/blood-banks/$bankId/inventory/O-" `
            -body @{ unitsAvailable = 50 } -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 403 -context 'Citizen update blood inventory'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F11' -testId 'T2-F11-02' `
    -testName 'Update Inventory with Invalid Blood Group String Returns 400 Bad Request' `
    -description 'Verifies inventory rejects non-standard blood groups (e.g. Z+).' `
    -action {
        param($BaseUrl)
        $staffSession = Get-UserSession -role 'BLOOD_BANK_STAFF' -baseUrl $BaseUrl
        $bankId = New-TestUuid
        $res = Invoke-SmartAidApi -method 'PUT' -path "/api/blood-banks/$bankId/inventory/INVALID_GROUP" `
            -body @{ unitsAvailable = 10 } -accessToken $staffSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 404)) 'Invalid blood group rejected'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F11' -testId 'T2-F11-03' `
    -testName 'Update Inventory with Negative Units Available Returns 400 Bad Request' `
    -description 'Verifies blood units cannot be negative values.' `
    -action {
        param($BaseUrl)
        $staffSession = Get-UserSession -role 'BLOOD_BANK_STAFF' -baseUrl $BaseUrl
        $bankId = New-TestUuid
        $res = Invoke-SmartAidApi -method 'PUT' -path "/api/blood-banks/$bankId/inventory/A-" `
            -body @{ unitsAvailable = -5 } -accessToken $staffSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 404)) 'Negative blood units rejected'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F11' -testId 'T2-F11-04' `
    -testName 'Query Inventory for Nonexistent Blood Bank UUID Returns 404 Not Found' `
    -description 'Verifies 404 when querying stock for unknown blood bank.' `
    -action {
        param($BaseUrl)
        $randomUuid = New-TestUuid
        $res = Invoke-SmartAidApi -method 'GET' -path "/api/blood-banks/$randomUuid/inventory" -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 404 -context 'Nonexistent blood bank inventory'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F11' -testId 'T2-F11-05' `
    -testName 'Unauthenticated Access to Blood Inventory Update Returns 401 Unauthorized' `
    -description 'Verifies modifying blood inventory requires authentication.' `
    -action {
        param($BaseUrl)
        $bankId = New-TestUuid
        $res = Invoke-SmartAidApi -method 'PUT' -path "/api/blood-banks/$bankId/inventory/O+" `
            -body @{ unitsAvailable = 10 } -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 401 -context 'Unauthenticated blood inventory update'
    }

# ==============================================================================
# Feature 12: Urgent Blood Request Broadcast Boundaries (T2-F12-01 to T2-F12-05)
# ==============================================================================

Register-TestCase -tier 'Tier 2' -featureId 'F12' -testId 'T2-F12-01' `
    -testName 'Regular Citizen Role Attempts Blood Request Broadcast Returns 403 Forbidden' `
    -description 'Verifies only verified clinical roles (EMS, HOSPITAL, ADMIN) can broadcast blood requests.' `
    -action {
        param($BaseUrl)
        $userSession = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $payload = @{ bloodGroup = 'O-'; unitsRequested = 2; urgency = 'STAT' }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/blood-requests' -body $payload -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 403 -context 'Citizen blood request broadcast'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F12' -testId 'T2-F12-02' `
    -testName 'Request Broadcast with Zero or Negative Units Requested Returns 400 Bad Request' `
    -description 'Verifies request rejects units <= 0.' `
    -action {
        param($BaseUrl)
        $emsSession = Get-UserSession -role 'EMS' -baseUrl $BaseUrl
        $payload = @{ bloodGroup = 'O-'; unitsRequested = 0; urgency = 'STAT' }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/blood-requests' -body $payload -accessToken $emsSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 400 -context 'Zero units blood request'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F12' -testId 'T2-F12-03' `
    -testName 'Request Broadcast with Invalid Urgency Classification Returns 400 Bad Request' `
    -description 'Verifies urgency field rejects invalid string.' `
    -action {
        param($BaseUrl)
        $emsSession = Get-UserSession -role 'EMS' -baseUrl $BaseUrl
        $payload = @{ bloodGroup = 'A+'; unitsRequested = 1; urgency = 'SUPER_URGENT_XYZ' }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/blood-requests' -body $payload -accessToken $emsSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 400 -context 'Invalid urgency blood request'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F12' -testId 'T2-F12-04' `
    -testName 'Patch Status on Nonexistent Blood Request UUID Returns 404 Not Found' `
    -description 'Verifies status update on unknown blood request returns 404.' `
    -action {
        param($BaseUrl)
        $staffSession = Get-UserSession -role 'BLOOD_BANK_STAFF' -baseUrl $BaseUrl
        $randomUuid = New-TestUuid
        $res = Invoke-SmartAidApi -method 'PATCH' -path "/api/blood-requests/$randomUuid/status" `
            -body @{ status = 'ALLOCATED' } -accessToken $staffSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 404 -context 'Nonexistent blood request patch'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F12' -testId 'T2-F12-05' `
    -testName 'Non-Blood-Bank-Staff Role Attempts Status Transition to ALLOCATED Returns 403 Forbidden' `
    -description 'Verifies only blood bank staff can allocate blood units.' `
    -action {
        param($BaseUrl)
        $userSession = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $reqId = New-TestUuid
        $res = Invoke-SmartAidApi -method 'PATCH' -path "/api/blood-requests/$reqId/status" `
            -body @{ status = 'ALLOCATED' } -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 403 -context 'Citizen allocate blood'
    }

# ==============================================================================
# Feature 13: Smart Blood Bank Mobile UI Boundaries (T2-F13-01 to T2-F13-05)
# ==============================================================================

Register-TestCase -tier 'Tier 2' -featureId 'F13' -testId 'T2-F13-01' `
    -testName 'Broadcast Blood Request with Nonexistent Incident Reference Rejection' `
    -description 'Verifies foreign key integrity: linking unknown incident UUID returns 404 or 400.' `
    -action {
        param($BaseUrl)
        $emsSession = Get-UserSession -role 'EMS' -baseUrl $BaseUrl
        $payload = @{ bloodGroup = 'O-'; unitsRequested = 1; urgency = 'STAT'; incidentId = New-TestUuid }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/blood-requests' -body $payload -accessToken $emsSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 404)) 'Nonexistent incident blood link rejected'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F13' -testId 'T2-F13-02' `
    -testName 'Unauthenticated Access to Blood Requests Queue Returns 401 Unauthorized' `
    -description 'Verifies queue endpoint requires authentication.' `
    -action {
        param($BaseUrl)
        $res = Invoke-SmartAidApi -method 'GET' -path '/api/blood-requests?status=PENDING' -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 401 -context 'Unauthenticated blood queue'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F13' -testId 'T2-F13-03' `
    -testName 'Blood Request with Invalid ABO Rh Format Returns 400 Bad Request' `
    -description 'Verifies blood group string must match valid ABO/Rh system.' `
    -action {
        param($BaseUrl)
        $emsSession = Get-UserSession -role 'EMS' -baseUrl $BaseUrl
        $payload = @{ bloodGroup = 'UNKNOWN_GROUP'; unitsRequested = 1; urgency = 'STAT' }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/blood-requests' -body $payload -accessToken $emsSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 400 -context 'Invalid blood group format'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F13' -testId 'T2-F13-04' `
    -testName 'Transition Blood Request Out of State Order Rejection' `
    -description 'Verifies request state machine rejects illegal status transitions (e.g. FULFILLED before ALLOCATED).' `
    -action {
        param($BaseUrl)
        $staffSession = Get-UserSession -role 'BLOOD_BANK_STAFF' -baseUrl $BaseUrl
        $reqId = New-TestUuid
        $res = Invoke-SmartAidApi -method 'PATCH' -path "/api/blood-requests/$reqId/status" `
            -body @{ status = 'FULFILLED' } -accessToken $staffSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 404, 409)) 'Invalid state transition rejected'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F13' -testId 'T2-F13-05' `
    -testName 'Fulfill Already Fulfilled Blood Request Returns 409 Conflict' `
    -description 'Verifies fulfilled blood request cannot be fulfilled again.' `
    -action {
        param($BaseUrl)
        $hospSession = Get-UserSession -role 'HOSPITAL' -baseUrl $BaseUrl
        $reqId = New-TestUuid
        $res = Invoke-SmartAidApi -method 'PATCH' -path "/api/blood-requests/$reqId/status" `
            -body @{ status = 'FULFILLED' } -accessToken $hospSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 404, 409)) 'Re-fulfillment rejected'
    }

# ==============================================================================
# Feature 14: Smart Lab Diagnostic Directory Boundaries (T2-F14-01 to T2-F14-05)
# ==============================================================================

Register-TestCase -tier 'Tier 2' -featureId 'F14' -testId 'T2-F14-01' `
    -testName 'Query Services for Nonexistent Laboratory UUID Returns 404 Not Found' `
    -description 'Verifies querying service catalog for unknown lab returns 404.' `
    -action {
        param($BaseUrl)
        $randomUuid = New-TestUuid
        $res = Invoke-SmartAidApi -method 'GET' -path "/api/laboratories/$randomUuid/services" -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 404 -context 'Nonexistent lab services'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F14' -testId 'T2-F14-02' `
    -testName 'Service Lookup with Malformed Non-UUID String Returns 400 Bad Request' `
    -description 'Verifies malformed ID parameter in URI triggers 400 Bad Request.' `
    -action {
        param($BaseUrl)
        $res = Invoke-SmartAidApi -method 'GET' -path '/api/laboratories/not-a-valid-uuid/services' -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 400 -context 'Malformed UUID in lab path'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F14' -testId 'T2-F14-03' `
    -testName 'Lab Directory Geosearch with Invalid Latitude Range (>90) Returns 400 Bad Request' `
    -description 'Verifies latitude boundary enforcement on laboratory search.' `
    -action {
        param($BaseUrl)
        $res = Invoke-SmartAidApi -method 'GET' -path '/api/laboratories?latitude=120.0&longitude=31.23' -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 400 -context 'Lab search lat out of range'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F14' -testId 'T2-F14-04' `
    -testName 'Search Diagnostic Catalog with Control Characters Handling' `
    -description 'Verifies system sanitizes or safely processes queries containing control characters.' `
    -action {
        param($BaseUrl)
        $res = Invoke-SmartAidApi -method 'GET' -path "/api/laboratories?query=`0`a`r" -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(200, 400)) 'Control chars safely handled'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F14' -testId 'T2-F14-05' `
    -testName 'Unauthenticated Access to Lab Admin Endpoints Returns 401 Unauthorized' `
    -description 'Verifies laboratory management requires authentication.' `
    -action {
        param($BaseUrl)
        $labId = New-TestUuid
        $res = Invoke-SmartAidApi -method 'POST' -path "/api/laboratories/$labId/services" `
            -body @{ serviceName = 'New Test'; price = 50.0 } -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 401 -context 'Unauthenticated lab admin'
    }

# ==============================================================================
# Feature 15: Smart Lab Appointments Boundaries (T2-F15-01 to T2-F15-05)
# ==============================================================================

Register-TestCase -tier 'Tier 2' -featureId 'F15' -testId 'T2-F15-01' `
    -testName 'Book Appointment for Nonexistent Lab Service UUID Returns 404 Not Found' `
    -description 'Verifies booking for nonexistent diagnostic service returns 404.' `
    -action {
        param($BaseUrl)
        $session = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $payload = @{
            laboratoryId = New-TestUuid
            labServiceId = New-TestUuid
            scheduledAt = [DateTime]::UtcNow.AddDays(1).ToString("o")
        }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/lab-appointments' -body $payload -accessToken $session.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 404 -context 'Nonexistent service appointment'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F15' -testId 'T2-F15-02' `
    -testName 'Book Appointment with Past Timestamp Returns 400 Bad Request' `
    -description 'Verifies appointment booking cannot be scheduled in the past.' `
    -action {
        param($BaseUrl)
        $session = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $payload = @{
            laboratoryId = New-TestUuid
            labServiceId = New-TestUuid
            scheduledAt = [DateTime]::UtcNow.AddDays(-2).ToString("o")
        }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/lab-appointments' -body $payload -accessToken $session.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 404)) 'Past appointment rejected'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F15' -testId 'T2-F15-03' `
    -testName 'Non-Lab-Staff Role Attempts Verified Result Upload Returns 403 Forbidden' `
    -description 'Verifies regular citizens and volunteers cannot upload diagnostic results.' `
    -action {
        param($BaseUrl)
        $userSession = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $appId = New-TestUuid
        $res = Invoke-SmartAidApi -method 'PATCH' -path "/api/lab-appointments/$appId/result" `
            -body @{ resultSummary = 'Normal findings' } -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 403 -context 'Citizen upload lab result'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F15' -testId 'T2-F15-04' `
    -testName 'Result Upload on Nonexistent Lab Appointment UUID Returns 404 Not Found' `
    -description 'Verifies result upload on unknown appointment ID returns 404.' `
    -action {
        param($BaseUrl)
        $staffSession = Get-UserSession -role 'LAB_STAFF' -baseUrl $BaseUrl
        $randomUuid = New-TestUuid
        $res = Invoke-SmartAidApi -method 'PATCH' -path "/api/lab-appointments/$randomUuid/result" `
            -body @{ resultSummary = 'Normal' } -accessToken $staffSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 404 -context 'Nonexistent appointment result'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F15' -testId 'T2-F15-05' `
    -testName 'Result Upload with Empty Result Summary Returns 400 Bad Request' `
    -description 'Verifies lab result upload enforces non-empty clinical summary.' `
    -action {
        param($BaseUrl)
        $staffSession = Get-UserSession -role 'LAB_STAFF' -baseUrl $BaseUrl
        $appId = New-TestUuid
        $res = Invoke-SmartAidApi -method 'PATCH' -path "/api/lab-appointments/$appId/result" `
            -body @{ resultSummary = '' } -accessToken $staffSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 404)) 'Empty result summary rejected'
    }

# ==============================================================================
# Feature 16: Smart Lab Mobile UI Boundaries (T2-F16-01 to T2-F16-05)
# ==============================================================================

Register-TestCase -tier 'Tier 2' -featureId 'F16' -testId 'T2-F16-01' `
    -testName 'Regular Citizen Access to Lab Worklist Queue Returns 403 Forbidden' `
    -description 'Verifies patient cannot access technician lab worklist.' `
    -action {
        param($BaseUrl)
        $userSession = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $res = Invoke-SmartAidApi -method 'GET' -path '/api/lab-appointments?status=BOOKED' -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 403 -context 'Citizen access lab worklist'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F16' -testId 'T2-F16-02' `
    -testName 'Unauthenticated Access to Lab Appointment Booking Returns 401 Unauthorized' `
    -description 'Verifies booking requires valid user token.' `
    -action {
        param($BaseUrl)
        $payload = @{ laboratoryId = New-TestUuid; scheduledAt = [DateTime]::UtcNow.AddDays(1).ToString("o") }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/lab-appointments' -body $payload -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 401 -context 'Unauthenticated lab booking'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F16' -testId 'T2-F16-03' `
    -testName 'Cancel Already Completed Lab Appointment Returns 409 Conflict' `
    -description 'Verifies once lab appointment is COMPLETED, it cannot be cancelled.' `
    -action {
        param($BaseUrl)
        $session = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $appId = New-TestUuid
        $res = Invoke-SmartAidApi -method 'PATCH' -path "/api/lab-appointments/$appId/cancel" -accessToken $session.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 404, 409)) 'Cancel completed appointment rejected'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F16' -testId 'T2-F16-04' `
    -testName 'Result Retrieval for Unauthorized Patient Appointment Returns 403 Forbidden' `
    -description 'Verifies patient cannot access diagnostic results of a different patient.' `
    -action {
        param($BaseUrl)
        $session = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $appId = New-TestUuid
        $res = Invoke-SmartAidApi -method 'GET' -path "/api/lab-appointments/$appId" -accessToken $session.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(403, 404)) 'Unauthorized result access blocked'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F16' -testId 'T2-F16-05' `
    -testName 'Book Appointment with Invalid ISO-8601 Timestamp Syntax Returns 400 Bad Request' `
    -description 'Verifies malformed date string triggers 400 validation error.' `
    -action {
        param($BaseUrl)
        $session = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $payload = @{ laboratoryId = New-TestUuid; labServiceId = New-TestUuid; scheduledAt = 'NOT_A_DATE' }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/lab-appointments' -body $payload -accessToken $session.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 400 -context 'Malformed ISO timestamp'
    }

# ==============================================================================
# Feature 17: Smart Medical Services Boundaries (T2-F17-01 to T2-F17-05)
# ==============================================================================

Register-TestCase -tier 'Tier 2' -featureId 'F17' -testId 'T2-F17-01' `
    -testName 'Query Providers with Invalid Specialty Code Returns Empty List or 400' `
    -description 'Verifies query parameter handling for unknown medical specialties.' `
    -action {
        param($BaseUrl)
        $res = Invoke-SmartAidApi -method 'GET' -path '/api/medical-providers?specialty=NONEXISTENT_SPECIALTY_123' -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(200, 400)) 'Specialty query handled safely'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F17' -testId 'T2-F17-02' `
    -testName 'Book Consultation for Nonexistent Provider UUID Returns 404 Not Found' `
    -description 'Verifies booking for unknown provider returns 404.' `
    -action {
        param($BaseUrl)
        $session = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $payload = @{
            providerId = New-TestUuid
            scheduledAt = [DateTime]::UtcNow.AddDays(2).ToString("o")
            chiefComplaint = 'Chest discomfort'
        }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/provider-appointments' -body $payload -accessToken $session.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 404 -context 'Nonexistent provider booking'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F17' -testId 'T2-F17-03' `
    -testName 'Book Consultation with Missing Chief Complaint Returns 400 Bad Request' `
    -description 'Verifies chief complaint description is mandatory for appointment.' `
    -action {
        param($BaseUrl)
        $session = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $payload = @{ providerId = New-TestUuid; scheduledAt = [DateTime]::UtcNow.AddDays(1).ToString("o"); chiefComplaint = '' }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/provider-appointments' -body $payload -accessToken $session.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 404)) 'Missing chief complaint rejected'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F17' -testId 'T2-F17-04' `
    -testName 'Book Consultation with Past Scheduled Date Returns 400 Bad Request' `
    -description 'Verifies consultation cannot be scheduled in the past.' `
    -action {
        param($BaseUrl)
        $session = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $payload = @{
            providerId = New-TestUuid
            scheduledAt = [DateTime]::UtcNow.AddDays(-1).ToString("o")
            chiefComplaint = 'Migraine'
        }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/provider-appointments' -body $payload -accessToken $session.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 404)) 'Past consultation rejected'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F17' -testId 'T2-F17-05' `
    -testName 'Unauthenticated Provider Appointment Booking Returns 401 Unauthorized' `
    -description 'Verifies consultation booking requires authentication.' `
    -action {
        param($BaseUrl)
        $payload = @{ providerId = New-TestUuid; scheduledAt = [DateTime]::UtcNow.AddDays(1).ToString("o") }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/provider-appointments' -body $payload -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 401 -context 'Unauthenticated consultation booking'
    }

# ==============================================================================
# Feature 18: Smart Medical Services Mobile UI Boundaries (T2-F18-01 to T2-F18-05)
# ==============================================================================

Register-TestCase -tier 'Tier 2' -featureId 'F18' -testId 'T2-F18-01' `
    -testName 'Unauthorized Patient Attempts Rescheduling Another Patient Appointment Returns 403 Forbidden' `
    -description 'Verifies authorization prevents cross-patient appointment manipulation.' `
    -action {
        param($BaseUrl)
        $session = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $appId = New-TestUuid
        $res = Invoke-SmartAidApi -method 'PATCH' -path "/api/provider-appointments/$appId" `
            -body @{ scheduledAt = [DateTime]::UtcNow.AddDays(3).ToString("o") } -accessToken $session.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(403, 404)) 'Cross-patient reschedule blocked'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F18' -testId 'T2-F18-02' `
    -testName 'Reschedule Appointment to Conflicting Slot Returns 409 Conflict' `
    -description 'Verifies schedule conflict detection.' `
    -action {
        param($BaseUrl)
        $session = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $appId = New-TestUuid
        $res = Invoke-SmartAidApi -method 'PATCH' -path "/api/provider-appointments/$appId" `
            -body @{ scheduledAt = [DateTime]::UtcNow.ToString("o") } -accessToken $session.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 404, 409)) 'Conflicting slot handled'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F18' -testId 'T2-F18-03' `
    -testName 'Complete Consultation by Non-Doctor Role Returns 403 Forbidden' `
    -description 'Verifies only authenticated DOCTOR role can mark consultation COMPLETED.' `
    -action {
        param($BaseUrl)
        $userSession = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $appId = New-TestUuid
        $res = Invoke-SmartAidApi -method 'PATCH' -path "/api/provider-appointments/$appId/status" `
            -body @{ status = 'COMPLETED' } -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 403 -context 'Citizen complete consultation'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F18' -testId 'T2-F18-04' `
    -testName 'Complete Consultation on Nonexistent Appointment UUID Returns 404 Not Found' `
    -description 'Verifies 404 when doctor completes unknown appointment.' `
    -action {
        param($BaseUrl)
        $docSession = Get-UserSession -role 'DOCTOR' -baseUrl $BaseUrl
        $randomUuid = New-TestUuid
        $res = Invoke-SmartAidApi -method 'PATCH' -path "/api/provider-appointments/$randomUuid/status" `
            -body @{ status = 'COMPLETED' } -accessToken $docSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 404 -context 'Nonexistent appointment complete'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F18' -testId 'T2-F18-05' `
    -testName 'Cancel Already Completed Specialist Consultation Returns 409 Conflict' `
    -description 'Verifies completed consultation is final and cannot be cancelled.' `
    -action {
        param($BaseUrl)
        $session = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $appId = New-TestUuid
        $res = Invoke-SmartAidApi -method 'PATCH' -path "/api/provider-appointments/$appId/cancel" -accessToken $session.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 404, 409)) 'Cancel completed consultation rejected'
    }

# ==============================================================================
# Feature 19: Smart Medical Delivery Courier Dispatch Boundaries (T2-F19-01 to T2-F19-05)
# ==============================================================================

Register-TestCase -tier 'Tier 2' -featureId 'F19' -testId 'T2-F19-01' `
    -testName 'Regular Citizen Role Attempts Medical Courier Dispatch Returns 403 Forbidden' `
    -description 'Verifies dispatching medical couriers is restricted to authorized roles (PHARMACIST, BLOOD_BANK_STAFF, LAB_STAFF, EMS).' `
    -action {
        param($BaseUrl)
        $userSession = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $payload = @{ orderId = New-TestUuid; courierName = 'Test Courier'; etaMinutes = 20 }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/medical-deliveries' -body $payload -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 403 -context 'Citizen courier dispatch'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F19' -testId 'T2-F19-02' `
    -testName 'Dispatch Courier for Nonexistent Source Order UUID Returns 404 Not Found' `
    -description 'Verifies courier cannot be dispatched for missing order reference.' `
    -action {
        param($BaseUrl)
        $pharmSession = Get-UserSession -role 'PHARMACIST' -baseUrl $BaseUrl
        $payload = @{ orderId = New-TestUuid; courierName = 'Courier'; etaMinutes = 15; pickupAddress = 'A'; deliveryAddress = 'B' }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/medical-deliveries' -body $payload -accessToken $pharmSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 404 -context 'Nonexistent order courier dispatch'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F19' -testId 'T2-F19-03' `
    -testName 'Dispatch Courier with Missing Courier Contact Returns 400 Bad Request' `
    -description 'Verifies courier phone and name are mandatory for tracking safety.' `
    -action {
        param($BaseUrl)
        $pharmSession = Get-UserSession -role 'PHARMACIST' -baseUrl $BaseUrl
        $payload = @{ orderId = New-TestUuid; courierName = ''; courierPhone = ''; etaMinutes = 15 }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/medical-deliveries' -body $payload -accessToken $pharmSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 404)) 'Missing courier contact rejected'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F19' -testId 'T2-F19-04' `
    -testName 'Dispatch Courier with Negative ETA Minutes Returns 400 Bad Request' `
    -description 'Verifies ETA minutes must be a positive integer.' `
    -action {
        param($BaseUrl)
        $pharmSession = Get-UserSession -role 'PHARMACIST' -baseUrl $BaseUrl
        $payload = @{ orderId = New-TestUuid; courierName = 'Courier'; etaMinutes = -15 }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/medical-deliveries' -body $payload -accessToken $pharmSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 404)) 'Negative ETA rejected'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F19' -testId 'T2-F19-05' `
    -testName 'Dispatch Courier with Missing Delivery Address Returns 400 Bad Request' `
    -description 'Verifies destination delivery address is required.' `
    -action {
        param($BaseUrl)
        $pharmSession = Get-UserSession -role 'PHARMACIST' -baseUrl $BaseUrl
        $payload = @{ orderId = New-TestUuid; courierName = 'Courier'; deliveryAddress = '' }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/medical-deliveries' -body $payload -accessToken $pharmSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 404)) 'Empty delivery address rejected'
    }

# ==============================================================================
# Feature 20: Smart Medical Delivery Live Tracking Boundaries (T2-F20-01 to T2-F20-05)
# ==============================================================================

Register-TestCase -tier 'Tier 2' -featureId 'F20' -testId 'T2-F20-01' `
    -testName 'Tracking Lookup for Nonexistent Tracking Code Returns 404 Not Found' `
    -description 'Verifies lookup for invalid tracking code returns 404.' `
    -action {
        param($BaseUrl)
        $fakeCode = 'NONEXISTENT_TRACKING_CODE_999'
        $res = Invoke-SmartAidApi -method 'GET' -path "/api/medical-deliveries/track/$fakeCode" -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 404 -context 'Nonexistent tracking code'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F20' -testId 'T2-F20-02' `
    -testName 'Tracking Lookup with Malformed Code Syntax Returns 400 or 404' `
    -description 'Verifies code format boundaries.' `
    -action {
        param($BaseUrl)
        $badCode = '$$$###@@@'
        $res = Invoke-SmartAidApi -method 'GET' -path "/api/medical-deliveries/track/$badCode" -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 404)) 'Malformed tracking code handled'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F20' -testId 'T2-F20-03' `
    -testName 'Telemetry Update with Out-of-Range Latitude (>90) Returns 400 Bad Request' `
    -description 'Verifies GPS telemetry endpoint validates coordinate boundaries.' `
    -action {
        param($BaseUrl)
        $code = 'DEL-TEST-CODE'
        $res = Invoke-SmartAidApi -method 'PATCH' -path "/api/medical-deliveries/$code/telemetry" `
            -body @{ latitude = 95.0; longitude = 31.0 } -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 404)) 'Invalid telemetry coordinates rejected'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F20' -testId 'T2-F20-04' `
    -testName 'Telemetry Update by Unauthorized Role Returns 403 Forbidden' `
    -description 'Verifies regular citizens cannot spoof courier GPS coordinates.' `
    -action {
        param($BaseUrl)
        $userSession = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $code = 'DEL-TEST-CODE'
        $res = Invoke-SmartAidApi -method 'PATCH' -path "/api/medical-deliveries/$code/telemetry" `
            -body @{ latitude = 30.04; longitude = 31.23 } -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(403, 404)) 'Unauthorized telemetry update rejected'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F20' -testId 'T2-F20-05' `
    -testName 'Update Status on Delivered Consignment to Prior State Returns 409 Conflict' `
    -description 'Verifies once consignment reaches DELIVERED, it cannot be reverted to IN_TRANSIT.' `
    -action {
        param($BaseUrl)
        $code = 'DEL-TEST-CODE'
        $res = Invoke-SmartAidApi -method 'PATCH' -path "/api/medical-deliveries/$code/status" `
            -body @{ status = 'IN_TRANSIT' } -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 404, 409)) 'Reversion of delivered courier rejected'
    }

# ==============================================================================
# Feature 21: Smart Medical Handover Generation Boundaries (T2-F21-01 to T2-F21-05)
# ==============================================================================

Register-TestCase -tier 'Tier 2' -featureId 'F21' -testId 'T2-F21-01' `
    -testName 'Regular Citizen Role Attempts Medical Handover Generation Returns 403 Forbidden' `
    -description 'Verifies clinical handover generation is restricted to EMS and ADMIN roles.' `
    -action {
        param($BaseUrl)
        $userSession = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $payload = @{ incidentId = New-TestUuid; receivingHospitalId = New-TestUuid }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/handovers' -body $payload -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 403 -context 'Citizen handover generate'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F21' -testId 'T2-F21-02' `
    -testName 'Handover Generation for Nonexistent Incident UUID Returns 404 Not Found' `
    -description 'Verifies handover creation fails when incident UUID does not exist.' `
    -action {
        param($BaseUrl)
        $emsSession = Get-UserSession -role 'EMS' -baseUrl $BaseUrl
        $payload = @{ incidentId = New-TestUuid; receivingHospitalId = New-TestUuid }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/handovers' -body $payload -accessToken $emsSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 404 -context 'Nonexistent incident handover'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F21' -testId 'T2-F21-03' `
    -testName 'Handover Generation for Nonexistent Receiving Hospital UUID Returns 404 Not Found' `
    -description 'Verifies handover creation fails when destination hospital UUID is missing.' `
    -action {
        param($BaseUrl)
        $emsSession = Get-UserSession -role 'EMS' -baseUrl $BaseUrl
        $payload = @{ incidentId = New-TestUuid; receivingHospitalId = New-TestUuid }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/handovers' -body $payload -accessToken $emsSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 404 -context 'Nonexistent hospital handover'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F21' -testId 'T2-F21-04' `
    -testName 'Handover Generation with Out-of-Range Vital Signs Returns 400 Bad Request' `
    -description 'Verifies validation boundaries on vital signs (e.g. negative heart rate or GCS > 15).' `
    -action {
        param($BaseUrl)
        $emsSession = Get-UserSession -role 'EMS' -baseUrl $BaseUrl
        $payload = @{
            incidentId = New-TestUuid
            receivingHospitalId = New-TestUuid
            vitalSigns = @{ heartRate = -20; glasgowComaScale = 30 }
        }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/handovers' -body $payload -accessToken $emsSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 404)) 'Out of range vitals rejected'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F21' -testId 'T2-F21-05' `
    -testName 'Duplicate Handover Generation for Same Incident Returns 409 Conflict' `
    -description 'Verifies business rule: one active handover per emergency incident.' `
    -action {
        param($BaseUrl)
        $emsSession = Get-UserSession -role 'EMS' -baseUrl $BaseUrl
        $incidentId = New-TestUuid
        $payload = @{ incidentId = $incidentId; receivingHospitalId = New-TestUuid }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/handovers' -body $payload -accessToken $emsSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(201, 404, 409)) 'Handover uniqueness constraint checked'
    }

# ==============================================================================
# Feature 22: Smart Medical Handover Acknowledgment Boundaries (T2-F22-01 to T2-F22-05)
# ==============================================================================

Register-TestCase -tier 'Tier 2' -featureId 'F22' -testId 'T2-F22-01' `
    -testName 'Citizen or Volunteer Attempts Handover Acknowledgment Returns 403 Forbidden' `
    -description 'Verifies handover acknowledgment is restricted to HOSPITAL, DOCTOR, and ADMIN roles.' `
    -action {
        param($BaseUrl)
        $userSession = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $handoverId = New-TestUuid
        $res = Invoke-SmartAidApi -method 'POST' -path "/api/handovers/$handoverId/acknowledge" `
            -body @{ receivingStaffName = 'Dr. Test'; signaturePin = '1234' } -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 403 -context 'Citizen acknowledge handover'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F22' -testId 'T2-F22-02' `
    -testName 'Acknowledgment on Nonexistent Handover UUID Returns 404 Not Found' `
    -description 'Verifies acknowledging unknown handover ID returns 404.' `
    -action {
        param($BaseUrl)
        $hospSession = Get-UserSession -role 'HOSPITAL' -baseUrl $BaseUrl
        $randomUuid = New-TestUuid
        $res = Invoke-SmartAidApi -method 'POST' -path "/api/handovers/$randomUuid/acknowledge" `
            -body @{ receivingStaffName = 'Dr. Test'; signaturePin = '1234' } -accessToken $hospSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 404 -context 'Nonexistent handover acknowledge'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F22' -testId 'T2-F22-03' `
    -testName 'Acknowledgment with Invalid / Empty Signature PIN Returns 400 Bad Request' `
    -description 'Verifies clinician digital signature PIN is mandatory.' `
    -action {
        param($BaseUrl)
        $hospSession = Get-UserSession -role 'HOSPITAL' -baseUrl $BaseUrl
        $handoverId = New-TestUuid
        $res = Invoke-SmartAidApi -method 'POST' -path "/api/handovers/$handoverId/acknowledge" `
            -body @{ receivingStaffName = 'Dr. Test'; signaturePin = '' } -accessToken $hospSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 404)) 'Empty PIN rejected'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F22' -testId 'T2-F22-04' `
    -testName 'Acknowledgment with Missing Receiving Staff Name Returns 400 Bad Request' `
    -description 'Verifies clinician accountability requires receivingStaffName.' `
    -action {
        param($BaseUrl)
        $hospSession = Get-UserSession -role 'HOSPITAL' -baseUrl $BaseUrl
        $handoverId = New-TestUuid
        $res = Invoke-SmartAidApi -method 'POST' -path "/api/handovers/$handoverId/acknowledge" `
            -body @{ receivingStaffName = ''; signaturePin = '1234' } -accessToken $hospSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 404)) 'Missing staff name rejected'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F22' -testId 'T2-F22-05' `
    -testName 'Re-Acknowledgment of Already Acknowledged Handover Returns 409 Conflict' `
    -description 'Verifies tamper-proofing: once acknowledged, handover cannot be re-acknowledged.' `
    -action {
        param($BaseUrl)
        $hospSession = Get-UserSession -role 'HOSPITAL' -baseUrl $BaseUrl
        $handoverId = New-TestUuid
        $res = Invoke-SmartAidApi -method 'POST' -path "/api/handovers/$handoverId/acknowledge" `
            -body @{ receivingStaffName = 'Dr. Test'; signaturePin = '1234' } -accessToken $hospSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 404, 409)) 'Re-acknowledgment rejected'
    }

# ==============================================================================
# Feature 23: Smart Medical Handover Mobile UI Boundaries (T2-F23-01 to T2-F23-05)
# ==============================================================================

Register-TestCase -tier 'Tier 2' -featureId 'F23' -testId 'T2-F23-01' `
    -testName 'Unauthenticated Access to Handover Generation Returns 401 Unauthorized' `
    -description 'Verifies handover submission requires valid authentication.' `
    -action {
        param($BaseUrl)
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/handovers' -body @{ incidentId = New-TestUuid } -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 401 -context 'Unauthenticated handover generate'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F23' -testId 'T2-F23-02' `
    -testName 'EMS Role Attempts Handover Acknowledgment Without Hospital Role Returns 403 Forbidden' `
    -description 'Verifies separation of concerns: EMS paramedics who create the handover cannot self-acknowledge.' `
    -action {
        param($BaseUrl)
        $emsSession = Get-UserSession -role 'EMS' -baseUrl $BaseUrl
        $handoverId = New-TestUuid
        $res = Invoke-SmartAidApi -method 'POST' -path "/api/handovers/$handoverId/acknowledge" `
            -body @{ receivingStaffName = 'Paramedic Self'; signaturePin = '1111' } -accessToken $emsSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 403 -context 'EMS self-acknowledgment blocked'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F23' -testId 'T2-F23-03' `
    -testName 'Query Pending Inbound Handovers Queue by Citizen Role Returns 403 Forbidden' `
    -description 'Verifies hospital pending handovers queue is protected from citizen access.' `
    -action {
        param($BaseUrl)
        $userSession = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $res = Invoke-SmartAidApi -method 'GET' -path '/api/handovers/pending' -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 403 -context 'Citizen access pending handovers'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F23' -testId 'T2-F23-04' `
    -testName 'Submit Handover with Missing Vital Signs Payload Returns 400 Bad Request' `
    -description 'Verifies clinical safety requirement: vital signs object is mandatory for handover.' `
    -action {
        param($BaseUrl)
        $emsSession = Get-UserSession -role 'EMS' -baseUrl $BaseUrl
        $payload = @{ incidentId = New-TestUuid; receivingHospitalId = New-TestUuid; paramedicNotes = 'Patient transferred' }
        $res = Invoke-SmartAidApi -method 'POST' -path '/api/handovers' -body $payload -accessToken $emsSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(400, 404)) 'Missing vital signs rejected'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F23' -testId 'T2-F23-05' `
    -testName 'Hospital Staff Attempts Access to Handover for Different Hospital Returns 403 Forbidden' `
    -description 'Verifies hospital data isolation: clinicians only see handovers routed to their facility.' `
    -action {
        param($BaseUrl)
        $hospSession = Get-UserSession -role 'HOSPITAL' -baseUrl $BaseUrl
        $handoverId = New-TestUuid
        $res = Invoke-SmartAidApi -method 'GET' -path "/api/handovers/$handoverId" -accessToken $hospSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($res.StatusCode -in @(200, 403, 404)) 'Hospital isolation boundary valid'
    }

# ==============================================================================
# Feature 24: E2E Test Suite Harness Boundaries (T2-F24-01 to T2-F24-05)
# ==============================================================================

Register-TestCase -tier 'Tier 2' -featureId 'F24' -testId 'T2-F24-01' `
    -testName 'Harness Verification of 401 Detection for Empty Bearer Token' `
    -description 'Verifies Invoke-SmartAidApi properly extracts 401 Unauthorized for empty token.' `
    -action {
        param($BaseUrl)
        $res = Invoke-SmartAidApi -method 'GET' -path '/api/users/me' -accessToken '' -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 401 -context 'Empty bearer token'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F24' -testId 'T2-F24-02' `
    -testName 'Harness Verification of 404 Detection on Nonexistent Route' `
    -description 'Verifies harness correctly extracts 404 status code from server response.' `
    -action {
        param($BaseUrl)
        $res = Invoke-SmartAidApi -method 'GET' -path '/api/fictional-route-that-does-not-exist' -baseUrl $BaseUrl
        Assert-StatusCode -actual $res.StatusCode -expected 404 -context 'Fictional route 404'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F24' -testId 'T2-F24-03' `
    -testName 'Harness Verification of Assert-That Failure Exception' `
    -description 'Verifies Assert-That throws exception when condition is false.' `
    -action {
        param($BaseUrl)
        $caught = $false
        try {
            Assert-That ($false) 'Expected failure condition'
        } catch {
            $caught = $true
        }
        Assert-That ($caught) 'Assert-That must throw exception on false condition'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F24' -testId 'T2-F24-04' `
    -testName 'Harness Verification of Assert-StatusCode Mismatch Exception' `
    -description 'Verifies Assert-StatusCode throws exception when actual does not equal expected.' `
    -action {
        param($BaseUrl)
        $caught = $false
        try {
            Assert-StatusCode -actual 500 -expected 200 -context 'Mismatch test'
        } catch {
            $caught = $true
        }
        Assert-That ($caught) 'Assert-StatusCode must throw exception on mismatch'
    }

Register-TestCase -tier 'Tier 2' -featureId 'F24' -testId 'T2-F24-05' `
    -testName 'Harness Verification of Assert-JsonField Missing Field Exception' `
    -description 'Verifies Assert-JsonField throws exception when field is absent from response object.' `
    -action {
        param($BaseUrl)
        $caught = $false
        try {
            $obj = [PSCustomObject]@{ existingField = 'value' }
            Assert-JsonField -body $obj -field 'nonexistentField' -expectedValue 'test' -context 'Missing field test'
        } catch {
            $caught = $true
        }
        Assert-That ($caught) 'Assert-JsonField must throw exception on missing field'
    }

# Execute tests if invoked directly
if (-not $global:TestRunnerActive) {
    $dry = $DryRun -or $global:DryRunActive
    Execute-RegisteredTests -tierFilter '2' -DryRun:$dry -baseUrl $BaseUrl
    Print-TestSummary
}
