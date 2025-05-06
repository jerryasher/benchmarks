<#
.SYNOPSIS
    Cleans up downloaded and installed benchmark tools.

.DESCRIPTION
    This script reads the configuration from config.json and removes
    downloaded and installed files for all enabled benchmark tools.

.NOTES
    File Name      : tool-cleanup.ps1
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
    [string[]]$Tools,
    
    [Parameter(Mandatory=$false)]
    [switch]$DownloadsOnly,
    
    [Parameter(Mandatory=$false)]
    [switch]$InstallsOnly
)

# Load configuration
try {
    $Config = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
    Write-Host "Configuration loaded from $ConfigFile"
} catch {
    Write-Error "Failed to load configuration from $ConfigFile: $_"
    exit 1
}

# Function to remove downloaded files for a tool
function Remove-Downloads {
    param(
        [string]$ToolName
    )
    
    $DownloadInfoPath = Join-Path -Path $DownloadDir -ChildPath "$ToolName-download-info.json"
    
    if (Test-Path -Path $DownloadInfoPath) {
        try {
            $DownloadInfo = Get-Content -Path $DownloadInfoPath -Raw | ConvertFrom-Json
            $DownloadPath = $DownloadInfo.download_path
            
            if (Test-Path -Path $DownloadPath) {
                Remove-Item -Path $DownloadPath -Force
                Write-Host "Removed download file: $DownloadPath" -ForegroundColor Green
            }
            
            Remove-Item -Path $DownloadInfoPath -Force
            Write-Host "Removed download info: $DownloadInfoPath" -ForegroundColor Green
            
            return $true
        } catch {
            Write-Error "Failed to process download info for $ToolName`: $_"
            return $false
        }
    } else {
        Write-Host "No download info found for $ToolName" -ForegroundColor Yellow
        return $false
    }
}

# Function to uninstall a tool
function Uninstall-Tool {
    param(
        [string]$ToolName,
        [PSCustomObject]$ToolConfig
    )
    
    # Check if an uninstall command is specified
    if ($ToolConfig.install.uninstall_command) {
        try {
            $Command = $ToolConfig.install.uninstall_command
            
            # Replace placeholders in the command
            $Command = $Command.Replace("{install_dir}", $ToolConfig.install.install_dir)
            
            Write-Host "Executing uninstall command: $Command"
            
            # Execute the command
            Invoke-Expression $Command
            
            Write-Host "Uninstall command executed" -ForegroundColor Green
        } catch {
            Write-Error "Failed to execute uninstall command: $_"
        }
    }
    
    # Remove the installation directory if it exists
    $InstallDir = $ToolConfig.install.install_dir
    if (Test-Path -Path $InstallDir) {
        try {
            Remove-Item -Path $InstallDir -Recurse -Force
            Write-Host "Removed installation directory: $InstallDir" -ForegroundColor Green
            return $true
        } catch {
            Write-Error "Failed to remove installation directory: $_"
            return $false
        }
    } else {
        Write-Host "Installation directory not found: $InstallDir" -ForegroundColor Yellow
        return $false
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

# Clean up each selected tool
foreach ($ToolName in $ToolsToProcess) {
    $ToolConfig = $Config.$ToolName
    Write-Host "`nCleaning up $($ToolConfig.long_name) ($ToolName)..." -ForegroundColor Blue
    
    # Remove downloads if not skipped
    if (-not $InstallsOnly) {
        Remove-Downloads -