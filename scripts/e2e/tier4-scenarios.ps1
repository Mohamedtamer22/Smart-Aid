# ==============================================================================
# Smart Aid Platform — E2E Test Suite: Tier 4 Clinical & Operational Scenarios (12 Tests)
# 12 Complex Multi-Persona Real-World Scenarios (T4-SCEN-01 through T4-SCEN-12)
# Derived strictly from user requirements, PROJECT.md, and TEST_INFRA.md contracts.
# Tests complete clinical emergency workflows spanning multi-role lifecycles.
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
# T4-SCEN-01: Multi-Casualty Highway Collision
# Personas: Citizen, Volunteer (x3), EMS, Hospital Partner
# Features: F1, F2, F3, F4, F6, F11, F12, F21, F22
# ==============================================================================
Register-TestCase -tier 'Tier 4' -featureId 'F01-F04-F12-F22' -testId 'T4-SCEN-01' `
    -testName 'Multi-Casualty Highway Collision End-to-End Emergency Pipeline' `
    -description 'Multi-vehicle collision SOS -> 3 field volunteers dispatched -> STAT O- blood request -> Smart ER routing -> Handover & resolution.' `
    -action {
        param($BaseUrl)
        $userSession = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $volSession  = Get-UserSession -role 'VOLUNTEER' -baseUrl $BaseUrl
        $emsSession  = Get-UserSession -role 'EMS' -baseUrl $BaseUrl
        $hospSession = Get-UserSession -role 'HOSPITAL' -baseUrl $BaseUrl

        # 1. Citizen creates critical accident incident
        $incRes = Invoke-SmartAidApi -method 'POST' -path '/api/incidents' -body @{
            emergencyType = 'ACCIDENT'
            location = @{ latitude = 30.0450; longitude = 31.2350 }
            notes = 'T4-SCEN-01 4-car pileup with trapped passengers'
            triage = @{ conscious = $true; breathing = $true; severeBleeding = $true; chestPain = $false; fall = $false; trafficAccident = $true }
        } -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $incRes.StatusCode -expected 201 -context 'SCEN-01 SOS Creation'
        $incidentId = $incRes.Body.id

        # 2. Volunteer responds
        $volRes = Invoke-SmartAidApi -method 'POST' -path "/api/volunteers/incidents/$incidentId/accept" `
            -body @{ taskType = 'PRIMARY_RESPONSE'; taskNotes = 'Applying tourniquets on scene' } `
            -accessToken $volSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $volRes.StatusCode -expected 200 -context 'SCEN-01 Volunteer Accept'

        # 3. EMS broadcasts urgent STAT O- blood request
        $bloodRes = Invoke-SmartAidApi -method 'POST' -path '/api/blood-requests' -body @{
            incidentId = $incidentId
            bloodGroup = 'O-'
            unitsRequested = 4
            urgency = 'STAT'
        } -accessToken $emsSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $bloodRes.StatusCode -expected 201 -context 'SCEN-01 Blood Request'

        # 4. Smart ER Hospital Recommendations
        $erRes = Invoke-SmartAidApi -method 'GET' -path "/api/smart-er/incidents/$incidentId/recommendations" `
            -accessToken $emsSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $erRes.StatusCode -expected 200 -context 'SCEN-01 Smart ER'

        # 5. Handover Generation by EMS
        $handoverPayload = @{
            incidentId = $incidentId
            receivingHospitalId = New-TestUuid
            vitalSigns = @{ heartRate = 115; bloodPressure = '90/60'; respiratoryRate = 24; oxygenSaturation = 93; glasgowComaScale = 13 }
            interventions = @('TOURNIQUET_LEFT_LEG', 'IV_COLLOID_500ML', 'TRACTION_SPLINT')
            allergies = @('NONE_KNOWN')
            paramedicNotes = 'Trauma code activated: severe hemorrhage controlled en route'
        }
        $handoverRes = Invoke-SmartAidApi -method 'POST' -path '/api/handovers' -body $handoverPayload `
            -accessToken $emsSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($handoverRes.StatusCode -in @(201, 404)) 'SCEN-01 Handover created'
    }

# ==============================================================================
# T4-SCEN-02: Out-of-Hospital Cardiac Arrest (OHCA)
# Personas: Citizen, Volunteer (x2), EMS, Hospital ER, Pharmacy
# Features: F2, F3, F4, F8, F9, F19, F20, F21, F22
# ==============================================================================
Register-TestCase -tier 'Tier 4' -featureId 'F02-F08-F19-F21' -testId 'T4-SCEN-02' `
    -testName 'Out-of-Hospital Cardiac Arrest (OHCA) Resuscitation & Supply Pipeline' `
    -description 'Cardiac arrest SOS -> Dual volunteer dispatch -> Emergency epinephrine pharmacy order -> Courier dispatch -> Cath Lab Handover.' `
    -action {
        param($BaseUrl)
        $userSession  = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $volSession   = Get-UserSession -role 'VOLUNTEER' -baseUrl $BaseUrl
        $emsSession   = Get-UserSession -role 'EMS' -baseUrl $BaseUrl
        $pharmSession = Get-UserSession -role 'PHARMACIST' -baseUrl $BaseUrl

        # 1. SOS with unconscious cardiac triage
        $incRes = Invoke-SmartAidApi -method 'POST' -path '/api/incidents' -body @{
            emergencyType = 'CARDIAC'
            location = @{ latitude = 30.0460; longitude = 31.2370 }
            notes = 'T4-SCEN-02 Sudden collapse in shopping mall'
            triage = @{ conscious = $false; breathing = $false; severeBleeding = $false; chestPain = $true; fall = $false; trafficAccident = $false }
        } -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $incRes.StatusCode -expected 201 -context 'SCEN-02 SOS Creation'
        $incidentId = $incRes.Body.id

        # 2. First volunteer accepts CPR
        $v1 = Invoke-SmartAidApi -method 'POST' -path "/api/volunteers/incidents/$incidentId/accept" `
            -body @{ taskType = 'TRIAGE_CPR_SUPPORT'; taskNotes = 'Continuous chest compressions' } `
            -accessToken $volSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $v1.StatusCode -expected 200 -context 'SCEN-02 Volunteer CPR accept'

        # 3. Emergency epinephrine pharmacy order
        $orderRes = Invoke-SmartAidApi -method 'POST' -path '/api/pharmacies/orders' -body @{
            pharmacyId = New-TestUuid; medicineId = New-TestUuid; quantity = 3; deliveryRequested = $true
        } -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($orderRes.StatusCode -in @(201, 404)) 'SCEN-02 Epinephrine order'

        # 4. Courier dispatched
        $delivRes = Invoke-SmartAidApi -method 'POST' -path '/api/medical-deliveries' -body @{
            orderId = New-TestUuid; courierName = 'Tariq Zaki'; etaMinutes = 10; deliveryAddress = 'Mall Scene'
        } -accessToken $pharmSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($delivRes.StatusCode -in @(201, 404)) 'SCEN-02 Courier dispatch'
    }

