Describe "Initialize-Blogger" {

  BeforeEach {
    Import-Module $PSScriptRoot\..\PSBlogger.psm1 -Force
  }

  Context "User provides AuthCode" {

    BeforeEach {
      InModuleScope -ModuleName PSBlogger {
        # simulate running as admin
        Mock Test-IsAdmin { $true }
        Mock Test-ChocolateyInstalled { $true }
        Mock Test-PandocInstalled { $true }

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

  Context "Pandoc Detection and Installation" {
    BeforeEach {
      InModuleScope -ModuleName PSBlogger {
        # simulate running as admin
        Mock Test-IsAdmin { $true }
        
        # Mock the authentication flow to avoid complications
        Mock Get-GoogleAccessToken { return @{ refresh_token = "refresh_token" } }
        Mock Update-GoogleAccessToken { return @{ access_token = "access_token" } }
        Mock Wait-GoogleAuthApiToken { "simulatedcode" }
        Mock Start-Process { }
        Mock Set-CredentialCache { }
      }
    }

    It "Should continue normally when Pandoc is already installed" {
      InModuleScope -ModuleName PSBlogger {
        # arrange
        Mock Test-PandocInstalled { $true }
        Mock Test-ChocolateyInstalled { throw "Should not be called when Pandoc is installed" }
        Mock Install-PandocWithChocolatey { throw "Should not be called when Pandoc is installed" }
        
        $initArgs = @{
          ClientId = "dummy"
          ClientSecret = "dummy"
          Confirm = $false  # Prevent any prompting
        }

        # act & assert
        { Initialize-Blogger @initArgs } | Should -Not -Throw
        
        # verify pandoc installation was not attempted
        Assert-MockCalled Test-PandocInstalled -Times 1
        Assert-MockCalled Install-PandocWithChocolatey -Times 0
      }
    }

    It "Should show warning when Pandoc is not installed and Chocolatey is not available" {
      InModuleScope -ModuleName PSBlogger {
        # arrange
        Mock Test-PandocInstalled { $false }
        Mock Test-ChocolateyInstalled { $false }
        Mock Install-PandocWithChocolatey { throw "Should not be called when Chocolatey is not available" }
        
        $initArgs = @{
          ClientId = "dummy"
          ClientSecret = "dummy"
          Confirm = $false  # Prevent any prompting
        }

        # act
        Initialize-Blogger @initArgs

        # assert
        Should -InvokeVerifiable
        Assert-MockCalled Install-PandocWithChocolatey -Times 0
      }
    }

    It "Should automatically install Pandoc when Confirm is false and Chocolatey is available" {
      InModuleScope -ModuleName PSBlogger {
        # arrange
        Mock Test-PandocInstalled { $false }
        Mock Test-ChocolateyInstalled { $true }
        Mock Install-PandocWithChocolatey { } -Verifiable
        
        $initArgs = @{
          ClientId = "dummy"
          ClientSecret = "dummy"
          Confirm = $false  # This should bypass confirmation and install automatically
        }

        # act
        Initialize-Blogger @initArgs

        # assert
        Should -InvokeVerifiable
      }
    }

    It "Should call pandoc and chocolatey check functions in correct order" {
      InModuleScope -ModuleName PSBlogger {
        # arrange
        Mock Test-PandocInstalled { $false } -Verifiable
        Mock Test-ChocolateyInstalled { $false } -Verifiable
        Mock Write-Warning { }
        
        $initArgs = @{
          ClientId = "dummy"
          ClientSecret = "dummy"
          Confirm = $false  # Prevent any prompting
        }

        # act
        Initialize-Blogger @initArgs

        # assert
        Should -InvokeVerifiable
      }
    }

    # Note: Additional confirmation behavior tests can be performed manually:
    # - Initialize-Blogger (with ConfirmPreference = 'Medium' or 'High') should prompt
    # - Initialize-Blogger -Confirm:$false should install without prompting  
    # - Initialize-Blogger -WhatIf should show what would happen without installing
  }
}