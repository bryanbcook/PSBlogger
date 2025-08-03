Describe "Initialize-Blogger" {

  BeforeEach {
    Import-Module $PSScriptRoot\..\PSBlogger.psm1 -Force
  }

  # Context "Try it" {
  #   It "Should launch browser and authenticate" {
  #     Initialize-Blogger
  #   }
  # }

  Context "User provides AuthCode" {

    BeforeEach {
      InModuleScope -ModuleName PSBlogger {
        # simulate valid auth token
        Mock Get-GoogleAccessToken { return @{ refresh_token = "refresh_token" } }
        # simulate valid offline token
        Mock Update-GoogleAccessToken { return @{ access_token = "access_token" } }
        # simulate auth-flow in browser
        Mock Wait-GoogleAuthApiToken { "simulatedcode" }
        # prevent browser from being launched
        Mock Start-Process { }
      }
    }

    It "Should persist credentials" {
      
      # test variable inside loaded module
      InModuleScope -ModuleName PSBlogger {
        # arrange
        $credentialCache = "TestDrive:\credentialcache.json"
        $BloggerSession.CredentialCache = $credentialCache
        $initArgs = @{
          ClientId = "dummy"
          ClientSecret = "dummy"
        }

        # act
        Initialize-Blogger @initArgs
        
        # assert
        $credentials = Get-Content -Path $credentialCache | ConvertFrom-Json
        $credentials.access_token | Should -Be "access_token"
      }
    }

    It "Should reset previous auth tokens" {
      # test variable inside loaded module
      InModuleScope -ModuleName PSBlogger {
        # arrange
        $credentialCache = "TestDrive:\credentialcache.json"
        $BloggerSession.CredentialCache = $credentialCache
        
        $BloggerSession.AccessToken = "invalid"
        $BloggerSession.RefreshToken = "invalid"

        $initArgs = @{
          ClientId = "dummy"
          ClientSecret = "dummy"
        }

        # act
        Initialize-Blogger @initArgs

        # assert
        $BloggerSession.AccessToken | Should -Be $null
        $BloggerSession.RefreshToken | Should -Be $null
      }
    }

  }

}