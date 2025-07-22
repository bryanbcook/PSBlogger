Describe "ConvertTo-MarkdownFromHtml" {
  BeforeAll {
    Import-Module $PSScriptRoot\_TestHelpers.ps1 -Force
    
  }

  BeforeEach {
    Import-Module $PSScriptRoot\..\PSBlogger.psm1 -Force
  }

  Context "Using Content" {

    BeforeEach {
      $outFile = "TestDrive:\123.md"
      $htmlContent = "<h1>Hello World</h1>"
    }

    AfterEach {
      if (Test-Path $outFile) {
        Remove-Item $outFile -Force
      }
    }

    It "Should save HTML content to a markdown file" {
      # act
      ConvertTo-MarkdownFromHtml -Content $htmlContent -OutFile $outFile

      # assert
      Test-Path $outFile | Should -BeTrue
    }

    It "Should convert HTML content to Markdown file" {
      # act
      $content = ConvertTo-MarkdownFromHtml -Content $htmlContent -OutFile $outFile

      # assert
      $content = (Get-Content -Path $outFile -Raw).Split("`r")
      $content[0] | Should -Be "# Hello World"
    }

    It "Should not persist to disk if OutFile is not specified" {
      # act
      $content = ConvertTo-MarkdownFromHtml -Content $htmlContent

      # assert
      $content | Should -Not -BeNullOrEmpty
      Test-Path $outFile | Should -BeFalse
    }
  }
  
  Context "Using File" {

    BeforeEach {
      $htmlContent = "<h1>Hello World</h1>"
      $htmlFile = "TestDrive:\123.html"
      $markdownFile = "TestDrive:\123.md"
      Set-Content -Path $htmlFile -Value $htmlContent
    }

    It "Should convert HTML file to Markdown" {
      # act
      $content = ConvertTo-MarkdownFromHtml -File $htmlFile -OutFile $markdownFile

      # assert
      Test-Path $markdownFile | Should -BeTrue
      $content = (Get-Content -Path $markdownFile -Raw).Split("`r")
      $content[0] | Should -Be "# Hello World"
    }

    It "Should delete temporary file" {
      # act
      $content = ConvertTo-MarkdownFromHtml -File $htmlFile

      # assert
      $content | Should -Not -BeNullOrEmpty
      Test-Path $markdownFile | Should -BeFalse
    }
  }
}