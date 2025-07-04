Describe "Publish-MarkdownDriveImages" {
  BeforeEach {
    Import-Module $PSScriptRoot\..\PSBlogger.psm1 -Force
    Import-Module $PSScriptRoot\_TestHelpers.ps1 -Force

    # Create test images in TestDrive
    $testImage1 = "TestDrive:\test-image1.png"
    $testImage2 = "TestDrive:\subfolder\test-image2.jpg"
    
    # Create directory structure
    New-Item -Path "TestDrive:\subfolder" -ItemType Directory -Force
    
    # Create dummy image files
    Set-Content -Path $testImage1 -Value "fake png content"
    Set-Content -Path $testImage2 -Value "fake jpg content"

    $fileWithSingleImage = "TestDrive:\single-image.md"
    $fileWithSingleImageMarkdown = @(
      "# Test Post",
      "",
      "![Test Image](test-image1.png)"
    ) -join "`n"
    Set-Content -Path $fileWithSingleImage -Value $fileWithSingleImageMarkdown

    # Prevent actual API calls during tests
    InModuleScope PSBlogger {
      Mock Invoke-GApi { throw "Unexpected call to $uri" }
    }
  }

  Context "No images in markdown file" {
    It "Should return empty array when no images are found" {
      # arrange
      $markdownFile = "TestDrive:\no-images.md"
      $markdownContent = "# Test Post`n`nThis post has no images."
      Set-MarkdownFile $markdownFile $markdownContent

      # act
      $result = Publish-MarkdownDriveImages -File $markdownFile

      # assert
      $result | Should -Be @()
      $result.Count | Should -Be 0
    }

    It "Should return empty array when only online images are found" {
      # arrange
      $markdownFile = "TestDrive:\online-images.md"
      $markdownContent = @(
        "# Test Post"
        ""
        "![Online Image](https://example.com/image.png)"
        "![Another Online](http://test.com/photo.jpg)"
      ) -join "`n"
      Set-MarkdownFile $markdownFile $markdownContent

      # act
      $result = Publish-MarkdownDriveImages -File $markdownFile

      # assert
      $result | Should -Be @()
      $result.Count | Should -Be 0
    }
  }

  Context "Single image upload" {
    BeforeEach {
      InModuleScope PSBlogger {
        # Mock successful image upload
        Mock Add-GoogleDriveFile {
          return [PSCustomObject]@{
            id = "mock-file-id-123"
            name = "test-image1.png"
            PublicUrl = "https://drive.google.com/uc?id=mock-file-id-123"
          }
        } -Verifiable

        # Mock Setting permissions
        Mock Set-GoogleDriveFilePermission { 
          return [PSCustomObject]@{ id = "permission-id" }
        } -Verifiable

        # Mock markdown update
        Mock Update-MarkdownImages { return $true } -Verifiable
      }
    }

    It "Should upload image and set permissions without Force parameter" {
      # arrange

      # act
      $result = Publish-MarkdownDriveImages -File $fileWithSingleImage

      # assert
      $result | Should -Not -BeNullOrEmpty
      $result.Count | Should -Be 1
      $result[0].FileName | Should -Be "test-image1.png"
      $result[0].NewUrl | Should -Be "https://drive.google.com/uc?id=mock-file-id-123"
      
      Should -InvokeVerifiable
      Should -Invoke Add-GoogleDriveFile -ModuleName PSBlogger -Exactly 1 -ParameterFilter {
        $FileName -eq "test-image1.png" -and $Force -eq $false
      }
      Should -Invoke Set-GoogleDriveFilePermission -ModuleName PSBlogger -Exactly 1 -ParameterFilter {
        $FileId -eq "mock-file-id-123"
      }
      Should -Invoke Update-MarkdownImages -ModuleName PSBlogger -Exactly 1
    }

    It "Should upload image with Force parameter when specified" {
      # arrange

      # act
      $result = Publish-MarkdownDriveImages -File $fileWithSingleImage -Force

      # assert
      $result | Should -Not -BeNullOrEmpty
      $result.Count | Should -Be 1
      
      Should -Invoke Add-GoogleDriveFile -ModuleName PSBlogger -Exactly 1 -ParameterFilter {
        $FileName -eq "test-image1.png" -and $Force -eq $true
      }
    }

    It "Should handle upload failure gracefully" {
      # arrange

      InModuleScope PSBlogger {
        # Mock failed upload
        Mock Add-GoogleDriveFile { return $null }
      }

      # act
      $result = Publish-MarkdownDriveImages -File $fileWithSingleImage

      # assert
      $result | Should -Be @()
      $result.Count | Should -Be 0
      
      Should -Invoke Add-GoogleDriveFile -ModuleName PSBlogger -Exactly 1
      Should -Invoke Set-GoogleDriveFilePermission -ModuleName PSBlogger -Exactly 0
      Should -Invoke Update-MarkdownImages -ModuleName PSBlogger -Exactly 0
    }

    It "Should handle upload exception gracefully" {
      # arrange

      InModuleScope PSBlogger {
        # Mock upload exception
        Mock Add-GoogleDriveFile { 
          throw [System.Exception]::new("Upload failed")
        }
      }

      # act
      $result = Publish-MarkdownDriveImages -File $fileWithSingleImage

      # assert
      $result | Should -Be @()
      $result.Count | Should -Be 0
      
      Should -Invoke Add-GoogleDriveFile -ModuleName PSBlogger -Exactly 1
      Should -Invoke Set-GoogleDriveFilePermission -ModuleName PSBlogger -Exactly 0
      Should -Invoke Update-MarkdownImages -ModuleName PSBlogger -Exactly 0
    }
  }

  Context "Multiple image upload" {
    BeforeEach {
      InModuleScope PSBlogger {
        # Mock successful uploads for different images
        Mock Add-GoogleDriveFile -ParameterFilter { $FileName -eq "test-image1.png" } {
          return [PSCustomObject]@{
            id = "mock-file-id-1"
            name = "test-image1.png"
            PublicUrl = "https://drive.google.com/uc?id=mock-file-id-1"
          }
        }

        Mock Add-GoogleDriveFile -ParameterFilter { $FileName -eq "test-image2.jpg" } {
          return [PSCustomObject]@{
            id = "mock-file-id-2"
            name = "test-image2.jpg"
            PublicUrl = "https://drive.google.com/uc?id=mock-file-id-2"
          }
        }

        Mock Set-GoogleDriveFilePermission { 
          return [PSCustomObject]@{ id = "permission-id" }
        }

        Mock Update-MarkdownImages { return $true }
      }
    }

    It "Should upload multiple images and set permissions for each" {
      # arrange
      $markdownFile = "TestDrive:\multiple-images.md"
      $markdownContent = @(
        "# Test Post"
        ""
        "![First Image](test-image1.png)"
        ""
        "Some content here."
        ""
        "![Second Image](subfolder/test-image2.jpg)"
      ) -join "`n"
      Set-MarkdownFile $markdownFile $markdownContent

      # act
      $result = Publish-MarkdownDriveImages -File $markdownFile

      # assert
      $result | Should -Not -BeNullOrEmpty
      $result.Count | Should -Be 2
      
      $result[0].FileName | Should -Be "test-image1.png"
      $result[0].NewUrl | Should -Be "https://drive.google.com/uc?id=mock-file-id-1"
      
      $result[1].FileName | Should -Be "test-image2.jpg"
      $result[1].NewUrl | Should -Be "https://drive.google.com/uc?id=mock-file-id-2"
      
      Should -Invoke Add-GoogleDriveFile -ModuleName PSBlogger -Exactly 2
      Should -Invoke Set-GoogleDriveFilePermission -ModuleName PSBlogger -Exactly 2
      Should -Invoke Update-MarkdownImages -ModuleName PSBlogger -Exactly 1
    }

    It "Should handle partial upload failures" {
      # arrange
      $markdownFile = "TestDrive:\partial-fail.md"
      $markdownContent = @(
        "# Test Post"
        ""
        "![First Image](test-image1.png)"
        "![Second Image](subfolder/test-image2.jpg)"
      ) -join "`n"
      Set-MarkdownFile $markdownFile $markdownContent

      InModuleScope PSBlogger {
        # First upload succeeds, second fails
        Mock Add-GoogleDriveFile -ParameterFilter { $FileName -eq "test-image1.png" } {
          return [PSCustomObject]@{
            id = "mock-file-id-1"
            name = "test-image1.png"
            PublicUrl = "https://drive.google.com/uc?id=mock-file-id-1"
          }
        }

        Mock Add-GoogleDriveFile -ParameterFilter { $FileName -eq "test-image2.jpg" } {
          return $null
        }
      }

      # act
      $result = Publish-MarkdownDriveImages -File $markdownFile

      # assert
      $result | Should -Not -BeNullOrEmpty
      $result.Count | Should -Be 1
      $result[0].FileName | Should -Be "test-image1.png"
      
      Should -Invoke Add-GoogleDriveFile -ModuleName PSBlogger -Exactly 2
      Should -Invoke Set-GoogleDriveFilePermission -ModuleName PSBlogger -Exactly 1
      Should -Invoke Update-MarkdownImages -ModuleName PSBlogger -Exactly 1
    }
  }

  Context "Markdown file update behavior" {
    BeforeEach {
      InModuleScope PSBlogger {
        Mock Add-GoogleDriveFile {
          return [PSCustomObject]@{
            id = "mock-file-id-123"
            name = "test-image1.png"
            PublicUrl = "https://drive.google.com/uc?id=mock-file-id-123"
          }
        }

        Mock Set-GoogleDriveFilePermission { 
          return [PSCustomObject]@{ id = "permission-id" }
        }
      }
    }

    It "Should update markdown when images are successfully uploaded" {
      # arrange

      InModuleScope PSBlogger {
        Mock Update-MarkdownImages { return $true } -Verifiable
      }

      # act
      $result = Publish-MarkdownDriveImages -File $fileWithSingleImage

      # assert
      $result | Should -Not -BeNullOrEmpty
      Should -Invoke Update-MarkdownImages -ModuleName PSBlogger -Exactly 1 -ParameterFilter {
        $File -eq $fileWithSingleImage -and $ImageMappings.Count -eq 1
      }
    }

    It "Should not update markdown when no images are uploaded" {
      # arrange

      InModuleScope PSBlogger {
        # All uploads fail
        Mock Add-GoogleDriveFile { return $null }
        Mock Update-MarkdownImages { return $true }
      }

      # act
      $result = Publish-MarkdownDriveImages -File $fileWithSingleImage

      # assert
      $result | Should -Be @()
      Should -Invoke Update-MarkdownImages -ModuleName PSBlogger -Exactly 0
    }
  }

  Context "Permission handling" {
    BeforeEach {
      InModuleScope PSBlogger {
        Mock Add-GoogleDriveFile {
          $FileName = $args[1]
          return [PSCustomObject]@{
            id = "mock-file-id-$FileName"
            name = "$FileName"
            PublicUrl = "https://drive.google.com/uc?id=mock-file-id-$FileName"
          }
        }

        Mock Update-MarkdownImages { return $true }
      }
    }

    It "Should create anonymous reader permission for uploaded files" {
      # arrange
      InModuleScope PSBlogger {

        Mock Set-GoogleDriveFilePermission { 
          return [PSCustomObject]@{ id = "permission-id" }
        } -Verifiable
      }

      # act
      $result = Publish-MarkdownDriveImages -File $fileWithSingleImage

      # assert
      $result | Should -Not -BeNullOrEmpty
      Should -Invoke Set-GoogleDriveFilePermission -ModuleName PSBlogger -Exactly 1 -ParameterFilter {
        $FileId -eq "mock-file-id-test-image1.png"
      }
    }

    It "Should handle permission setting failure gracefully" {
      # arrange
      $markdownFile = "TestDrive:\permission-fail.md"
      $markdownContent = @(
        "# Test Post"
        ""
        "![Test Image](test-image1.png)"
        "![Image with Permission Failure](test-image2.png)"
      ) -join "`n"
      Set-MarkdownFile $markdownFile $markdownContent

      InModuleScope PSBlogger {

        # Permission setting fails but shouldn't stop the process
        Mock Set-GoogleDriveFilePermission -ParameterFilter { $FileId -eq "mock-file-id-test-image2.png" } { 
          throw [System.Exception]::new("Permission failed")
        }
      }

      # act & assert - should not throw
      { 
        $script:result = Publish-MarkdownDriveImages -File $markdownFile 
      } | Should -Not -Throw
      
      # Although the image was uploaded, permissions setting failed,
      # so the original markdown image reference should not have been updated
      # and only one of the images should have been processed.
      $script:result.Count | Should -Be 1
    }
  }
}
