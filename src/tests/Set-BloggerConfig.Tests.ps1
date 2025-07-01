
Describe "Set-BloggerConfig" {
  BeforeEach {
    Import-Module $PSScriptRoot\..\PSBlogger.psm1 -Force
    
    # Ensure the test has a clean BloggerSession variable
    InModuleScope "PSBlogger" {
      # Remove the existing variable if it exists
      if (Get-Variable -Name BloggerSession -Scope Script -ErrorAction SilentlyContinue) {
        Remove-Variable -Name BloggerSession -Scope Script -Force
      }
      
      # Create a new test-specific BloggerSession
      $BloggerSession = [pscustomobject]@{
        BlogId = $null
        UserPreferences = "TestDrive:\UserPreferences.json"
      }
      
      # Set it as a script-scoped variable (same as the module does)
      New-Variable -Name BloggerSession -Value $BloggerSession -Scope Script -Force
    }
  }

  It "Should persist new value to <UserPreference> to BloggerSession.UserPreferences" -TestCases @(
    @{ UserPreference="BlogId"; UserPreferenceValue="12345" }
  ) {

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