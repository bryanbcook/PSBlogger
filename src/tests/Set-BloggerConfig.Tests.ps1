
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
        ExcludeLabels = @()
        UserPreferences = "TestDrive:\UserPreferences.json"
        AttachmentsDirectory = $null
      }
      
      # Set it as a script-scoped variable (same as the module does)
      New-Variable -Name BloggerSession -Value $BloggerSession -Scope Script -Force
    }
  }

  It "Should persist new value to <UserPreference> to BloggerSession.UserPreferences" -TestCases @(
    @{ UserPreference="BlogId"; UserPreferenceValue="12345" }
    @{ UserPreference="ExcludeLabels"; UserPreferenceValue=@("personal/blog-post") }
    @{ UserPreference="AttachmentsDirectory"; UserPreferenceValue="c:\attachments"}
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
    @{ UserPreference="ExcludeLabels"; UserPreferenceValue=@("personal/blog-post") }
    @{ UserPreference="AttachmentsDirectory"; UserPreferenceValue="c:\attachments"}
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