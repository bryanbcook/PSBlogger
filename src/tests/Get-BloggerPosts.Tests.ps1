Describe "Get-BloggerPosts" {

  BeforeEach {
    Import-Module $PSScriptRoot\..\PSBlogger.psm1 -Force
  }

  Context "Retrieve All Posts" {
    BeforeEach {
      InModuleScope PSBlogger {

        $BloggerSession.BlogId = "123456789"

        # Setup initial get-bloggerposts
        Mock Invoke-GApi {
          return @{
            items = @(
              @{ id = "1"; title = "Post 1"; published = "2023-10-01T00:00:00Z" },
              @{ id = "2"; title = "Post 2"; published = "2023-10-02T00:00:00Z" }
            )
            nextPageToken = "1"
          }
        } -ParameterFilter { $uri -notlike "*pageToken*" }
      

        # setup second call
        Mock Invoke-GApi {
          @{
            items = @(
              @{ id = "3"; title = "Post 3"; published = "2023-10-03T00:00:00Z" }
            )
            nextPageToken = $null
          }
        } -ParameterFilter { $uri -like "*pageToken*" }
      }
    }

    It "Should fetch all posts when -All switch is used" {

      # act
      $result = Get-BloggerPosts -All

      # assert
      $result.Count | Should -Be 3
    }
  }
}