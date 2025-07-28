Describe "Update-MarkdownImages" {
  BeforeAll {
     Import-Module $PSScriptRoot\_TestHelpers.ps1 -Force
  }
  BeforeEach {
    Import-Module $PSScriptRoot\..\PSBlogger.psm1 -Force
  }

  Context "Update Markdown Images" {

    It "Should replace <scenario> with google file ids" -TestCases @(
      @{ scenario = "local path with alt text"; altText="image"; original = "![](/path/image.png)"}
    ) {
      # act
      # setup image mapping object
      $imagesMappings = @(
        New-MarkdownImage `
          -OriginalMarkdown $original `
          -AltText $altText `
          -NewUrl "https://image.com/12345"
      )
      $expected = "![$altText](https://image.com/12345)"
      $expectedRegex = [regex]::Escape($expected)

      # create test file
      Set-MarkdownFile "TestDrive:\test.md" @(
          "# First Post"
          ""
          "Some content with an $original image"
        ) -join [System.Environment]::NewLine

      # act
      Update-MarkdownImages -File "TestDrive:\test.md" -ImageMappings $imagesMappings
      $result = Get-Content -Path "TestDrive:\test.md" -Raw

      $result | Should -Match $expectedRegex
    }

    It "Should write changes to the OutFile if specified" {
      # arrange
      $inputFile = "TestDrive:\test.md"
      $outputFile = "TestDrive:\output.md"
      $inputContent = @(
        "# First Post"
        ""
        "Some content with an ![image](/path/image.png)"
      ) -join [System.Environment]::NewLine
      Set-MarkdownFile $inputFile $inputContent
      
      $imagesMappings = @(
        New-MarkdownImage `
          -OriginalMarkdown "![image](/path/image.png)" `
          -AltText "image" `
          -NewUrl "https://image.com/12345"
      )

      # act
      Update-MarkdownImages -File $inputFile -ImageMappings $imagesMappings -OutFile $outputFile

      # assert
      $outputContent = Get-Content -Path $outputFile -Raw
      $outputContent | Should -Not -BeNullOrEmpty
      $outputContent | Should -Not -Be $inputContent
    }

    It "Should write changes to the OutFile even if images weren't updated" {
      # arrange
      $inputFile = "TestDrive:\test.md"
      $outputFile = "TestDrive:\output.md"
      Set-MarkdownFile $inputFile "dummy content without images"
      $imagesMappings = @()

      # act
      Update-MarkdownImages -File $inputFile -ImageMappings $imagesMappings -OutFile $outputFile

      # assert
      Test-Path $outputFile | Should -Be $true
    }

  }

  Context "Mixed format image replacement" {
    BeforeAll {
      $mixedFormatTestCases = @(
        @{
          Name = "Standard markdown format"
          Original = "![Alt text](image.png)"
          AltText = "Alt text"
          Title = ""
          NewUrl = "https://drive.google.com/uc?export=view&id=123"
          Expected = "![Alt text](https://drive.google.com/uc?export=view&id=123)"
        },
        @{
          Name = "Standard markdown with title"
          Original = '![Alt text](image.png "Image title")'
          AltText = "Alt text"
          Title = "Image title"
          NewUrl = "https://drive.google.com/uc?export=view&id=123"
          Expected = '![Alt text](https://drive.google.com/uc?export=view&id=123 "Image title")'
        },
        @{
          Name = "Obsidian format without alt text"
          Original = "![[image.png]]"
          AltText = ""
          Title = ""
          NewUrl = "https://drive.google.com/uc?export=view&id=456"
          Expected = "![](https://drive.google.com/uc?export=view&id=456)"
        },
        @{
          Name = "Obsidian format with alt text"
          Original = "![[image.png|My image]]"
          AltText = "My image"
          Title = ""
          NewUrl = "https://drive.google.com/uc?export=view&id=456"
          Expected = "![My image](https://drive.google.com/uc?export=view&id=456)"
        },
        @{
          Name = "Obsidian format with empty alt text after pipe"
          Original = "![[image.png|]]"
          AltText = ""
          Title = ""
          NewUrl = "https://drive.google.com/uc?export=view&id=456"
          Expected = "![](https://drive.google.com/uc?export=view&id=456)"
        }
      )
    }

    It "Should handle <Name>" -TestCases $mixedFormatTestCases {
      param($Name, $Original, $AltText, $Title, $NewUrl, $Expected)
      
      # arrange
      $testFile = "TestDrive:\mixed-format-test.md"
      $content = @(
        "# Test Post"
        ""
        "Before image"
        $Original
        "After image"
      ) -join [System.Environment]::NewLine
      Set-Content -Path $testFile -Value $content

      $imageMapping = New-MarkdownImage `
        -OriginalMarkdown $Original `
        -AltText $AltText `
        -Title $Title `
        -NewUrl $NewUrl

      # act
      $result = Update-MarkdownImages -File $testFile -ImageMappings @($imageMapping)

      # assert
      $result | Should -Be $true
      $updatedContent = Get-Content -Path $testFile -Raw
      $updatedContent | Should -Match ([regex]::Escape($Expected))
      $updatedContent | Should -Not -Match ([regex]::Escape($Original))
    }

    It "Should handle multiple images of different formats in one file" {
      # arrange
      $testFile = "TestDrive:\multiple-formats.md"
      $content = @(
        "# Test Post"
        ""
        "Standard: ![Standard alt](standard.png)"
        "Obsidian: ![[obsidian.jpg|Obsidian alt]]"
        "Another standard: ![Another](another.gif `"With title`")"
        "Another Obsidian: ![[another-obsidian.png]]"
      ) -join [System.Environment]::NewLine
      Set-Content -Path $testFile -Value $content

      $imageMappings = @(
        (New-MarkdownImage -OriginalMarkdown "![Standard alt](standard.png)" -AltText "Standard alt" -Title "" -NewUrl "https://example.com/1"),
        (New-MarkdownImage -OriginalMarkdown "![[obsidian.jpg|Obsidian alt]]" -AltText "Obsidian alt" -Title "" -NewUrl "https://example.com/2"),
        (New-MarkdownImage -OriginalMarkdown '![Another](another.gif "With title")' -AltText "Another" -Title "With title" -NewUrl "https://example.com/3"),
        (New-MarkdownImage -OriginalMarkdown "![[another-obsidian.png]]" -AltText "" -Title "" -NewUrl "https://example.com/4")
      )

      # act
      $result = Update-MarkdownImages -File $testFile -ImageMappings $imageMappings

      # assert
      $result | Should -Be $true
      $updatedContent = Get-Content -Path $testFile -Raw
      
      # Check that all images were converted to standard format
      $updatedContent | Should -Match "!\[Standard alt\]\(https://example\.com/1\)"
      $updatedContent | Should -Match "!\[Obsidian alt\]\(https://example\.com/2\)"
      $updatedContent | Should -Match "!\[Another\]\(https://example\.com/3 `"With title`"\)"
      $updatedContent | Should -Match "!\[\]\(https://example\.com/4\)"
      
      # Verify original formats are gone
      $updatedContent | Should -Not -Match "\!\[\[.*\]\]"
    }

    It "Should preserve content that doesn't match any mappings" {
      # arrange
      $testFile = "TestDrive:\partial-replacement.md"
      $content = @(
        "# Test Post"
        ""
        "This will be replaced: ![Replace me](replace.png)"
        "This won't be replaced: ![Keep me](keep.png)"
        "Neither will this: ![[keep-obsidian.jpg|Keep this too]]"
      ) -join [System.Environment]::NewLine
      Set-Content -Path $testFile -Value $content

      $imageMapping = @(
        New-MarkdownImage -OriginalMarkdown "![Replace me](replace.png)" -AltText "Replace me" -Title "" -NewUrl "https://example.com/replaced"
      )

      # act
      $result = Update-MarkdownImages -File $testFile -ImageMappings $imageMapping

      # assert
      $result | Should -Be $true
      $updatedContent = Get-Content -Path $testFile -Raw
      
      # Check replacement occurred
      $updatedContent | Should -Match "!\[Replace me\]\(https://example\.com/replaced\)"
      
      # Check other content preserved
      $updatedContent | Should -Match "!\[Keep me\]\(keep\.png\)"
      $updatedContent | Should -Match "!\[\[keep-obsidian\.jpg\|Keep this too\]\]"
    }
  }
}

