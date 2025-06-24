<#

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
    [switch]$Draft
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

  # TODO: Extension point to create additional metadata-file
  # - eg: dynamically build a flickr header image from a url in the meta block
    
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

  if ($postInfo.tags) {
    $postArgs.Labels = [array]$postInfo.tags
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