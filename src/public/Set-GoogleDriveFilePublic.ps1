<#
.SYNOPSIS
Sets public read permissions on a Google Drive file.

.DESCRIPTION
Configures a Google Drive file to be publicly accessible without authentication.

.PARAMETER FileId
The ID of the Google Drive file to make public.

.EXAMPLE
Set-GoogleDriveFilePublic -FileId "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms"
#>
function Set-GoogleDriveFilePublic {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FileId
    )

    $permissionData = @{
        role = "reader"
        type = "anyone"
    } | ConvertTo-Json

    $uri = "https://www.googleapis.com/drive/v3/files/$FileId/permissions"
    
    try {
        $result = Invoke-GApi -uri $uri -body $permissionData -method "POST"
        Write-Verbose "Set public permissions for file ID: $FileId"
        return $result
    }
    catch {
        Write-Error "Failed to set public permissions on Google Drive file: $($_.Exception.Message)"
        throw
    }
}
