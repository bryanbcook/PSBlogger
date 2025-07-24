<#
.SYNOPSIS
  Publish a blog post to Blogger.
  
.DESCRIPTION
  Publish a blog post to blogger as a final or draft post

.PARAMETER BlogId
  Required. The Id of the blog to publish the post to.

.PARAMETER PostId
  Optional. The Id of the post to update. If not specified, a new post will be created.

.PARAMETER Title
  Required. The title of the post.

.PARAMETER Content
  Required. The content of the post in HTML format.

.PARAMETER Labels
  Optional. An array of labels (tags) to apply to the post.

.PARAMETER Draft
  Optional. If specified, the post will be saved as a draft instead of being published.

#>
Function Publish-BloggerPost {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [string]$BlogId,

    [Parameter()]
    [string]$PostId,

    [Parameter(Mandatory = $true)]
    [string]$Title,

    [Parameter(Mandatory = $true)]
    [string]$Content,

    [string[]]$Labels,

    [switch]$Draft
  )

  $uri = "https://www.googleapis.com/blogger/v3/blogs/$BlogId/posts"
  $method = "POST"

  # if the postId exists, we're performing an update
  if ($PostId) {
    $uri += "/$PostId"
    $method = "PUT"

    if (-not $Draft) {
      $uri += "?publish=true"
    }

  }
  else {
    if ($Draft) {
      $uri += "?isDraft=true"
    }
  }   

  $body = @{
    kind    = "blogger#post"
    blog    = @{
      id = $BlogId
    }
    title   = $Title
    content = $Content
    labels  = $Labels
  }

  $body | ConvertTo-Json | Write-Verbose

  $post = Invoke-GApi -Uri $uri -Body ($body | ConvertTo-Json) -Method $method

  $postUrl = `
    if ($Draft) {
    "https://www.blogger.com/blog/post/edit/preview/$BlogId/$($post.id)"
  }
  else {
    $post.url
  }

  Start-Process $postUrl

  return $post
}