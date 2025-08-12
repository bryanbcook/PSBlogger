<#
.SYNOPSIS
  Initialize the local system to use Pandoc + Blogger together

.DESCRIPTION
  This prepares your system to use Pandoc + Blogger together by obtaining an authtoken that is 
  authorized to communicate with blogger.

.PARAMETER ClientId
  Google API Client ID. This currently defaults to the one I use, but you
  will need to create your own until the Google Application is published and verified
    
.PARAMETER ClientSecret
  Google API Client Secret. A default value is provided, but you can provide your own if you don't trust me.

.PARAMETER RedirectUri
  The oAuth redirect URL specifed in the Google API Consent Form.

.EXAMPLE
Initiate a login flow with Google

  Initialize-Blogger

.NOTES
  Note that this function requires administrator permissions to support the authentication flow.
  
  Pandoc is a dependency for this module. If it's not installed and the user has Chocolately installed,
  the function will prompt to install pandoc using Chocolatey. To disable the prompt, change the
  ConfirmPreference to 'None' or use the -Confirm:$false parameter. 
#>
Function Initialize-Blogger {
  [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
  Param(
    [Parameter(HelpMessage = "Google API ClientId")]
    [string]$ClientId = "<<CLIENT_ID>>",

    [Parameter(HelpMessage = "Google API Client Secret")]
    [string]$ClientSecret = "<<CLIENT_SECRET>>",

    [Parameter(HelpMessage = "Redirect Uri specified in Google API Consent Form")]
    [string]$RedirectUri = "http://localhost/oauth2callback"
  )
  
  # Check that we're running as an admin
  if (-not (Test-IsAdmin)) {
    Write-Warning "Administrator privileges are required to initialize Blogger authentication."
    Write-Warning "Please restart PowerShell as Administrator and try again."
    return
  }

  $ErrorActionPreference = 'Stop'

  # Check if Pandoc is installed
  if (-not (Test-PandocInstalled)) {
    Write-Warning "Pandoc is not installed or not available in PATH."
    
    if (Test-ChocolateyInstalled) {
      # Prompt user to install Pandoc using Chocolatey if $ConfirmPreference is set to 'Medium' or higher
      if ($PSCmdlet.ShouldProcess("Pandoc", "Install using Chocolatey")) {
        Install-PandocWithChocolatey
      }
      else {
        Write-Warning "Pandoc installation skipped. Note that certain functions may fail."
      }
    }
  }

  # Show warning to developers if they attempt to use the neutered credentials by mistake
  if ($env:PSBLOGGER_CLIENT_ID -and !$PSBoundParameters.ContainsKey("ClientId"))
  {
    Write-Verbose "Using environment variable PSBLOGGER_CLIENT_ID for ClientId"
    $ClientId = $env:PSBLOGGER_CLIENT_ID
  }
  if ($env:PSBLOGGER_CLIENT_SECRET -and !$PSBoundParameters.ContainsKey("ClientSecret"))
  {
    Write-Verbose "Using environment variable PSBLOGGER_CLIENT_SECRET for ClientSecret"
    $ClientSecret = $env:PSBLOGGER_CLIENT_SECRET
  }
  if ($ClientId -like "*CLIENT_ID*" -or $ClientSecret -like "*CLIENT_SECRET*") {
    Write-Error "See contribution guide for how to set up your own Google API for local development."
    return
  }

  Write-Information "Let's get an auth-code."

  # specify the scopes we want in our auth token
  $scope = @(
    "https://www.googleapis.com/auth/blogger" 
    "https://www.googleapis.com/auth/drive.file"
  ) -join " "

  $url = "https://accounts.google.com/o/oauth2/auth?client_id=$ClientId&scope=$scope&response_type=code&redirect_uri=$RedirectUri&access_type=offline&approval_prompt=force"

  Start-Process $url

  $code = Wait-GoogleAuthApiToken

  if ($null -eq $code) {
    Write-Information "Authentication cancelled by user."
    return
  }

  Write-Information "Sucessfully obtained auth-code!"


  # trade the auth-code for an token that has a short-lived expiry
  $expiringToken = Get-GoogleAccessToken -clientId $ClientId -clientSecret $ClientSecret -redirectUri $RedirectUri -code $code

  # use the refresh-token to get an updated access-token
  $token = Update-GoogleAccessToken -clientId $ClientId -clientSecret $ClientSecret -refreshToken $expiringToken.refresh_token

  # save the token in the credential_cache.json
  Set-CredentialCache -clientId $ClientId -clientSecret $ClientSecret -refreshToken $expiringToken -token $token

  Write-Information "Awesome. We're all set."
}