function Get-TestFilePath {
  <#
    .SYNOPSIS
    Returns a platform-agnostic test file path rooted in TestDrive
    .DESCRIPTION
    Use this helper to generate file paths for test files, ensuring compatibility across platforms.
    .PARAMETER PathSegments
    One or more path segments to append to TestDrive
    .EXAMPLE
    Get-TestFilePath 'foo.md' # => TestDrive/foo.md (Linux) or TestDrive:\foo.md (Windows)
  #>
  param(
    [Parameter(Mandatory, ValueFromRemainingArguments=$true)]
    [string[]]$PathSegments
  )
  $path = 'TestDrive:'
  foreach ($segment in $PathSegments) {
    $path = Join-Path -Path $path -ChildPath $segment
  }
  return $path
}

function Set-MarkdownFile($path, $content) {
  <#
    .SYNOPSIS
    Set the content of a markdown file
  #>
    # resolve path
  $resolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)
  $Folder = [System.IO.Path]::GetDirectoryName($resolvedPath)
  if (-not (Test-Path -Path $Folder)) {
    New-Item -ItemType Directory -Path $Folder -Force | Out-Null
  }
  Set-Content -Path $resolvedPath -Value $content
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