function Get-GoogleAccessToken
{
    param(
        [Parameter(Mandatory=$true)]
        [string]$code,

        [Parameter()]
        [string]$clientId = "284606892422-ribvo7oodlbtd70e8onn8rg4hm58mluj.apps.googleusercontent.com",

        [Parameter()]
        [string]$clientSecret = "PUK0j9ig-GHcSByQao2i1aIa",

        [Parameter()]
        [string]$redirectUri = "http://localhost/oauth2callback"
    )

    # url-encode code
    $code = [System.Web.HttpUtility]::UrlEncode($code)

    # construct form-body
    $body = "code=$code&client_id=$clientId&client_secret=$clientSecret&redirect_uri=$redirectUri&grant_type=authorization_code"

    try {

        Write-Verbose "Get-GoogleAccessToken: Fetching Access Token with short-lived expiry..."

        $requestUri = "https://www.googleapis.com/oauth2/v4/token"

        $tokens = Invoke-RestMethod -Uri $requestUri -Method POST -Body $body -ContentType "application/x-www-form-urlencoded" -Verbose:$false
        
        $tokens
    }
    catch {
        Write-Error $_.ToString()
    }
}

function Update-GoogleAccessToken
{
    param(
        [Parameter()]
        [string]$clientId = "284606892422-ribvo7oodlbtd70e8onn8rg4hm58mluj.apps.googleusercontent.com",

        [Parameter()]
        [string]$clientSecret = "PUK0j9ig-GHcSByQao2i1aIa",

        [Parameter()]
        [string]$refreshToken
    )

    $body = "client_id=$clientId&client_secret=$clientSecret&refresh_token=$refreshToken&grant_type=refresh_token"

    $requestUri = "https://www.googleapis.com/oauth2/v4/token"

    Write-Verbose "Update-GoogleAccessToken: Upgrading token using refresh-token..."

    $tokens = Invoke-RestMethod -Uri $requestUri -Method POST -Body $body -ContentType "application/x-www-form-urlencoded"

    Write-Verbose "Update-GoogleAccessToken: Received token: $tokens"

    $tokens
}


function Test-GoogleAccessToken
{
    param(
        [string]$accessToken
    )

    try {
        Write-Verbose "Test-GoogleAccessToken: Validating access-token"

        $uri = "https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=$accessToken"
        Invoke-RestMethod -Uri $uri -Verbose:$false
        Write-Verbose "Test-GoogleAccessToken: Valid"
        $true
    }
    catch {
        Write-Verbose "Test-GoogleAccessToken: Access token is not valid"
        $false
    }
}