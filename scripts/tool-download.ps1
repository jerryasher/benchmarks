<#
.SYNOPSIS
    Downloads benchmark tools defined in config.json.

.DESCRIPTION
    This script reads the configuration from config.json and downloads
    all enabled benchmark tools. If a tool requires manual download,
    it provides instructions to the user.

.PARAMETER ConfigFile
    Specifies the path to the configuration file. Defaults to 'config.json'.

.PARAMETER DownloadDir
    Specifies the directory where tools are downloaded. Defaults to 'downloads'.

.PARAMETER Force
    Overwrites existing files if specified.

.PARAMETER Tools
    Specifies a list of tools to download. If not provided, all enabled tools are processed.

.PARAMETER Help
    Displays this help information. Alias: -h

.EXAMPLE
    .\tool-download.ps1
    Downloads all enabled tools from config.json to the default 'downloads' directory.

.EXAMPLE
    .\tool-download.ps1 -ConfigFile "myconfig.json" -DownloadDir "tools"
    Downloads tools specified in myconfig.json to the 'tools' directory.

.EXAMPLE
    .\tool-download.ps1 -Tools "tool1","tool2" -Force
    Downloads only tool1 and tool2, overwriting existing files if they exist.

.EXAMPLE
    .\tool-download.ps1 -h
    Displays this help information.

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
    [string[]]$Tools,

    [Parameter(Mandatory=$false)]
    [Alias("h")]
    [switch]$Help
)

# Display help if -Help or -h is specified
if ($Help) {
    Get-Help $MyInvocation.MyCommand.Path
    exit 0
}

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
    Write-Error "Failed to load configuration from ${ConfigFile}: $($_.Exception.Message)"
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
$ManualDownloadTools = @()

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

Write-Host "Processing tools: $ToolsToProcess"

# Process automatic downloads first and queue manual downloads
foreach ($ToolName in $ToolsToProcess) {
    $ToolConfig = $Config.$ToolName
    Write-Host "`nProcessing $($ToolConfig.long_name) ($ToolName)..." -ForegroundColor Blue
    
    # Check if tool is enabled (redundant for explicitly specified tools)
    if ($Tools -or $ToolConfig.enabled -eq $true) {
        if ($ToolConfig.download.manual_download -eq $true) {
            # Queue manual download for later processing
            $ManualDownloadTools += [PSCustomObject]@{
                ToolName = $ToolName
                ToolConfig = $ToolConfig
            }
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

# Process manual downloads
if ($ManualDownloadTools.Count -gt 0) {
    Write-Host "`n======================================================" -ForegroundColor Cyan
    Write-Host "MANUAL DOWNLOADS REQUIRED" -ForegroundColor Cyan
    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host "The following tools require manual download. Please follow the instructions below and place the downloaded files in the specified directories.`n"
    
    foreach ($ManualTool in $ManualDownloadTools) {
        $ToolName = $ManualTool.ToolName
        $ToolConfig = $ManualTool.ToolConfig
        Write-Host "Tool: $($ToolConfig.long_name) ($ToolName)" -ForegroundColor Cyan
        if ($ToolConfig.download.download_url) {
            Write-Host "Download from: $($ToolConfig.download.download_url)"
        }
        if ($ToolConfig.download.download_instructions) {
            Write-Host "Instructions:`n$($ToolConfig.download.download_instructions)"
        }
        Write-Host "Target directory: $($ToolConfig.install.install_dir)"
        Write-Host "------------------------------------------------------`n"
    }
    
    Write-Host "Please complete the downloads before continuing."
    Write-Host "Press Enter to proceed and specify the downloaded file paths..."
    $null = Read-Host
    
    # Prompt for file paths and save metadata
    foreach ($ManualTool in $ManualDownloadTools) {
        $ToolName = $ManualTool.ToolName
        $ToolConfig = $ManualTool.ToolConfig
        Write-Host "`nEnter the full path to the downloaded file for $($ToolConfig.long_name) ($ToolName):"
        $DownloadPath = Read-Host
        
        if (Test-Path -Path $DownloadPath) {
            # Store download path in a file for later use by the install script
            $DownloadInfo = @{
                "tool_name" = $ToolName
                "download_path" = $DownloadPath
                "timestamp" = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            } | ConvertTo-Json
            
            $DownloadInfoPath = Join-Path -Path $DownloadDir -ChildPath "$ToolName-download-info.json"
            $DownloadInfo | Out-File -FilePath $DownloadInfoPath -Force
            
            Write-Host "Download information saved to $DownloadInfoPath" -ForegroundColor Green
        } else {
            Write-Warning "File not found at $DownloadPath. Metadata not saved for $ToolName."
        }
    }
}

Write-Host "`nDownload process completed!" -ForegroundColor Green
