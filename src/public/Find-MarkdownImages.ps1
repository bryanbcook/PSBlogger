<#
.SYNOPSIS
  Finds all image references in a markdown file.

.DESCRIPTION
  Parses a markdown file and extracts all image references including:
  - Standard markdown format: ![alt text](image_path "optional title")
  - Obsidian format: ![[image_path|alt text]]
  Returns information about each image including the original markdown syntax, image path, alt text, and title.

.PARAMETER File
  The path to the markdown file to analyze.

.PARAMETER AttachmentsDirectory
  The directory where attachments are stored. If specified, it will be used to resolve relative paths for images.

.EXAMPLE
    Find-MarkdownImages -File "post.md"

.EXAMPLE
    Find-MarkdownImages -File "post.md" -AttachmentsDirectory "C:\Attachments"

  This command will find all images in the specified markdown file and resolve their paths against the provided attachments directory.
#>
function Find-MarkdownImages {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
    [string]$File,

    [Parameter(Mandatory = $false)]
    [string]$AttachmentsDirectory
  )

  $content = Get-Content -Path $File -Raw
  $images = @()
  $fileDirectory = Split-Path -Path $File -Parent
    
  # If the file is in the current directory, use the current directory
  if ([string]::IsNullOrEmpty($fileDirectory)) {
    $fileDirectory = "."
  }

  if ([string]::IsNullOrEmpty($AttachmentsDirectory)) {
    if ($BloggerSession.AttachmentsDirectory) {
      # Use the Blogger session's attachments directory if available
      Write-Verbose "Using PSBlogger config for attachments directory: $($BloggerSession.AttachmentsDirectory)"
      $AttachmentsDirectory = $BloggerSession.AttachmentsDirectory
    } else {
      # Default to the file's directory if no attachments directory is specified
      $AttachmentsDirectory = $fileDirectory
    }
  }

  # Regex pattern for standard markdown images: ![alt text](image_path "optional title")
  $standardPattern = '!\[([^\]]*)\]\(([^)]+?)(?:\s+"([^"]*)")?\)'
    
  # Regex pattern for Obsidian images: ![[image_path|alt text]]
  $obsidianPattern = '!\[\[([^|\]]+?)(?:\|([^\]]*))?\]\]'
    
  # Collect all matches with their positions
  $allMatches = @()
    
  # Find all standard markdown image matches
  $standardMatches = [regex]::Matches($content, $standardPattern)
  foreach ($match in $standardMatches) {
    $allMatches += @{
      Match    = $match
      Position = $match.Index
      Format   = "Standard"
    }
  }
    
  # Find all Obsidian image matches
  $obsidianMatches = [regex]::Matches($content, $obsidianPattern)
  foreach ($match in $obsidianMatches) {
    $allMatches += @{
      Match    = $match
      Position = $match.Index
      Format   = "Obsidian"
    }
  }
    
  # Sort matches by position in document
  $allMatches = $allMatches | Sort-Object Position
    
  # Process each match in document order
  foreach ($matchInfo in $allMatches) {
    $match = $matchInfo.Match
    $format = $matchInfo.Format
        
    if ($format -eq "Standard") {
      $altText = $match.Groups[1].Value
      $imagePath = $match.Groups[2].Value.Trim()
      $title = if ($match.Groups[3].Success) { $match.Groups[3].Value } else { "" }
    }
    else {
      # Obsidian format
      $imagePath = $match.Groups[1].Value.Trim()
      $altText = if ($match.Groups[2].Success) { $match.Groups[2].Value } else { "" }
      $title = ""  # Obsidian format doesn't support titles
    }
        
    # Skip URLs (images already hosted online)
    if ($imagePath -match '^https?://') {
      continue
    }
        
    # Resolve the image file path
    $resolvedPath = Resolve-ImageFilePath `
                      -FilePath $imagePath `
                      -BaseDirectory $fileDirectory `
                      -AttachmentsDirectory $AttachmentsDirectory

    # Check if the file exists
    if (Test-Path -Path $resolvedPath -PathType Leaf) {
      $images += New-MarkdownImage `
        -OriginalMarkdown $match.Value `
        -AltText $altText `
        -LocalPath $resolvedPath `
        -RelativePath $imagePath `
        -Title $title `
        -FileName $(Split-Path -Path $resolvedPath -Leaf)
    }
  }

  return $images
}

Function New-MarkdownImage {
  param(
    [string]$OriginalMarkdown,
    [string]$AltText,
    [string]$LocalPath,
    [string]$RelativePath,
    [string]$Title = "",
    [string]$FileName
  )
  return [PSCustomObject]@{
    OriginalMarkdown = $OriginalMarkdown
    AltText          = $AltText
    LocalPath        = $LocalPath
    RelativePath     = $RelativePath
    Title            = $Title
    FileName         = $FileName
    NewUrl           = $null  # This will be set after uploading to Google Drive
  }
}

Function Resolve-ImageFilePath
{
  param(
    [string]$FilePath,
    [string]$BaseDirectory,
    [string]$AttachmentsDirectory
  )

  # Test if the file path is relative to the base directory
  if (-not [System.IO.Path]::IsPathRooted($FilePath)) {
    # If the path is relative, resolve it against the base directory
    $resolvedPath = Join-Path -Path $BaseDirectory -ChildPath $FilePath
  } else {
    # If the path is absolute, use it as is
    $resolvedPath = $FilePath
  }
  if (Test-Path $resolvedPath) {
    Write-Verbose "Found image at base directory: $resolvedPath"
    return $resolvedPath
  }

  #Test if the file path is relative to the attachments directory
  $resolvedPath = Join-Path -Path $AttachmentsDirectory -ChildPath $FilePath
  if (Test-Path $resolvedPath) {
    Write-Verbose "Found image at attachments directory: $resolvedPath"
    return $resolvedPath
  }

  # # If not found, recursively search the attachments directory
  $files = @(Get-ChildItem -Path $AttachmentsDirectory -Recurse -File -Filter $FilePath)
  if ($files.Count -gt 0) {
    if ($files.Count -gt 1) {
      Write-Warning "Multiple files found matching '$FilePath' in '$AttachmentsDirectory'. Returning the first match."
    }
    Write-Verbose "Found image in attachments directory: $($files[0].FullName)"
    return $files[0].FullName
  }

  # If still not found, return the original file path
  return $FilePath
}