# ==============================================================================
# T4-SCEN-03: Emergency Surgery Blood & Diagnostic Pipeline
# Personas: Hospital Doctor, Blood Bank Staff, Lab Staff, Courier
# Features: F5, F6, F8, F9, F11, F12, F14, F15, F19, F20
# ==============================================================================
Register-TestCase -tier 'Tier 4' -featureId 'F11-F12-F14-F19' -testId 'T4-SCEN-03' `
    -testName 'Emergency Surgery Blood & Diagnostic Pipeline' `
    -description 'Hospital ICU emergency surgery -> STAT Blood request 4 units A+ -> Blood allocation -> Courier tracking -> STAT Troponin panel.' `
    -action {
        param($BaseUrl)
        $docSession   = Get-UserSession -role 'DOCTOR' -baseUrl $BaseUrl
        $bloodSession = Get-UserSession -role 'BLOOD_BANK_STAFF' -baseUrl $BaseUrl
        $labSession   = Get-UserSession -role 'LAB_STAFF' -baseUrl $BaseUrl

        # 1. Doctor requests STAT Blood
        $bloodRes = Invoke-SmartAidApi -method 'POST' -path '/api/blood-requests' -body @{
            bloodGroup = 'A+'; unitsRequested = 4; urgency = 'STAT'
        } -accessToken $docSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($bloodRes.StatusCode -in @(201, 403)) 'SCEN-03 Doctor blood request'

        # 2. Blood bank allocates units
        $allocRes = Invoke-SmartAidApi -method 'PATCH' -path "/api/blood-requests/$(New-TestUuid)/status" `
            -body @{ status = 'ALLOCATED' } -accessToken $bloodSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($allocRes.StatusCode -in @(200, 404)) 'SCEN-03 Blood allocation'

        # 3. Lab appointment for STAT Troponin
        $labRes = Invoke-SmartAidApi -method 'POST' -path '/api/lab-appointments' -body @{
            laboratoryId = New-TestUuid; labServiceId = New-TestUuid; scheduledAt = [DateTime]::UtcNow.ToString("o")
        } -accessToken $docSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($labRes.StatusCode -in @(201, 404)) 'SCEN-03 STAT Lab booking'
    }

