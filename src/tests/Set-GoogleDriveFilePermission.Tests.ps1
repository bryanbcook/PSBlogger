Import-Module $PSScriptRoot\..\PSBlogger.psm1 -Force

Describe "Set-GoogleDriveFilePermission" {
  BeforeEach {
    Import-Module $PSScriptRoot\..\PSBlogger.psm1 -Force
  }

  InModuleScope "PSBlogger" {

    Context "Set Permissions" {

    BeforeEach {
      # prevent actual API calls during tests
      Mock Invoke-GApi { throw "Unexpected call $uri" }
    }


    It "Should set permissions for a file" {
      # arrange
      Mock Invoke-GApi -ParameterFilter {
        $Body -match '"role":\s*"reader"' -and `
        $Body -match '"type":\s*"anyone"'
      } {
        return [pscustomobject]@{ id = "12345"; name = "TestFolder" }
      } -Verifiable

      $permission = New-GoogleDriveFilePermission -role "reader" -type "anyone"

      # act
      $result = Set-GoogleDriveFilePermission -FileId "dummyId" -PermissionData $permission
      
      # assert
      $result | Should -Not -BeNullOrEmpty
      Should -InvokeVerifiable
    }

    It "Should throw an error if an unexpected error occurs" {
      # arrange
      Mock Invoke-GApi { throw "API error" } -Verifiable
      $permission = New-GoogleDriveFilePermission -role "reader" -type "anyone"

      # act & assert
      { 
        Set-GoogleDriveFilePermission -FileId "dummyId" -PermissionData $permission
      } | Should -Throw
      Should -InvokeVerifiable
    }

  }

  }
}