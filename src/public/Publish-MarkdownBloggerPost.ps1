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

.PARAMETER PreserveOriginal
  If specified, preserves the original markdown file with local image references. The file with Google Drive URLs 
  is used only for HTML conversion and blog publishing.

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
  # publish or update a post, launching a web browser with the page preview
  Publish-MarkdownBloggerPost -File "my-post.md" -Draft -Open

.EXAMPLE
  # publish or update a post while preserving local image references in the original file
  Publish-MarkdownBloggerPost -File "my-post.md" -PreserveOriginal
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
    [string]$AttachmentsDirectory,

    [Parameter(Mandatory=$false)]
    [switch]$Force,

    [Parameter(Mandatory=$false)]
    [switch]$PreserveOriginal,

    [Parameter(Mandatory=$false)]
    [switch]$Open

  )

  # Obtain -BlogId from User Preferences if available
  if (!$PSBoundParameters.ContainsKey("BlogId"))
  {
    $BlogId = $BloggerSession.BlogId
    if (0 -eq $BlogId) {
      throw "BlogId not specified."
    }
  }

  # Obtain -ExcludeLabesl from User Preferences if availabe
  if (!$PSBoundParameters.ContainsKey("ExcludeLabels")) {
    $ExcludeLabels = $BloggerSession.ExcludeLabels
  }

  # grab the front matter
  $postInfo = Get-MarkdownFrontMatter -File $File

  # Process images: detect, upload to Google Drive, and update markdown
  $tempFile = $null
  $fileForConversion = $File
  
  try {
    if ($PreserveOriginal) {
      # Create temporary file for modified content
      $tempFile = [System.IO.Path]::GetTempFileName()
      $tempFile = [System.IO.Path]::ChangeExtension($tempFile, ".md")
      Write-Verbose "Using temporary file for image processing: $tempFile"
            
      # publishes markdown drive images to google drive and writes the output to the specified OutFile
      $imageMappings = Publish-MarkdownDriveImages -File $File -AttachmentsDirectory $AttachmentsDirectory -Force:$Force -OutFile $tempFile
      $fileForConversion = $tempFile
    }
    else {
      $imageMappings = Publish-MarkdownDriveImages -File $File -AttachmentsDirectory $AttachmentsDirectory -Force:$Force
    }
    
    # convert from markdown to html file
    $content = ConvertTo-HtmlFromMarkdown -File $fileForConversion

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
  finally {
    # Clean up temporary file if it was created
    if ($tempFile -and (Test-Path $tempFile)) {
      Write-Verbose "Cleaning up temporary file: $tempFile"
      Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    }
  }
}