$credentialCache = Get-Content $env:userprofile\.psblogger\credentialcache.json -Raw | ConvertFrom-Json

$uri = "https://oauth2.googleapis.com/tokeninfo?access_token=$($credentialCache.access_token)"

try {
  $tokenInfo = Invoke-RestMethod -Uri $uri
  $expiry = [System.DateTimeOffset]::FromUnixTimeSeconds($tokenInfo.exp).LocalDateTime
  if ($expiry -lt (Get-Date)) {
      Write-Host "Token has expired!"
  } else {
      Write-Host "Token expires at $expiry ($([int]($tokenInfo.expires_in/60)) minutes)"
  }  
}
catch {
  Write-Host "Error occurred while checking token expiry: $_"
}
