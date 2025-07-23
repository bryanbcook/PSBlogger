Function Set-BloggerConfig
{
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("BlogId","PandocAdditionalArgs","PandocHtmlFormat","PandocMarkdownFormat","ExcludeLabels")]
    [string]$Name,

    [Parameter(Mandatory=$true)]
    [AllowEmptyString()]
    $Value
  )
  $userPreferences = [pscustomobject]@{}

  if (Test-Path $BloggerSession.UserPreferences)
  {
    Write-Verbose "Set-BloggerConfig: Loading preferences from $($BloggerSession.UserPreferences)"
    $userPreferences = [pscustomobject](Get-Content $BloggerSession.UserPreferences -Raw | ConvertFrom-Json)
    $userPreferences | Out-String | Write-Verbose
  }

  if (@($userPreferences.PsObject.Properties).Count -eq 0 -or $Name -notin $userPreferences.PsObject.Properties.Name)
  {
    Write-Verbose "Set-BloggerConfig: Adding Property $Name"
    $userPreferences | Add-Member -Name $Name -Value $Value -MemberType NoteProperty
  }
  else {
    Write-Verbose "Set-BloggerConfig: Updating Propery $Name"
    $userPreferences.$Name = $Value
  }  

  Write-Verbose "Set-BloggerConfig: Saving preferences to $($BloggerSession.UserPreferences)"
  Set-Content -Path $BloggerSession.UserPreferences -Value ($userPreferences | ConvertTo-Json)
  $BloggerSession.$Name = $Value
}