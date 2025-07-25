<#
.SYNOPSIS
  Convert HTML content or a HTML file to Markdown using Pandoc

.PARAMETER File
  The file path of the html file. Required when Content is not specified.

.PARAMETER Content
  The HTML content to convert to Markdown. Required when File is not specified.

.PARAMETER OutFile
  The resulting markdown file, if specified.

.PARAMETER PassThru
  Return markdown content as output, in addition to writing it to disk.

.EXAMPLE
  # Convert HTML content to Markdown and save to a file
  ConvertTo-MarkdownFromHtml -Content "<h1>Hello World</h1>" -OutFile "C:\path\to\file.md"

.EXAMPLE
  # Convert a HTML file to Markdown and save to a file
  ConvertTo-MarkdownFromHtml -File "C:\path\to\file.html" -OutFile "C:\path\to\file.md"

.EXAMPLE
  # Convert a HTML file to Markdown and return the content
  $content = ConvertTo-MarkdownFromHtml -File "C:\path\to\file.html"

.EXAMPLE
  # Convert HTML content to Markdown and return the content
  $content = ConvertTo-MarkdownFromHtml -Content "<h1>Hello World</h1>"

.EXAMPLE
  # Convert HTML content to Markdown and save to a file, returning the content
  $content = ConvertTo-MarkdownFromHtml -Content "<h1>Hello World</h1>" -OutFile "C:\path\to\file.md" -PassThru

.EXAMPLE
  # Convert a HTML file to Markdown and save to a file, returning the content
  $content = ConvertTo-MarkdownFromHtml -File "C:\path\to\file.html" -OutFile "C:\path\to\file.md" -PassThru
#>
function ConvertTo-MarkdownFromHtml {
  param(
    [Parameter(Mandatory, ParameterSetName = "FromFile")]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$File,

    [Parameter(Mandatory, ParameterSetName = "FromContent")]
    [string]$Content,

    [Parameter(ParameterSetName = "FromFile")]
    [Parameter(ParameterSetName = "FromContent")]
    [string]$OutFile,

    [Parameter(ParameterSetName = "FromFile")]
    [Parameter(ParameterSetName = "FromContent")]
    [switch]$PassThru
  )

  # when FromContent is specified, write the content to a temporary file
  if ($PSCmdlet.ParameterSetName -eq "FromContent") {
    # If content is provided, create a temporary file
    $tempFile = [System.IO.Path]::GetTempFileName() + ".html"
    Set-Content -Path $tempFile -Value $Content
    $File = $tempFile
  }

  # ensure that the file is an absolute path because pandoc.exe doesn't like powershell relative paths
  $File = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($File)

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
  # ensure that the file is an absolute path because pandoc.exe doesn't like powershell relative paths
  $OutFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutFile)

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

  # return output if not persisting to disk or PassThru is specified
  if (!$PSBoundParameters.ContainsKey("OutFile") -or ($PassThru.IsPresent -and $PassThru)) {
    Write-Verbose "Returning content"
    return $content
  }
}