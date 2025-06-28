Describe "Get-GoogleDriveFile" {

    BeforeEach {
        Import-Module $PSScriptRoot\..\PSBlogger.psm1 -Force

        InModuleScope PSBlogger {
            Mock Invoke-GApi { throw "Unexpected call $uri" }
        }

    }

    It "should get all files and folders by default" {
        # arrange
        InModuleScope PSBlogger {
            Mock Invoke-GApi -ParameterFilter { 
                $uri.Split('?')[1].Split("&").Contains("q=") } -Verifiable {
                @{
                    files = @(
                        @{ id = "1"; name = "Folder1"; mimeType = "application/vnd.google-apps.folder" },
                        @{ id = "2"; name = "File2"; mimeType = "application/pdf" }
                    )
                }
            }
        }        

        # act
        $result = Get-GoogleDriveFiles

        # assert
        $result | Should -Not -BeNullOrEmpty
        Should -InvokeVerifiable
    }

    It "Should get only get files when result type is Files" {
        # arrange
        InModuleScope PSBlogger {
            Mock Invoke-GApi -ParameterFilter { 
                $uri -like "*q=mimeType!%3d%27application%2fvnd.google-apps.folder%27*" } -Verifiable {
                @{
                    files = @(
                        @{ id = "2"; name = "File2"; mimeType = "application/pdf" }
                    )
                }
            }
        }

        # act
        $result = Get-GoogleDriveFiles -ResultType Files

        # assert
        $result | Should -Not -BeNullOrEmpty
        Should -InvokeVerifiable
    }

    It "Should get only folders when result type is Folders" {
        # arrange
        InModuleScope PSBlogger {
            Mock Invoke-GApi -ParameterFilter { 
                $uri -like "*q=mimeType%3d%27application%2fvnd.google-apps.folder%27*" } -Verifiable {
                @{
                    files = @(
                        @{ id = "1"; name = "Folder1"; mimeType = "application/vnd.google-apps.folder" }
                    )
                }
            }
        }

        # act
        $result = Get-GoogleDriveFiles -ResultType Folders

        # assert
        $result | Should -Not -BeNullOrEmpty
        Should -InvokeVerifiable
    }

    It "Should get specific file or folder by title" {
        # arrange
        InModuleScope PSBlogger {
            Mock Invoke-GApi -ParameterFilter { 
                $uri -like "*q=name%3d%27Unit+Test%27*" } -Verifiable {
                @{
                    files = @(
                        @{ id = "3"; name = "Unit Test"; mimeType = "application/vnd.google-apps.folder" }
                    )
                }
            }
        }

        # act
        $result = Get-GoogleDriveFiles -Title "Unit Test"

        # assert
        $result | Should -Not -BeNullOrEmpty
        Should -InvokeVerifiable
    }

    It "Should get files and folders by parent ID" {
        # arrange
        InModuleScope PSBlogger {
            Mock Invoke-GApi -ParameterFilter { 
                $uri -like "*q=%27parent-id%27+in+parents*" } -Verifiable {
                @{
                    files = @(
                        @{ id = "4"; name = "Child File"; mimeType = "application/pdf" }
                    )
                }
            }
        }

        # act
        $result = Get-GoogleDriveFiles -ParentId "parent-id"

        # assert
        $result | Should -Not -BeNullOrEmpty
        Should -InvokeVerifiable
    }

    It "should get all files and folders" {
        # arrange
        $global:count = 0
        $global:responses = @(
                [pscustomobject]@{ nextPageToken="continue"; files = @( @{ id="1" }, @{ id="2" } ); }
                [pscustomobject]@{ files = @( @{ id="3" }, @{ id="4" } ); }
            )

        InModuleScope PSBlogger {
            Mock Invoke-GApi -ParameterFilter { 
                $uri -like "*q=*" } -Verifiable {
                $global:responses[$global:count++]
            }
        }

        # act
        $result = Get-GoogleDriveFiles

        # assert
        $result.Count | Should -Be 4
        $global:count | Should -Be 2
    }
}