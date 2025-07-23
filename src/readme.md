# Module Design

## Setup + Config

- Setup the google access-token + refresh token, save it to disk

  ```
  Initialize-Blogger -clientId -clientSecret -redirectUri -code
  ```

  And if we could host a weblistener, we could launch the browser and wait for the auth-flow

We want configuration settings to store default values.

- Get configuration settings. This returns an object with settings to use.

  ```
  Get-BloggerConfig
  ```

- Set Configuration settings. You can pass individual settings. Set to "" to erase

  ```
  Set-BloggerConfig -Name <parameter> -Value
  ```


## Blogger Capabilities

- Get a list of my blogs
  
  ```
  Get-BloggerBlogs
  ```

- Get a list of blogger posts

  ```
  Get-BloggerPosts -BlogId <blogid> -All
  ```

- Publish to Blogger.  We also need to consider 'publishing' or scheduling a publish
  
  ```
  Publish-BloggerPost -blogid <blogid> -content <html> -title "First Post" -draft
  Publish-BloggerPost -blogid <blogid> -postid <postid> -content <html> -title "First Post"
  ```

## Google Drive

We need the ability to upload images to google drive. The upload process would read the images from the markdown and if the backing URL isn't Google Drive, it uploads to google and then updates the markdown. You should be able to publish the images independently of the blog.

- Get all items from Google Drive

  ```
  Get-GoogleDriveItems -ResultType All
  ```

- Find if an image exists in Google Drive

  ```
  $folder = Get-GoogleDriveItems -ResultType Folders -Title "PSBlogger"
  Get-GoogleDriveItem -ResultType Files -Title image.jpg -Folder $folder.id
  ```

- Upload an image to Google Drive

  ```
  Add-GoogleDriveFile -FilePath "c:\image.jpg" -TargetFolderName "PSBlogger"
  ```

- Make an image publicly accessible to the internet

  ```
  $folder = Get-GoogleDriveItems -ResultType Folders -Title "PSBlogger"
  $file = Get-GoogleDriveItem -ResultType Files -Title image.jpg -Folder $folder.id
  $permission = New-GoogleDriveFilePermission -role "reader" -type "anyone"
  Set-GoogleDriveFilePermission -FileId $file.id -PermissionData $permission
  ```

## Markdown

- Related to finding images in the markdown, we want:

  ```
  $imageMappings = Find-MarkdownImages -File .\file.md
  ```

- After uploading these images, we update the mappings and then update the file:

  ```
  Update-MarkdownImages -File .\file.md -ImageMappings $imageMappings
  ```

- We'll also need to get the meta-data from the markdown

  ```
  Get-MarkdownFrontMatter -File .\file.md
  ```

- And the ability to update the meta-data

  ```
  Set-MarkdownFrontMatter -file .\file.md -Update [ordered]@{ postid = "123" }

## Pandoc

The conversion of markdown to HTML will use pandoc with some custom extensions to format things like TOC.

- Convert Markdown to HTML so that it can be posted.

  ```
  ConvertTo-HtmlFromMarkdown -file something.md
  ```

  ...which is equivalent to:

  ```
  pandoc test.md -f markdown -t html -o test.html
  ```

- Upload the images in the markdown to Google Drive.  This involves:

  - Find all the images in the markdown that need to be uploaded `Find-MarkdownImages`
  - Upload the files in the markdown to google drive `Add-GoogleDriveFile`
  - Update the markdown with the values `Update-MarkdownIamges`

  ```
  Publish-MarkdownDriveImages -file something.md
  ```

- The "money shot" is performing the work of converting the markdown and publishing to blogger. Assuming this involves:
  
  - Publish-MarkdownDriveImages
  - ConvertTo-HtmlFromMarkDown
  - Get-MarkdownFrontMatter
  - Publish-BloggerPost
  - Set-MarkdownFrontMatter

  ```
  Publish-MarkdownBloggerPost -file post.md
  ```