function Get-AuthHeader()
{
    Assert-CredentialCache

    if (!(Test-GoogleAccessToken $BloggerSession.AccessToken))
    {
        $token = Update-GoogleAccessToken -refreshToken $BloggerSession.RefreshToken
        Update-CredentialCache -token $token
    }

    $header= @{ Authorization = "Bearer $($BloggerSession.AccessToken)"}

    $header
}
