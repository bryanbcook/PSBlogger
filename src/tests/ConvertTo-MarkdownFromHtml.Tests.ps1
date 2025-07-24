Describe "ConvertTo-MarkdownFromHtml" {
  BeforeAll {
    Import-Module $PSScriptRoot\_TestHelpers.ps1 -Force
    $script:inFile = "TestDrive:\123.html"
    $script:outFile = "TestDrive:\123.md"
    $script:htmlContent = "<h1>Hello World</h1>"
    Set-Content -Path $script:inFile -Value $script:htmlContent
  }

  BeforeEach {
    Import-Module $PSScriptRoot\..\PSBlogger.psm1 -Force
  }

  AfterEach {
    if (Test-Path $outFile) {
      Remove-Item $outFile -Force
    }
  }

  Context "Using Content" {

    It "Should convert HTML content to Markdown file" {
      # act
      ConvertTo-MarkdownFromHtml -Content $script:htmlContent -OutFile $script:outFile

      # assert
      Test-Path $script:outFile | Should -BeTrue
      $content = (Get-Content -Path $script:outFile -Raw).Split("`r")
      $content[0] | Should -Be "# Hello World"
    }

    It "Should not persist to disk if OutFile is not specified" {
      # act
      $content = ConvertTo-MarkdownFromHtml -Content $script:htmlContent

      # assert
      $content | Should -Not -BeNullOrEmpty
      Test-Path $script:outFile | Should -BeFalse
    }

    It "Should return content when writing to disk if PassThru is specified" {
      # act
      $content = ConvertTo-MarkdownFromHtml -Content $script:htmlContent -OutFile $script:outFile -PassThru

      # assert
      $content | Should -Not -BeNullOrEmpty
      Test-Path $script:outFile | Should -BeTrue
    }
  }
  
  Context "Using File" {

    It "Should convert HTML content to Markdown and persist to OutFile" {
      # act
      ConvertTo-MarkdownFromHtml -File $script:inFile -OutFile $script:outFile

      # assert
      Test-Path $script:outFile | Should -BeTrue
      $content = (Get-Content -Path $script:outFile -Raw).Split("`r")
      $content[0] | Should -Be "# Hello World"
    }

    It "Should convert HTML file to Markdown" {
      # act
      $content = ConvertTo-MarkdownFromHtml -File $script:inFile

      # assert
      $content | Should -Not -BeNullOrEmpty
      $content | Should -BeLike "# Hello World*"
    }

    It "Should delete temporary OutFile if OutFile is not specified" {
      # act
      $content = ConvertTo-MarkdownFromHtml -File $script:inFile

      # assert
      $content | Should -Not -BeNullOrEmpty
      Test-Path $script:outFile | Should -BeFalse
    }

    It "Should return content when writing to disk if PassThru is specified" {
      # act
      $content = ConvertTo-MarkdownFromHtml -File $script:inFile -OutFile $script:outFile -PassThru

      # assert
      $content | Should -Not -BeNullOrEmpty
      Test-Path $script:outFile | Should -BeTrue
    }
  }
}