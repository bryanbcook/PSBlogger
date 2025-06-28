
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
      @(
        "# First Post"
        ""
        "Some content with an $original image"
      ) -join [System.Environment]::NewLine | 
      Set-Content -Path "TestDrive:\test.md"

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
      $inputContent | Set-Content -Path $inputFile
      
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

  }
}

