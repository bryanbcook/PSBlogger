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
      { Get-BloggerPost } | Should -Throw "*PostId*"
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
          return @{ content = "<html>Test content</html>" }
        }
      }            
            
      # act
      $result = Get-BloggerPost -PostId "123" -OutDirectory $OutDirectory

      # assert
      $result | Should -Not -BeNullOrEmpty
      Test-Path -Path (Join-Path -Path $OutDirectory -ChildPath "123.html") | Should -BeTrue
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
          return @{ content = "<html>Test content</html>" }
        } -ParameterFilter { 
          $uri -eq "https://www.googleapis.com/blogger/v3/blogs/test-blog-id/posts/123" 
        } -Verifiable
      }      
      
      # act
      Get-BloggerPost -PostId "123"
           
      # assert
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
  }
    
  Context "File operations" {
    BeforeEach {
      InModuleScope PSBlogger {
        # Mock the session to return a test blog ID
        $BloggerSession.BlogId = "test-blog-id"

        # mock post retrieval
        Mock Invoke-GApi {
          return @{ content = "<html>Test content</html>" }
        }
      }
    }
        
    It "Should create output directory if it doesn't exist" {
      # arrange
      $OutDirectory = "TestDrive:\nonexistent"
      
      # act
      Get-BloggerPost -PostId "123" -OutDirectory $OutDirectory
            
      # assert
      Test-Path -Path $OutDirectory | Should -BeTrue
    }
        
    It "Should save content to correct filename" {
      
      # arrange      
      Get-BloggerPost -PostId "123" -OutDirectory (Resolve-Path "TestDrive:")
            
      # assert
      Test-Path -Path "TestDrive:\123.html" | Should -BeTrue
    }
        
    It "Should use current directory when OutDirectory not specified" {
      # act
      Get-BloggerPost -PostId "123"  

      # assert
      Test-Path -Path $ExpectedPath | Should -BeTrue
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
}
