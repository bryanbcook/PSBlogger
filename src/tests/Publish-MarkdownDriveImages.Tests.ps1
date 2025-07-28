Describe "Publish-MarkdownDriveImages" {
  BeforeEach {
    Import-Module $PSScriptRoot\..\PSBlogger.psm1 -Force
    Import-Module $PSScriptRoot\_TestHelpers.ps1 -Force

    # Create test images in TestDrive
    $testImage1 = New-TestImage "TestDrive:\test-image1.png"
    $testImage2 = New-TestImage "TestDrive:\subfolder\test-image2.jpg"

    $fileWithSingleImage = "TestDrive:\single-image.md"
    $fileWithSingleImageMarkdown = @(
      "# Test Post",
      "",
      "![Test Image](test-image1.png)"
    ) -join "`n"
    Set-MarkdownFile $fileWithSingleImage $fileWithSingleImageMarkdown

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
        # Mock permission creation
        Mock New-GoogleDriveFilePermission {
          return [PSCustomObject]@{
            role = "reader"
            type = "anyone"
          }
        }

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
        Mock Add-GoogleDriveFile { return $null } -Verifiable
        
        # Override previous mocks for this specific test
        Mock New-GoogleDriveFilePermission {
          return [PSCustomObject]@{
            role = "reader"
            type = "anyone"
          }
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

    It "Should handle upload exception gracefully" {
      # arrange

      InModuleScope PSBlogger {
        # Mock upload exception
        Mock Add-GoogleDriveFile { 
          throw [System.Exception]::new("Upload failed")
        } -Verifiable
        
        # Override previous mocks for this specific test
        Mock New-GoogleDriveFilePermission {
          return [PSCustomObject]@{
            role = "reader"
            type = "anyone"
          }
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
        # Mock permission creation first
        Mock New-GoogleDriveFilePermission {
          return [PSCustomObject]@{
            role = "reader"
            type = "anyone"
          }
        }

        # Mock successful uploads for different images with specific parameter filters
        Mock Add-GoogleDriveFile -ParameterFilter { $FileName -eq "test-image1.png" } {
          return [PSCustomObject]@{
            id = "mock-file-id-1"
            name = "test-image1.png"
            PublicUrl = "https://drive.google.com/uc?id=mock-file-id-1"
          }
        } -Verifiable

        Mock Add-GoogleDriveFile -ParameterFilter { $FileName -eq "test-image2.jpg" } {
          return [PSCustomObject]@{
            id = "mock-file-id-2"
            name = "test-image2.jpg"
            PublicUrl = "https://drive.google.com/uc?id=mock-file-id-2"
          }
        } -Verifiable

        Mock Set-GoogleDriveFilePermission { 
          return [PSCustomObject]@{ id = "permission-id" }
        } -Verifiable

        Mock Update-MarkdownImages { return $true } -Verifiable
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
        # Override mocks for this specific scenario
        Mock New-GoogleDriveFilePermission {
          return [PSCustomObject]@{
            role = "reader"
            type = "anyone"
          }
        }

        # First upload succeeds, second fails
        Mock Add-GoogleDriveFile -ParameterFilter { $FileName -eq "test-image1.png" } {
          return [PSCustomObject]@{
            id = "mock-file-id-1"
            name = "test-image1.png"
            PublicUrl = "https://drive.google.com/uc?id=mock-file-id-1"
          }
        } -Verifiable

        Mock Add-GoogleDriveFile -ParameterFilter { $FileName -eq "test-image2.jpg" } {
          return $null
        } -Verifiable

        Mock Set-GoogleDriveFilePermission { 
          return [PSCustomObject]@{ id = "permission-id" }
        } -Verifiable

        Mock Update-MarkdownImages { return $true } -Verifiable
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
        Mock New-GoogleDriveFilePermission {
          return [PSCustomObject]@{
            role = "reader"
            type = "anyone"
          }
        }

        Mock Add-GoogleDriveFile {
          return [PSCustomObject]@{
            id = "mock-file-id-123"
            name = "test-image1.png"
            PublicUrl = "https://drive.google.com/uc?id=mock-file-id-123"
          }
        } -Verifiable

        Mock Set-GoogleDriveFilePermission { 
          return [PSCustomObject]@{ id = "permission-id" }
        } -Verifiable
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
        Mock Add-GoogleDriveFile { return $null } -Verifiable
        Mock Update-MarkdownImages { return $true }
        
        # Override permission mock for this test
        Mock New-GoogleDriveFilePermission {
          return [PSCustomObject]@{
            role = "reader"
            type = "anyone"
          }
        }
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
        Mock New-GoogleDriveFilePermission {
          return [PSCustomObject]@{
            role = "reader"
            type = "anyone"
          }
        }

        Mock Add-GoogleDriveFile {
          # Extract the filename parameter properly
          $fileName = if ($FileName) { $FileName } else { "unknown" }
          return [PSCustomObject]@{
            id = "mock-file-id-$fileName"
            name = "$fileName"
            PublicUrl = "https://drive.google.com/uc?id=mock-file-id-$fileName"
          }
        } -Verifiable

        Mock Update-MarkdownImages { return $true } -Verifiable
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
      
      # Create the second test image that doesn't exist yet
      Set-Content -Path "TestDrive:\test-image2.png" -Value "fake png content"

      InModuleScope PSBlogger {
        # Override mocks for this specific test
        Mock New-GoogleDriveFilePermission {
          return [PSCustomObject]@{
            role = "reader"
            type = "anyone"
          }
        }

        # Both uploads succeed
        Mock Add-GoogleDriveFile -ParameterFilter { $FileName -eq "test-image1.png" } {
          return [PSCustomObject]@{
            id = "mock-file-id-test-image1.png"
            name = "test-image1.png"
            PublicUrl = "https://drive.google.com/uc?id=mock-file-id-test-image1.png"
          }
        } -Verifiable

        Mock Add-GoogleDriveFile -ParameterFilter { $FileName -eq "test-image2.png" } {
          return [PSCustomObject]@{
            id = "mock-file-id-test-image2.png"
            name = "test-image2.png"
            PublicUrl = "https://drive.google.com/uc?id=mock-file-id-test-image2.png"
          }
        } -Verifiable

        # First permission setting succeeds, second fails
        Mock Set-GoogleDriveFilePermission -ParameterFilter { $FileId -eq "mock-file-id-test-image1.png" } { 
          return [PSCustomObject]@{ id = "permission-id-1" }
        } -Verifiable

        Mock Set-GoogleDriveFilePermission -ParameterFilter { $FileId -eq "mock-file-id-test-image2.png" } { 
          throw [System.Exception]::new("Permission failed")
        } -Verifiable

        Mock Update-MarkdownImages { return $true } -Verifiable
      }

      # act & assert - should not throw
      { 
        $script:result = Publish-MarkdownDriveImages -File $markdownFile 
      } | Should -Not -Throw
      
      # Both images should be processed (upload succeeded), even if permission fails
      # The function continues processing and adds images to result even on permission failure
      $script:result.Count | Should -Be 2
    }
  }

  Context "Attachments Directory" {

    It "Should find images in specified attachments directory" {
      # arrange
      InModuleScope PSBlogger {
        Mock Find-MarkdownImages -ParameterFilter { $AttachmentsDirectory -eq "TestDrive:\attachments" } {
          return @()
        } -Verifiable
      }

      # act
      Publish-MarkdownDriveImages -File $fileWithSingleImage -AttachmentsDirectory "TestDrive:\attachments"

      # assert
      Should -InvokeVerifiable
    }

    It "Should allow no attachments directory to be specified and use default behavior" {
      # arrange
      InModuleScope PSBlogger {
        Mock Find-MarkdownImages -ParameterFilter { $AttachmentsDirectory -eq ""} {
          return @()
        } -Verifiable
      }

      # act
      Publish-MarkdownDriveImages -File $fileWithSingleImage

      # assert
      Should -InvokeVerifiable
    }
  }

  Context "OutFile Parameter" {

    BeforeEach {
      InModuleScope PSBlogger {
        Mock Add-GoogleDriveFile {
          return @{ id = "123"; PublicUrl = "https://drive.google.com/uc?export=view&id=123" }
        }
        Mock Set-GoogleDriveFilePermission { }
        Mock New-GoogleDriveFilePermission { return @{ role = "reader"; type = "anyone" } }
      }
    }

    It "Should write updated markdown to OutFile when specified" {
      # arrange
      $outFile = "TestDrive:\output-with-updated-images.md"

      # act
      Publish-MarkdownDriveImages -File $fileWithSingleImage -OutFile $outFile

      # assert
      Test-Path $outFile | Should -Be $true
      $outFileContent = Get-Content $outFile -Raw
      $outFileContent | Should -Match "https://drive.google.com/uc\?export=view&id=123"
    }

    It "Should preserve original file content when OutFile is specified" {
      # arrange
      $outFile = "TestDrive:\modified-file.md"

      # act
      Publish-MarkdownDriveImages -File $fileWithSingleImage -OutFile $outFile

      # assert
      $originalFileContent = Get-Content $fileWithSingleImage -Raw
      $originalFileContent.TrimEnd() | Should -Be $fileWithSingleImageMarkdown.TrimEnd()
      $originalFileContent | Should -Not -Match "https://drive.google.com"
    }

    It "Should always create OutFile parameter even when no images are found" {
      # arrange
      $markdownFile = "TestDrive:\no-images.md"
      $outFile = "TestDrive:\no-images-output.md"
      $markdownContent = "# Test Post`n`nThis post has no images."
      Set-MarkdownFile $markdownFile $markdownContent

      # act
      $result = Publish-MarkdownDriveImages -File $markdownFile -OutFile $outFile

      # assert
      $result | Should -Be @()
      Test-Path $outFile | Should -Be $true
    }

    It "Should handle invalid OutFile path gracefully" {
      # arrange
      $invalidOutFile = "InvalidDrive:\nonexistent\path\output.md"

      InModuleScope PSBlogger {
        Mock Add-GoogleDriveFile {
          return @{ id = "123"; PublicUrl = "https://drive.google.com/uc?export=view&id=123" }
        }
        Mock Set-GoogleDriveFilePermission { }
        Mock New-GoogleDriveFilePermission { return @{ role = "reader"; type = "anyone" } }
      }

      # act & assert
      { Publish-MarkdownDriveImages -File $fileWithSingleImage -OutFile $invalidOutFile } | Should -Throw
    }
  }
}
