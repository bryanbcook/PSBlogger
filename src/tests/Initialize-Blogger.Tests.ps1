Describe "Initialize-Blogger" {

  BeforeEach {
    Import-Module $PSScriptRoot\..\PSBlogger.psm1 -Force
  }

  Context "User provides AuthCode" {

    BeforeEach {
      InModuleScope -ModuleName PSBlogger {
        # simulate running as admin
        Mock Test-IsAdmin { $true }

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

  Context "Running as non-admin" {
    BeforeEach {
      InModuleScope -ModuleName PSBlogger {
        # simulate running as non-admin
        Mock Test-IsAdmin { $false }

        # ensure that we don't launch browser or admin features
        Mock Start-Process { throw "Unexpected call to start-process"}
      }
    }

    It "Should show warning and exit when not admin" {
      InModuleScope -ModuleName PSBlogger {
        # arrange
        $initArgs = @{ ClientId="dummy"; ClientSecret="dummy" }
        Mock Write-Warning {} -Verifiable

        # act & assert
        { Initialize-Blogger @initArgs } | Should -Not -Throw
        
        # The function should exit early, so we can verify it doesn't try to do auth
        Assert-MockCalled Test-IsAdmin -Times 1
        Should -InvokeVerifiable
      }
    }
  }
}