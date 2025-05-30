# tests/Tests.ps1
# Requires Pester 5.x
# Run from top-level directory with: Invoke-Pester -Path .\tests\Tests.ps1

Describe "Windows Benchmark Toolkit Scripts" {
    BeforeAll {
        # Ensure we're running from the top-level directory
        $TopLevelDir = Split-Path -Parent $PSScriptRoot  # $PSScriptRoot is tests/
        $ConfigPath = Join-Path -Path $TopLevelDir -ChildPath "config.json"
        $ScriptsDir = Join-Path -Path $TopLevelDir -ChildPath "scripts"

        # Verify config.json exists
        if (-not (Test-Path -Path $ConfigPath)) {
            throw "config.json not found at $ConfigPath. Ensure it exists in the top-level directory."
        }

        # Create temporary config.json in TestDrive
        $ConfigContent = Get-Content -Path $ConfigPath -Raw
        Set-Content -Path "TestDrive:\config.json" -Value $ConfigContent

        # Define test directories
        $DownloadDir = "TestDrive:\downloads"
        $ToolsDir = "TestDrive:\tools"

        # Mock Write-Host to capture output
        Mock Write-Host { }

        # Mock Write-Error to capture errors
        Mock Write-Error { }

        # Mock Write-Warning to capture warnings
        Mock Write-Warning { }

        # Mock filesystem commands
        Mock Test-Path { $true } -ParameterFilter { $Path -like "*downloads*" }
        Mock New-Item { } -ParameterFilter { $ItemType -eq "Directory" }
        Mock Remove-Item { }
        Mock Get-ChildItem { @() }

        # Mock JSON loading
        Mock Get-Content { $ConfigContent } -ParameterFilter { $Path -like "*config.json" }
        Mock ConvertFrom-Json { ConvertFrom-Json $ConfigContent }

        # Mock network and execution commands
        Mock Invoke-WebRequest { } -ParameterFilter { $Uri -like "https*" }
        Mock Invoke-Expression { }
        Mock Expand-Archive { }
        Mock Start-Process { }

        # Mock Read-Host for manual download prompts
        Mock Read-Host { "TestDrive:\downloads\$($args[0]).zip" }
    }

    Describe "tool-download.ps1" {
        BeforeEach {
            # Reset mocks
            Mock Test-Path { $true } -ParameterFilter { $Path -like "*downloads*" }
            Mock New-Item { } -ParameterFilter { $ItemType -eq "Directory" }
            Mock Out-File { }
        }

        Context "When downloading all enabled tools" {
            It "Downloads tools with valid URLs and creates download-info.json" {
                Mock Invoke-WebRequest { }
                Mock Out-File { } -ParameterFilter { $FilePath -like "*download-info.json" }

                & "$ScriptsDir\tool-download.ps1" -ConfigFile "TestDrive:\config.json" -DownloadDir $DownloadDir

                Assert-MockCalled Invoke-WebRequest -Times 3 -Exactly # cpu-z, crystaldiskmark, geekbench
                Assert-MockCalled Out-File -Times 5 -Exactly # download-info.json for cpu-z, crystaldiskmark, geekbench, cinebench, pytorch
                Assert-MockCalled Write-Host -ParameterFilter { $Object -like "*Download successful*" }
            }

            It "Displays consolidated manual download instructions for Cinebench and PyTorch" {
                Mock Read-Host { "TestDrive:\downloads\cinebench.zip" } -ParameterFilter { $args[0] -eq "cinebench" }
                Mock Read-Host { "TestDrive:\downloads\pytorch.zip" } -ParameterFilter { $args[0] -eq "pytorch" }

                & "$ScriptsDir\tool-download.ps1" -ConfigFile "TestDrive:\config.json" -DownloadDir $DownloadDir

                Assert-MockCalled Write-Host -ParameterFilter { $Object -like "*MANUAL DOWNLOADS REQUIRED*" }
                Assert-MockCalled Write-Host -ParameterFilter { $Object -like "*Tool: Cinebench R23 (cinebench)*" }
                Assert-MockCalled Write-Host -ParameterFilter { $Object -like "*Tool: PyTorch Microbenchmark (pytorch)*" }
                Assert-MockCalled Write-Host -ParameterFilter { $Object -like "*Target directory: tools/cinebench*" }
                Assert-MockCalled Write-Host -ParameterFilter { $Object -like "*Target directory: tools/pytorch*" }
                Assert-MockCalled Read-Host -Times 3 -Exactly # Once for pause, once each for cinebench and pytorch
            }

            It "Saves metadata for manual downloads after user input" {
                Mock Read-Host { "TestDrive:\downloads\cinebench.zip" } -ParameterFilter { $args[0] -eq "cinebench" }
                Mock Read-Host { "TestDrive:\downloads\pytorch.zip" } -ParameterFilter { $args[0] -eq "pytorch" }
                Mock Out-File { } -ParameterFilter { $FilePath -like "*cinebench-download-info.json" }
                Mock Out-File { } -ParameterFilter { $FilePath -like "*pytorch-download-info.json" }

                & "$ScriptsDir\tool-download.ps1" -ConfigFile "TestDrive:\config.json" -DownloadDir $DownloadDir

                Assert-MockCalled Out-File -ParameterFilter { $FilePath -like "*cinebench-download-info.json" } -Times 1 -Exactly
                Assert-MockCalled Out-File -ParameterFilter { $FilePath -like "*pytorch-download-info.json" } -Times 1 -Exactly
                Assert-MockCalled Write-Host -ParameterFilter { $Object -like "*Download information saved to *cinebench-download-info.json*" }
                Assert-MockCalled Write-Host -ParameterFilter { $Object -like "*Download information saved to *pytorch-download-info.json*" }
            }

            It "Warns for invalid manual download file paths" {
                Mock Read-Host { "TestDrive:\downloads\invalid.zip" } -ParameterFilter { $args[0] -eq "cinebench" }
                Mock Test-Path { $false } -ParameterFilter { $Path -like "*invalid.zip" }

                & "$ScriptsDir\tool-download.ps1" -ConfigFile "TestDrive:\config.json" -DownloadDir $DownloadDir

                Assert-MockCalled Write-Warning -ParameterFilter { $Message -like "*File not found at *invalid.zip*" }
            }
        }

        Context "When downloading a specific tool" {
            It "Downloads only the specified tool (cpu-z)" {
                Mock Invoke-WebRequest { }
                Mock Out-File { } -ParameterFilter { $FilePath -like "*cpu-z-download-info.json" }

                & "$ScriptsDir\tool-download.ps1" -ConfigFile "TestDrive:\config.json" -DownloadDir $DownloadDir -Tools "cpu-z"

                Assert-MockCalled Invoke-WebRequest -Times 1 -Exactly
                Assert-MockCalled Out-File -Times 1 -Exactly
            }

            It "Handles manual download for a specific tool (cinebench)" {
                Mock Read-Host { "TestDrive:\downloads\cinebench.zip" } -ParameterFilter { $args[0] -eq "cinebench" }
                Mock Out-File { } -ParameterFilter { $FilePath -like "*cinebench-download-info.json" }

                & "$ScriptsDir\tool-download.ps1" -ConfigFile "TestDrive:\config.json" -DownloadDir $DownloadDir -Tools "cinebench"

                Assert-MockCalled Write-Host -ParameterFilter { $Object -like "*Tool: Cinebench R23 (cinebench)*" }
                Assert-MockCalled Read-Host -Times 2 -Exactly # Pause and file path
                Assert-MockCalled Out-File -ParameterFilter { $FilePath -like "*cinebench-download-info.json" } -Times 1 -Exactly
            }

            It "Warns for non-existent tool" {
                & "$ScriptsDir\tool-download.ps1" -ConfigFile "TestDrive:\config.json" -DownloadDir $DownloadDir -Tools "invalid-tool"

                Assert-MockCalled Write-Warning -ParameterFilter { $Message -like "*not found in configuration*" }
            }
        }

        Context "When config.json is invalid" {
            It "Exits with error if config.json is missing" {
                Mock Test-Path { $false } -ParameterFilter { $Path -like "*config.json" }
                Mock Get-Content { throw "File not found" }

                { & "$ScriptsDir\tool-download.ps1" -ConfigFile "TestDrive:\config.json" -DownloadDir $DownloadDir } | Should -Throw

                Assert-MockCalled Write-Error -ParameterFilter { $Message -like "*Failed to load configuration*" }
            }
        }
    }

    Describe "print-config.ps1" {
        BeforeEach {
            # Reset mocks
            Mock Test-Path { $true } -ParameterFilter { $Path -like "*config.json" }
            Mock Get-Content { $ConfigContent } -ParameterFilter { $Path -like "*config.json" }
            Mock ConvertFrom-Json { ConvertFrom-Json $ConfigContent }
        }

        Context "When displaying configuration" {
            It "Displays a table with correct tool names and types" {
                & "$ScriptsDir\print-config.ps1" -ConfigFile "TestDrive:\config.json"

                Assert-MockCalled Write-Host -ParameterFilter { $Object -like "*CPU-Z Benchmark*Automatic*Automatic*" }
                Assert-MockCalled Write-Host -ParameterFilter { $Object -like "*Cinebench R23*Manual*Manual*" }
                Assert-MockCalled Write-Host -ParameterFilter { $Object -like "*CrystalDiskMark*Automatic*Automatic*" }
                Assert-MockCalled Write-Host -ParameterFilter { $Object -like "*Geekbench 6*Automatic*Automatic*" }
                Assert-MockCalled Write-Host -ParameterFilter { $Object -like "*PyTorch Microbenchmark*Manual*Manual*" }
                Assert-MockCalled Write-Host -ParameterFilter { $Object -like "*Benchmark Tools Configuration:*" }
            }
        }

        Context "When config.json is invalid" {
            It "Exits with error if config.json is missing" {
                Mock Test-Path { $false } -ParameterFilter { $Path -like "*config.json" }

                { & "$ScriptsDir\print-config.ps1" -ConfigFile "TestDrive:\config.json" } | Should -Throw

                Assert-MockCalled Write-Error -ParameterFilter { $Message -like "*Configuration file not found*" }
            }

            It "Exits with error if config.json is invalid JSON" {
                Mock Get-Content { "invalid json" } -ParameterFilter { $Path -like "*config.json" }
                Mock ConvertFrom-Json { throw "Invalid JSON" }

                { & "$ScriptsDir\print-config.ps1" -ConfigFile "TestDrive:\config.json" } | Should -Throw

                Assert-MockCalled Write-Error -ParameterFilter { $Message -like "*Failed to load configuration*" }
            }
        }
    }

    Describe "tool-install.ps1" {
        BeforeEach {
            # Mock download-info.json existence
            Mock Test-Path { $true } -ParameterFilter { $Path -like "*download-info.json" }
            Mock Get-Content { '{"tool_name":"cpu-z","download_path":"TestDrive:\\downloads\\cpu-z.zip"}' } -ParameterFilter { $Path -like "*download-info.json" }
            Mock ConvertFrom-Json { [PSCustomObject]@{ tool_name = "cpu-z"; download_path = "TestDrive:\downloads\cpu-z.zip" } }
        }

        Context "When installing all enabled tools" {
            It "Installs tools with valid download-info and commands" {
                Mock Test-Path { $true } -ParameterFilter { $Path -like "*tools*" }
                Mock Expand-Archive { }
                Mock Get-ChildItem { @("file1", "file2") } # Simulate non-empty install dir

                & "$ScriptsDir\tool-install.ps1" -ConfigFile "TestDrive:\config.json" -DownloadDir $DownloadDir

                Assert-MockCalled Expand-Archive -Times 2 -Exactly # cpu-z, crystaldiskmark
                Assert-MockCalled Write-Host -ParameterFilter { $Object -like "*Installation successful*" }
            }

            It "Displays manual install instructions for Cinebench and PyTorch" {
                & "$ScriptsDir\tool-install.ps1" -ConfigFile "TestDrive:\config.json" -DownloadDir $DownloadDir

                Assert-MockCalled Write-Host -ParameterFilter { $Object -like "*MANUAL INSTALLATION REQUIRED for Cinebench*" }
                Assert-MockCalled Write-Host -ParameterFilter { $Object -like "*MANUAL INSTALLATION REQUIRED for PyTorch*" }
            }
        }

        Context "When installing a specific tool" {
            It "Installs only the specified tool (geekbench)" {
                Mock Start-Process { }
                Mock Get-ChildItem { @("file1") }

                & "$ScriptsDir\tool-install.ps1" -ConfigFile "TestDrive:\config.json" -DownloadDir $DownloadDir -Tools "geekbench"

                Assert-MockCalled Start-Process -Times 1 -Exactly
                Assert-MockCalled Write-Host -ParameterFilter { $Object -like "*Installation successful*" }
            }
        }

        Context "When download-info.json is missing" {
            It "Warns if download-info.json is missing for non-manual install" {
                Mock Test-Path { $false } -ParameterFilter { $Path -like "*cpu-z-download-info.json" }

                & "$ScriptsDir\tool-install.ps1" -ConfigFile "TestDrive:\config.json" -DownloadDir $DownloadDir -Tools "cpu-z"

                Assert-MockCalled Write-Warning -ParameterFilter { $Message -like "*Run tool-download.ps1 first*" }
            }
        }
    }

    Describe "tool-cleanup.ps1" {
        BeforeEach {
            # Mock download-info.json and install dir existence
            Mock Test-Path { $true } -ParameterFilter { $Path -like "*download-info.json" }
            Mock Test-Path { $true } -ParameterFilter { $Path -like "*tools*" }
            Mock Get-Content { '{"tool_name":"cpu-z","download_path":"TestDrive:\\downloads\\cpu-z.zip"}' } -ParameterFilter { $Path -like "*download-info.json" }
            Mock ConvertFrom-Json { [PSCustomObject]@{ tool_name = "cpu-z"; download_path = "TestDrive:\downloads\cpu-z.zip" } }
        }

        Context "When cleaning up all enabled tools" {
            It "Removes downloads and installation directories" {
                Mock Remove-Item { }
                Mock Invoke-Expression { }

                & "$ScriptsDir\tool-cleanup.ps1" -ConfigFile "TestDrive:\config.json" -DownloadDir $DownloadDir

                Assert-MockCalled Remove-Item -Times 10 -Exactly # Downloads, download-info, and install dirs
                Assert-MockCalled Write-Host -ParameterFilter { $Object -like "*Removed download file*" }
                Assert-MockCalled Write-Host -ParameterFilter { $Object -like "*Removed installation directory*" }
            }

            It "Removes empty download directory" {
                Mock Remove-Item { }
                Mock Get-ChildItem { @() } # Empty download dir

                & "$ScriptsDir\tool-cleanup.ps1" -ConfigFile "TestDrive:\config.json" -DownloadDir $DownloadDir

                Assert-MockCalled Remove-Item -ParameterFilter { $Path -eq $DownloadDir }
                Assert-MockCalled Write-Host -ParameterFilter { $Object -like "*Removed empty download directory*" }
            }
        }

        Context "When cleaning up with -DownloadsOnly" {
            It "Only removes download files and download-info.json" {
                Mock Remove-Item { }

                & "$ScriptsDir\tool-cleanup.ps1" -ConfigFile "TestDrive:\config.json" -DownloadDir $DownloadDir -DownloadsOnly

                Assert-MockCalled Remove-Item -Times 6 -Exactly # Downloads and download-info only
                Assert-MockCalled Write-Host -ParameterFilter { $Object -like "*Removed download file*" }
                Assert-MockCalled Write-Host -ParameterFilter { $Object -notlike "*Removed installation directory*" }
            }
        }

        Context "When files are missing" {
            It "Handles missing download-info.json gracefully" {
                Mock Test-Path { $false } -ParameterFilter { $Path -like "*download-info.json" }

                & "$ScriptsDir\tool-cleanup.ps1" -ConfigFile "TestDrive:\config.json" -DownloadDir $DownloadDir

                Assert-MockCalled Write-Host -ParameterFilter { $Object -like "*No download info found*" }
            }
        }
    }

    AfterAll {
        # Clean up TestDrive
        Remove-Item -Path "TestDrive:\*" -Recurse -Force -ErrorAction SilentlyContinue
    }
}
