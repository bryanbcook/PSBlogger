Describe "Get-MarkdownFrontMatter" {
  BeforeEach {
    Import-Module $PSScriptRoot\..\PSBlogger.psm1 -Force
    Import-Module $PSScriptRoot\_TestHelpers.ps1 -Force

    $markdownWithFrontMatterFile = "TestDrive:\valid.md"
    $markdownWithFrontMatter = @"
---
title: hello world
postid: 1234
---
# First Heading
"@
    Set-MarkdownFile $markdownWithFrontMatterFile $markdownWithFrontMatter

    $markdownWithoutFrontMatterFile = "TestDrive:\invalid.md"
    $markdownWithoutFrontMatter = @"
# First Heading
"@
    Set-MarkdownFile $markdownWithoutFrontMatterFile $markdownWithoutFrontMatter
  }

  It "Should pull front matter attributes from markdown file" {

    $result = Get-MarkdownFrontMatter -File $markdownWithFrontMatterFile

    $result.title | Should -Be "hello world"
    $result.postId | Should -Be "1234"
  }

  Context "Front Matter does not contain title" {
    It "Should create default title from first heading when available" {

      $result = Get-MarkdownFrontMatter -File $markdownWithoutFrontMatterFile
  
      $result.title | Should -Be "First Heading"
    }
  
    It "Should use file name for title if no headings are present" {
      $file = "TestDrive:\markdown-without-header.md"
      Set-MarkdownFile -Path $file -Content @"
no heading
"@

      $result = Get-MarkdownFrontMatter -File $file

      $result.title | Should -Be "markdown without header"
    }
  }

  
}