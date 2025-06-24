Function Set-BloggerConfig
{
  [CmdletBinding()]
  Param(
    [ValidateSet("BlogId","PandocAdditionalArgs","PandocHtmlFormat","PandocMarkdownFormat")]
    [string]$Name,

    [string]$Value
  )

  $userPreferences = @{}

  if (Test-Path $BloggerSession.UserPreferences)
  {
    Write-Verbose "Loading preferences from $($BloggerSession.UserPreferences)"
    $userPreferences = Get-Content $BloggerSession.UserPreferences | ConvertFrom-Json
  }

  if ($userPreferences.PsObject.Properties.Name -notcontains $Name)
  {
    Write-Verbose "Adding Property $Name"
    $userPreferences | Add-Member -Name $Name -Value $Value -MemberType NoteProperty
  }
  else {
    Write-Verbose "Updating Propery $Name"
    $userPreferences.$Name = $Value
  }  

  Set-Content -Path $BloggerSession.UserPreferences -Value ($userPreferences | ConvertTo-Json)
  $BloggerSession.$Name = $Value
}