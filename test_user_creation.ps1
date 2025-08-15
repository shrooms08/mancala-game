# Test script for user creation endpoint
$body = @{
    userPubkey = "test_wallet_12345678901234567890123456789012"
    username = "TestPlayer"
    displayName = "Test Player"
} | ConvertTo-Json

Write-Host "Testing user creation endpoint..."
Write-Host "Request body: $body"

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/users" -Method POST -Body $body -ContentType "application/json"
    Write-Host "✅ Success! Response:"
    $response | ConvertTo-Json -Depth 10
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response body: $responseBody"
    }
}
