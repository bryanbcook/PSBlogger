<#
.SYNOPSIS
  Publishes local images from a markdown file to Google Drive and updates the markdown file with the new URLs.

.DESCRIPTION
  This function finds all local images referenced in a markdown file, uploads them to Google Drive,
  sets public permissions, and updates the markdown file with the new Google Drive URLs.

.PARAMETER File
  The path to the markdown file containing image references.

.PARAMETER AttachmentsDirectory
  Optional. The directory where images are stored. If not specified, the function will look for
  images in the same directory as the markdown file.

.PARAMETER Force
  If specified, will overwrite existing files in Google Drive with the same name.

.PARAMETER OutFile
  If specified, writes the updated markdown content with Google Drive URLs to this file instead of modifying the original file.

.EXAMPLE
  Publish-MarkdownDriveImages -File "blog-post.md"

.EXAMPLE
  Publish-MarkdownDriveImages -File "blog-post.md" -Force

.EXAMPLE
  Publish-MarkdownDriveImages -File "blog-post.md" -OutFile "blog-post-published.md"
#>
Function Publish-MarkdownDriveImages
{
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
    [string]$File,

    [Parameter(Mandatory=$false)]
    [string]$AttachmentsDirectory,

    [Parameter(Mandatory=$false)]
    [switch]$Force,

    [Parameter(Mandatory=$false)]
    [string]$OutFile
  )

  # Process images: detect, upload to Google Drive, and update markdown
  $imageMappings = @()
  $images = Find-MarkdownImages -File $File -AttachmentsDirectory $AttachmentsDirectory -ExcludeExternal
  
  if ($images -and $images.Count -gt 0) {
    Write-Verbose "Found $($images.Count) local images to upload to Google Drive"

    $anonymous = New-GoogleDriveFilePermission -role "reader" -type "anyone"
    
    foreach ($image in $images) {
      try {
        Write-Verbose "Uploading image: $($image.FileName)"
        
        # Use the Force parameter when calling Add-GoogleDriveFile
        $uploadParams = @{
          FilePath = $image.LocalPath
          FileName = $image.RelativePath # name that appears in markdown, including any folder structures
          Force = $Force
        }
        
        $uploadResult = Add-GoogleDriveFile @uploadParams
        
        if (!$uploadResult) {
          Write-Warning "Failed to upload image $($image.FileName)"
          continue
        }
        
        try {
          Set-GoogleDriveFilePermission -FileId $uploadResult.id -Permission $anonymous | Out-Null
        }
        catch {
          Write-Warning "Failed to set public permission for image $($image.FileName): $($_.Exception.Message)$([Environment]::NewLine)$($_.ErrorDetails | ConvertTo-Json -Depth 10)"
        }
        
        $image.NewUrl = $uploadResult.PublicUrl
        $imageMappings += $image
        
        Write-Verbose "Successfully uploaded: $($image.FileName) -> $($uploadResult.PublicUrl)"
      }
      catch {
        Write-Warning "Failed to upload image $($image.FileName): $($_.Exception.Message)$([Environment]::NewLine)$($_.ErrorDetails | ConvertTo-Json -Depth 10)"
      }
    }
  }

  # Update the markdown file with new URLs, or ensure that OutFile is created if specified
  if (($imageMappings -and $imageMappings.Count -gt 0) -or $OutFile) {
    $updateParams = @{
      File = $File
      ImageMappings = $imageMappings
      OutFile = $OutFile
    }
    
    $updated = Update-MarkdownImages @updateParams
    if ($updated) {
      $targetFile = if ($OutFile) { $OutFile } else { $File }
      Write-Verbose "Updated markdown file $targetFile with $($imageMappings.Count) new image URLs"
    }
  }
  
  return $imageMappings
}
