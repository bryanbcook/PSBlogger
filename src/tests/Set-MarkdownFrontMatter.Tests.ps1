Describe 'Set-MarkdownFrontMatter' {
  BeforeAll {
    Import-Module $PSScriptRoot\_TestHelpers.ps1 -Force
  }
  BeforeEach {
    Import-Module $PSScriptRoot\..\PSBlogger.psm1 -Force
  }

  It "Should only support markdownfiles" {
    Set-Content -Path "TestDrive:\validfile.html" -Value "dummy"
    {
      Set-MarkdownFrontMatter -File "TestDrive:\validfile.html" -Replace [ordered]@{}
    } | Should -Throw "*Test-Path*"
  }

  It "Should support saving boolean values" {
    $testFile = "TestDrive:\testfile.md"
    Set-Content -Path $testFile -Value ""

    # act
    $update = [ordered]@{ wip = $true }
    Set-MarkdownFrontMatter -File $testFile -Update $update

    # assert
    $fm = Get-MarkdownFrontMatter -File $testFile
    $fm.wip | Should -Be $true
  }

  It "Should not quote string values" {
    $testFile = "TestDrive:\testfile.md"
    Set-Content -Path $testFile -Value ""

    # act
    $update = [ordered]@{ title = "hello world" }
    Set-MarkdownFrontMatter -File $testFile -Update $update

    # assert
    $raw = (Get-Content -Path $testFile -Raw).Split("`n")
    $raw[1].Trim() | Should -Be 'title: hello world'
  }

  Context "Update Existing FrontMatter" {

    BeforeEach {
      # arrange
      $testFile = "TestDrive:\valid.md"
      $frontMatter = New-FrontMatter @("title: title value", "postid: 123")
      Set-Content -Path $testFile -Value $frontMatter
    }

    It "Should update single value" {
      # act
      $update = @{ title = "new title value" }
      Set-MarkdownFrontMatter -File $testFile -Update $update

      # assert
      $result = Get-MarkdownFrontMatter -File $testFile
      $result.title | Should -Be "new title value"
    }

    It "Should update multiple values" {
      # act
      $update = @{ title = "new title value"; postid = "1234" }
      Set-MarkdownFrontMatter -File $testFile -Update $update

      # assert
      $result = Get-MarkdownFrontMatter -File $testFile
      $result.title | Should -Be "new title value"
      $result.postid | Should -Be "1234"
    }

    It "Should add new items in frontmatter if not present" {
      # act
      $update = @{ newvalue="abc"}
      Set-MarkdownFrontMatter -File $testFile -Update $update

      # assert
      $result = Get-MarkdownFrontMatter -File $testFile
      $result.title | Should -Not -BeNullOrEmpty
      $result.postid | Should -Not -BeNullOrEmpty
      $result.newvalue | Should -Be "abc"
    }
  }

  Context "Replacing Existing FrontMatter" {
    BeforeEach {
      # arrange
      $testFile = "TestDrive:\valid.md"
      $frontMatter = New-FrontMatter @("title: title value", "postid: 123")
      $frontMatter += "# hello world"
      Set-Content -Path $testFile -Value $frontMatter
    }

    It "Should replace existing values in frontmatter with new values" {
      # act
      $replace = [ordered]@{ one="1"; two="2"; three="3"; four="4";}
      Set-MarkdownFrontMatter -File $testFile -Replace $replace

      # assert
      # (look at the raw content to avoid extra processing of Get-MarkdownFrontMatter)
      $lines = (Get-Content -Path $testFile -Raw).Split("`n")
      $lines[0] | Should -Be "---"
      $lines[1].Trim() | Should -Be "one: `"1`""
      $lines[2].Trim() | Should -Be "two: `"2`""
      $lines[3].Trim() | Should -Be "three: `"3`""
      $lines[4].Trim() | Should -Be "four: `"4`""
      $lines[5] | Should -Be "---"
    }

    It "Shouldn't add additional whitespace after updating the frontmatter" {

      # arrange
      $length = (Get-Content -Path $testFile).Count

      # act
      $replace = [ordered]@{ one="1"; two="2"; }
      Set-MarkdownFrontMatter -File $testFile -Replace $replace

      # asert
      $lines = (Get-Content -Path $testFile)
      $lines[0] | Should -Be "---"
      $lines[1].Trim() | Should -Be "one: `"1`""
      $lines[2].Trim() | Should -Be "two: `"2`""
      $lines[3] | Should -Be "---"
      $lines.Count | Should -Be $length
    }
  }
}