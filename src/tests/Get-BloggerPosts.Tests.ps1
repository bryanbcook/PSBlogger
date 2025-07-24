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
          return [pscustomobject]@{
            items = @(
              @{ id = "1"; title = "Post 1"; published = "2023-10-01T00:00:00Z" },
              @{ id = "2"; title = "Post 2"; published = "2023-10-02T00:00:00Z" }
            )
            nextPageToken = "1"
          }
        } -ParameterFilter { $uri -notlike "*pageToken*" }
      

        # setup second call
        Mock Invoke-GApi {
          return [pscustomobject]@{
            items = @(
              @{ id = "3"; title = "Post 3"; published = "2023-10-03T00:00:00Z" }
            )
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

    It "Should only fetch initial set if -All switch is not used" {
      # arrange
      InModuleScope PSBlogger {
        # Setup initial get-bloggerposts
        Mock Invoke-GApi {
          return [pscustomobject]@{
            items = @(
              @{ id = "1"; title = "Post 1"; published = "2023-10-01T00:00:00Z" },
              @{ id = "2"; title = "Post 2"; published = "2023-10-02T00:00:00Z" }
            )
            nextPageToken = $null
          }
        } -ParameterFilter { $uri -notlike "*pageToken*" }
      }

      # act
      $result = Get-BloggerPosts -All

      # assert
      $result.Count | Should -Be 2
    }
  }

  Context "Retrieve Posts with Date Filter" {
    BeforeEach {
      InModuleScope PSBlogger {

        $BloggerSession.BlogId = "123456789"
      }
    }

    It "Should filter posts based on Since parameter" {
      # arrange
      InModuleScope PSBlogger {

        # Mock the API call to return posts after a specific date
        Mock Invoke-GApi {
          return [pscustomobject]@{
            items = @(
              @{ id = "1"; title = "Post 1"; published = "2023-10-01T00:00:00Z" },
              @{ id = "2"; title = "Post 2"; published = "2023-10-02T00:00:00Z" }
            )
            nextPageToken = $null
          }
        } -ParameterFilter { $uri -like "*since=2023-09-30*" }
      }

      # act
      $result = Get-BloggerPosts -Since (Get-Date "2023-09-30")

      # assert
      $result.Count | Should -Be 2
      $result[0].title | Should -Be "Post 1"
      $result[1].title | Should -Be "Post 2"
    }

    It "Should not constrain by date if Since parameter is not provided" {
      # arrange
      InModuleScope PSBlogger {

        # Mock the API call to return all posts
        Mock Invoke-GApi {
          return [pscustomobject]@{
            items = @(
              @{ id = "1"; title = "Post 1"; published = "2023-10-01T00:00:00Z" },
              @{ id = "2"; title = "Post 2"; published = "2023-10-02T00:00:00Z" }
            )
            nextPageToken = $null
          }
        } -ParameterFilter { $uri -notlike "*since*" }
      }

      # act
      $result = Get-BloggerPosts

      # assert
      $result.Count | Should -Be 2
    }
  }
}