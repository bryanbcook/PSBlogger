Describe "Publish-MarkdownBloggerPost" {
  BeforeAll {

    Import-Module $PSScriptRoot\_TestHelpers.ps1 -Force

    $validFile = "TestDrive:\validfile.md"
    Set-MarkdownFile $validFile "# hello world"
    
  }
  BeforeEach {
    Import-Module $PSScriptRoot\..\PSBlogger.psm1 -Force

    # set up dummy results
    InModuleScope PSBlogger {
      # avoid blogger api for now
      Mock Publish-BloggerPost {return @{ id="123"}}
      # avoid pandoc for now
      Mock ConvertTo-HtmlFromMarkdown { return "<div>dummy</div>" }
    }
  }

  Context "Blog Id Preference has not been set" {

    BeforeEach {
      # clear blogid
      InModuleScope PSBlogger {
        $BloggerSession.BlogId = $null
      }      
    }

    It "Should complain when blog id is not specified" {
      # act / assert
      {
        Publish-MarkdownBloggerPost -File $validFile 
      } | Should -Throw -ExpectedMessage "BlogId not specified."
    }

    It "Should publish to blog when blog id is specified" {
      # arrange
      InModuleScope PSBlogger {
        Mock Set-MarkdownFrontMatter -Verifiable {}
      }

      # act
      Publish-MarkdownBloggerPost -File $validFile -BlogId 1234

      Should -InvokeVerifiable      
    }
  }

  Context "Publishing with Draft setting enabled" {

    It "Should mark the file as wip" {
      # arrange
      $testFile = "TestDrive:\testfile.md"
      Set-Content -Path $testFile -Value "# hello world"

      # act
      Publish-MarkdownBloggerPost -File $testFile -BlogId 1234 -Draft

      #assert
      $result = Get-MarkdownFrontMatter -File $testFile
      $result['wip'] | Should -Not -BeNullOrEmpty
      $result.wip | Should -Be $true
    }

    It "Should set draft on blogger post" {
      # arrange
      $testFile = "TestDrive:\testfile.md"
      Set-Content -Path $testFile -Value "# hello world"
      InModuleScope PSBlogger {
        Mock Publish-BloggerPost -ParameterFilter { $Draft -eq $true } { return @{ id=123 } }
      }

      # act
      Publish-MarkdownBloggerPost -File $testFile -BlogId 1234 -Draft

      #assert
      Should -InvokeVerifiable
    }
  }

  Context "Publishing with Draft setting removed" {
    It "Should remove the wip flag from existing front-matter" {
      # arrange
      $testFile = "TestDrive:\valid.md"
      Set-Content -Path $testFile -Value @"
---
wip: true
---
# helloworld
"@

      # act
      Publish-MarkdownBloggerPost -File $testFile -BlogId 1234

      # arrange
      $frontMatter = Get-MarkdownFrontMatter $testFile
      $frontMatter['wip'] | Should -Be $null
    }
  }

  Context "Publishing an update to existing post" {

    It "Should use post id when publishing" {
      InModuleScope PSBlogger {
      #arrange
        $post = @"
---
postId: "123456"
---
# hello world
"@
        $testFile = "TestDrive:\dummy.md"
        Set-Content $testFile -Value $post
        $BloggerSession.BlogId = 1234
        Mock Publish-BloggerPost -Verifiable -ParameterFilter { $PostId -eq "123456"} { return @{ id="123"}}

        #act
        Publish-MarkdownBloggerPost -File $testFile

        #assert
        Should -InvokeVerifiable 

      }
    }
  }

  It "Should set blog post labels based on tags in front-matter" {
    # arrange

    # add our tags to the file
    $postInfo = Get-MarkdownFrontMatter -File $validFile
    $postInfo.tags = @("PowerShell","Pester")
    Set-MarkdownFrontMatter -File $validFile -Replace $postInfo

    InModuleScope PSBlogger {
      Mock Publish-BloggerPost -Verifiable -ParameterFilter { 
        $Labels -ne $null -and (-not (Compare-Object $Labels @("PowerShell","Pester")))} { return @{ id="123"} }
    }

    # act
    Publish-MarkdownBloggerPost -File $validFile -BlogId "123"

    # assert
    Should -InvokeVerifiable 
  }

  It "Should exclude certain tags from post labels when publishing " {
    # arrange

    # add our tags to the file
    $postInfo = Get-MarkdownFrontMatter -File $validFile
    $postInfo.tags = @("PowerShell","Pester", "personal/blog-post")
    Set-MarkdownFrontMatter -File $validFile -Replace $postInfo

    InModuleScope PSBlogger {
      Mock Publish-BloggerPost -Verifiable -ParameterFilter { 
        $Labels -ne $null -and (-not (Compare-Object $Labels @("PowerShell","Pester")))} { return @{ id="123"} }
    }

    # act
    Publish-MarkdownBloggerPost -File $validFile -BlogId "123" -ExcludeLabels "personal/blog-post"

    # assert
    Should -InvokeVerifiable 
  }

  It "Should use excludelabels user preference when not specified" {
    # arrange
    InModuleScope PSBlogger {
      $BloggerSession.ExcludeLabels = @("personal/blog-post")
      Mock Publish-BloggerPost -Verifiable -ParameterFilter { 
        $Labels -ne $null -and (-not (Compare-Object $Labels @("PowerShell","Pester")))} { return @{ id="123"} }
    }

    # add our tags to the file
    $postInfo = Get-MarkdownFrontMatter -File $validFile
    $postInfo.tags = @("PowerShell","Pester", "personal/blog-post")
    Set-MarkdownFrontMatter -File $validFile -Replace $postInfo

    # act
    Publish-MarkdownBloggerPost -File $validFile -BlogId "123"

    # assert
    Should -InvokeVerifiable 
  }
  
  It "Should update front matter with postid after publishing" {
    # arrange
    $blogPost = New-BlogPost "post1"
    Mock -ModuleName PSBlogger Publish-BloggerPost { return $blogPost }
    
    # act
    Publish-MarkdownBloggerPost -File $validFile -BlogId "123"

    # assert
    $postInfo = Get-MarkdownFrontMatter $validFile
    $postInfo.postid | Should -Be "post1" -Because "Markdown file should be updated with post id after publishing for the first time."
  }

  Context "Open post after publishing" {

    BeforeEach {
      InModuleScope PSBlogger {
        Mock Set-MarkdownFrontMatter {}
      }
    }

    It "Should pass Open parameter to Publish-BloggerPost when specified" {
      # arrange
      $testFile = "TestDrive:\testfile.md"
      Set-Content -Path $testFile -Value "# hello world"

      InModuleScope PSBlogger {
        Mock Publish-BloggerPost -ParameterFilter { $Open -eq $true } -Verifiable {
          return @{ id = "123" }
        }
      }

      # act
      Publish-MarkdownBloggerPost -File $testFile -BlogId 1234 -Open

      # assert
      Should -InvokeVerifiable
    }

    It "Should not pass Open parameter to Publish-BloggerPost by default" {
      # arrange
      $testFile = "TestDrive:\testfile.md"
      Set-Content -Path $testFile -Value "# hello world"

      InModuleScope PSBlogger {
        Mock Publish-BloggerPost -ParameterFilter { $Open -eq $false } -Verifiable {
          return [pscustomobject]@{ id = "123" }
        }
      }

      # act
      Publish-MarkdownBloggerPost -File $testFile -BlogId 1234

      # assert
      Should -InvokeVerifiable
    }

  }

  Context "Upload Images to Google Drive" {

    BeforeEach {
      InModuleScope "PSBlogger" {
        Mock Publish-BloggerPost { @{ id = "1234"} }
      }
      
      New-TestImage "TestDrive:\image.png"
      $script:testFile = "TestDrive:\testfile.md"
      Set-MarkdownFile $script:testFile  "# hello world$([Environment]::NewLine)Your image ![image](image.png)"
    }

    It "Should upload images and update markdown in place" {
      # arrange
      InModuleScope "PSBlogger" {

        Mock Add-GoogleDriveFile -Verifiable {
          return @{
            id = "12345"
            PublicUrl = "https://drive.google.com/12345"
          }
        }
        Mock Set-GoogleDriveFilePermission -Verifiable {}
      }

      # act
      $actualFile = Resolve-Path $script:testFile
      Publish-MarkdownBloggerPost -File $actualFile -BlogId 1234

      # assert
      Should -InvokeVerifiable
      $updatedContent = Get-Content -Path $script:testFile -Raw
      $escapedRegex = [regex]::Escape("![image](https://drive.google.com/12345)")
      $updatedContent | Should -Match $escapedRegex
    }

    It "Should upload images from supplied attachments directory" {
      # arrange
      InModuleScope PSBlogger {
        Mock Publish-MarkdownDriveImages -ParameterFilter { $AttachmentsDirectory -eq "TestDrive:\attachments" } {
          return @()
        } -Verifiable
      }

      # act
      Publish-MarkdownBloggerPost -File $script:testFile -BlogId 1234 -AttachmentsDirectory "TestDrive:\attachments"
    
      # assert
      Should -InvokeVerifiable
    }

    It "Should upload images from default attachments directory if not specified" {
      # arrange
      InModuleScope PSBlogger {
        Mock Publish-MarkdownDriveImages -ParameterFilter { $AttachmentsDirectory -eq "" } {
          return @()
        } -Verifiable
      }

      # act
      Publish-MarkdownBloggerPost -File $validFile -BlogId 1234
    
      # assert
      Should -InvokeVerifiable
    }

    It "Should overwrite existing images in google drive if Force is specified" {
      # arrange
      InModuleScope PSBlogger {
        Mock Publish-MarkdownDriveImages -ParameterFilter { $Force -eq $true } {
          return @()
        } -Verifiable
      }

      # act
      Publish-MarkdownBloggerPost -File $script:testFile -BlogId 1234 -Force

      # assert
      Should -InvokeVerifiable
    }

  }
}
