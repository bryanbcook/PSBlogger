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

   > **Note**:
   >
   > You may be prompted that _Google hasn't verified the app yet_. Working on it. Click Continue for now.

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
   Publish-MarkdownBlogPost -File .\filename.md -Draft
   ```

   This will post a draft to your blog and update the markdown file with the blogger `postid` and mark it as `wip`.

1. Publish a markdown file to your blog

   ```
   Publish-MarkdownBlogPost -File .\filename.md
   ```

## Future


- Download existing posts to your machine in markdown
