<#
.SYNOPSIS
Obtains the Markdown FrontMatter from a Markdown file

.PARAMETER File
Path to a valid Markdown (.md) file

#>
Function Get-MarkdownFrontMatter
{
  Param(

    [Parameter(HelpMessage="Markdown file")]
    [ValidateScript({ Test-Path -Path $_ -Include "*.md"})]
    [string]$File
  )

  $Content = Get-Content $File -Raw
  
  $yamlRegex = '(?smi)(---.*?)(?:---)'

  try {

    $result = $null
    
    if ($Content -match $yamlRegex) {
      $yamlBlock = ($Content | Select-String $yamlRegex -AllMatches).Matches[0].Groups[1].Value
  
      $result = $yamlBlock | ConvertFrom-Yaml -Ordered 
    } else {
      $result = [ordered]@{}
    }

    if (!$result['title']) {
      # attempt set title from first heading
      $result.title = ($Content.Split("`n") | Where-Object { $_.StartsWith("#") } | Select-Object -First 1) -replace '#+ ([\w ]*)\r?', '$1' 
  
      # attempt set title from file name
      if ([string]::IsNullOrEmpty($result.title)) {
        $result.title = [System.IO.Path]::GetFileNameWithoutExtension($File) -replace '[\-_]', ' '
      }
    }

    return $result
  }
  catch {
    $errorMessage = $_.ToString()
    Write-Error "Error parsing yaml front matter in $($File): $errorMessage" -ErrorAction Stop
  }
}