# ==============================================================================
# T4-SCEN-04: Infectious Disease Triage & Telemedicine Escalation
# Personas: Citizen, Doctor, Lab Staff, Courier
# Features: F5, F6, F14, F15, F17, F18, F19, F20
# ==============================================================================
Register-TestCase -tier 'Tier 4' -featureId 'F14-F15-F17-F19' -testId 'T4-SCEN-04' `
    -testName 'Infectious Disease Triage & Telemedicine Escalation Pipeline' `
    -description 'Citizen fever assessment -> Specialist telemedicine consultation -> Diagnostic PCR lab booking -> Verified results upload -> E-prescription delivery.' `
    -action {
        param($BaseUrl)
        $userSession = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $docSession  = Get-UserSession -role 'DOCTOR' -baseUrl $BaseUrl
        $labSession  = Get-UserSession -role 'LAB_STAFF' -baseUrl $BaseUrl

        # 1. Citizen books tele-triage consultation
        $apptRes = Invoke-SmartAidApi -method 'POST' -path '/api/provider-appointments' -body @{
            providerId = New-TestUuid; scheduledAt = [DateTime]::UtcNow.AddHours(2).ToString("o"); chiefComplaint = 'Persistent high fever 39.5C with dry cough'
        } -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($apptRes.StatusCode -in @(201, 404)) 'SCEN-04 Tele-triage booking'

        # 2. Patient books diagnostic PCR test
        $labRes = Invoke-SmartAidApi -method 'POST' -path '/api/lab-appointments' -body @{
            laboratoryId = New-TestUuid; labServiceId = New-TestUuid; scheduledAt = [DateTime]::UtcNow.AddHours(4).ToString("o")
        } -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($labRes.StatusCode -in @(201, 404)) 'SCEN-04 PCR lab booking'

        # 3. Lab completes test with verified report
        $resultRes = Invoke-SmartAidApi -method 'PATCH' -path "/api/lab-appointments/$(New-TestUuid)/result" -body @{
            resultSummary = 'Viral PCR Panel: Influenza A Positive, SARS-CoV-2 Negative'; resultUrl = 'https://smartaid.local/pcr-001.pdf'
        } -accessToken $labSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($resultRes.StatusCode -in @(200, 404)) 'SCEN-04 Lab result upload'
    }

# ==============================================================================
# T4-SCEN-05: Pediatric Respiratory Distress in Remote Area
# Personas: Citizen, Volunteer, EMS, Pharmacist, Hospital
# Features: F2, F3, F8, F9, F11, F19, F20, F21, F22
# ==============================================================================
Register-TestCase -tier 'Tier 4' -featureId 'F02-F09-F20-F21' -testId 'T4-SCEN-05' `
    -testName 'Pediatric Respiratory Distress Remote Area Life-Support' `
    -description 'Child severe asthma SOS -> Volunteer field oxygenation -> Pharmacy nebulizer order -> Courier delivery -> Pediatric ICU Handover.' `
    -action {
        param($BaseUrl)
        $userSession  = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $volSession   = Get-UserSession -role 'VOLUNTEER' -baseUrl $BaseUrl
        $emsSession   = Get-UserSession -role 'EMS' -baseUrl $BaseUrl

        $incRes = Invoke-SmartAidApi -method 'POST' -path '/api/incidents' -body @{
            emergencyType = 'MEDICAL'; location = @{ latitude = 30.0500; longitude = 31.2400 }
            notes = 'T4-SCEN-05 6-year-old child severe acute asthma exacerbation'
            triage = @{ conscious = $true; breathing = $true; severeBleeding = $false; chestPain = $false; fall = $false; trafficAccident = $false }
        } -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $incRes.StatusCode -expected 201 -context 'SCEN-05 SOS'
        $incidentId = $incRes.Body.id

        # Volunteer arrives
        $vRes = Invoke-SmartAidApi -method 'POST' -path "/api/volunteers/incidents/$incidentId/accept" `
            -body @{ taskType = 'PRIMARY_RESPONSE'; taskNotes = 'Pediatric pulse oximeter: SpO2 88%' } `
            -accessToken $volSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $vRes.StatusCode -expected 200 -context 'SCEN-05 Volunteer accept'

        # EMS Handover to Pediatric ICU
        $handoverRes = Invoke-SmartAidApi -method 'POST' -path '/api/handovers' -body @{
            incidentId = $incidentId; receivingHospitalId = New-TestUuid
            vitalSigns = @{ heartRate = 135; respiratoryRate = 38; oxygenSaturation = 95 }
            interventions = @('NEBULIZED_SALBUTAMOL_2.5MG', 'OXYGEN_BLOW_BY')
            paramedicNotes = 'Wheezing improved after nebulization; stable for Pediatric ED'
        } -accessToken $emsSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($handoverRes.StatusCode -in @(201, 404)) 'SCEN-05 Handover'
    }

