Describe "Find-MarkdownImages" {
  BeforeEach {
    Import-Module $PSScriptRoot\..\PSBlogger.psm1 -Force
    Import-Module $PSScriptRoot\_TestHelpers.ps1 -Force

    # Create test images in TestDrive
    New-TestImage "TestDrive:\test-image1.png"
    New-TestImage "TestDrive:\subfolder\test-image2.jpg"
    New-TestImage "TestDrive:\absolute-image.gif"

    InModuleScope PSBlogger {
      # reset blogger session to ensure that user preferences are not carried over into test
      $BloggerSession.AttachmentsDirectory = $null
    }
  }

  Context "Basic image detection" {
      It "Should include external images by default" {
        # arrange
        $markdownFile = Join-Path "TestDrive:" "external.md"
        $markdownContent = @(
          "# Test Post"
          ""
          "External image:"
          "![External](https://example.com/image.png)"
        ) -join [Environment]::NewLine
        Set-MarkdownFile $markdownFile $markdownContent

        # act
        $result = Find-MarkdownImages -File $markdownFile

        # assert
        $result.Count | Should -Be 1
        $result[0].AltText | Should -Be "External"
        $result[0].RelativePath | Should -Be "https://example.com/image.png"
        $result[0].LocalPath | Should -Be "https://example.com/image.png"
      }

      It "Should exclude external images when -ExcludeExternal is used" {
        # arrange
        $markdownFile = Join-Path "TestDrive:" "external-exclude.md"
        $markdownContent = @(
          "# Test Post"
          ""
          "External image:"
          "![External](https://example.com/image.png)"
          "Local image:"
          "![Local](test-image1.png)"
        ) -join [Environment]::NewLine
        Set-MarkdownFile $markdownFile $markdownContent

        # act
        $result = Find-MarkdownImages -File $markdownFile -ExcludeExternal

        # assert
        $result.Count | Should -Be 1
        $result[0].AltText | Should -Be "Local"
        $result[0].FileName | Should -Be "test-image1.png"
        $result[0].RelativePath | Should -Be "test-image1.png"
      }

    It "Should return an empty array if there are no images" {
      # arrange
      $markdownFile = Join-Path "TestDrive:" "no-images.md"
      $markdownContent = "# Test Post"
      Set-MarkdownFile $markdownFile $markdownContent

      # act
      $result = Find-MarkdownImages -File $markdownFile

      # assert
      $result.Count | Should -Be 0
      $result | Should -Be @()
    }

    It "Should find images with alt text only" {
      # arrange
      $markdownFile = Join-Path "TestDrive:" "basic.md"
      $markdownContent = @(
        "# Test Post"
        ""
        "Here's an image:"
        "![Alt text](test-image1.png)"
      ) -join [Environment]::NewLine
      Set-MarkdownFile $markdownFile $markdownContent

      # act
      $result = Find-MarkdownImages -File $markdownFile

      # assert
      $result.Count | Should -Be 1
      $result[0].AltText | Should -Be "Alt text"
      $result[0].FileName | Should -Be "test-image1.png"
      $result[0].OriginalMarkdown | Should -Be "![Alt text](test-image1.png)"
      $result[0].Title | Should -Be ""
      $result[0].LocalPath | Should -BeLike "*test-image1.png"
    }

    It "Should find images with alt text and title" {
      # arrange
      $markdownFile = Join-Path "TestDrive:" "with-title.md"
      $markdownContent = @(
        "# Test Post"
        ""
        "Here's a screenshot:"
        '![Screenshot](test-image1.png "Application Screenshot")'
      ) -join [Environment]::NewLine

      Set-MarkdownFile $markdownFile $markdownContent

      # act
      $result = Find-MarkdownImages -File $markdownFile

      # assert
      $result.Count | Should -Be 1
      $result[0].AltText | Should -Be "Screenshot"
      $result[0].Title | Should -Be "Application Screenshot"
      $result[0].OriginalMarkdown | Should -Be '![Screenshot](test-image1.png "Application Screenshot")'
    }

    It "Should find multiple images in the same file" {
      # arrange
      $markdownFile = Join-Path "TestDrive:" "multiple.md"
      $markdownContent = @(
        "# Test Post"
        ""
        "First image:"
        "![Image 1](test-image1.png)"
        ""
        "Second image:"
        "![Image 2](subfolder/test-image2.jpg `"Second image title`")"
        ""
        "Third image (reused):"
        "![Image 3](test-image1.png `"Reused image`")"
      ) -join [Environment]::NewLine
      Set-MarkdownFile $markdownFile $markdownContent

      # act
      $result = Find-MarkdownImages -File $markdownFile

      # assert
      $result.Count | Should -Be 3
      $result[0].FileName | Should -Be "test-image1.png"
      $result[1].FileName | Should -Be "test-image2.jpg"
      $result[2].FileName | Should -Be "test-image1.png"
      $result[1].Title | Should -Be "Second image title"
    }
  }

  Context "Image Path resolution" {
      It "Should return the original value for external URLs in Resolve-ImageFilePath" {
        InModuleScope PSBlogger {
          $result = Resolve-ImageFilePath -FilePath "https://example.com/image.png" -BaseDirectory "TestDrive:/" -AttachmentsDirectory "TestDrive:/attachments"
          $result | Should -Be "https://example.com/image.png"
        }
      }
    It "Should resolve relative paths correctly" {
      # arrange
      $markdownFile = Join-Path "TestDrive:" "relative.md"
      $markdownContent = @(
        ""
        "![Relative image](./subfolder/test-image2.jpg)"
      ) -join [Environment]::NewLine
      Set-MarkdownFile $markdownFile $markdownContent

      # act
      $result = Find-MarkdownImages -File $markdownFile

      # assert
      $result.Count | Should -Be 1
      $result[0].FileName | Should -Be "test-image2.jpg"
      $result[0].RelativePath | Should -Be "./subfolder/test-image2.jpg"
      $result[0].LocalPath | Should -BeLike "*subfolder*test-image2.jpg"
    }

    It "Should handle absolute paths" {
      # arrange
      $markdownFile = Join-Path "TestDrive:" "absolute.md"
      $absolutePath = (Get-Item (Join-Path "TestDrive:" "absolute-image.gif")).FullName
      $markdownContent = @(
        ""
        "![Absolute image]($absolutePath)"
      ) -join [Environment]::NewLine
      Set-MarkdownFile $markdownFile $markdownContent

      # act
      $result = Find-MarkdownImages -File $markdownFile

      # assert
      $result.Count | Should -Be 1
      $result[0].FileName | Should -Be "absolute-image.gif"
      $result[0].LocalPath | Should -Be $absolutePath
    }

    It "Should handle parent directory references" {
      # arrange
      # Create a markdown file in a subdirectory
      $subDir = Join-Path "TestDrive:" "subdir"
      New-Item -Path $subDir -ItemType Directory -Force
      $markdownFile = Join-Path $subDir "parent-ref.md"
      $markdownContent = @(
        ""
        "![Parent image](../test-image1.png)"
      ) -join [Environment]::NewLine
      Set-MarkdownFile $markdownFile $markdownContent

      # act
      $result = Find-MarkdownImages -File $markdownFile

      # assert
      $result.Count | Should -Be 1
      $result[0].FileName | Should -Be "test-image1.png"
      $result[0].RelativePath | Should -Be "../test-image1.png"
    }
  }

  Context "Path resolution with attachments directory" {
    BeforeEach{
      # create images in the attachments directory
      New-TestImage "TestDrive:\attachments\test-attachment1.png"
      New-TestImage "TestDrive:\attachments\subfolder\test-attachment2.jpg"
    }

    It "Should resolve absolute image in the attachments directory" {
      # arrange
      $markdownFile = Join-Path "TestDrive:" "attachments.md"
      $markdownContent = @(
        ""
        "![Image in attachments](test-attachment1.png)"
      ) -join [Environment]::NewLine
      Set-MarkdownFile $markdownFile $markdownContent

      # act
      $result = Find-MarkdownImages -File $markdownFile -AttachmentsDirectory "TestDrive:\attachments"

      # assert
      $result.Count | Should -Be 1
      $result[0].FileName | Should -Be "test-attachment1.png"
      $result[0].LocalPath | Should -BeLike "*attachments*test-attachment1.png"
    }

    It "Should resolve absolute image with subfolder relative to the attachments directory" {
      # arrange
      $markdownFile = Join-Path "TestDrive:" "attachments-subfolder.md"
      $markdownContent = @(
        ""
        "![Image in subfolder](subfolder/test-attachment2.jpg)"
      ) -join [Environment]::NewLine
      Set-MarkdownFile $markdownFile $markdownContent

      # act
      $result = Find-MarkdownImages -File $markdownFile -AttachmentsDirectory "TestDrive:\attachments"

      # assert
      $result.Count | Should -Be 1
      $result[0].FileName | Should -Be "test-attachment2.jpg"
      $result[0].LocalPath | Should -BeLike "*attachments*subfolder*test-attachment2.jpg"
    }

    It "Should find images in subfolders of the attachments directory when markdown does not specify a subfolder" {
      # arrange
      $markdownFile = Join-Path "TestDrive:" "attachments-subfolder.md"
      $markdownContent = @(
        ""
        "![Image in subfolder](test-attachment2.jpg)" # this is in the subfolder
      ) -join [Environment]::NewLine
      Set-MarkdownFile $markdownFile $markdownContent

      # act
      $result = Find-MarkdownImages -File $markdownFile -AttachmentsDirectory "TestDrive:\attachments"

      # assert
      $result.Count | Should -Be 1
      $result[0].FileName | Should -Be "test-attachment2.jpg"
      $result[0].LocalPath | Should -BeLike "*attachments*subfolder*test-attachment2.jpg"
    }

    It "Should use folder of file if attachments directory is not specified" {
      # arrange
      $markdownFile = Join-Path "TestDrive:" "relative-path.md"
      $markdownContent = @(
        ""
        "![Image with relative path](test-attachment1.png)"
      ) -join [Environment]::NewLine
      Set-MarkdownFile $markdownFile $markdownContent

      # act
      $result = Find-MarkdownImages -File $markdownFile

      # assert
      $result.Count | Should -Be 1
      $result[0].FileName | Should -Be "test-attachment1.png"
      $result[0].LocalPath | Should -BeLike "*attachments*test-attachment1.png"
    }

    It "Should use attachments directory user preference if available" {
      # arrange
      InModuleScope PSBlogger {
        $BloggerSession.AttachmentsDirectory = "TestDrive:\attachments"
      }

      # use a markdown file that is a sibling to attachments directory to ensure
      # attachments are not in a subfolder of the markdown file
      $markdownFile = "TestDrive:\subfolder\attachments-preference.md"
      $markdownContent = @(
        ""
        "![Image in attachments directory](test-attachment1.png)"
      ) -join [Environment]::NewLine
      Set-MarkdownFile $markdownFile $markdownContent

      # act
      $result = Find-MarkdownImages -File $markdownFile

      # assert
      $result.Count | Should -Be 1
      $result[0].FileName | Should -Be "test-attachment1.png"
      $result[0].LocalPath | Should -BeLike "*attachments*test-attachment1.png"
    }
  }

  Context "Filtering and validation" {
    It "Should skip images that are already web hosted (HTTP/HTTPS)" {
      # arrange
      $markdownFile = Join-Path "TestDrive:" "with-urls.md"
      $markdownContent = @(
        ""
        "![Local image](test-image1.png)"
        "![HTTP image](http://example.com/image.jpg)"
        "![HTTPS image](https://example.com/image.png)"
      ) -join [Environment]::NewLine
      Set-MarkdownFile $markdownFile $markdownContent

      # act
      $result = Find-MarkdownImages -File $markdownFile -ExcludeExternal

      # assert
      $result.Count | Should -Be 1
      $result[0].FileName | Should -Be "test-image1.png"
    }

    It "Should skip non-existent files" {
      # arrange
      $markdownFile = Join-Path "TestDrive:" "missing-files.md"
      $markdownContent = @(
        ""
        "![Existing image](test-image1.png)"
        "![Missing image](does-not-exist.jpg)"
        "![Another existing](subfolder/test-image2.jpg)"
      ) -join [Environment]::NewLine
      Set-MarkdownFile $markdownFile $markdownContent

      # act
      $result = Find-MarkdownImages -File $markdownFile

      # assert
      $result.Count | Should -Be 2
      $result[0].FileName | Should -Be "test-image1.png"
      $result[1].FileName | Should -Be "test-image2.jpg"
    }

    It "Should handle empty alt text" {
      # arrange
      $markdownFile = Join-Path "TestDrive:" "empty-alt.md"
      $markdownContent = @(
        ""
        "![](test-image1.png)"
      ) -join [Environment]::NewLine
      Set-MarkdownFile $markdownFile $markdownContent

      # act
      $result = Find-MarkdownImages -File $markdownFile

      # assert
      $result.Count | Should -Be 1
      $result[0].AltText | Should -Be ""
      $result[0].FileName | Should -Be "test-image1.png"
    }
  }

  Context "Edge cases and special characters" {
    It "Should handle images with spaces in filenames" {
      # arrange
      $imageWithSpaces = Join-Path "TestDrive:" "image with spaces.png"
      Set-Content -Path $imageWithSpaces -Value "fake content"

      $markdownFile = Join-Path "TestDrive:" "spaces.md"
      $markdownContent = @(
        ""
        "![Image with spaces](image with spaces.png)"
      ) -join [Environment]::NewLine
      Set-MarkdownFile $markdownFile $markdownContent

      # act
      $result = Find-MarkdownImages -File $markdownFile

      # assert
      $result.Count | Should -Be 1
      $result[0].FileName | Should -Be "image with spaces.png"
    }

    It "Should handle special characters in alt text" {
      # arrange
      $markdownFile = Join-Path "TestDrive:" "special-chars.md"
      $markdownContent = @(
        ""
        "![Alt with `"quotes`" and 'apostrophes'](test-image1.png)"
      ) -join [Environment]::NewLine
      Set-MarkdownFile $markdownFile $markdownContent

      # act
      $result = Find-MarkdownImages -File $markdownFile

      # assert
      $result.Count | Should -Be 1
      $result[0].AltText | Should -Be "Alt with `"quotes`" and 'apostrophes'"
    }

    It "Should handle markdown files with no images" {
      # arrange
      $markdownFile = Join-Path "TestDrive:" "no-images.md"
      $markdownContent = @(
        "# Test Post"
        ""
        "This markdown file has no images."
      ) -join [Environment]::NewLine
      Set-MarkdownFile $markdownFile $markdownContent

      # act
      $result = Find-MarkdownImages -File $markdownFile

      # assert
      $result.Count | Should -Be 0
    }
  }

  Context "Return object structure" {
    It "Should return objects with all expected properties" {
      # arrange
      $markdownFile = Join-Path "TestDrive:" "properties.md"
      $markdownContent = @(
        ""
        "![Test Alt](test-image1.png `"Test Title`")"
      ) -join [Environment]::NewLine
      Set-MarkdownFile $markdownFile $markdownContent

      # act
      $result = Find-MarkdownImages -File $markdownFile

      # assert
      $result.Count | Should -Be 1
      $image = $result[0]
      
      # Check all properties exist
      $image.PSObject.Properties.Name | Should -Contain "OriginalMarkdown"
      $image.PSObject.Properties.Name | Should -Contain "AltText"
      $image.PSObject.Properties.Name | Should -Contain "LocalPath"
      $image.PSObject.Properties.Name | Should -Contain "RelativePath"
      $image.PSObject.Properties.Name | Should -Contain "Title"
      $image.PSObject.Properties.Name | Should -Contain "FileName"
      
      # Check property values
      $image.OriginalMarkdown | Should -Be '![Test Alt](test-image1.png "Test Title")'
      $image.AltText | Should -Be "Test Alt"
      $image.RelativePath | Should -Be "test-image1.png"
      $image.Title | Should -Be "Test Title"
      $image.FileName | Should -Be "test-image1.png"
      $image.LocalPath | Should -BeLike "*test-image1.png"
    }
  }

  Context "Obsidian image format support" {

    BeforeAll {
      $obsidianTestCases = @(
        @{
          Name = "Basic Obsidian format without alt text"
          Content = "![[test-image1.png]]"
          ExpectedCount = 1
          ExpectedAltText = ""
          ExpectedFileName = "test-image1.png"
          ExpectedOriginal = "![[test-image1.png]]"
        },
        @{
          Name = "Obsidian format with alt text"
          Content = "![[test-image1.png|My Alt Text]]"
          ExpectedCount = 1
          ExpectedAltText = "My Alt Text"
          ExpectedFileName = "test-image1.png"
          ExpectedOriginal = "![[test-image1.png|My Alt Text]]"
        },
        @{
          Name = "Obsidian format with subfolder path"
          Content = "![[subfolder/test-image2.jpg|Image in subfolder]]"
          ExpectedCount = 1
          ExpectedAltText = "Image in subfolder"
          ExpectedFileName = "test-image2.jpg"
          ExpectedOriginal = "![[subfolder/test-image2.jpg|Image in subfolder]]"
        },
        @{
          Name = "Obsidian format with empty alt text after pipe"
          Content = "![[test-image1.png|]]"
          ExpectedCount = 1
          ExpectedAltText = ""
          ExpectedFileName = "test-image1.png"
          ExpectedOriginal = "![[test-image1.png|]]"
        },
        @{
          Name = "Multiple Obsidian images"
          Content = @(
            "![[test-image1.png|First image]]",
            "Some text here",
            "![[subfolder/test-image2.jpg]]",
            "More text",
            "![[test-image1.png|Duplicate image]]"
          ) -join [Environment]::NewLine
          ExpectedCount = 3
          ExpectedAltText = @("First image", "", "Duplicate image")
          ExpectedFileName = @("test-image1.png", "test-image2.jpg", "test-image1.png")
        }
      )
    }

    It "Should handle <Name>" -TestCases $obsidianTestCases {
      param($Name, $Content, $ExpectedCount, $ExpectedAltText, $ExpectedFileName, $ExpectedOriginal)
      # arrange
      $markdownFile = Join-Path "TestDrive:" "obsidian-test.md"
      Set-MarkdownFile $markdownFile $Content

      # act
      $result = Find-MarkdownImages -File $markdownFile

      # assert
      $result.Count | Should -Be $ExpectedCount
      
      if ($ExpectedCount -eq 1) {
        $result[0].AltText | Should -Be $ExpectedAltText
        $result[0].FileName | Should -Be $ExpectedFileName
        $result[0].Title | Should -Be ""  # Obsidian format doesn't support titles
        if ($ExpectedOriginal) {
          $result[0].OriginalMarkdown | Should -Be $ExpectedOriginal
        }
      } elseif ($ExpectedCount -gt 1) {
        for ($i = 0; $i -lt $ExpectedCount; $i++) {
          $result[$i].AltText | Should -Be $ExpectedAltText[$i]
          $result[$i].Format | Should -Be $ExpectedFormat[$i]
          $result[$i].FileName | Should -Be $ExpectedFileName[$i]
          $result[$i].Title | Should -Be ""
        }
      }
    }

    It "Should skip Obsidian images with HTTP URLs" {
      # arrange
      $markdownFile = Join-Path "TestDrive:" "obsidian-urls.md"
      $markdownContent = @(
        "![[test-image1.png|Local image]]",
        "![[http://example.com/image.jpg|HTTP image]]",
        "![[https://example.com/image.png|HTTPS image]]"
      ) -join [Environment]::NewLine
      Set-MarkdownFile $markdownFile $markdownContent

      # act
      $result = Find-MarkdownImages -File $markdownFile -ExcludeExternal

      # assert
      $result.Count | Should -Be 1
      $result[0].FileName | Should -Be "test-image1.png"
    }

    It "Should skip non-existent Obsidian images" {
      # arrange
      $markdownFile = Join-Path "TestDrive:" "obsidian-missing.md"
      $markdownContent = @(
        "![[test-image1.png|Existing image]]",
        "![[does-not-exist.jpg|Missing image]]",
        "![[subfolder/test-image2.jpg|Another existing]]"
      ) -join [Environment]::NewLine
      Set-MarkdownFile $markdownFile $markdownContent

      # act
      $result = Find-MarkdownImages -File $markdownFile

      # assert
      $result.Count | Should -Be 2
      $result[0].FileName | Should -Be "test-image1.png"
      $result[1].FileName | Should -Be "test-image2.jpg"
    }

    It "Should not find embedded markdown content" {
      # arrange
      # obsidian can link content from an external file as an embedded markdown block
      $markdownFile = Join-Path "TestDrive:" "obsidian-embedded.md"
      $markdownContent = "![[Embedded Markdown Page|Title]]"
      Set-MarkdownFile $markdownFile $markdownContent

      # act
      $result = Find-MarkdownImages -File $markdownFile

      # assert
      $result.Count | Should -Be 0
    }
  }

  Context "Mixed format support (Standard + Obsidian)" {
    BeforeAll {
      $mixedFormatTestCases = @(
        @{
          Name = "Both standard and Obsidian in same file"
          Content = @(
            "# Mixed Format Test",
            "",
            "Here are some images:",
            "![Standard image](test-image1.png `"Standard title`")",
            "![[test-image1.png|Obsidian image]]",
            "![Another standard](subfolder/test-image2.jpg)",
            "![[subfolder/test-image2.jpg]]"
          ) -join [Environment]::NewLine
          ExpectedCount = 4
          ExpectedAltTexts = @("Standard image", "Obsidian image", "Another standard", "")
          ExpectedTitles = @("Standard title", "", "", "")
        },
        @{
          Name = "Standard format only"
          Content = @(
            "# Standard Format Test",
            "",
            "Here are some images:",
            "![Image 1](test-image1.png)",
            "![Image 2](subfolder/test-image2.jpg `"With title`")"
          ) -join [Environment]::NewLine
          ExpectedCount = 2
          ExpectedAltTexts = @("Image 1", "Image 2")
          ExpectedTitles = @("", "With title")
        },
        @{
          Name = "Obsidian format only"
          Content = @(
            "# Obsidian Format Test",
            "",
            "Here are some images:",
            "![[test-image1.png|Alt 1]]",
            "![[subfolder/test-image2.jpg]]"
          ) -join [Environment]::NewLine
          ExpectedCount = 2
          ExpectedAltTexts = @("Alt 1", "")
          ExpectedTitles = @("", "")
        }
      )
    }

    It "Should handle <Name>" -TestCases $mixedFormatTestCases {
      param($Name, $Content, $ExpectedCount, $ExpectedAltTexts, $ExpectedTitles)
      # arrange
      $markdownFile = Join-Path "TestDrive:" "mixed-format-test.md"
      Set-MarkdownFile $markdownFile $Content

      # act
      $result = Find-MarkdownImages -File $markdownFile

      # assert
      $result.Count | Should -Be $ExpectedCount
      
      for ($i = 0; $i -lt $ExpectedCount; $i++) {
        $result[$i].AltText | Should -Be $ExpectedAltTexts[$i]
        $result[$i].Title | Should -Be $ExpectedTitles[$i]
      }
    }
  }
}
