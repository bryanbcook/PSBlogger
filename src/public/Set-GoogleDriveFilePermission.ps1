<#
.SYNOPSIS
Sets public read permissions on a Google Drive file.

.DESCRIPTION
Configures a Google Drive file to be publicly accessible without authentication.

.PARAMETER FileId
The ID of the Google Drive file to make public.

.EXAMPLE
Set-GoogleDriveFilePermission -FileId "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgvE2upms"
#>
# Change to Set-GoogleDriveFile Permission
function Set-GoogleDriveFilePermission {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FileId,

        [Parameter(Mandatory=$true)]
        [PSCustomObject]$PermissionData
    )

    # $permissionData = @{
    #     role = "reader"
    #     type = "anyone"
    # } | ConvertTo-Json
    $body = $PermissionData | ConvertTo-Json -Compress

    $uri = "https://www.googleapis.com/drive/v3/files/$FileId/permissions"
    
    try {
        $result = Invoke-GApi -uri $uri -body $body
        Write-Verbose "Set-GoogleDriveFilePermission: Set public permissions for file ID: $FileId"
        return $result
    }
    catch {
        Write-Error "Failed to set public permissions on Google Drive file: $($_.Exception.Message)$([Environment]::NewLine)$($_.ErrorDetails | ConvertTo-Json -Depth 10)" -ErrorAction Stop
    }
}