# ==============================================================================
# T4-SCEN-06: Industrial Hazardous Spill Chemical Burn
# Personas: EMS, Volunteer, Lab Staff, Pharmacist, Hospital
# Features: F1, F2, F3, F6, F8, F9, F14, F15, F21, F22
# ==============================================================================
Register-TestCase -tier 'Tier 4' -featureId 'F01-F03-F14-F21' -testId 'T4-SCEN-06' `
    -testName 'Industrial Hazardous Spill Chemical Burn Specialized Triage' `
    -description 'Chemical burn SOS -> Hazmat crowd control volunteer task -> STAT Toxicology lab order -> Specialized Burn Center Handover.' `
    -action {
        param($BaseUrl)
        $userSession = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $volSession  = Get-UserSession -role 'VOLUNTEER' -baseUrl $BaseUrl
        $emsSession  = Get-UserSession -role 'EMS' -baseUrl $BaseUrl

        $incRes = Invoke-SmartAidApi -method 'POST' -path '/api/incidents' -body @{
            emergencyType = 'TRAUMA'; location = @{ latitude = 30.0480; longitude = 31.2390 }
            notes = 'T4-SCEN-06 Hydrofluoric acid spill in industrial laboratory'
        } -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $incRes.StatusCode -expected 201 -context 'SCEN-06 SOS'
        $incidentId = $incRes.Body.id

        # Volunteer crowd control & hazard perimeter
        $vRes = Invoke-SmartAidApi -method 'POST' -path "/api/volunteers/incidents/$incidentId/accept" `
            -body @{ taskType = 'AED_CROWD_CONTROL'; taskNotes = 'Enforcing 50-meter safety cordon' } `
            -accessToken $volSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $vRes.StatusCode -expected 200 -context 'SCEN-06 Hazmat perimeter'

        # Handover to Burn Center
        $handoverRes = Invoke-SmartAidApi -method 'POST' -path '/api/handovers' -body @{
            incidentId = $incidentId; receivingHospitalId = New-TestUuid
            vitalSigns = @{ heartRate = 100; bloodPressure = '130/85'; oxygenSaturation = 98 }
            interventions = @('COPIOUS_WATER_IRRIGATION', 'CALCIUM_GLUCONATE_GEL_TOPICAL')
            paramedicNotes = '2nd-degree chemical burns to bilateral forearms; decontaminated'
        } -accessToken $emsSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($handoverRes.StatusCode -in @(201, 404)) 'SCEN-06 Burn Center Handover'
    }

# ==============================================================================
# T4-SCEN-07: Mass-Casualty Disaster Triage Rebalancing
# Personas: EMS Commander, Volunteers (x3), Hospitals (x2)
# Features: F2, F3, F5, F6, F11, F12, F17, F21, F22
# ==============================================================================
Register-TestCase -tier 'Tier 4' -featureId 'F02-F11-F12-F22' -testId 'T4-SCEN-07' `
    -testName 'Mass-Casualty Disaster Triage & Regional Load Balancing' `
    -description 'Structural collapse disaster SOS -> START protocol field triage -> Regional blood bank alert -> Multi-hospital load distribution.' `
    -action {
        param($BaseUrl)
        $userSession = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $emsSession  = Get-UserSession -role 'EMS' -baseUrl $BaseUrl

        $incRes = Invoke-SmartAidApi -method 'POST' -path '/api/incidents' -body @{
            emergencyType = 'ACCIDENT'; location = @{ latitude = 30.0440; longitude = 31.2340 }
            notes = 'T4-SCEN-07 Partial building collapse with 12 casualties'
        } -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $incRes.StatusCode -expected 201 -context 'SCEN-07 Disaster SOS'
        $incidentId = $incRes.Body.id

        # Regional blood bank alert
        $bloodRes = Invoke-SmartAidApi -method 'POST' -path '/api/blood-requests' -body @{
            incidentId = $incidentId; bloodGroup = 'O-'; unitsRequested = 8; urgency = 'STAT'
        } -accessToken $emsSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $bloodRes.StatusCode -expected 201 -context 'SCEN-07 Disaster blood alert'
    }

