Import-Module $PSScriptRoot\..\PSBlogger.psm1 -Force

Describe "Add-GoogleDriveFolder" {
  BeforeEach {
    Import-Module $PSScriptRoot\..\PSBlogger.psm1 -Force
  }

  InModuleScope "PSBlogger" {

    BeforeEach {
      # prevent actual API calls during tests
      Mock Invoke-GApi { throw "Unexpected call $uri" }
    }

    Context "Folder Creation" {

      It "Should create a new folder in the root if parent not specified" {
        # arrange
        Mock Invoke-GApi -ParameterFilter {
          $Body -match '"name":\s*"TestFolder"' -and `
          $Body -notmatch '\"parents\"'
        } {
          return [pscustomobject]@{ id = "12345"; name = "TestFolder" }
        } -Verifiable

        # act
        $result = Add-GoogleDriveFolder -Name "TestFolder"
        
        # assert
        $result | Should -Not -BeNullOrEmpty
        Should -InvokeVerifiable
      }

      It "Should throw an error if an unexpected error occurs" {
        # arrange
        Mock Invoke-GApi { throw "API error" } -Verifiable

        # act & assert
        { 
          Add-GoogleDriveFolder -Name "TestFolder" 
        } | Should -Throw
        Should -InvokeVerifiable
      }

    }

  }
}