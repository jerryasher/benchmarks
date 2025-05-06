<#
.SYNOPSIS
    Installs benchmark tools defined in config.json.

.DESCRIPTION
    This script reads the configuration from config.json and installs
    all enabled benchmark tools. If a tool requires manual installation,
    it provides instructions to the user.

.NOTES
    File Name      : tool-install.ps1
    Prerequisite   : PowerShell 5.0 or later
    Created        : May 5, 2025
#>

# Script parameters
param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigFile = "config.json",

    [Parameter(Mandatory=$false)]
    [string]$DownloadDir = "downloads",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force,
    
    [Parameter(Mandatory=$false)]
    [string[]]$Tools
)

# Load configuration
try {
    $Config = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
    Write-Host "Configuration loaded from $ConfigFile"
} catch {
    Write-Error "Failed to load configuration from $ConfigFile: $_"
    exit 1
}

# Function to display manual installation instructions
function Show-ManualInstallInstructions {
    param(
        [string]$ToolName,
        [PSCustomObject]$ToolConfig
    )
    
    Write-Host "`n======================================================" -ForegroundColor Cyan
    Write-Host "MANUAL INSTALLATION REQUIRED for $($ToolConfig.long_name)" -ForegroundColor Cyan
    Write-Host "======================================================" -ForegroundColor Cyan
    
    if ($ToolConfig.install.install_instructions) {
        Write-Host "`nInstructions:`n$($ToolConfig.install.install_instructions)"
    }
    
    Write-Host "`nInstall directory should be: $($ToolConfig.install.install_dir)"
    Write-Host "======================================================`n" -ForegroundColor Cyan
}

# Function to install a tool
function Install-Tool {
    param(
        [string]$ToolName,
        [PSCustomObject]$ToolConfig,
        [string]$DownloadPath,
        [switch]$Force
    )
    
    $InstallDir = $ToolConfig.install.install_dir
    
    # Create the installation directory if it doesn't exist
    if (-not (Test-Path -Path $InstallDir)) {
        New-Item -Path $InstallDir -ItemType Directory -Force | Out-Null
        Write-Host "Created installation directory: $InstallDir"
    } elseif ($Force) {
        # Clean existing installation if Force is specified
        Write-Host "Cleaning existing installation in $InstallDir" -ForegroundColor Yellow
        Remove-Item -Path "$InstallDir\*" -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Execute the installation command
    if ($ToolConfig.install.install_command) {
        try {
            $Command = $ToolConfig.install.install_command
            
            # Replace placeholders in the command
            $Command = $Command.Replace("{download_path}", $DownloadPath)
            $Command = $Command.Replace("{install_dir}", $InstallDir)
            
            Write-Host "Executing installation command: $Command"
            
            # Execute the command
            Invoke-Expression $Command
            
            # Verify if the installation directory has content
            if (Test-Path -Path $InstallDir) {
                $Items = Get-ChildItem -Path $InstallDir -ErrorAction SilentlyContinue
                if ($Items.Count -gt 0) {
                    Write-Host "Installation successful" -ForegroundColor Green
                    return $true
                } else {
                    Write-Warning "Installation directory is empty after installation"
                    return $false
                }
            } else {
                Write-Error "Installation directory does not exist after installation"
                return $false
            }
        } catch {
            Write-Error "Installation failed: $_"
            return $false
        }
    } else {
        Write-Host "No installation command specified, assuming files are already in place" -ForegroundColor Yellow
        return $true
    }
}

# Process each tool in the configuration
$ToolsToProcess = @()

# Determine which tools to process
if ($Tools) {
    # Process only specified tools
    foreach ($ToolName in $Tools) {
        if ($Config.PSObject.Properties.Name -contains $ToolName) {
            $ToolsToProcess += $ToolName
        } else {
            Write-Warning "Tool '$ToolName' not found in configuration"
        }
    }
} else {
    # Process all enabled tools
    foreach ($Tool in $Config.PSObject.Properties.Name) {
        $ToolConfig = $Config.$Tool
        if ($ToolConfig.enabled -eq $true) {
            $ToolsToProcess += $Tool
        }
    }
}

# Install each selected tool
foreach ($ToolName in $ToolsToProcess) {
    $ToolConfig = $Config.$ToolName
    Write-Host "`nProcessing $($ToolConfig.long_name) ($ToolName)..." -ForegroundColor Blue
    
    # Check if tool is enabled (redundant for explicitly specified tools)
    if ($Tools -or $ToolConfig.enabled -eq $true) {
        # Check if manual installation is required
        if ($ToolConfig.install.manual_install -eq $true) {
            Show-ManualInstallInstructions -ToolName $ToolName -ToolConfig $ToolConfig
        } else {
            # Get the download path from the download-info.json file
            $DownloadInfoPath = Join-Path -Path $DownloadDir -ChildPath "$ToolName-download-info.json"
            
            if (Test-Path -Path $DownloadInfoPath) {
                try {
                    $DownloadInfo = Get-Content -Path $DownloadInfoPath -Raw | ConvertFrom-Json
                    $DownloadPath = $DownloadInfo.download_path
                    
                    if (Test-Path -Path $DownloadPath) {
                        $Installed = Install-Tool -ToolName $ToolName -ToolConfig $ToolConfig -DownloadPath $DownloadPath -Force:$Force
                        
                        if ($Installed) {
                            Write-Host "$($ToolConfig.long_name) installed successfully" -ForegroundColor Green
                        } else {
                            Write-Error "Failed to install $($ToolConfig.long_name)"
                        }
                    } else {
                        Write-Error "Download file not found: $DownloadPath"
                    }
                } catch {
                    Write-Error "Failed to process download info for $ToolName`: $_"
                }
            } else {
                # If no download info found, try to install without a download path
                if ($ToolConfig.install.install_command -and -not $ToolConfig.install.install_command.Contains("{download_path}")) {
                    $Installed = Install-Tool -ToolName $ToolName -ToolConfig $ToolConfig -DownloadPath "" -Force:$Force
                    
                    if ($Installed) {
                        Write-Host "$($ToolConfig.long_name) installed successfully" -ForegroundColor Green
                    } else {
                        Write-Error "Failed to install $($ToolConfig.long_name)"
                    }
                } else {
                    Write-Warning "No download information found for $ToolName. Run tool-download.ps1 first."
                }
            }
        }
    } else {
        Write-Host "Tool '$ToolName' is disabled in the configuration, skipping" -ForegroundColor Yellow
    }
}

Write-Host "`nInstallation process completed!" -ForegroundColor Green
