<#
.SYNOPSIS
  Uploads a file to Google Drive in a specified folder.

.DESCRIPTION
  Uploads a file to Google Drive, places it in the "Open Live Writer" subfolder,
  preserves the original filename.

.PARAMETER FilePath
  The local path to the file to upload.

.PARAMETER FileName
  Optional custom name for the file. If not specified, uses the original filename.

.PARAMETER Force
  If specified, will overwrite an existing file with the same name in the target folder.
  If not specified and the file already exists, it will return the existing file's metadata.

.EXAMPLE
  Add-GoogleDriveFile -FilePath "C:\images\photo.jpg"
#>
function Add-GoogleDriveFile {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
    [string]$FilePath,
        
    [Parameter()]
    [string]$FileName,

    [Parameter()]
    [string]$TargetFolderName = "Open Live Writer",

    [Parameter()]
    [switch]$Force
  )

  $sourceItem = Get-Item (Resolve-Path $FilePath)
  Write-Verbose "Add-GoogleDriveFile: Uploading file: $($sourceItem.FullName) to Google Drive"
    
  if (-not $FileName) {
    $FileName = $sourceItem.Name
  }

  # First, find or create the upload folder in Google Drive
  Write-Verbose "Add-GoogleDriveFile: Verifying target folder: $TargetFolderName"
  $folder = Get-GoogleDriveItems -ResultType "Folders" -Title $TargetFolderName

  if (-not $folder) {
    # Create the folder if it doesn't exist
    Write-Verbose "Add-GoogleDriveFile: Folder '$TargetFolderName' not found. Creating new folder."
    $folder = Add-GoogleDriveFolder -Name $TargetFolderName
  }
  else {
    # Get the first folder if multiple exist
    Write-Verbose "Add-GoogleDriveFile: Folder '$TargetFolderName' found."
    $folder = $folder | Select-Object -First 1
  }

  # Determine if the file already exists in the target folder
  Write-Verbose "Add-GoogleDriveFile: Checking if file '$FileName' already exists in folder '$TargetFolderName'"
  $existingFile = Get-GoogleDriveItems -ResultType "Files" -Title $FileName -ParentId $folder.id
  if ($existingFile) {
    if (-not $Force) {
      # use existing file
      return New-GoogleDriveMetadata -id $existingFile.id -name $existingFile.name
    }
    # address multiple file issue
    # todo: evaluate additional meta-data of the file to ensure it's not deleted
    $existingFile = $existingFile | Select-Object -First 1
  }

  $sourceMime = Get-ImageMimeType -Extension $sourceItem.Extension
    
  # Prepare metadata for the file
  $metadata = @{
    name    = $FileName
    parents = @($folder.id)
  } | ConvertTo-Json -Compress

  $fileContent = [System.IO.File]::ReadAllBytes($sourceItem.FullName)
  $fileContentBase64 = [Convert]::ToBase64String($fileContent)

  # Create multipart body
  $boundary = "boundary_" + [System.Guid]::NewGuid().ToString()

  $body = @(

    # Metadata part
    "--$boundary"
    "Content-Type: application/json; charset=UTF-8"
    ""
    $metadata
    "--$boundary"

    # File content part
    "Content-Type: $sourceMime"
    "Content-Transfer-Encoding: base64"
    ""
    $fileContentBase64
    "--$boundary--"
  ) -join "`r`n"

  $additionalHeaders = @{
    "Content-Type" = "multipart/related; boundary=$boundary"
  }

  try {
        
    if ($existingFile) {
      # If the file exists and Force is specified, update it
      $uri = "https://www.googleapis.com/upload/drive/v3/files/$($existingFile.id)?uploadType=media"
      $method = "PATCH"

      "Add-GoogleDriveFile: $Method $uri" | Write-Verbose

      $uploadResult = Invoke-GApi -uri $uri -InFile $sourceItem.FullName -method $method -ContentType $sourceMime -Verbose:$false
    }
    else {
      $uri = "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart"
      $method = "POST"
      "Add-GoogleDriveFile: $Method $uri" | Write-Verbose

      $uploadResult = Invoke-GApi -uri $uri -body $body -method $method -ContentType "multipart/related; boundary=$boundary" -AdditionalHeaders $additionalHeaders -Verbose:$false
    }
        
    # Return the file information with public URL
    return New-GoogleDriveMetadata -id $uploadResult.id -name $uploadResult.name
  }
  catch {
    Write-Error "Failed to upload file to Google Drive: $($_.Exception.Message). $($_.ErrorDetails | ConvertTo-Json -Depth 10)" -ErrorAction Stop
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
    [Parameter(Mandatory = $true)]
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
  }
  else {
    return 'application/octet-stream'
  }
}

function New-GoogleDriveMetadata {
  param(
    [string]$id,
    [string]$name
  )
  $publicUrl = "https://lh3.googleusercontent.com/d/$id"
        
  return [PSCustomObject]@{
    Id        = $id
    Name      = $name
    PublicUrl = $publicUrl
    DriveUrl  = "https://drive.google.com/file/d/$id/view"
  }
}
