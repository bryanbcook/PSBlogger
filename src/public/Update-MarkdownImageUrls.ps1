<#
.SYNOPSIS
Updates markdown content by replacing local image references with Google Drive URLs.

.DESCRIPTION
Takes a markdown file and replaces local image references with Google Drive public URLs,
while preserving alt text and titles.

.PARAMETER File
The path to the markdown file to update.

.PARAMETER ImageMappings
An array of objects containing the mapping between original markdown and new URLs.
Each object should have OriginalMarkdown and NewUrl properties.

.EXAMPLE
$mappings = @(
    @{ OriginalMarkdown = "![alt](local.jpg)"; NewUrl = "https://drive.google.com/uc?export=view&id=123" }
)
Update-MarkdownImageUrls -File "post.md" -ImageMappings $mappings
#>
function Update-MarkdownImageUrls {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
        [string]$File,
        
        [Parameter(Mandatory=$true)]
        [array]$ImageMappings
    )

    $content = Get-Content -Path $File -Raw
    $originalContent = $content

    foreach ($mapping in $ImageMappings) {
        $originalMarkdown = $mapping.OriginalMarkdown
        $newUrl = $mapping.NewUrl
        $altText = $mapping.AltText
        $title = $mapping.Title
        
        # Construct the new markdown image syntax
        if ($title) {
            $newMarkdown = "![$altText]($newUrl `"$title`")"
        } else {
            $newMarkdown = "![$altText]($newUrl)"
        }
        
        # Replace the original markdown with the new one
        $content = $content -replace [regex]::Escape($originalMarkdown), $newMarkdown
    }

    # Only write the file if content has changed
    if ($content -ne $originalContent) {
        Set-Content -Path $File -Value $content -NoNewline
        Write-Verbose "Updated markdown file: $File"
        return $true
    } else {
        Write-Verbose "No changes made to markdown file: $File"
        return $false
    }
}