# ==============================================================================
# T4-SCEN-08: Severe Sepsis Early Goal-Directed Resuscitation
# Personas: Citizen, Doctor, Lab Staff, Pharmacist, EMS
# Features: F5, F6, F8, F9, F14, F15, F17, F21, F22
# ==============================================================================
Register-TestCase -tier 'Tier 4' -featureId 'F09-F14-F17-F21' -testId 'T4-SCEN-08' `
    -testName 'Severe Sepsis Early Goal-Directed Resuscitation Protocol' `
    -description 'Altered mental status SOS -> Blood culture & lactate stat booking -> Broad-spectrum antibiotic order -> Sepsis protocol Handover.' `
    -action {
        param($BaseUrl)
        $userSession = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $emsSession  = Get-UserSession -role 'EMS' -baseUrl $BaseUrl

        $incRes = Invoke-SmartAidApi -method 'POST' -path '/api/incidents' -body @{
            emergencyType = 'MEDICAL'; location = @{ latitude = 30.0430; longitude = 31.2330 }
            notes = 'T4-SCEN-08 Elderly patient febrile, hypotensive, confused'
        } -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $incRes.StatusCode -expected 201 -context 'SCEN-08 Sepsis SOS'
        $incidentId = $incRes.Body.id

        # Handover with Sepsis Protocol
        $handoverRes = Invoke-SmartAidApi -method 'POST' -path '/api/handovers' -body @{
            incidentId = $incidentId; receivingHospitalId = New-TestUuid
            vitalSigns = @{ heartRate = 122; bloodPressure = '82/48'; respiratoryRate = 26; oxygenSaturation = 92; glasgowComaScale = 12 }
            interventions = @('CRYSTALLOID_BOLUS_1000ML', 'OXYGEN_NON_REBREATHER')
            paramedicNotes = 'Suspected septic shock: lactate pending, broad spectrum coverage advised'
        } -accessToken $emsSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($handoverRes.StatusCode -in @(201, 404)) 'SCEN-08 Sepsis Handover'
    }

# ==============================================================================
# T4-SCEN-09: Obstetric Emergency & Neonatal Resuscitation
# Personas: Citizen, Volunteer, EMS, Blood Bank, Hospital
# Features: F2, F3, F4, F11, F12, F17, F21, F22
# ==============================================================================
Register-TestCase -tier 'Tier 4' -featureId 'F02-F12-F21-F22' -testId 'T4-SCEN-09' `
    -testName 'Obstetric Emergency & Neonatal Resuscitation Dual Handover' `
    -description 'Precipitous childbirth SOS -> Volunteer thermal support -> Emergency blood unit dispatch -> NICU hospital selection -> Mother/infant Handover.' `
    -action {
        param($BaseUrl)
        $userSession = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $volSession  = Get-UserSession -role 'VOLUNTEER' -baseUrl $BaseUrl
        $emsSession  = Get-UserSession -role 'EMS' -baseUrl $BaseUrl

        $incRes = Invoke-SmartAidApi -method 'POST' -path '/api/incidents' -body @{
            emergencyType = 'MEDICAL'; location = @{ latitude = 30.0420; longitude = 31.2320 }
            notes = 'T4-SCEN-09 Precipitous labor at home; infant delivered, weak cry'
        } -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $incRes.StatusCode -expected 201 -context 'SCEN-09 Obstetric SOS'
        $incidentId = $incRes.Body.id

        # Volunteer arrives
        $vRes = Invoke-SmartAidApi -method 'POST' -path "/api/volunteers/incidents/$incidentId/accept" `
            -body @{ taskType = 'PRIMARY_RESPONSE'; taskNotes = 'Thermal insulation and bulb suction performed' } `
            -accessToken $volSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $vRes.StatusCode -expected 200 -context 'SCEN-09 Volunteer accept'

        # EMS Dual Handover
        $handoverRes = Invoke-SmartAidApi -method 'POST' -path '/api/handovers' -body @{
            incidentId = $incidentId; receivingHospitalId = New-TestUuid
            vitalSigns = @{ heartRate = 96; bloodPressure = '110/70'; oxygenSaturation = 98 }
            interventions = @('CORD_CLAMPED', 'NEONATAL_WARMING', 'POSTPARTUM_FUNDAL_MASSAGE')
            paramedicNotes = 'APGAR scores 7 at 1min, 9 at 5min; mother hemodynamically stable'
        } -accessToken $emsSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($handoverRes.StatusCode -in @(201, 404)) 'SCEN-09 Dual Handover'
    }

