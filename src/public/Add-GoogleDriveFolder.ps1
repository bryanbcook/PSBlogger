<#
.SYNOPSIS
Creates a new folder in Google Drive.

.DESCRIPTION
  Creates a new folder in Google Drive with the specified name.

.PARAMETER Name
  The name of the folder to create.

.PARAMETER ParentId
  Optional parent folder ID. If not specified, creates in root.

.EXAMPLE
  New-GoogleDriveFolder -Name "Open Live Writer"
#>
function Add-GoogleDriveFolder {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$Name,
        
    [Parameter(Mandatory = $false)]
    [string]$ParentId
  )

  Write-Verbose ("Creating folder '$Name' {0}" -f ($ParentId ? "in parent '$ParentId'" : "in root"))

  $metadata = @{
    name     = $Name
    mimeType = "application/vnd.google-apps.folder"
  }
    
  if ($ParentId) {
    $metadata.parents = @($ParentId)
  }

  $body = $metadata | ConvertTo-Json -Compress
  $uri = "https://www.googleapis.com/drive/v3/files"
    
  try {
    return Invoke-GApi -uri $uri -body $body -Verbose:$false
  }
  catch {
    Write-Error "Failed to create folder in Google Drive: $($_.Exception.Message)" -ErrorAction Stop
  }
}
