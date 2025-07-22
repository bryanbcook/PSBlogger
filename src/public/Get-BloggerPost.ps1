<#
.DESCRIPTION
  Retrieves an individual post from a specified Blogger blog and saves the HTML content to a file.

.PARAMETER BlogId
  The ID of the blog to retrieve the post from. If not specified, uses the BlogId in the user preferences.

.PARAMETER PostId
  The ID of the post to retrieve. This parameter is required.

.PARAMETER OutDirectory
  The directory where the HTML file will be saved. If not specified, uses the current directory.

.EXAMPLE
  Get-BloggerPost -PostId "1234567890123456789"

.EXAMPLE
  Get-BloggerPost -BlogId "9876543210987654321" -PostId "1234567890123456789" -OutDirectory "C:\temp"
#>
Function Get-BloggerPost {
  [CmdletBinding()]
  param(
    [string]$BlogId,

    [Parameter(Mandatory)]
    [string]$PostId,

    [string]$OutDirectory = (Get-Location).Path
  )

  if (!$PSBoundParameters.ContainsKey("BlogId")) {
    $BlogId = $BloggerSession.BlogId
    if ([string]::IsNullOrEmpty($BlogId) -or $BlogId -eq 0) {
      throw "BlogId not specified and no default BlogId found in settings."
    }
  }

  if ([string]::IsNullOrEmpty($PostId)) {
    throw "PostId is required."
  }

  # Ensure the output directory exists
  if (!(Test-Path -Path $OutDirectory)) {
    try {
      New-Item -ItemType Directory -Path $OutDirectory -Force | Out-Null
    }
    catch {
      throw "Failed to create output directory '$OutDirectory': $($_.Exception.Message)"
    }
  }

  try {
    $uri = "https://www.googleapis.com/blogger/v3/blogs/$BlogId/posts/$PostId"
        
    $result = Invoke-GApi -uri $uri
        
    if ($null -eq $result) {
      throw "No post found with PostId '$PostId' in blog '$BlogId'."
    }

    # Extract the HTML content
    $htmlContent = $result.content
        
    if ([string]::IsNullOrEmpty($htmlContent)) {
      Write-Warning "Post '$PostId' has no content."
      $htmlContent = ""
    }

    # Create the output file path
    $fileName = "$PostId.html"
    $filePath = Join-Path -Path $OutDirectory -ChildPath $fileName

    # Save the HTML content to the file
    try {
      $htmlContent | Out-File -FilePath $filePath -Encoding UTF8
      Write-Verbose "Post content saved to: $filePath"
            
      # Return the post object for further processing if needed
      return $result
    }
    catch {
      throw "Failed to save post content to file '$filePath': $($_.Exception.Message)"
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