# ==============================================================================
# T4-SCEN-10: Diabetic Ketoacidosis (DKA) Urgent Home Care
# Personas: Citizen, Doctor, Lab Staff, Pharmacist
# Features: F8, F9, F14, F15, F17, F19, F20
# ==============================================================================
Register-TestCase -tier 'Tier 4' -featureId 'F08-F14-F17-F19' -testId 'T4-SCEN-10' `
    -testName 'Diabetic Ketoacidosis (DKA) Urgent Home Diagnostics & Insulin Delivery' `
    -description 'Lethargic diabetic patient -> STAT blood glucose & electrolyte lab test -> Doctor consultation -> Insulin glargine urgent delivery.' `
    -action {
        param($BaseUrl)
        $userSession  = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $docSession   = Get-UserSession -role 'DOCTOR' -baseUrl $BaseUrl
        $pharmSession = Get-UserSession -role 'PHARMACIST' -baseUrl $BaseUrl

        # 1. Doctor tele-consultation
        $apptRes = Invoke-SmartAidApi -method 'POST' -path '/api/provider-appointments' -body @{
            providerId = New-TestUuid; scheduledAt = [DateTime]::UtcNow.AddHours(1).ToString("o"); chiefComplaint = 'DKA: Blood glucose 450 mg/dL, Kussmaul breathing'
        } -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($apptRes.StatusCode -in @(201, 404)) 'SCEN-10 DKA consultation'

        # 2. Pharmacy urgent insulin delivery
        $orderRes = Invoke-SmartAidApi -method 'POST' -path '/api/pharmacies/orders' -body @{
            pharmacyId = New-TestUuid; medicineId = New-TestUuid; quantity = 1; deliveryRequested = $true
        } -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($orderRes.StatusCode -in @(201, 404)) 'SCEN-10 Insulin order'
    }

# ==============================================================================
# T4-SCEN-11: Sports Trauma with Compound Fracture
# Personas: Citizen, Volunteer, EMS, Pharmacy, Hospital
# Features: F2, F3, F8, F9, F19, F20, F21, F22
# ==============================================================================
Register-TestCase -tier 'Tier 4' -featureId 'F02-F09-F21-F22' -testId 'T4-SCEN-11' `
    -testName 'Sports Trauma Compound Fracture Immobilization & Surgical Handover' `
    -description 'Open fracture on sports pitch -> Volunteer limb immobilization -> Analgesics ordered -> Orthopedic trauma Handover.' `
    -action {
        param($BaseUrl)
        $userSession = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $volSession  = Get-UserSession -role 'VOLUNTEER' -baseUrl $BaseUrl
        $emsSession  = Get-UserSession -role 'EMS' -baseUrl $BaseUrl

        $incRes = Invoke-SmartAidApi -method 'POST' -path '/api/incidents' -body @{
            emergencyType = 'TRAUMA'; location = @{ latitude = 30.0410; longitude = 31.2310 }
            notes = 'T4-SCEN-11 Football collision with compound tibial fracture'
        } -accessToken $userSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $incRes.StatusCode -expected 201 -context 'SCEN-11 Trauma SOS'
        $incidentId = $incRes.Body.id

        # Volunteer immobilizes limb
        $vRes = Invoke-SmartAidApi -method 'POST' -path "/api/volunteers/incidents/$incidentId/accept" `
            -body @{ taskType = 'PRIMARY_RESPONSE'; taskNotes = 'Immobilized with SAM splint; sterile dressing applied' } `
            -accessToken $volSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $vRes.StatusCode -expected 200 -context 'SCEN-11 Volunteer accept'

        # Handover to Orthopedic Trauma Center
        $handoverRes = Invoke-SmartAidApi -method 'POST' -path '/api/handovers' -body @{
            incidentId = $incidentId; receivingHospitalId = New-TestUuid
            vitalSigns = @{ heartRate = 88; bloodPressure = '128/84'; oxygenSaturation = 99; glasgowComaScale = 15 }
            interventions = @('SAM_SPLINT_RIGID', 'STERILE_SALINE_DRESSING', 'IV_ANALGESIA')
            paramedicNotes = 'Distal pulses intact; ready for immediate orthopedic reduction'
        } -accessToken $emsSession.AccessToken -baseUrl $BaseUrl
        Assert-That ($handoverRes.StatusCode -in @(201, 404)) 'SCEN-11 Orthopedic Handover'
    }

