<#
.DESCRIPTION
  Retrieves a list of posts from a specified Blogger blog.

.PARAMETER BlogId
  The ID of the blog to retrieve posts from. If not specified, uses the BlogId in the user preferences.

.PARAMETER Status
  The status of the posts to retrieve. Valid values are "draft", "live", and "scheduled"

.PARAMETER Since
  Filter the results to only return posts that are older than the supplied date.

.PARAMETER All
  Flag to indicate if all paginated results should be returned.
#>
Function Get-BloggerPosts {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $false)]
    [string]$BlogId,

    [Parameter(Mandatory = $false)]
    [ValidateSet("draft", "live", "scheduled")]
    [string]$Status = "live",

    [Parameter(Mandatory = $false)]
    [datetime]$Since,

    [Parameter(Mandatory = $false)]
    [switch]$All
  )

  if (!$PSBoundParameters.ContainsKey("BlogId")) {
    $BlogId = $BloggerSession.BlogId
    if (0 -eq $BlogId) {
      throw "BlogId not specified."
    }
  }
  $includeDateFilter = $PSBoundParameters.ContainsKey("Since")

  try {
    $done = $false
    $pageToken = $null
    while (!$done) {
      $uri = "https://www.googleapis.com/blogger/v3/blogs/$BlogId/posts?status=$status&fetchBodies=false"

      if ($pageToken) {
        $uri += "&pageToken=$pageToken"
      }
      if ($includeDateFilter) {
        $uri += "&since=" + $Since.ToString("yyyy-MM-ddTHH:mm:ssZ")
      }
      $result = Invoke-GApi -uri $uri
    
      $result.items

      # loop if pageToken is present and -All switch is set
      $pageToken = $result.nextPageToken
      $done = ($All.IsPresent -and $All -and [string]::IsNullOrEmpty($pageToken)) -or !$All.IsPresent
    }
  }
  catch {
    Write-Error $_.ToString() -ErrorAction Stop
  }
}