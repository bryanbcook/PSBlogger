<#
#>
function Add-GoogleDriveFile {
    [CmdletBinding()]
    param(
        [string]$Path,
        [string]$Name,
        [string]$Description
    )

    $sourceItem = Get-Item (Resolve-Path $Path)
    $sourceBase64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($sourceItem.FullName))
    $sourceMime = Get-MimeType($sourceItem.Extension)

    if (-not $Name) {
        $Name = $sourceItem.Name
        $Description = $sourceItem.VersionInfo.FileDescription
    }

    $meta = @{
        originalFileName = $sourceItem.Name
        name = $Name
        title = $Name
        description = $Description
        mimeType = $sourceMime
    }

    $body = @"
--boundary
Content-Type: application/json; charset=UTF-8

$($meta | ConvertTo-Json)

--boundary
Content-Transfer-Encoding: base64
Content-Type: $sourceMime

$sourceBase64
--boundary--
"@

    $headers = Get-AuthHeader
    #$headers."Content-Type" = 'multipart/related; boundary=boundary'
    #$headers."Content-Length" = $body.Length
    $headers."Content-Type" = $sourceMime

    $uri = "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart"
    #$result = Invoke-GApi -uri $uri -Body $body -ContentType 'multi-part/related; boundary="boundary"'
    $result = Invoke-RestMethod -Uri $uri -Method "Post" -Headers $headers -InFile $sourceItem.FullName
}



function Get-MimeType
{
    param(
        [string]$Extension
    )

    $drive = Get-PSDrive HKCR -ErrorAction SilentlyContinue
    if ($null -eq $drive) {
        $drive = New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
    }
    (Get-ItemProperty HKCR:$Extension)."Content Type"
}