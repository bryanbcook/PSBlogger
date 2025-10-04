Describe 'Add-GoogleDriveFile' {

    BeforeEach {
      Import-Module $PSScriptRoot/../PSBlogger.psm1 -Force

      # prevent actual API calls during tests
      InModuleScope PSBlogger {
          Mock Invoke-GApi { throw "Unexpected call $uri" }
      }
    }

    Context "New File" {

      BeforeEach {
        InModuleScope PSBlogger {
          # setup file doesn't exist
          # folder does not exist
          Mock Get-GoogleDriveItems -ParameterFilter {
            $ResultType -eq "Files" -and $Title -eq "my.png"
          } { return $null }
        }
      }

      It "Should create specified folder if it does not exist before adding file" {
        # arrange
        InModuleScope PSBlogger {

          # folder does not exist
          Mock Get-GoogleDriveItems -ParameterFilter {
            $ResultType -eq "Folders"
          } { return $null }

          # folder was added
          Mock Add-GoogleDriveFolder { return [pscustomobject]@{ id = "12345"}} -Verifiable

          # file was added
          Mock Invoke-GApi -ParameterFilter {
            $uri -eq "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart"
          } {
            return [pscustomobject]@{ id = "67890"; name = "my.png" }
          } -Verifiable
        }

        # act
        $result = Add-GoogleDriveFile -FilePath "$PSScriptRoot\data\my.png" -TargetFolderName "TestFolder"

        # assert
        $result | Should -Not -BeNullOrEmpty
        Should -InvokeVerifiable
      }

      Context "Folder Exists" {

        BeforeEach {
          InModuleScope PSBlogger {
            # folder exists
            Mock Get-GoogleDriveItems -ParameterFilter {
              $ResultType -eq "Folders"
            } { return @([pscustomobject]@{ id = "12345"; name = "TestFolder" }) }
          }
        }

        It "Should send multi-part request to Google Drive" {
          # arrange
          $global:body = ""
          InModuleScope PSBlogger {
            # upload file
            Mock Invoke-GApi -ParameterFilter {
              $uri -eq "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart"
            } {
              # capture the body for verification
              $global:body = $PesterBoundParameters.body
              return [pscustomobject]@{ id = "67890"; name = "my.png" }
            } -Verifiable
          }

          # act
          $result = Add-GoogleDriveFile -FilePath "$PSScriptRoot\data\my.png" -TargetFolderName "TestFolder"

          # assert
          $result | Should -Not -BeNullOrEmpty
          $regexMatches = [regex]::Matches($global:body, "--boundary_")
          $regexMatches.Count | Should -Be 3
          $bodyLines = $global:body.Split([Environment]::NewLine)

          $bodyLines.Count | Should -Be 10
          $bodyLines[0].StartsWith("--boundary_") | Should -Be $true
          $bodyLines[4].StartsWith("--boundary_") | Should -Be $true
          $bodyLines[-1].StartsWith("--boundary_") | Should -Be $true
          $bodyLines[-1].EndsWith("--") | Should -Be $true
        }

        It "Should add file to specified folder" {
          # arrange
          InModuleScope PSBlogger {
            Mock Invoke-GApi -ParameterFilter {
              $uri -eq "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart" -and `
              $body -match '"parents":\s*\["12345"\]'
            } {
              return [pscustomobject]@{ id = "67890"; name = "my.png" }
            } -Verifiable
          }
          # act
          $result = Add-GoogleDriveFile -FilePath "$PSScriptRoot\data\my.png" -TargetFolderName "TestFolder"

          # assert
          $result | Should -Not -BeNullOrEmpty
          Should -InvokeVerifiable
        }

        It "Should use the default file name as the google file name" {
          # arrange
          InModuleScope PSBlogger {
            Mock Invoke-GApi -ParameterFilter {
              $uri -eq "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart" -and `
              $body -match '"name":\s*"my\.png"'
            } {
              return [pscustomobject]@{ id = "67890"; name = "my.png" }
            } -Verifiable
          }
          # act
          $result = Add-GoogleDriveFile -FilePath "$PSScriptRoot\data\my.png" -TargetFolderName "TestFolder"

          # assert
          $result | Should -Not -BeNullOrEmpty
          Should -InvokeVerifiable
        }

        It "Should include mime type in the request" {
          # arrange
          InModuleScope PSBlogger {
            Mock Invoke-GApi -ParameterFilter {
              $uri -eq "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart" -and `
              $body -match 'Content-Type:\s*image/png'
            } {
              return [pscustomobject]@{ id = "67890"; name = "my.png" }
            } -Verifiable
          }
          # act
          $result = Add-GoogleDriveFile -FilePath "$PSScriptRoot\data\my.png" -TargetFolderName "TestFolder"

          # assert
          $result | Should -Not -BeNullOrEmpty
          Should -InvokeVerifiable
        }
      }

      Context "Preserve subfolder path" {

        It "Should create full paths in GoogleDrive matching the supplied FileName" {
          # arrange
          InModuleScope PSBlogger {
            # folders do not exist
            Mock Get-GoogleDriveItems -ParameterFilter {
              $ResultType -eq "Folders"
            } { return $null }

            # create root folder
            Mock Add-GoogleDriveFolder -ParameterFilter { $Name -eq "TestFolder" } {
              return [pscustomobject]@{ id = "12345"; name = "TestFolder" }
            } -Verifiable

            # create subfolder
            Mock Add-GoogleDriveFolder -ParameterFilter { $Name -eq "subfolder" -and $ParentId -eq "12345" } {
              return [pscustomobject]@{ id = "67890"; name = "subfolder" }
            } -Verifiable

            # file in subfolder does not exist
            Mock Get-GoogleDriveItems -ParameterFilter {
              $ResultType -eq "Files" -and $Title -eq "my.png" -and $ParentId -eq "67890"
            } { return $null }

            # file was added
            Mock Invoke-GApi -ParameterFilter {
              $uri -eq "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart" -and `
              $body -match '"parents":\s*\["67890"\]' -and `
              $body -match '"name":\s*"my\.png"'
            } {
              return [pscustomobject]@{ id = "abcde"; name = "my.png" }
            } -Verifiable
          }

          # act
          $result = Add-GoogleDriveFile -FilePath "$PSScriptRoot\data\my.png" -FileName "subfolder/my.png" -TargetFolderName "TestFolder"

          # assert
          $result | Should -Not -BeNullOrEmpty
          Should -InvokeVerifiable
        }

        It "Should create missing subfolders in Google Drive matching the supplied FileName" {
          # arrange
          InModuleScope PSBlogger {
            # folders do not exist
            Mock Get-GoogleDriveItems -ParameterFilter {
              $ResultType -eq "Folders"
            } { 
              @(
                [pscustomobject]@{ id= "12345"; name = "TestFolder" }
              )
            }

            # create subfolder
            Mock Add-GoogleDriveFolder -ParameterFilter { $Name -eq "subfolder" -and $ParentId -eq "12345" } {
              return [pscustomobject]@{ id = "67890"; name = "subfolder" }
            } -Verifiable

            # file in subfolder does not exist
            Mock Get-GoogleDriveItems -ParameterFilter {
              $ResultType -eq "Files" -and $Title -eq "my.png" -and $ParentId -eq "67890"
            } { return $null }

            # file was added
            Mock Invoke-GApi -ParameterFilter {
              $uri -eq "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart" -and `
              $body -match '"parents":\s*\["67890"\]' -and `
              $body -match '"name":\s*"my\.png"'
            } {
              return [pscustomobject]@{ id = "abcde"; name = "my.png" }
            } -Verifiable
          }

          # act
          $result = Add-GoogleDriveFile -FilePath "$PSScriptRoot\data\my.png" -FileName "subfolder/my.png" -TargetFolderName "TestFolder"

          # assert
          $result | Should -Not -BeNullOrEmpty
          Should -InvokeVerifiable

        }
      }
    }

    Context "Existing File" {

      BeforeEach {
        InModuleScope PSBlogger {
          # folder exists
          Mock Get-GoogleDriveItems -ParameterFilter {
            $ResultType -eq "Folders"
          } { return @([pscustomobject]@{ id = "12345"; name = "TestFolder" }) }

          # file exists
          Mock Get-GoogleDriveItems -ParameterFilter {
            $ResultType -eq "Files" -and $Title -eq "my.png" -and $ParentId -eq "12345"
          } { return @([pscustomobject]@{ id = "67890"; name = "my.png" }) }
        }
      }
      

      It "Should return the existing file if overwrite is not specified" {
        # act
        $result = Add-GoogleDriveFile -FilePath "$PSScriptRoot\data\my.png" -TargetFolderName "TestFolder"
        
        # assert
        $result | Should -Not -BeNullOrEmpty
        $result.id | Should -Be "67890"
        $result.name | Should -Be "my.png"
      }

      It "Should overwrite the existing file if overwrite is specified" {
        # arrange
        InModuleScope PSBlogger {
          # file was overwritten
          Mock Invoke-GApi -ParameterFilter {
            $uri -eq "https://www.googleapis.com/upload/drive/v3/files/67890?uploadType=media" -and `
            $method -eq "PATCH"
          } {
            return [pscustomobject]@{ id = "67890"; name = "my.png" }
          } -Verifiable
        }
        
        # act
        $result = Add-GoogleDriveFile -FilePath "$PSScriptRoot\data\my.png" -TargetFolderName "TestFolder" -Force
        
        # assert
        $result | Should -Not -BeNullOrEmpty
        Should -InvokeVerifiable
      }

    }
  
}