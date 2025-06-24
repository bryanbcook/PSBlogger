Param(
    [string]$code
)
$credential = Get-Content .\credentials.json | ConvertFrom-Json

Initialize-Blogger -$code