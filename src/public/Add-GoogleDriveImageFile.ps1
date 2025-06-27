<#
.SYNOPSIS
Uploads a file to Google Drive in a specified folder with public permissions.

.DESCRIPTION
Uploads a file to Google Drive, places it in the "Open Live Writer" subfolder,
preserves the original filename, and sets public read permissions.

.PARAMETER FilePath
The local path to the file to upload.

.PARAMETER FileName
Optional custom name for the file. If not specified, uses the original filename.

.EXAMPLE
Add-GoogleDriveImageFile -FilePath "C:\images\photo.jpg"
#>
function Add-GoogleDriveImageFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]$FilePath,
        
        [Parameter(Mandatory=$false)]
        [string]$FileName,

        [Parameter(Mandatory=$false)]
        [string]$GoogleFolderName = "Open Live Writer"
    )

    $sourceItem = Get-Item (Resolve-Path $FilePath)
    
    if (-not $FileName) {
        $FileName = $sourceItem.Name
    }

    # First, find or create the upload folder in Google Drive
    $folder = Get-GoogleDriveFiles -ResultType "Folders" -Title $GoogleFolderName

    if (-not $folder) {
        # Create the folder if it doesn't exist
        $folder = New-GoogleDriveFolder -Name $GoogleFolderName
    } else {
        # Get the first folder if multiple exist
        $folder = $folder | Select-Object -First 1
    }

    $sourceMime = Get-ImageMimeType -Extension $sourceItem.Extension
    
    # Prepare metadata for the file
    $metadata = @{
        name = $FileName
        parents = @($folder.id)
    } | ConvertTo-Json

    # Create multipart body
    $boundary = "boundary_" + [System.Guid]::NewGuid().ToString()
    
    $metadataPart = @"
--$boundary
Content-Type: application/json; charset=UTF-8

$metadata

"@

    $fileContent = [System.IO.File]::ReadAllBytes($sourceItem.FullName)
    $fileContentBase64 = [Convert]::ToBase64String($fileContent)
    
    $filePart = @"
--$boundary
Content-Type: $sourceMime
Content-Transfer-Encoding: base64

$fileContentBase64
--$boundary--
"@

    $body = $metadataPart + $filePart

    $additionalHeaders = @{
        "Content-Type" = "multipart/related; boundary=$boundary"
    }

    $uri = "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart"
    
    try {
        $uploadResult = Invoke-GApi -uri $uri -body $body -method "POST" -ContentType "multipart/related; boundary=$boundary" -AdditionalHeaders $additionalHeaders
        
        # Set public permissions on the uploaded file
        Set-GoogleDriveFilePublic -FileId $uploadResult.id
        
        # Return the file information with public URL
        $publicUrl = "https://lh3.googleusercontent.com/d/$($uploadResult.id)"
        
        return [PSCustomObject]@{
            Id = $uploadResult.id
            Name = $uploadResult.name
            PublicUrl = $publicUrl
            DriveUrl = "https://drive.google.com/file/d/$($uploadResult.id)/view"
        }
    }
    catch {
        Write-Error "Failed to upload file to Google Drive: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
Gets the MIME type for common image file extensions.

.DESCRIPTION
Returns the appropriate MIME type for image files. Falls back to application/octet-stream for unknown types.

.PARAMETER Extension
The file extension (including the dot).

.EXAMPLE
Get-ImageMimeType -Extension ".jpg"
#>
function Get-ImageMimeType {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Extension
    )

    $mimeTypes = @{
        '.jpg'  = 'image/jpeg'
        '.jpeg' = 'image/jpeg'
        '.png'  = 'image/png'
        '.gif'  = 'image/gif'
        '.bmp'  = 'image/bmp'
        '.webp' = 'image/webp'
        '.svg'  = 'image/svg+xml'
        '.ico'  = 'image/x-icon'
        '.tiff' = 'image/tiff'
        '.tif'  = 'image/tiff'
    }

    $normalizedExtension = $Extension.ToLower()
    
    if ($mimeTypes.ContainsKey($normalizedExtension)) {
        return $mimeTypes[$normalizedExtension]
    } else {
        return 'application/octet-stream'
    }
}
