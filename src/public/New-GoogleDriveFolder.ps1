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
function New-GoogleDriveFolder {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$false)]
        [string]$ParentId
    )

    $metadata = @{
        name = $Name
        mimeType = "application/vnd.google-apps.folder"
    }
    
    if ($ParentId) {
        $metadata.parents = @($ParentId)
    }

    $body = $metadata | ConvertTo-Json
    $uri = "https://www.googleapis.com/drive/v3/files"
    
    try {
        $result = Invoke-GApi -uri $uri -body $body -method "POST"
        return $result
    }
    catch {
        Write-Error "Failed to create folder in Google Drive: $($_.Exception.Message)"
        throw
    }
}
