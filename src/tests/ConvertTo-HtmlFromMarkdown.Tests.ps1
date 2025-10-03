Describe "ConvertTo-HtmlFromMarkdown" {
  BeforeAll {
    Import-Module $PSScriptRoot/_TestHelpers.ps1 -Force

    $script:InFile = Get-TestFilePath "123.md"
    $script:OutFile = Get-TestFilePath "123.html"

    Set-MarkdownFile -Path $script:InFile -Content "# Hello World"
  }

  BeforeEach {
    Import-Module $PSScriptRoot/../PSBlogger.psm1 -Force
  }

  AfterEach {
    if (Test-Path $script:OutFile) {
      Remove-Item $script:OutFile -Force
    }
  }

  It "Should convert Markdown file to HTML" {
    # act
    $result = ConvertTo-HtmlFromMarkdown -File $script:InFile

    # assert
    $result | Should -Not -BeNullOrEmpty
    $result | Should -BeLike "<h1*>Hello World</h1>*"
  }

  It "Should not produce an HTML file if OutFile is not specified" {
    # act
    $result = ConvertTo-HtmlFromMarkdown -File $script:InFile

    # assert
    $result | Should -Not -BeNullOrEmpty
    Test-Path $script:OutFile | Should -BeFalse
  }

  It "Should create an HTML file when OutFile is specified" {
    # act
    ConvertTo-HtmlFromMarkdown -File $script:InFile -OutFile $script:OutFile

    # assert
    Test-Path $script:OutFile | Should -BeTrue
  }

  It "Should not return content if OutFile is specified without PassThru" {
    # act
    $result = ConvertTo-HtmlFromMarkdown -File $script:InFile -OutFile $script:OutFile

    # assert
    $result | Should -BeNullOrEmpty
    Test-Path $script:OutFile | Should -BeTrue
  }

  It "Should return content if PassThru is specified with OutFile" {
    # act
    $result = ConvertTo-HtmlFromMarkdown -File $script:InFile -OutFile $script:OutFile -PassThru

    # assert
    $result | Should -Not -BeNullOrEmpty
    Test-Path $script:OutFile | Should -BeTrue
  }
}