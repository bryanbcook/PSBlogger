# Module Design

## Setup + Config

- Setup the google access-token + refresh token, save it to disk

  ```
  Init-Blogger -clientId -clientSecret -redirectUri -code
  ```

  And if we could host a weblistener, we could launch the browser and wait for the auth-flow

  ```
  Connect-Blogger
  ```

We want configuration settings to store default values.

- Get configuration settings. This returns an object with settings to use.

  ```
  Get-BloggerConfig
  ```

- Set Configuration settings. You can pass individual settings. Set to "" to erase

  ```
  Set-BloggerConfig 
  ```


## Blogger Capabilities

- Get a list of my blogs
  
  ```
  Get-BloggerBlogs
  ```

- Get a list of blogger posts and save to disk

  ```
  Get-BloggerPosts -blogid -directory
  ```

- Publish to Blogger.  We also need to consider 'publishing' or scheduling a publish
  
  ```
  Publish-BloggerPost -blogid -content -title -draft
  Publish-BloggerPost -blogid -postid -title 
  ```

## Google Drive

We need the ability to upload images to google drive. The upload process would read the images from the markdown and if the backing URL isn't Google Drive, it uploads to google and then updates the markdown. You should be able to publish the images independently of the blog.

- Test if an image exists in GDrive

  ```
  Test-GDriveImage
  ```

- Upload an image to GDrive

  ```
  Send-GDriveImage -file 
  ```

## Markdown

- Related to finding images in the markdown and uploading, we want:

```
Get-MarkdownLinks -file
```

and

```
Update-MarkdownLink -file -path -url
```

- We'll also need to get the meta-data from the markdown

  ```
  Show-MarkdownFrontMatter
  ```

## Pandoc

The conversion of markdown to HTML will use pandoc with some custom extensions to format things like TOC.

- Convert Markdown to HTML so that it can be posted.

  ```
  ConvertTo-HtmlFromMarkdown -file something.md
  ```

  ```
  pandoc test.md -f markdown -t html -o test.html
  ```

- Upload the images in the markdown to Google Drive.  This involves:

  - Find all the images in the markdown that need to be uploaded
  - Upload the files in the markdown to google drive
  - Update the markdown with the values

  ```
  Publish-GDriveImages -file something.md
  ```

- Update the local files for a post if they've been updated.  This involves:

  - find all the referenced images in the markdown
  - get the modified date from the local file
  - get the modified date from google drive
  - upload newer files to google drive

  ```
  Update-GDriveImages -file something.md
  ```

- The "money shot" is performing the work of converting the markdown and publishing to blogger. Assuming this involves:
  
  - Publish-GDriveImages
  - Update-GDriveImages
  - ConvertTo-HtmlFromMarkDown
  - Get-MarkdownFrontMatter
  - Publish-BloggerPost

  ```
  Publish-MarkdownToBlog -file post.md
  ```