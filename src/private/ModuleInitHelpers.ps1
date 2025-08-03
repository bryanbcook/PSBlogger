function Test-IsAdmin
{
  $currentIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = New-Object System.Security.Principal.WindowsPrincipal($currentIdentity)
  return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}
