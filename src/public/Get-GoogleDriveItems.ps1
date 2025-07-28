<#
.DESCRIPTION
  Queries files and folders in the Google drive associated with the authenticated account

.PARAMETER ResultType
  Optional filter to specify the type of results to return. Valid values are:
  - All: Returns all files and folders
  - Files: Returns only files
  - Folders: Returns only folders

  Default is All.

.PARAMETER Title
  Optional filter to return files or folders with a specific title.

.PARAMETER ParentId
  Optional filter to return files or folders that are children of a specific parent folder.
  If not specified, returns items from the root directory.
#>
function Get-GoogleDriveItems {
  [CmdletBinding()]
  param(
    [Parameter()]
    [ValidateSet("All", "Files", "Folders")]
    [string]$ResultType = "All",

    [Parameter()]
    [string]$Title,

    [Parameter()]
    [string]$ParentId
  )

  $q = @()

  # mimeType
  if ($ResultType -ne "All") {
    if ($ResultType -eq "Folders") {
      $q += "mimeType='application/vnd.google-apps.folder'"
    }
    else {
      $q += "mimeType!='application/vnd.google-apps.folder'"
    }
  }

  # title
  if (![string]::IsNullOrEmpty($Title)) {
    $q += "name='$Title'"
  }

  # parents
  if (![string]::IsNullOrEmpty($ParentId)) {
    $q += "'$ParentId' in parents"
  }

  $q += "trashed=false"  # Exclude trashed items

  $queryArgs = @{
    q        = [System.Web.HttpUtility]::UrlEncode($q -join ' and ')
    pageSize = 40
  }

  do {

    $queryString = $queryArgs.GetEnumerator() | ForEach-Object { "$($_.Name)=$($_.Value)" } | Join-String -Separator "&"    
        
    $uri = "https://www.googleapis.com/drive/v3/files?$queryString"
        
    "Get-GoogleDriveItems: $uri" | Write-Verbose

    $result = Invoke-GApi -uri $uri

    # stream results
    $result.files

    if ('nextPageToken' -in $result.PSObject.Properties.Name) {
      $queryArgs.pageToken = $result.nextPageToken
    }
    else {
      $queryArgs.pageToken = $null    
    }

    $result | Out-String | Write-Verbose

  } while ($queryArgs.pageToken)

}