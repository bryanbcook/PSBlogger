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

1. Fetch an individual post from your blog

   ```
   $post = Get-BloggerPost -PostId <postid>
   ```

   You can also persist the post to disk as HTML or markdown in the current directory.

   When using `HTML` format, files are saved as `<postid>.html`

   When using `Markdown` format, files are saved as `<title>.md`

   When using `JSON` format, files are saved as `<postid>.json`

   ```
   Get-BloggerPost -PostId <postid> -Format HTML
   Get-BloggerPost -PostId <postid> -Format Markdown
   Get-BloggerPost -PostId <postid> -Format JSON
   ```
   
   You can specify an output directory where the file will be saved.

   ```
   Get-BloggerPost -PostId <postid> -OutDirectory "C:\MyPosts" -Format HTML
   ```

   You can also include a `FolderDateFormat` that uses the `published` property of the blog post to construct a subfolder.

   ```
   Get-BloggerPost -PostId <postId> -OutDirectory ".\Blog" -FolderDateFormat "YYYY\\MM" -Format Markdown
   ```

   When persisting to disk, the post object is not returned unless `-PassThru` is specified.

   ```
   $post = Get-BloggerPost -PostId <postid> -Format Markdown -PassThru
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

PSBlogger supports Google Drive for hosting your images and handles both standard markdown and Obsidian image formats.

### Supported Image Formats

PSBlogger can detect and process images in both formats:

- **Standard Markdown**: `![alt text](image.png "optional title")`
- **Obsidian Format**: `![[image.png|alt text]]`

When publishing, all images are converted to standard markdown format with Google Drive URLs, ensuring compatibility across platforms.

### Google Drive Integration

- Add-GoogleDriveFile: Uploads a file to your Google Drive
- Add-GoogleDriveFolder: Creates a folder in your Google Drive
- Get-GoogleDriveItems: Query the contents of your Google Drive
- Set-GoogleDriveFilePermission: Modifes the permission of a file.

### Markdown Image Management

- Find-MarkdownImages: scans the markdown file to locate images in both standard and Obsidian formats
- Update-MarkdownImages: updates the content in the markdown file with updated urls, converting all formats to standard markdown

## Examples

## Download existing posts to your machine in markdown

```powershell
### Initialize the auth settings for your google account
Initialize-Blogger -ClientId <id> -ClientSecret <secret>

### Fetch the available blogs and set the first blog as the default
$blogs = Get-BloggerBlogs
$blogId = $blogs[0].id
Set-BloggerConfig -Name BlogId $blogId

### Fetch posts
$posts = Get-BloggerPosts -All

### Download Posts
$total = $posts.count
$count = 0
foreach($post in $posts) {
   $complete = $count++/$total * 100
   Write-Progress -Activity "Downloading..." -PercentComplete $complete -Status "$complete% ($count of $total)"
   $post = Get-BloggerPost -PostId $post.id -Format Markdown -FolderDateFormat "yyyy\\MM" -OutDirectory ".\Posts" -PassThru
   Write-Host "Downloaded: $($post.title) - $($post.published)"
}
Write-Progress -Activity "Downloading..." -Complete
```
