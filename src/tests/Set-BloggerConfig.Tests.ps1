
Describe "Set-BloggerConfig" {
  BeforeEach {
    Import-Module $PSScriptRoot\..\PSBlogger.psm1 -Force
    InModuleScope "PSBlogger" {
      $BloggerSession = [pscustomobject]@{
        BlogId = $null
        UserPreferences = "TestDrive:\UserPreferences.json"
      }
    }
  }

  It "Should persist new value to <UserPreference> to BloggerSession.UserPreferences" -TestCases @(
    @{ UserPreference="BlogId"; UserPreferenceValue="12345" }
  ) {
    # arrange
    InModuleScope "PSBlogger" {
      $BloggerSession = [pscustomobject]@{
        BlogId = $null
        UserPreferences = "TestDrive:\UserPreferences.json"
      }
    }

    # act
    Set-BloggerConfig -Name $UserPreference -Value $UserPreferenceValue -ErrorAction Stop

    # assert
    InModuleScope "PSBlogger" {
      $userPreferences = Get-Content $BloggerSession.UserPreferences -Raw | ConvertFrom-Json
      $userPreferences.$UserPreference | Should -Be $UserPreferenceValue
    } -Parameters @{ UserPreference=$UserPreference; UserPreferenceValue=$UserPreferenceValue }
  }

  It "Should persist new value to <UserPreference> to empty BloggerSession.UserPreferences file" -TestCases @(
    @{ UserPreference="BlogId"; UserPreferenceValue="12345" }
  ) {
    # arrange: empty file
    Set-Content TestDrive:\UserPreferences.json -Value "{}"

    # act
    Set-BloggerConfig -Name $UserPreference -Value $UserPreferenceValue

    # assert
    InModuleScope "PSBlogger" {
      $userPreferences = Get-Content $BloggerSession.UserPreferences -Raw | ConvertFrom-Json
      $userPreferences.$UserPreference | Should -Be $UserPreferenceValue
    } -Parameters @{ UserPreference=$UserPreference; UserPreferenceValue=$UserPreferenceValue }
  }
}