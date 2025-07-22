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
      $outFilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($outFile)
      $htmlContent = "<h1>Hello World</h1>"
    }

    It "Should save HTML content to a markdown file" {
      # act
      ConvertTo-MarkdownFromHtml -Content $htmlContent -OutFile $outFilePath

      # assert
      Test-Path $outFile | Should -BeTrue
    }

    It "Should convert HTML content to Markdown file" {
      # act
      $content = ConvertTo-MarkdownFromHtml -Content $htmlContent -OutFile $outFilePath

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
      $htmlFilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($htmlFile)
      $markdownFile = "TestDrive:\123.md"
      $markdownFilePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($markdownFile)
      Set-Content -Path $htmlFile -Value $htmlContent
    }

    It "Should convert HTML file to Markdown" {
      # act
      $content = ConvertTo-MarkdownFromHtml -File $htmlFilePath -OutFile $markdownFilePath

      # assert
      Test-Path $markdownFile | Should -BeTrue
      $content = (Get-Content -Path $markdownFile -Raw).Split("`r")
      $content[0] | Should -Be "# Hello World"
    }

    It "Should delete temporary file" {
      # act
      $content = ConvertTo-MarkdownFromHtml -File $htmlFilePath

      # assert
      $content | Should -Not -BeNullOrEmpty
      Test-Path $markdownFile | Should -BeFalse
    }
  }
}