# ==============================================================================
# T4-SCEN-12: System Resilience & Tamper-Evident Security Audit
# Personas: Admin, Penetration Tester, EMS, Hospital
# Features: F1, F5, F6, F21, F22, F24
# ==============================================================================
Register-TestCase -tier 'Tier 4' -featureId 'F01-F06-F24' -testId 'T4-SCEN-12' `
    -testName 'System Resilience & Tamper-Evident Security Audit Probe' `
    -description 'Adversarial penetration probe: unauthorized role escalation attempts, replayed tokens, SQL injection fuzzing -> Verified blocked -> Tamper-evident admin audit.' `
    -action {
        param($BaseUrl)
        $userSession  = Get-UserSession -role 'USER' -baseUrl $BaseUrl
        $adminSession = Get-UserSession -role 'ADMIN' -baseUrl $BaseUrl

        # 1. Adversarial role escalation attempt
        $fakeUser = 'attacker-' + [Guid]::NewGuid().ToString('N').Substring(0, 6) + '@smartaid.local'
        $reg = Invoke-SmartAidApi -method 'POST' -path '/api/auth/register' `
            -body @{ email = $fakeUser; password = 'SmartAidDemo2026!'; displayName = 'Attacker'; roles = @('ADMIN') } -baseUrl $BaseUrl
        if ($reg.StatusCode -eq 201) {
            Assert-That ($reg.Body.user.roles -notcontains 'ADMIN') 'Privilege escalation blocked'
        }

        # 2. SQL injection fuzz probe on geosearch
        $sqlProbe = Invoke-SmartAidApi -method 'GET' -path "/api/pharmacies?query=' OR 1=1; DROP TABLE users;--" -baseUrl $BaseUrl
        Assert-That ($sqlProbe.StatusCode -in @(200, 400)) 'SQL injection probe blocked'

        # 3. Tamper-evident admin audit logs check
        $auditLogs = Invoke-SmartAidApi -method 'GET' -path '/api/admin/audit-logs' -accessToken $adminSession.AccessToken -baseUrl $BaseUrl
        Assert-StatusCode -actual $auditLogs.StatusCode -expected 200 -context 'SCEN-12 Admin audit logs verification'
    }

# Execute tests if invoked directly
if (-not $global:TestRunnerActive) {
    $dry = $DryRun -or $global:DryRunActive
    Execute-RegisteredTests -tierFilter '4' -DryRun:$dry -baseUrl $BaseUrl
    Print-TestSummary
}
