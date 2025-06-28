
function Get-CredentialCache()
{
    (Get-Content $BloggerSession.CredentialCache) | ConvertFrom-Json
}

function Set-CredentialCache
{
    Param(
        [string]$clientId,
        [string]$clientSecret,
        [psobject]$refreshToken,
        [psobject]$token
    )

    $cache = @{
        client_id=$clientId
        client_secret=$clientSecret
        access_token=$token.access_token
        refresh_token=$refreshToken.refresh_token
    }

    $parentFolder = Split-Path $BloggerSession.CredentialCache -Parent

    if (-not (Test-Path $parentFolder)) {
        Write-Verbose "Creating credential cache folder: $parentFolder"
        New-Item -ItemType Directory -Path $parentFolder -Force
    }

    Write-Verbose "Writing access + refresh tokens to credential cache..."
    Set-Content $BloggerSession.CredentialCache -Value ($cache | ConvertTo-Json) -Force

    # reset previously loaded auth tokens / force reload + validation for next api call
    $BloggerSession.AccessToken = $null
    $BloggerSession.RefreshToken = $null
}

function Update-CredentialCache
{
    param(
        [psobject]$token
    )

    Write-Verbose "Updating credential cache with: $token"

    $credentialCache = Get-CredentialCache
    $credentialCache.access_token = $token.access_token

    Write-Verbose "Updating session access token..."
    $BloggerSession.AccessToken = $token.access_token

    Set-Content $BloggerSession.CredentialCache -Value ($credentialCache | ConvertTo-Json)

}

function Assert-CredentialCache
{
    if ($null -eq $BloggerSession.AccessToken)
    {
        Write-Verbose "Assert-CredentialCache: Initializing session with cached access+refresh tokens..."
        if (-not (Test-Path $BloggerSession.CredentialCache)) {
            Write-Error "Cached credentials not found. Please call Initialize-Blogger"
            # todo: verify ErrorActionPreference is set
            throw "Cached credentials not found. Please call Initialize-Blogger"
        }

        $cache = Get-CredentialCache

        $BloggerSession.AccessToken  = $cache.access_token
        $BloggerSession.RefreshToken = $cache.refresh_token
    }
}