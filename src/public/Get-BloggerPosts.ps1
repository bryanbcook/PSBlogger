<#
.DESCRIPTION
  Retrieves a list of posts from a specified Blogger blog.

.PARAMETER BlogId
  The ID of the blog to retrieve posts from. If not specified, uses the BlogId in the user preferences.

.PARAMETER Status
  The status of the posts to retrieve. Valid values are "draft", "live", and "scheduled"
#>
Function Get-BloggerPosts
{
    [CmdletBinding()]
    param(
        [string]$BlogId,

        [ValidateSet("draft","live","scheduled")]
        [string]$Status = "live"
    )

    if (!$PSBoundParameters.ContainsKey("BlogId"))
    {
      $BlogId = $BloggerSession.BlogId
      if (0 -eq $BlogId) {
        throw "BlogId not specified."
      }
    }

    try {
        $uri = "https://www.googleapis.com/blogger/v3/blogs/$BlogId/posts?status=$status"
    
        $result = Invoke-GApi -uri $uri
    
        $result.items            
    }
    catch {
        Write-Error $_.ToString() -ErrorAction Stop
    }
}