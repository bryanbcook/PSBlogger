<#
.SYNOPSIS
    Convert HTML content or a HTML file to Markdown using Pandoc

.PARAMETER File
    The file path of the html file. Required when Content is not specified.

.PARAMETER Content
    The HTML content to convert to Markdown. Required when File is not specified.

.PARAMETER OutFile
    The resulting markdown file, if specified.

#>
function ConvertTo-MarkdownFromHtml {
  param(
    [Parameter(Mandatory, ParameterSetName = "FromFile")]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$File,

    [Parameter(Mandatory, ParameterSetName = "FromContent")]
    [string]$Content,

    [Parameter(ParameterSetName = "FromFile")]
    [Parameter(Mandatory=$false, ParameterSetName = "FromContent")]
    [string]$OutFile
  )

  # when FromContent is specified, write the content to a temporary file
  if ($PSCmdlet.ParameterSetName -eq "FromContent") {
    # If content is provided, create a temporary file
    $tempFile = [System.IO.Path]::GetTempFileName() + ".html"
    Set-Content -Path $tempFile -Value $Content
    $File = $tempFile
  }

  # ensure that the file is an absolute path because pandoc.exe doesn't like powershell relative paths
  $File = (Resolve-Path $File).Path

  # Use pandoc to convert the markdown to Html 
  $pandocArgs = "`"{0}`" " -f $File
  $pandocArgs += "-f {0} " -f $BloggerSession.PandocHtmlFormat
  $pandocArgs += "-t {0} " -f $BloggerSession.PandocMarkdownFormat

  # add additional command-line arguments
  if ($BloggerSession.PandocAdditionalArgs) {
    Write-Verbose "Using additional args"
    $pandocArgs += "{0} " -f $BloggerSession.PandocAdditionalArgs
  }

  if (!($OutFile)) {
    $OutFile = Join-Path (Split-Path $File -Parent) ((Split-Path $File -LeafBase) + ".md")
    Write-Verbose "Using OutFile: $OutFile"
  }

  $pandocArgs += "-o `"{0}`" " -f $OutFile

  Write-Verbose ">> pandoc $($pandocArgs)"
  Start-Process pandoc -ArgumentList $pandocArgs -NoNewWindow -Wait

  $content = Get-Content $OutFile -Raw

  # remove temporary files
  if ($PSCmdlet.ParameterSetName -eq "FromContent") {
    Remove-Item $File
  } elseif (!$PSBoundParameters.ContainsKey("OutFile")) {
    Remove-Item $OutFile
  } 

  return $content
}