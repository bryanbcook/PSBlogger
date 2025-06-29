function Set-MarkdownFile($path, $content) {
  <#
    .SYNOPSIS
    Set the content of a markdown file
  #>
  Set-Content -Path $path -Value $content
}

function New-BlogPost($id) {
  <#
    .SYNOPSIS
    Blogger Blog post
  #>
  @{ id=$id }
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