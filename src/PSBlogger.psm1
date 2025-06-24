Set-StrictMode -Version 2.0

if (!(Get-Module powershell-yaml)) {
    Import-Module powershell-yaml
}

# Get Functions
$private = Get-ChildItem -Path (Join-Path $PSScriptRoot Private) -Include *.ps1 -File -Recurse
$public = Get-ChildItem -Path (Join-Path $PSScriptRoot Public) -Include *.ps1 -File -Recurse

# Dot source to scope
# Private must be sourced first - usage in public functions during load
($private + $public) | ForEach-Object {
    try {
        Write-Verbose "Loading $($_.FullName)"
        . $_.FullName
    }
    catch {
        Write-Warning $_.Exception.Message
    }
}

$publicFunctions = $public | ForEach-Object { $_.Name.Replace(".ps1","") }
Export-ModuleMember -Function $publicFunctions

# ensure Tls12
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$BloggerSession = Get-BloggerSession
$BloggerSession | Out-String | Write-Verbose
New-Variable -Name BloggerSession -Value $BloggerSession -Scope Script -Force
