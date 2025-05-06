<#
.SYNOPSIS
    Downloads benchmark tools defined in config.json.

.DESCRIPTION
    This script reads the configuration from config.json and downloads
    all enabled benchmark tools. If a tool requires manual download,
    it provides instructions to the user.

.NOTES
    File Name      : tool-download.ps1
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

Write-Host "ConfigFile: $ConfigFile"
Write-Host "DownloadDir: $DownloadDir"
Write-Host "Force: $Force"
Write-Host "Tools: $Tools"

# Create downloads directory if it doesn't exist
if (-not (Test-Path -Path $DownloadDir)) {
    New-Item -Path $DownloadDir -ItemType Directory | Out-Null
    Write-Host "Created downloads directory: $DownloadDir"
}

# Load configuration
Write-Host "Attempting to load config from: $ConfigFile"
Write-Host "Current directory: $(Get-Location)"
Write-Host "Config file exists: $(Test-Path -Path $ConfigFile)"
try {
    $Config = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
    Write-Host "Configuration loaded from $ConfigFile"
} catch {
    Write-Host "Caught exception: $($_.GetType().FullName)"
    Write-Host "Exception message: $($_.Exception.Message)"
    # Write-Error "Failed to load configuration from ${ConfigFile}: $_"
    Write-Error "Failed to load configuration from $ConfigFile: $($_.Exception.Message)
    exit 1
}

# Function to download a file
function Download-File {
    param(
        [string]$Url,
        [string]$DestinationPath,
        [switch]$Force
    )
    
    if ((Test-Path -Path $DestinationPath) -and -not $Force) {
        Write-Host "File already exists: $DestinationPath (use -Force to overwrite)" -ForegroundColor Yellow
        return $false
    }
    
    try {
        Write-Host "Downloading from $Url to $DestinationPath"
        $ProgressPreference = 'SilentlyContinue'  # Suppress progress bar for faster downloads
        Invoke-WebRequest -Uri $Url -OutFile $DestinationPath
        $ProgressPreference = 'Continue'
        
        if (Test-Path -Path $DestinationPath) {
            Write-Host "Download successful: $DestinationPath" -ForegroundColor Green
            return $true
        } else {
            Write-Error "Download failed: File not found at $DestinationPath"
            return $false
        }
    } catch {
        Write-Error "Failed to download from $Url`: $_"
        return $false
    }
}

# Function to display manual download instructions
function Show-ManualDownloadInstructions {
    param(
        [string]$ToolName,
        [PSCustomObject]$ToolConfig
    )
    
    Write-Host "`n======================================================" -ForegroundColor Cyan
    Write-Host "MANUAL DOWNLOAD REQUIRED for $($ToolConfig.long_name)" -ForegroundColor Cyan
    Write-Host "======================================================" -ForegroundColor Cyan
    
    if ($ToolConfig.download.download_url) {
        Write-Host "Please download manually from: $($ToolConfig.download.download_url)"
    }
    
    if ($ToolConfig.download.download_instructions) {
        Write-Host "`nInstructions:`n$($ToolConfig.download.download_instructions)"
    }
    
    Write-Host "`nAfter downloading, place the file in the appropriate location"
    Write-Host "as specified in the installation instructions."
    Write-Host "======================================================`n" -ForegroundColor Cyan
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

# Download each selected tool
foreach ($ToolName in $ToolsToProcess) {
    $ToolConfig = $Config.$ToolName
    Write-Host "`nProcessing $($ToolConfig.long_name) ($ToolName)..." -ForegroundColor Blue
    
    # Check if tool is enabled (redundant for explicitly specified tools)
    if ($Tools -or $ToolConfig.enabled -eq $true) {
        # Check if manual download is required
        if ($ToolConfig.download.manual_download -eq $true) {
            Show-ManualDownloadInstructions -ToolName $ToolName -ToolConfig $ToolConfig
        } else {
            # Handle automatic download
            if ($ToolConfig.download.download_url) {
                $FileName = [System.IO.Path]::GetFileName($ToolConfig.download.download_url)
                $DownloadPath = Join-Path -Path $DownloadDir -ChildPath "$ToolName-$FileName"
                
                $Downloaded = Download-File -Url $ToolConfig.download.download_url -DestinationPath $DownloadPath -Force:$Force
                
                if ($Downloaded) {
                    # Store download path in a file for later use by the install script
                    $DownloadInfo = @{
                        "tool_name" = $ToolName
                        "download_path" = $DownloadPath
                        "timestamp" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    } | ConvertTo-Json
                    
                    $DownloadInfoPath = Join-Path -Path $DownloadDir -ChildPath "$ToolName-download-info.json"
                    $DownloadInfo | Out-File -FilePath $DownloadInfoPath -Force
                    
                    Write-Host "Download information saved to $DownloadInfoPath" -ForegroundColor Green
                }
            } else {
                Write-Host "No download URL specified for $ToolName, skipping download" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "Tool '$ToolName' is disabled in the configuration, skipping" -ForegroundColor Yellow
    }
}

Write-Host "`nDownload process completed!" -ForegroundColor Green

