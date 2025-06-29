Function New-GoogleDriveFilePermission {
  param(
    [Parameter(Mandatory=$true)]
    [string]$role,

    [Parameter(Mandatory=$true)]
    [string]$type
  
  )

  return [PSCustomObject]@{
    role = "reader"
    type = "anyone"
  } 
}