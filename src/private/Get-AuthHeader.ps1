function Get-AuthHeader()
{
    Assert-CredentialCache

    if (!(Test-GoogleAccessToken $BloggerSession.AccessToken))
    {
        $credentialCache = Get-CredentialCache
        $updateArgs = @{
            clientId = $credentialCache.client_id
            clientSecret = $credentialCache.client_secret
            refreshToken = $BloggerSession.RefreshToken
        }
        $token = Update-GoogleAccessToken @updateArgs
        Update-CredentialCache -token $token
    }

    $header= @{ Authorization = "Bearer $($BloggerSession.AccessToken)"}

    $header
}
