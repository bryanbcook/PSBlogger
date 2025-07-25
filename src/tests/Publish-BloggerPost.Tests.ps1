Describe "Publish-BloggerPost" {
  BeforeAll {
    Import-Module $PSScriptRoot\_TestHelpers.ps1 -Force
  }

  BeforeEach {
    Import-Module $PSScriptRoot\..\PSBlogger.psm1 -Force

    $script:blogId = "123456789"
    $script:title = "Test Post"
    $script:content = "<p>Test content</p>"
    $script:labels = @("tag1", "tag2")

    # Set up mock responses
    InModuleScope PSBlogger {
      Mock Invoke-GApi {
        return [pscustomobject]@{
          id = "12345"
          url = "https://example.blogspot.com/2023/01/test-post.html"
          title = "Test Post"
          content = "<p>Test content</p>"
        }
      }
      Mock Start-Process {}
    }
  }

  Context "Creating a new post" {
    It "Should call Blogger API with correct parameters for new post" {
      # arrange
      InModuleScope PSBlogger {
        Mock Invoke-GApi -ParameterFilter {
          $Uri -eq "https://www.googleapis.com/blogger/v3/blogs/123456789/posts" -and
          $Method -eq "POST"
        } -Verifiable {
          return [pscustomobject]@{ id = "12345"; url = "https://example.blogspot.com/2023/01/test-post.html" }
        }
      }
      $invokeArgs = @{
        BlogId = $script:blogId
        Title = $script:title
        Content = $script:content
        Labels = $script:labels
      }

      # act
      Publish-BloggerPost @invokeArgs

      # assert
      Should -InvokeVerifiable
    }

    It "Should create a published post by default" {
      # arrange
      InModuleScope PSBlogger {
        Mock Invoke-GApi -ParameterFilter {
          $Uri -eq "https://www.googleapis.com/blogger/v3/blogs/123456789/posts"
        } -Verifiable {
          return [pscustomobject]@{ id = "12345"; url = "https://example.blogspot.com/2023/01/test-post.html" }
        }
      }
      $invokeArgs = @{
        BlogId = $script:blogId
        Title = $script:title
        Content = $script:content
      }

      # act
      Publish-BloggerPost @invokeArgs

      # assert
      Should -InvokeVerifiable
    }

    It "Should create a draft post when Draft switch is specified" {
      # arrange
      InModuleScope PSBlogger {
        Mock Invoke-GApi -ParameterFilter {
          $Uri -eq "https://www.googleapis.com/blogger/v3/blogs/123456789/posts?isDraft=true"
        } -Verifiable {
          return @{ id = "12345"; url = "https://example.blogspot.com/2023/01/test-post.html" }
        }
      }

      # act
      Publish-BloggerPost -BlogId $script:blogId -Title $script:title -Content $script:content -Draft

      # assert
      Should -InvokeVerifiable
    }
  }

  Context "Updating an existing post" {

    BeforeEach {
      $script:postId = "98765"
      $script:invokeArgs = @{
        BlogId = $script:blogId
        PostId = $script:postId
        Title = $script:Title
        Content = $script:Content
      }
    }

    It "Should call Blogger API with correct parameters for updating post" {
      # arrange
      InModuleScope PSBlogger {
        Mock Invoke-GApi -ParameterFilter {
          $Uri -eq "https://www.googleapis.com/blogger/v3/blogs/123456789/posts/98765?publish=true" -and
          $Method -eq "PUT"
        } -Verifiable {
          return @{ id = "98765"; url = "https://example.blogspot.com/2023/01/updated-test-post.html" }
        }
      }

      # act
      Publish-BloggerPost @script:invokeArgs

      # assert
      Should -InvokeVerifiable
    }

    It "Should update post as draft when Draft switch is specified" {
      # arrange
      $postId = "98765"

      InModuleScope PSBlogger {
        Mock Invoke-GApi -ParameterFilter {
          $Uri -eq "https://www.googleapis.com/blogger/v3/blogs/123456789/posts/98765" -and
          $Method -eq "PUT"
        } -Verifiable {
          return @{ id = "98765"; url = "https://example.blogspot.com/2023/01/updated-test-post.html" }
        }
      }

      # act
      Publish-BloggerPost -BlogId $script:blogId -PostId $postId -Title $script:title -Content $script:content -Draft

      # assert
      Should -InvokeVerifiable
    }
  }

  Context "Open post after publishing" {

    BeforeEach {
      $script:invokeArgs = @{
        BlogId = $script:blogId
        Title = $script:title
        Content = $script:content
      }
    }

    It "Should not launch browser by default" {
      # arrange
      InModuleScope PSBlogger {
        Mock Start-Process {
          throw "Start-Process should not be called without Open switch"
        }
      }

      # act / assert - should not throw
      { 
        Publish-BloggerPost @script:invokeArgs
      } | Should -Not -Throw
    }

    It "Should launch browser when Open switch is specified for published post" {
      # arrange
      InModuleScope PSBlogger {
        Mock Start-Process -Verifiable {}
      }

      # act
      Publish-BloggerPost @script:invokeArgs -Open

      # assert
      Should -InvokeVerifiable
    }

    It "Should launch browser with draft preview URL when Open and Draft switches are specified" {
      # arrange
      InModuleScope PSBlogger {
        Mock Start-Process -Verifiable {}
      }

      # act
      Publish-BloggerPost @script:invokeArgs -Draft -Open

      # assert
      Should -InvokeVerifiable
    }
  }

  Context "Request body validation" {

    BeforeEach {
      $script:invokeArgs = @{
        BlogId = $script:blogId
        Title = $script:title
        Content = $script:content
      }
    }

    It "Should include all specified parameters in request body" {
      # arrange
      InModuleScope PSBlogger {
        Mock Invoke-GApi -ParameterFilter {
          $bodyObj = $Body | ConvertFrom-Json
          $bodyObj.kind -eq "blogger#post" -and
          $bodyObj.blog.id -eq "123456789" -and
          $bodyObj.title -eq "Test Post" -and
          $bodyObj.content -eq "<p>Test content</p>" -and
          $bodyObj.labels.Count -eq 2 -and
          $bodyObj.labels[0] -eq "tag1" -and
          $bodyObj.labels[1] -eq "tag2"
        } -Verifiable {
          return [pscustomobject]@{ id = "12345"; url = "https://example.blogspot.com/2023/01/test-post.html" }
        }
      }

      # act
      Publish-BloggerPost @script:invokeArgs -Labels @("tag1", "tag2")

      # assert
      Should -InvokeVerifiable
    }

    It "Should handle empty labels array" {
      # arrange

      InModuleScope PSBlogger {
        Mock Invoke-GApi -ParameterFilter {
          $bodyObj = $Body | ConvertFrom-Json
          $bodyObj.labels -eq $null -or $bodyObj.labels.Count -eq 0
        } -Verifiable {
          return @{ id = "12345"; url = "https://example.blogspot.com/2023/01/test-post.html" }
        }
      }

      # act
      Publish-BloggerPost @script:invokeArgs

      # assert
      Should -InvokeVerifiable
    }
  }

  Context "Return value" {
    It "Should return the post object from API response" {
      # arrange
      InModuleScope PSBlogger {
        Mock Invoke-GApi { 
          return [pscustomobject]@{
            id = "12345"
            url = "https://example.blogspot.com/2023/01/test-post.html"
            title = "Test Post"
            content = "<p>Test content</p>"
          }
        }
      }

      # act
      $result = Publish-BloggerPost @script:invokeArgs

      # assert
      $result.id | Should -Be "12345"
      $result.url | Should -Be "https://example.blogspot.com/2023/01/test-post.html"
      $result.title | Should -Be "Test Post"
      $result.content | Should -Be "<p>Test content</p>"
    }
  }
}
