<#
.SYNOPSIS
  Publishes a markdown file as a blog post to Blogger, including uploading any local images to Google Drive.

.DESCRIPTION
  This function processes a markdown file to publish it as a blog post. It handles:
  - Extracting front matter from the markdown file
  - Finding and uploading local images to Google Drive
  - Converting markdown content to HTML
  - Publishing the post to Blogger
  - Updating the front matter with post information

.PARAMETER File
  The path to the markdown file to publish.

.PARAMETER BlogId
  The ID of the blog to publish to. If not specified, uses the BlogId from the current BloggerSession.

.PARAMETER Draft
  If specified, publishes the post as a draft rather than a published post.

.PARAMETER Force
  If specified, will overwrite existing images in Google Drive with the same name.

.PARAMETER Open
  If specified, launches a browser to view the post after publishing.

.EXAMPLE
  # publish or update post
  Publish-MarkdownBloggerPost -File "my-post.md"

.EXAMPLE
  # publish or update a draft post
  Publish-MarkdownBloggerPost -File "my-post.md" -Draft

.EXAMPLE
  # publish or update a post, updating google drive images if required
  Publish-MarkdownBloggerPost -File "my-post.md" -Force

.EXAMPLE
  # publish or update a post, launching a web browser to view the published post
  Publish-MarkdownBloggerPost -File "my-post.md" -Open

.EXAMPLE
  # publish or update a draft, launching a web browser with the page preview
  Publish-MarkdownBloggerPost -File "my-post.md" -Draft -Open
#>
Function Publish-MarkdownBloggerPost
{
  [CmdletBinding()]
  Param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
    [string]$File,

    [Parameter(Mandatory=$false)]
    [int]$BlogId,

    [Parameter(Mandatory=$false)]
    [switch]$Draft,

    [Parameter(Mandatory=$false)]
    [array]$ExcludeLabels = @(),

    [Parameter(Mandatory=$false)]
    [switch]$Force,

    [Parameter(Mandatory=$false)]
    [switch]$Open

  )

  if (!$PSBoundParameters.ContainsKey("BlogId"))
  {
    $BlogId = $BloggerSession.BlogId
    if (0 -eq $BlogId) {
      throw "BlogId not specified."
    }
  }

  if (!$PSBoundParameters.ContainsKey("ExcludeLabels")) {
    $ExcludeLabels = $BloggerSession.ExcludeLabels
  }

  # grab the front matter
  $postInfo = Get-MarkdownFrontMatter -File $File

  # Process images: detect, upload to Google Drive, and update markdown
  $imageMappings = Publish-MarkdownDriveImages -File $File -Force:$Force
  
  # convert from markdown to html file
  $content = ConvertTo-HtmlFromMarkdown -File $File

  # TODO: Extension point to apply corrections to HTML
  # - eg: remove instances of <pre><code> from the content

  # construct args
  $postArgs = @{
    BlogId = $BlogId
    Title = $postInfo.title
    Content = $content
    Draft = $Draft
    Open = $Open
  }

  if ($postInfo["postId"]) {
    $postArgs.PostId = $postInfo.postid
  }

  if ($postInfo["tags"]) {
    $postArgs.Labels = [array]$postInfo.tags | Where-Object { $_ -notin $ExcludeLabels }
  }
  
  Write-Verbose "Publishing blogger post with args: $($postArgs | ConvertTo-Json -Depth 5)"
  $post = Publish-BloggerPost @postArgs

  # update post id
  $postInfo["postId"] = $post.id
  if ($Draft) {
    Write-Verbose "Adding 'wip' to front matter"
    $postInfo["wip"] = $true
  } else {
    if ($postInfo["wip"]) {
      Write-Verbose "Removing 'wip' from front matter"
      $postInfo.Remove("wip")
    }
  }

  Write-Verbose "Updating front matter with post id: $($postInfo['postId'])"
  Set-MarkdownFrontMatter -File $File -Replace $postInfo

  return $post
}