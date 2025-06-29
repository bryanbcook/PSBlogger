# PSBlogger

A PowerShell library for publishing markdown files authored in markdown to Blogger. This library exists because _OpenLiveWriter_ isn't being actively maintained and [Typora](https://typora.io) and [Obsidian](https://obsidian.md) are awesome. The intention is that you would author your blog posts in markdown and then drop to a command-prompt to publish them to Blogger.

> **Note**:
>
> Currently in development. Currently tested on Windows

## Getting Started

1. Install necessary dependencies:

   ```
   choco install pandoc
   ```

   (Future: still need to publish to PowerShell nuget library)
   ```
   Install-Module PSBlogger
   ```

1. Authenticate with your Blogger account:

   ```
   Initialize-Blogger
   ```

   This will launch a browser and authenticate with Google.

   > **Notes**:
   >
   > - You may need to perform this command with an elevated command-prompt (Administrator) as this
   >   activity opens a temporary port listener for oauth callbacks.
   >
   > - You may be prompted that _Google hasn't verified the app yet_. Working on it. Click Continue for now.

1. List your blogs

   ```
   Get-BloggerBlogs
   ```
   
1. Set a default blog

   ```
   Set-BloggerConfig -Name BlogId <blogid>
   ```

1. List your posts for that blog

   ```
   Get-BloggerPosts
   ```

1. Publish a markdown file to your blog as draft

   ```
   Publish-MarkdownBloggerPost -File .\filename.md -Draft
   ```

   This will post a draft to your blog and update the markdown file with the blogger `postid` and mark it as `wip`.

1. Publish a markdown file to your blog

   ```
   Publish-MarkdownBloggerPost -File .\filename.md
   ```

## Image Support

PSBlogger supports Google Drive for hosting your images.

- Add-GoogleDriveFile: Uploads a file to your Google Drive
- Add-GoogleDriveFolder: Creates a folder in your Google Drive
- Get-GoogleDriveItems: Query the contents of your Google Drive
- Set-GoogleDriveFilePermission: Modifes the permission of a file.

Markdown methods for managing images.

- Find-MarkdownImages: scans the markdown file to locate images in the content.
- Update-MarkdownImages: updates the content in the markdown file with updated urls

## Future

- Download existing posts to your machine in markdown
