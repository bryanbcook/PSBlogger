Describe "Get-BloggerPost" {
  BeforeEach {
    Import-Module $PSScriptRoot\..\PSBlogger.psm1 -Force
    Import-Module $PSScriptRoot\_TestHelpers.ps1 -Force

    $OutDirectory = Resolve-Path TestDrive:
  }

  AfterEach {
    # remove temporarily created files
    $ExpectedPath = Join-Path (Get-Location).Path -ChildPath "123.html"
    if (Test-Path $ExpectedPath) {
      Remove-Item $ExpectedPath -Force
    }
  }

  Context "Parameter validation" {
    It "Should require PostId parameter" {
      # act / assert
      { Get-BloggerPost -Format Markdown } | Should -Throw "*PostId*"
    }
        
    It "Should throw error when BlogId is not provided and not in session" {
      # arrange
      InModuleScope PSBlogger {
        $BloggerSession.BlogId = $null
      }

      # act / assert
      { 
        Get-BloggerPost -PostId "123" 
      } | Should -Throw "*BlogId not specified*"
    }
        
    It "Should use session BlogId when not provided" {
      # arrange
      InModuleScope PSBlogger {
        # setup blog id
        $BloggerSession.BlogId = "test-blog-id"

        # setup blog post retrieval
        Mock Invoke-GAPi {
          return [pscustomobject]@{ content = "<p>Test content</p>" }
        }
      }            
            
      # act
      Get-BloggerPost -PostId "123" -Format HTML -OutDirectory $OutDirectory

      # assert
      $outputFile = Join-Path -Path $OutDirectory -ChildPath "123.html"
      Test-Path -Path $outputFile | Should -BeTrue
    }
  }
    
  Context "API interaction" {
    BeforeEach {
      InModuleScope PSBlogger {
        # Mock the session to return a test blog ID
        $BloggerSession.BlogId = "test-blog-id"
      }
    }
        
    It "Should call correct API endpoint" {
      InModuleScope PSBlogger {
        Mock Invoke-GApi { 
          return [pscustomobject]@{ content = "<p>Test content</p>" }
        } -ParameterFilter { 
          $uri -eq "https://www.googleapis.com/blogger/v3/blogs/test-blog-id/posts/123" 
        } -Verifiable
      }      
      
      # act
      $result = Get-BloggerPost -PostId "123"
           
      # assert
      $result | Should -Not -BeNullOrEmpty
      Should -InvokeVerifiable
    }
        
    It "Should handle 404 errors with meaningful message" {
      # arrange
      Mock -ModuleName PSBlogger Invoke-GApi { 
        throw [System.Exception]::new("404 Not Found")
      }

      # act / assert
      { 
        Get-BloggerPost -PostId "nonexistent" 
      } | Should -Throw "*Post with PostId 'nonexistent' not found*"
    }
        
    It "Should handle 403 errors with meaningful message" {
      # arrange
      Mock -ModuleName PSBlogger Invoke-GApi { 
        throw [System.Exception]::new("403 Forbidden")
      }

      # act / assert
      { 
        Get-BloggerPost -PostId "123" 
      } | Should -Throw "*Access denied*"
    }

        It "Should handle empty content gracefully" {
      # arrange
      InModuleScope PSBlogger {
        Mock Invoke-GApi { 
          return @{ content = "" }
        }

        Mock Write-Warning { }
      }
      
      
      # act
      Get-BloggerPost -PostId "123"
      
      # assert: verify warning is issued
      Should -Invoke -ModuleName PSBlogger Write-Warning -Exactly 1 -ParameterFilter {
        $Message -like "*has no content*"
      }
    }
  }
    
  Context "As HTML" {
    BeforeEach {
      InModuleScope PSBlogger {
        # Mock the session to return a test blog ID
        $BloggerSession.BlogId = "test-blog-id"

        # mock post retrieval
        Mock Invoke-GApi {
          return @{ content = "<p>Test content</p>" }
        }
      }
    }
        
    It "Should create output directory if it doesn't exist" {
      # arrange
      $OutDirectory = "TestDrive:\nonexistent"
      
      # act
      Get-BloggerPost -PostId "123" -OutDirectory $OutDirectory -Format HTML
            
      # assert
      Test-Path -Path $OutDirectory | Should -BeTrue
    }
        
    It "Should save content to correct filename" {
      
      # arrange      
      Get-BloggerPost -PostId "123" -OutDirectory (Resolve-Path "TestDrive:") -Format HTML
            
      # assert
      Test-Path -Path "TestDrive:\123.html" | Should -BeTrue
    }
        
    It "Should use current directory when OutDirectory not specified" {
      # arrange
      $ExpectedPath = Join-Path (Get-Location).Path -ChildPath "123.html"

      # act
      Get-BloggerPost -PostId "123" -Format HTML

      # assert
      Test-Path -Path $ExpectedPath | Should -BeTrue
    }
  }

  Context "As Markdown" {

    BeforeEach {
      InModuleScope PSBlogger {
        # Mock the session to return a test blog ID
        $BloggerSession.BlogId = "test-blog-id"

        $postId = "123"

        # mock post retrieval
        Mock Invoke-GApi {
          return [pscustomobject]@{ 
            id = $postId
            title = "Test Post"
            published = [datetime]"2023-10-01T17:30:00-04:00"
            content = "<h1>Hello World</h1><p>This is a post.</p>" 
            labels = @("Azure DevOps", "Azure Pipelines")
          }
        }
      }

      $postId = "123"
      $title = "Test Post"
      $outFile = "TestDrive:\$title.md"
      
    }

    AfterEach {
      if (Test-Path $outFile) {
        Remove-Item $outFile -Force
      }
    }

    It "Should write postid to frontmatter" {
      
      # act
      Get-BloggerPost -PostId $postId -Format Markdown -OutDirectory "TestDrive:\"

      # assert
      $frontMatter = Get-MarkdownFrontMatter -File $outFile
      $frontMatter.postId | Should -Be "123"
    }

    It "Should write labels to frontmatter" {
      # act
      Get-BloggerPost -PostId $postId -Format Markdown -OutDirectory "TestDrive:\"

      # assert
      $frontMatter = Get-MarkdownFrontMatter -File $outFile
      $frontMatter.tags.Count | Should -Be 2
      $frontMatter.tags[0] | Should -Be "Azure DevOps"
      $frontMatter.tags[1] | Should -Be "Azure Pipelines"
    }

    It "Should include empty tags in frontmatter if labels are not present" {
      # arrange
      InModuleScope PSBlogger {
        # Mock the session to return a test blog ID
        $BloggerSession.BlogId = "test-blog-id"

        $postId = "123"

        # mock post retrieval
        Mock Invoke-GApi {
          return [pscustomobject]@{ 
            id = $postId
            title = "Test Post"
            published = [datetime]"2023-10-01T17:30:00-04:00"
            content = "<h1>Hello World</h1><p>This is a post.</p>"
          }
        }
      }
      # act
      Get-BloggerPost -PostId $postId -Format Markdown -OutDirectory "TestDrive:\"

      # assert
      $frontMatter = Get-MarkdownFrontMatter -File $outFile
      $frontMatter['tags'] -eq $null | Should -BeFalse
      $frontMatter['tags'] | Should -Be @()
    }
  }

  Context "As Json" {
    BeforeEach {
      InModuleScope PSBlogger {
        # Mock the session to return a test blog ID
        $BloggerSession.BlogId = "test-blog-id"

        $postId = "123"

        # mock post retrieval
        Mock Invoke-GApi {
          return [pscustomobject]@{ 
            id = $postId
            title = "Test Post"
            published = [datetime]"2023-10-01T17:30:00-04:00"
            content = "<h1>Hello World</h1><p>This is a post.</p>" 
          }
        }
      }

      $postId = "123"
      $title = "Test Post"
      $outFile = "TestDrive:\$postId.json"
      
    }

    AfterEach {
      if (Test-Path $outFile) {
        Remove-Item $outFile -Force
      }
    }

    It "Should write json response to file" {
      
      # act
      Get-BloggerPost -PostId $postId -Format JSON -OutDirectory "TestDrive:\"

      # assert
      $jsonContent = Get-Content -Path $outFile -Raw | ConvertFrom-Json
      $jsonContent.id | Should -Be "123"
      $jsonContent.title | Should -Be "Test Post"
      $jsonContent.content | Should -Not -BeNullOrEmpty
      $jsonContent.published | Should -Not -BeNullOrEmpty
    }
  }

  Context "Using FolderDateFormat" {

    BeforeEach {
      InModuleScope PSBlogger {
        # Mock the session to return a test blog ID
        $BloggerSession.BlogId = "test-blog-id"

        $postId = "123"

        # mock post retrieval
        Mock Invoke-GApi {
          return [pscustomobject]@{ 
            id = $postId
            title = "Test Post"
            published = [datetime]"2023-10-01T17:30:00-04:00"
            content = "<h1>Hello World</h1><p>This is a post.</p>" 
          }
        }
      }
    }
    
    It "Should write file to specified formatted directory - <dateformat> - <format>" -TestCases @(
      @{ DateFormat = "yyyy\\MM"; ExpectedPath = "TestDrive:\2023\10\Test Post.md"; Format = "Markdown" }
      @{ DateFormat = "yyyy\\MM\\dd"; ExpectedPath = "TestDrive:\2023\10\01\123.html"; Format = "HTML" }
      @{ DateFormat = "yyyy"; ExpectedPath = "TestDrive:\2023\123.json"; Format = "JSON"}
    ) {
      # arrange
      $invokeArgs = @{
        PostId = 123
        Format = $Format
        OutDirectory = "TestDrive:\"
        FolderDateFormat = $DateFormat
      }

      # act
      Get-BloggerPost @invokeArgs

      # assert
      Test-Path $ExpectedPath | Should -BeTrue

    }

    It "Should ignore folderdateformat when not specified" {

      # act
      Get-BloggerPost -PostId 123 -Format HTML -OutDirectory "TestDrive:\"

      # assert
      Test-Path "TestDrive:\123.html" | Should -BeTrue

    }

    It "Should ignore folderdateformat when post has not been published" {
      # arrange
      InModuleScope PSBlogger {
        Mock Invoke-GApi {
          return @{ 
            id = 123
            title = "Test Post"
            published = $null
            content = "<h1>Hello World</h1><p>This is a post.</p>" 
          }
        }
      }

      # act
      Get-BloggerPost -PostId 123 -Format HTML -OutDirectory "TestDrive:\" -FolderDateFormat "YYYY\\MM"

      # assert
      Test-Path "TestDrive:\123.html" | Should -BeTrue
    }
  }

  Context "PassThru" {

    BeforeEach {
      InModuleScope PSBlogger {
        # Mock the session to return a test blog ID
        $BloggerSession.BlogId = "test-blog-id"

        # mock post retrieval
        Mock Invoke-GApi {
          return @{ content = "<p>Test content</p>" }
        }
      }
    }

    It "Should return post object when not persisting output to disk" {
      # act
      $result = Get-BloggerPost -PostId "123"

      # assert
      $result | Should -Not -BeNullOrEmpty
    }

    It "Should not return a post object when persisting to disk" {
      # act
      $result = Get-BloggerPost -PostId "123" -Format HTML -OutDirectory TestDrive:\

      # assert
      $result | Should -BeNullOrEmpty
    }

    It "Should return post object when persisting to disk with PassThru specified" {
      # act
      $result = Get-BloggerPost -PostId "123" -Format HTML -OutDirectory TestDrive:\ -PassThru

      # assert
      $result | Should -Not -BeNullOrEmpty
    }


  }
}
