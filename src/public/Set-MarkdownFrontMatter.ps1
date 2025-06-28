Function Set-MarkdownFrontMatter
{
  [CmdletBinding(SupportsShouldProcess=$true)]
  Param(
    [Parameter(Mandatory=$true, HelpMessage="Markdown file")]
    [ValidateScript({ Test-Path $_ -Include "*.md"})]
    [string]$File,

    [Parameter(HelpMessage="Udpate the front-matter with the values supplied.", Mandatory=$true, ParameterSetName="Update")]
    [hashtable]$Update,

    [Parameter(HelpMessage="Replace the front-matter with the hashtable", Mandatory=$true, ParameterSetName="Replace")]
    [System.Collections.Specialized.IOrderedDictionary]$Replace
  )

  try {
    $frontMatter = Get-MarkdownFrontMatter -File $File

    # fetch file contents without the front-matter
    $content = Get-Content -Path $File -Raw
    $content = ($content -replace '(?smi)(---.*?)(?:---)\r?\n?','').Trim()
    
    if ($PSBoundParameters["Update"]) {
      Write-Verbose "Updating FrontMatter in $File"

      $Update.GetEnumerator()| ForEach-Object {
        $Name  = $_.Name
        $Value = $_.Value

        if (!($frontMatter.Contains($Name))) {
          Write-Verbose "Adding Property $($Name): $Value"
          $frontMatter.Add($Name,$Value)
        } else {
          Write-Verbose "Setting Property $($Name): $Value"
          $frontMatter.$Name = $Value
        }
      }
  
    } else {
      Write-Verbose "Using ordered dictionary to replace markdown front matter"
      $frontMatter = $Replace
    }

    $content = ("---`n" + ($frontMatter | ConvertTo-Yaml) + "---`n" + $content).Trim()

    if ($PSCmdlet.ShouldProcess("Update $File")) {
      Set-Content -Path $File -Value $content
    } else {
      Write-Verbose $content
    }
  }
  catch {
    $errorMessage = $_.ToString()
    Write-Error "Couldn't update markdown file: $errorMessage" -ErrorAction Stop
  }  
}