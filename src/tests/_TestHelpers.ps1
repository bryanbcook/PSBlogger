function Set-MarkdownFile($path, $content) {
  <#
    .SYNOPSIS
    Set the content of a markdown file
  #>
    # resolve path
  $path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)
  $Folder = [System.IO.Path]::GetDirectoryName($path)
  if (-not (Test-Path -Path $Folder)) {
    New-Item -ItemType Directory -Path $Folder -Force | Out-Null
  }
  Set-Content -Path $path -Value $content
}

function New-BlogPost($id) {
  <#
    .SYNOPSIS
    Blogger Blog post
  #>
  [pscustomobject]@{ id=$id }
}


Function New-FrontMatter([string[]]$lines) {
  return "---`n" + ($lines -join "`n") + "`n---`n"
}

Function New-MarkdownImage
{
    param(
        [string]$OriginalMarkdown,
        [string]$AltText,
        [string]$LocalPath,
        [string]$RelativePath,
        [string]$Title = "",
        [string]$FileName,
        [string]$NewUrl

    )
    return [PSCustomObject]@{
        OriginalMarkdown = $OriginalMarkdown
        AltText = $AltText
        LocalPath = $LocalPath
        RelativePath = $RelativePath
        Title = $Title
        FileName = $FileName
        NewUrl = $NewUrl
    }
}

Function New-TestImage
{
  param(
    [string]$FilePath
  )

  # resolve path
  $FilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($FilePath)
  $Folder = [System.IO.Path]::GetDirectoryName($FilePath)
  if (-not (Test-Path -Path $Folder)) {
    New-Item -ItemType Directory -Path $Folder -Force | Out-Null
  }

  # create a test image
  $TestImage = New-Item -ItemType File -Path $FilePath -Force
  Set-Content -Path $TestImage -Value "fake image content"

  return $FilePath
}