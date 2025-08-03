function Test-IsAdmin
{
  $currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object System.Security.Principal.WindowsPrincipal($currentIdentity)
  return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-PandocInstalled {
  [CmdletBinding()]
  [OutputType([bool])]
  param()

  try {
    $null = Get-Command pandoc -ErrorAction Stop
    Write-Verbose "Pandoc is installed and available in PATH"
    return $true
  }
  catch {
    Write-Verbose "Pandoc is not installed or not available in PATH"
    return $false
  }
}

function Test-ChocolateyInstalled {
  [CmdletBinding()]
  [OutputType([bool])]
  param()
  
  try {
    $null = Get-Command choco -ErrorAction Stop
    Write-Verbose "Chocolatey is installed and available in PATH"
    return $true
  }
  catch {
    Write-Verbose "Chocolatey is not installed or not available in PATH"
    return $false
  }
}

function Install-PandocWithChocolatey {
  [CmdletBinding()]
  param()
  
  Write-Information "Installing Pandoc using Chocolatey..."
  
  try {
    $process = Start-Process choco -ArgumentList "install", "pandoc", "-y" -NoNewWindow -Wait -PassThru
    
    if ($process.ExitCode -eq 0) {
      Write-Information "Pandoc installation completed successfully."
      Write-Information "You may need to restart your PowerShell session for Pandoc to be available in PATH."
    }
    else {
      Write-Error "Pandoc installation failed with exit code: $($process.ExitCode)"
    }
  }
  catch {
    Write-Error "Failed to install Pandoc: $($_.Exception.Message)"
  }
}
