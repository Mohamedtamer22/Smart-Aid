# Smart Aid - Live Database Viewer & Inspector (V1)
$ErrorActionPreference = "Stop"

$DB_HOST = "127.0.0.1"
$DB_PORT = "5432"
$DB_NAME = "smartaid"
$DB_USER = "smartaid_user"
$DB_PASS = "smartaid-local-only-rotate-before-production-91!"

$env:PGPASSWORD = $DB_PASS

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  SMART AID V1 - LIVE DATABASE INSPECTOR (POSTGRESQL)       " -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Connecting to PostgreSQL at ${DB_HOST}:${DB_PORT}/${DB_NAME} as '${DB_USER}'...`n" -ForegroundColor Gray

$psqlPath = "psql"
if (!(Get-Command "psql" -ErrorAction SilentlyContinue)) {
    $candidates = @(
        "C:\Program Files\PostgreSQL\18\bin\psql.exe",
        "C:\Program Files\PostgreSQL\17\bin\psql.exe",
        "C:\Program Files\PostgreSQL\16\bin\psql.exe",
        "C:\Program Files\PostgreSQL\15\bin\psql.exe"
    )
    foreach ($cand in $candidates) {
        if (Test-Path $cand) {
            $psqlPath = $cand
            break
        }
    }
}

# Helper to run psql queries
function Run-Query($sql, $title) {
    Write-Host "--- $title ---" -ForegroundColor Green
    try {
        & $psqlPath -h $DB_HOST -p $DB_PORT -U $DB_USER -d $DB_NAME -c $sql
    } catch {
        Write-Host "Error running query: $_" -ForegroundColor Red
    }
    Write-Host ""
}

# 1. Total Tables & Row Counts
Run-Query @"
SELECT table_name, 
       (xpath('/row/cnt/text()', xml_count))[1]::text::int as approximate_row_count
FROM (
  SELECT table_name, 
         table_schema,
         query_to_xml(format('select count(*) as cnt from %I.%I', table_schema, table_name), false, true, '') as xml_count
  FROM information_schema.tables
  WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
) t
ORDER BY table_name;
"@ "1. SYSTEM TABLES & CURRENT RECORD COUNTS"

# 2. Registered Users & Roles
Run-Query @"
SELECT u.id, u.email, u.display_name, r.code as role_code, u.created_at
FROM users u
LEFT JOIN user_roles ur ON u.id = ur.user_id
LEFT JOIN roles r ON ur.role_id = r.id
ORDER BY u.created_at DESC;
"@ "2. REGISTERED USERS & ROLES"

# 3. Active Incidents & Statuses
Run-Query @"
SELECT i.id, et.code as emergency_type, i.status, i.priority, i.latitude, i.longitude, i.created_at
FROM incidents i
LEFT JOIN emergency_types et ON i.emergency_type_id = et.id
ORDER BY i.created_at DESC
LIMIT 5;
"@ "3. RECENT INCIDENTS (SOS EMERGENCY CALLS)"

# 4. Verified Hospitals & Critical Resources
Run-Query @"
SELECT id, name, latitude, longitude, verified, estimated_congestion
FROM hospitals
ORDER BY name ASC;
"@ "4. VERIFIED HOSPITALS DIRECTORY"

# 5. Ambulance Fleet Units
Run-Query @"
SELECT id, call_sign, status, latitude, longitude, updated_at
FROM ambulances
ORDER BY call_sign ASC;
"@ "5. OPERATIONAL AMBULANCE FLEET"

# 6. AED Devices (Automated External Defibrillators)
Run-Query @"
SELECT id, label, resource_type, availability_status, verified
FROM aed_devices
LIMIT 5;
"@ "6. PUBLIC AED LOCATIONS"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  GUI CONNECTION DETAILS (FOR PGADMIN, DBEAVER, VS CODE)    " -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Host:     $DB_HOST" -ForegroundColor White
Write-Host "Port:     $DB_PORT" -ForegroundColor White
Write-Host "Database: $DB_NAME" -ForegroundColor White
Write-Host "Username: $DB_USER" -ForegroundColor White
Write-Host "Password: $DB_PASS" -ForegroundColor White
Write-Host "============================================================`n" -ForegroundColor Cyan
