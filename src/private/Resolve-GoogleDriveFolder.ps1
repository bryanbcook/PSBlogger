<#
.SYNOPSIS
  Maps a local folder path to a corresponding Google Drive folder, creating any missing folders or subfolders as needed.

.DESCRIPTION
  This function takes a folder path (e.g., "PSBlogger/Subfolder") and returns the corresponding Google Drive folder object.
  If any part of the folder path does not exist in Google Drive, it will be created automatically.

.PARAMETER FolderPath
  The folder path within Google Drive, using '/' as the separator for subfolders (e.g., "PSBlogger/Subfolder").


#>
function Resolve-GoogleDriveFolder
{
  param(
    [Parameter(Mandatory = $true)]
    [string]$FolderPath
  )

  Write-Verbose "Resolve-GoogleDriveFolder: Resolving folder path '$FolderPath' in Google Drive"

  # Get all Folders in Google Drive
  $folderCache = @{}

  $items = Get-GoogleDriveItems -ResultType "Folders"
  foreach($item in $items) {
    $folderCache[$item.Id] = $item
  }

  $folders = $FolderPath -split '/'
  $folderId = $null

  foreach($folder in $folders) {

    $item = $null

    # attempt to locate folder in cache
    if ($null -eq $folderId) {
      # root folder won't have an id yet, so find it by name only
      $item = $folderCache.Values | Where-Object { $_.name -eq $folder }
    } else {
      # find by name and parent id
      $item = $folderCache.Values | Where-Object { $_.name -eq $folder -and $_.parents -contains $folderId }
    }

    # if the folder wasn't found, create it
    if ($null -eq $item) {
      Write-Verbose "Add-GoogleDriveFile: Folder '$folder' not found. Creating new folder."

      $newFolderParams = @{
        Name = $folder
      }
      if ($folderId) {
        $newFolderParams.ParentId = $folderId
      }
      $item = Add-GoogleDriveFolder @newFolderParams

      # save new folder into cache
      $folderCache[$item.id] = $item
      $folderId = $item.id
    } else {
      # folder was found, so just update the folderId for the next iteration
      $folderId = $item.id
    }
  }

  return $folderCache[$folderId]
}
