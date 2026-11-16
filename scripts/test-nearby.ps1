$loginBody = @{
    email = "demo.volunteer@smartaid.local"
    password = "SmartAidDemo2026!"
} | ConvertTo-Json

$login = Invoke-RestMethod -Uri "http://localhost:8080/api/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
$token = $login.accessToken

Write-Host "JWT obtained successfully: $($token.Substring(0, 25))..." -ForegroundColor Green

$headers = @{
    "Authorization" = "Bearer $token"
}

$dashboard = Invoke-RestMethod -Uri "http://localhost:8080/api/volunteers/dashboard" -Headers $headers
Write-Host "`n--- VOLUNTEER DASHBOARD ---" -ForegroundColor Cyan
$dashboard | ConvertTo-Json -Depth 5

$nearby = Invoke-RestMethod -Uri "http://localhost:8080/api/volunteers/incidents/nearby" -Headers $headers
Write-Host "`n--- NEARBY INCIDENTS COUNT: $($nearby.Count) ---" -ForegroundColor Cyan
$nearby | ConvertTo-Json -Depth 5
