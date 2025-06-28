<#
.SYNOPSIS
    Finds all image references in a markdown file.

.DESCRIPTION
    Parses a markdown file and extracts all image references (both inline and reference-style).
    Returns information about each image including the original markdown syntax, image path, alt text, and title.

.PARAMETER File
    The path to the markdown file to analyze.

.EXAMPLE
    Find-MarkdownImages -File "post.md"
#>
function Find-MarkdownImages {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]$File
    )

    $content = Get-Content -Path $File -Raw
    $images = @()
    $fileDirectory = Split-Path -Path $File -Parent

    # Regex pattern for inline images: ![alt text](image_path "optional title")
    $inlinePattern = '!\[([^\]]*)\]\(([^)]+?)(?:\s+"([^"]*)")?\)'
    
    # Find all inline image matches
    $inlineMatches = [regex]::Matches($content, $inlinePattern)
    
    foreach ($match in $inlineMatches) {
        $altText = $match.Groups[1].Value
        $imagePath = $match.Groups[2].Value.Trim()
        $title = if ($match.Groups[3].Success) { $match.Groups[3].Value } else { "" }
        
        # Skip URLs (images already hosted online)
        if ($imagePath -match '^https?://') {
            continue
        }
        
        # Resolve relative paths
        if (-not [System.IO.Path]::IsPathRooted($imagePath)) {
            $resolvedPath = Join-Path -Path $fileDirectory -ChildPath $imagePath
        } else {
            $resolvedPath = $imagePath
        }
        
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

Function New-MarkdownImage
{
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
        AltText = $AltText
        LocalPath = $LocalPath
        RelativePath = $RelativePath
        Title = $Title
        FileName = $FileName
        NewUrl = $null  # This will be set after uploading to Google Drive
    }
}