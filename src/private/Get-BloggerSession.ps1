Function Get-BloggerSession
{
  $session =   
    [ordered]@{
      CredentialCache = "$($env:USERPROFILE)\\.PSBlogger\\credentialcache.json"
      UserPreferences = "$($env:USERPROFILE)\\.PSBlogger\\settings.json"
      AccessToken = $null
      RefreshToken = $null
      PandocMarkdownFormat = "markdown+emoji"
      PandocHtmlFormat = "html"
      PandocTemplate = "$($env:USERPROFILE)\\.PSBlogger\\template.html"
      PandocAdditionalArgs = "--html-q-tags --ascii"
      BlogId = $null
      ExcludeLabels = @()
    }

  if (Test-Path $session.UserPreferences)
  {
    $prefs = Get-Content $session.UserPreferences | ConvertFrom-Json
    $prefs.PSObject.Properties | ForEach-Object {
      $session[$_.Name] = $_.Value
    }
  }

  $session
}