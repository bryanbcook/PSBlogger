Describe "Get-GoogleDriveFile" {

    BeforeEach {
        Import-Module $PSScriptRoot\..\PSBlogge.psm1 -Force
    }

    It "should get files" {
        
        Get-GoogleDriveFiles
    }

    It "should upload file" {
        Add-GoogleDriveFile -Path "..\my.png" -Name "Unit Test" -Description "Wah"
    }
}