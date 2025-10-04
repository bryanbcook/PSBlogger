
$script:UserPreferences = @(
  @{ UserPreference="BlogId"; UserPreferenceValue="12345" }
  @{ UserPreference="ExcludeLabels"; UserPreferenceValue=@("personal/blog-post") }
  @{ UserPreference="AttachmentsDirectory"; UserPreferenceValue="TestDrive:/Attachments"}
)

Describe "Set-BloggerConfig" {
  BeforeAll {
    Import-Module $PSScriptRoot/_TestHelpers.ps1 -Force
  }

  BeforeEach {
    Import-Module $PSScriptRoot/../PSBlogger.psm1 -Force    
    
    # Ensure the test has a clean BloggerSession variable
    InModuleScope "PSBlogger" {
      # Remove the existing variable if it exists
      if (Get-Variable -Name BloggerSession -Scope Script -ErrorAction SilentlyContinue) {
        Remove-Variable -Name BloggerSession -Scope Script -Force
      }
      
      # Create a new test-specific BloggerSession
      $BloggerSession = [pscustomobject]@{
        BlogId = $null
        ExcludeLabels = @()
        UserPreferences = "TestDrive:\UserPreferences.json"
        AttachmentsDirectory = $null
      }
      
      # Set it as a script-scoped variable (same as the module does)
      New-Variable -Name BloggerSession -Value $BloggerSession -Scope Script -Force
    }

    New-Item -Path (Get-TestFilePath "Attachments") -ItemType Directory -Force | Out-Null
  }

  It "Should persist new value to <UserPreference> to BloggerSession.UserPreferences" -TestCases $script:UserPreferences {
    # act
    Set-BloggerConfig -Name $UserPreference -Value $UserPreferenceValue -ErrorAction Stop

    # assert
    InModuleScope "PSBlogger" {
      $userPreferences = Get-Content $BloggerSession.UserPreferences -Raw | ConvertFrom-Json
      
      # Handle path normalization for cross-platform compatibility
      if ($UserPreference -eq "AttachmentsDirectory") {
        # Convert both paths to the same format for comparison
        $actualPath = [System.IO.Path]::GetFullPath($userPreferences.$UserPreference)
        $expectedPath = [System.IO.Path]::GetFullPath($UserPreferenceValue)
        $actualPath | Should -Be $expectedPath
      } else {
        $userPreferences.$UserPreference | Should -Be $UserPreferenceValue
      }
    } -Parameters @{ UserPreference=$UserPreference; UserPreferenceValue=$UserPreferenceValue }
  }

  It "Should persist new value to <UserPreference> to empty BloggerSession.UserPreferences file" -TestCases $script:UserPreferences {
    # arrange: empty file
    Set-Content TestDrive:\UserPreferences.json -Value "{}"


    # act
    Set-BloggerConfig -Name $UserPreference -Value $UserPreferenceValue

    # assert
    InModuleScope "PSBlogger" {
      $userPreferences = Get-Content $BloggerSession.UserPreferences -Raw | ConvertFrom-Json
      
      # Handle path normalization for cross-platform compatibility
      if ($UserPreference -eq "AttachmentsDirectory") {
        # Convert both paths to the same format for comparison
        $actualPath = [System.IO.Path]::GetFullPath($userPreferences.$UserPreference)
        $expectedPath = [System.IO.Path]::GetFullPath($UserPreferenceValue)
        $actualPath | Should -Be $expectedPath
      } else {
        $userPreferences.$UserPreference | Should -Be $UserPreferenceValue
      }
    } -Parameters @{ UserPreference=$UserPreference; UserPreferenceValue=$UserPreferenceValue }
  }

  It "Should clear <UserPreference> if set to empty string" -TestCases $script:UserPreferences {
    # act
    Set-BloggerConfig -Name $UserPreference -Value ""

    # assert
    InModuleScope "PSBlogger" {
      $userPreferences = Get-Content $BloggerSession.UserPreferences -Raw | ConvertFrom-Json
      $userPreferences.$UserPreference | Should -Be $UserPreferenceValue
    } -Parameters @{ UserPreference=$UserPreference; UserPreferenceValue="" }
  }

  It "Should enforce the AttachmentsDirectory is a valid path" {
    # act
    {
      Set-BloggerConfig -Name AttachmentsDirectory -Value "./InvalidPath"
    } | Should -Throw
  }

  It "Should store AttachmentsDirectory as an absolute path" {
    
    try {
      # arrange
      $relativePath = "./Attachments"
      Push-Location TestDrive:/      

      # act
      Set-BloggerConfig -Name AttachmentsDirectory -Value $relativePath

      # assert
      InModuleScope "PSBlogger" {
        $expectedPath = [System.IO.Path]::GetFullPath((Join-Path "TestDrive:" "Attachments"))
        $userPreferences = Get-Content $BloggerSession.UserPreferences -Raw | ConvertFrom-Json
        $actualPath = [System.IO.Path]::GetFullPath($userPreferences.AttachmentsDirectory)
        $actualPath | Should -Be $expectedPath
      }
    }
    finally {
      Pop-Location
    }
  }
}