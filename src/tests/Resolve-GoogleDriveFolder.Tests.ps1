Describe "Resolve-GoogleDriveFolder" {

  BeforeEach {
    Import-Module $PSScriptRoot\..\PSBlogger.psm1 -Force
    Import-Module $PSScriptRoot\_TestHelpers.ps1 -Force
  }

  Context "No folders exist" {

    It "Should create the root folder" {
      
      InModuleScope PSBlogger {
        # arrange
        # return no folders
        Mock Get-GoogleDriveItems -ParameterFilter {
          $ResultType -eq "Folders"
        } { return @() }

        # ensure folder is created
        Mock Add-GoogleDriveFolder -ParameterFilter { $Name -eq "PSBlogger" } {
          return [pscustomobject]@{ id = "root"; name = "PSBlogger" }
        } -Verifiable

        # act
        $result = Resolve-GoogleDriveFolder -FolderPath "PSBlogger"

        # assert
        $result | Should -Not -BeNullOrEmpty
        Should -InvokeVerifiable
      }
    }

    It "Should create root folder and subfolder" {
      InModuleScope PSBlogger {
        # arrange
        # return no folders
        Mock Get-GoogleDriveItems -ParameterFilter {
          $ResultType -eq "Folders"
        } { return @() }

        # ensure root folder is created
        Mock Add-GoogleDriveFolder -ParameterFilter { $Name -eq "PSBlogger" } {
          return [pscustomobject]@{ id = "root"; name = "PSBlogger"; }
        } -Verifiable

        # ensure subfolder is created
        Mock Add-GoogleDriveFolder -ParameterFilter { $Name -eq "Subfolder" -and $ParentId -eq "root" } {
          return [pscustomobject]@{ id = "subfolder"; name = "Subfolder"; parents = @("root") }
        } -Verifiable

        # act
        $result = Resolve-GoogleDriveFolder -FolderPath "PSBlogger/Subfolder"

        # assert
        $result | Should -Not -BeNullOrEmpty
        Should -InvokeVerifiable
      }
    }

  }
}