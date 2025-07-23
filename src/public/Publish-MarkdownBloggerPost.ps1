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

.EXAMPLE
    Publish-MarkdownBloggerPost -File "my-post.md"

.EXAMPLE
    Publish-MarkdownBloggerPost -File "my-post.md" -Draft -Force
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
    [switch]$Force

  )

  if (!$PSBoundParameters.ContainsKey("BlogId"))
  {
    $BlogId = $BloggerSession.BlogId
    if (0 -eq $BlogId) {
      throw "BlogId not specified."
    }
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
  }

  if ($postInfo["postId"]) {
    $postArgs.PostId = $postInfo.postid
  }

  if ($postInfo["tags"]) {
    $postArgs.Labels = [array]$postInfo.tags | Where-Object { $_ -notin $ExcludeLabels }
  }
  
  $post = Publish-BloggerPost @postArgs

  # update post id
  $postInfo["postId"] = $post.id
  if ($Draft) {
    $postInfo["wip"] = $true
  } else {
    if ($postInfo["wip"]) {
      $postInfo.Remove("wip")
    }
  }

  Set-MarkdownFrontMatter -File $File -Replace $postInfo

  return $post
}