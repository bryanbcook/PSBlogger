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

  # Process images: detect, upload to Google Drive, and update markdown
  $imageMappings = @()
  $images = Find-MarkdownImages -File $File
  if ($images -and $images.Count -gt 0) {
    Write-Verbose "Found $($images.Count) local images to upload to Google Drive"

    $anonymous = New-GoogleDriveFilePermission -role "reader" -type "anyone"
    
    foreach ($image in $images) {
      try {
        Write-Verbose "Uploading image: $($image.FileName)"
        $uploadResult = Add-GoogleDriveFile -FilePath $image.LocalPath -FileName $image.FileName
        if (!$uploadResult) {
          Write-Warning "Failed to upload image $($image.FileName)"
          continue
        }
        Set-GoogleDriveFilePermission -FileId $uploadResult.id -Permission $anonymous | Out-Null
        
        $image.NewUrl = $uploadResult.PublicUrl
        $imageMappings += $image
        
        Write-Verbose "Successfully uploaded: $($image.FileName) -> $($uploadResult.PublicUrl)"
      }
      catch {
        Write-Warning "Failed to upload image $($image.FileName): $($_.Exception.Message)$([Environment]::NewLine)$($_.ErrorDetails | ConvertTo-Json -Depth 10)"
      }
    }
    
    # Update the markdown file with new URLs
    if ($imageMappings -and $imageMappings.Count -gt 0) {
      $updated = Update-MarkdownImages -File $File -ImageMappings $imageMappings
      if ($updated) {
        Write-Verbose "Updated markdown file with $($imageMappings.Count) new image URLs"
      }
    }
  }
  
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