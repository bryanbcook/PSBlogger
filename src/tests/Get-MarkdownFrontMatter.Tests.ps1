Describe "Get-MarkdownFrontMatter" {
  BeforeAll {
    Import-Module $PSScriptRoot/_TestHelpers.ps1 -Force
  }
  BeforeEach {
    Import-Module $PSScriptRoot/../PSBlogger.psm1 -Force   

    $markdownWithFrontMatterFile = Get-TestFilePath 'valid.md'
    $markdownWithFrontMatter = @"
---
title: hello world
postid: 1234
---
# First Heading
"@
    Set-MarkdownFile $markdownWithFrontMatterFile $markdownWithFrontMatter

    $markdownWithoutFrontMatterFile = Get-TestFilePath 'invalid.md'
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

  It "Should only find front matter at the top of the file" {
    # arrange
    # create content with two --- sections
    $content = @(
      "---"
      "title: First Title"
      "---"
      "# Heading"
      "An example with a page break or hr"
      "---"
      "# Second Title"
    ) -join "`n"
    $path = Get-TestFilePath 'front-matter-top-only.md'
    Set-MarkdownFile -Path $path -Content $content

    # act
    $result = Get-MarkdownFrontMatter -File $path

    # assert
    $result.title | Should -Be "First Title"
  }

  It "Should not complain if content has --- but not intended as front matter" {
    # arrange
    $content = @(
      "An example with a page break or hr"
      "````"
      "---"
      "Some content in a block"
      "---"
      "````"
    ) -join "`n"
    $path = Get-TestFilePath 'no-front-matter.md'
    Set-MarkdownFile -Path $path -Content $content

    # act
    $result = Get-MarkdownFrontMatter -File $path

    # assert
    $result.title | Should -Be "no front matter" # from file name
  }

  Context "Front Matter does not contain title" {
    It "Should create default title from first heading when available" {

      # act
      $result = Get-MarkdownFrontMatter -File $markdownWithoutFrontMatterFile
  
      # assert
      $result.title | Should -Be "First Heading"
    }

    It "Should use file name for title if no headings are present" {
      $file = Get-TestFilePath 'markdown-without-header.md'
      Set-MarkdownFile -Path $file -Content @"
no heading
"@

      $result = Get-MarkdownFrontMatter -File $file

      # The expected title is the file name without extension, with dashes replaced by spaces
      $expectedTitle = ([System.IO.Path]::GetFileNameWithoutExtension($file) -replace '-', ' ')
      $result.title | Should -Be $expectedTitle
    }
  }  
}