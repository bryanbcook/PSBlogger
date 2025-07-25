<#
.SYNOPSIS
  Convert a Markdown file to HTML using Pandoc

.PARAMETER File
  The file path of the markdown file

.PARAMETER OutFile
  The resulting html. If this parameter is not specified an HTML file with the same name of the markdown file will be created.

.PARAMETER PassThru
  If specified, the content of the HTML file will be returned as well as written to disk.

.EXAMPLE
  # obtain an HTML representation of the markdown file
  $html = ConvertTo-HtmlFromMarkdown -File "C:\path\to\file.md"

.EXAMPLE
  # write the HTML representation of the markdown file to disk
  ConvertTo-HtmlFromMarkdown -File "C:\path\to\file.md" -OutFile "C:\path\to\file.html"

.EXAMPLE
  # write the HTML representation of the markdown file to disk and return the content
  $html = ConvertTo-HtmlFromMarkdown -File "C:\path\to\file.md" -OutFile "C:\path\to\file.html" -PassThru
#>
function ConvertTo-HtmlFromMarkdown {
  [CmdletBinding(DefaultParameterSetName = "Default")]
  param(
    [Parameter(Mandatory = $true, ParameterSetName = "Default")]
    [Parameter(Mandatory = $true, ParameterSetName = "Persist")]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$File,

    [Parameter(ParameterSetName = "Persist")]
    [string]$OutFile,

    [Parameter(ParameterSetName = "Persist")]
    [switch]$PassThru
  )

  # ensure that the file is an absolute path because pandoc.exe doesn't like powershell relative paths
  $File = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($File)

  # Use pandoc to convert the markdown to Html 
  $pandocArgs = "`"{0}`" " -f $File
  $pandocArgs += "-f {0} " -f $BloggerSession.PandocMarkdownFormat
  $pandocArgs += "-t {0} " -f $BloggerSession.PandocHtmlFormat

  # add template and toc if template is available
  if (Test-Path $BloggerSession.PandocTemplate) {
    Write-Verbose "Using template"
    $pandocArgs += "--template `"{0}`" --toc " -f $BloggerSession.PandocTemplate
  }
  # add additional command-line arguments
  if ($BloggerSession.PandocAdditionalArgs) {
    Write-Verbose "Using additional args"
    $pandocArgs += "{0} " -f $BloggerSession.PandocAdditionalArgs
  }

  if (!($OutFile)) {
    $OutFile = Join-Path (Split-Path $File -Parent) ((Split-Path $File -LeafBase) + ".html")
    # ensure that the file is an absolute path because pandoc.exe doesn't like powershell relative paths
    Write-Verbose "Using OutFile: $OutFile"
  }
  $OutFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutFile)

  $pandocArgs += "-o `"{0}`" " -f $OutFile

  Write-Verbose ">> pandoc $($pandocArgs)"
  Start-Process pandoc -ArgumentList $pandocArgs -NoNewWindow -Wait

  # Apply additional transforms
  $content = Get-Content $OutFile -Raw
    
  ## TEMP: My blog doesn't support <pre><code> yet, so I'm trimming it out.
  # convert <pre><code> -> <pre>
  $content = $content -replace '<pre(.*)><code>', '<pre$1>'
  # convert </code></pre> -> </pre>
  $content = $content -replace '</code></pre>', '</pre>'

  Set-Content -Path $OutFile -Value $content

  if (!($PSCmdlet.ParameterSetName -eq "Persist")) {
    Write-Verbose "Removing temporary file: $OutFile"
    Remove-Item $OutFile

    return $content
  }

  if ($PassThru.IsPresent -and $PassThru) {
    return $content
  }
}