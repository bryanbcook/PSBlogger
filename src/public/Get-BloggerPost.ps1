<#
.DESCRIPTION
  Retrieves an individual post from a specified Blogger blog and optionally saves the content to a file as HTML or Markdown.

.PARAMETER BlogId
  The ID of the blog to retrieve the post from. If not specified, uses the BlogId in the user preferences.

.PARAMETER PostId
  The ID of the post to retrieve. This parameter is required.

.PARAMETER Format
  The format of the post content to retrieve. Use either Markdown, JSON or HTML.

.PARAMETER FolderDateFormat
  The folder name as expressed in a DateTime format string. For example, "YYYY/MM" which will save files
  in a folder structure like "2023/10" based on the date of the post.

.PARAMETER OutDirectory
  The directory where the HTML file will be saved. If not specified, uses the current directory.

.PARAMETER PassThru
  If specified, the function will return the post object instead of just saving it to a file

.EXAMPLE
  # obtain a post from the blog defined in the user preferences
  $post = Get-BloggerPost -PostId "1234567890123456789"

.EXAMPLE
  # obtain a post from a specified blog and save it as HTML in a specific directory
  Get-BloggerPost -BlogId "9876543210987654321" -PostId "1234567890123456789" -Format HTML -OutDirectory "C:\temp"

.EXAMPLE
  # obtain a post from a specified blog and save it as Markdown in a specific directory with a date-based folder structure
  Get-BloggerPost -BlogId "9876543210987654321" -PostId "1234567890123456789" -Format Markdown -DateFormat "YYYY\\MM" -OutDirectory "C:\blogposts"

.EXAMPLE
  # obtain a post from a specified blog and save it as JSON in the current directory
  Get-BloggerPost -BlogId "9876543210987654321" -PostId "1234567890123456789" -Format JSON

.EXAMPLE
  # obtain a post from a specified blog, write it to disk and return the post object
  $post = Get-BloggerPost -BlogId "9876543210987654321" -PostId "1234567890123456789" -Format Markdown -PassThru
#>
Function Get-BloggerPost {
  [CmdletBinding()]
  param(
    [Parameter(ParameterSetName = "Default")]
    [Parameter(ParameterSetName = "Persist")]
    [string]$BlogId,

    [Parameter(Mandatory,ParameterSetName = "Default")]
    [Parameter(Mandatory,ParameterSetName = "Persist")]
    [string]$PostId,

    [Parameter(Mandatory, ParameterSetName = "Persist")]
    [ValidateSet("HTML", "Markdown", "JSON")]
    [string]$Format,

    [Parameter(ParameterSetName ="Persist")]
    [string]$FolderDateFormat,

    [Parameter(ParameterSetName = "Persist")]
    [string]$OutDirectory = (Get-Location).Path,

    [Parameter(ParameterSetName = "Persist")]
    [switch]$PassThru
  )

  if (!$PSBoundParameters.ContainsKey("BlogId")) {
    $BlogId = $BloggerSession.BlogId
    if ([string]::IsNullOrEmpty($BlogId) -or $BlogId -eq 0) {
      throw "BlogId not specified and no default BlogId found in settings."
    }
  }

  try {
    $uri = "https://www.googleapis.com/blogger/v3/blogs/$BlogId/posts/$PostId"
        
    $result = Invoke-GApi -uri $uri
        
    if ($null -eq $result) {
      throw "No post found with PostId '$PostId' in blog '$BlogId'."
    }
    Write-Verbose "Post: $($result | ConvertTo-Json -Depth 10)"

    # Construct a subfolder based on the published date
    if ($FolderDateFormat -and $result.published) {
      $formattedDate = $result.published.ToString($FolderDateFormat)
      Write-Verbose "Using published date '$formattedDate' for folder structure."
      $OutDirectory = Join-Path -Path $OutDirectory -ChildPath $formattedDate
      Write-Verbose "Output directory set to: $OutDirectory"
    }

    # Ensure the output directory exists
    if (!(Test-Path -Path $OutDirectory)) {
      try {
        Write-Verbose "Creating output directory: $OutDirectory"
        New-Item -ItemType Directory -Path $OutDirectory -Force | Out-Null
      }
      catch {
        throw "Failed to create output directory '$OutDirectory': $($_.Exception.Message)"
      }
    }
    Write-Verbose "Using output directory: $OutDirectory"

    # Extract the HTML content
    $htmlContent = $result.content
        
    if ([string]::IsNullOrEmpty($htmlContent)) {
      Write-Warning "Post '$PostId' has no content."
      $htmlContent = ""
    }

    # Create the output file path
    try {
      
      switch ($Format) {

        # Save the HTML content to a file
        "HTML" {

          $fileName = "$PostId.html"
          $filePath = Join-Path -Path $OutDirectory -ChildPath $fileName
          $htmlContent | Out-File -FilePath $filePath -Encoding UTF8
          Write-Verbose "Post content saved to: $filePath"
        }

        # Save the Post to a Markdown file
        "Markdown" {
          
          $title = $result.title
          $frontMatter = [ordered]@{
            postId = $result.id
          }
          if ($result.PSObject.Properties.Name -contains "labels") {
            Write-Verbose "Using post labels: $($result.labels)"
            $frontMatter['tags'] = $result.labels
          } else {
            Write-Verbose "No labels found in post, using empty tags."
            $frontMatter['tags'] = @()
          }
          Write-Verbose "Saving frontmatter: $($frontMatter | ConvertTo-Json -Depth 10)"
          $file = "$title.md"
          
          $filePath = Join-Path -Path $OutDirectory -ChildPath $file
          ConvertTo-MarkdownFromHtml -Content $result.content -OutFile $filePath
          Set-MarkdownFrontMatter -File $filePath -Replace $frontMatter
          Write-Verbose "Post content saved to: $filePath"
        }

        "JSON" {
          $fileName = "$PostId.json"
          $filePath = Join-Path -Path $OutDirectory -ChildPath $fileName
          $result | ConvertTo-Json | Out-File -FilePath $filePath -Encoding UTF8
          Write-Verbose "Post content saved to: $filePath"
        }
      }  

      # Return the post object for further processing if needed
      if (!($PSCmdlet.ParameterSetName -eq "Persist") -or ($PassThru.IsPresent -and $PassThru)) {
        Write-Verbose "Returning blog post object"
        return $result
      }
    }
    catch {
      throw "Failed to save post content: $($_.Exception.Message)"
    }
  }
  catch {
    # Handle specific HTTP errors
    if ($_.Exception -like "*404*" -or $_.Exception -like "*Not Found*") {
      throw "Post with PostId '$PostId' not found in blog '$BlogId'. Please verify the PostId and BlogId are correct."
    }
    elseif ($_.Exception -like "*403*" -or $_.Exception -like "*Forbidden*") {
      throw "Access denied to blog '$BlogId' or post '$PostId'. Please verify your permissions."
    }
    else {
      Write-Error $_.ToString() -ErrorAction Stop
    }
  }
}
