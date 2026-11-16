$adminBody = @{
    email = "demo.admin@smartaid.local"
    password = "SmartAidDemo2026!"
} | ConvertTo-Json

$login = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/login" -Method Post -Body $adminBody -ContentType "application/json"
$token = $login.accessToken

Write-Host "Admin JWT obtained: $($token.Substring(0, 25))..." -ForegroundColor Green

$headers = @{
    "Authorization" = "Bearer $token"
}

$overview = Invoke-RestMethod -Uri "http://localhost:8080/api/admin/overview" -Headers $headers
Write-Host "`n--- ADMIN SYSTEM OVERVIEW ---" -ForegroundColor Cyan
$overview | ConvertTo-Json

$users = Invoke-RestMethod -Uri "http://localhost:8080/api/admin/users" -Headers $headers
Write-Host "`n--- USERS COUNT: $($users.Count) ---" -ForegroundColor Cyan

$volunteers = Invoke-RestMethod -Uri "http://localhost:8080/api/admin/volunteers" -Headers $headers
Write-Host "`n--- VOLUNTEERS COUNT: $($volunteers.Count) ---" -ForegroundColor Cyan

$audit = Invoke-RestMethod -Uri "http://localhost:8080/api/admin/audit-logs" -Headers $headers
Write-Host "`n--- AUDIT LOGS COUNT: $($audit.Count) ---" -ForegroundColor Cyan

$analytics = Invoke-RestMethod -Uri "http://localhost:8080/api/analytics/dashboard" -Headers $headers
Write-Host "`n--- ANALYTICS DASHBOARD ---" -ForegroundColor Cyan
$analytics | ConvertTo-Json
