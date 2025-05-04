<#
.SYNOPSIS
    Downloads benchmark tool archives defined in benchmarks_config.json.

.DESCRIPTION
    Iterates over the tools defined in benchmarks_config.json and downloads
    any tools that are not already downloaded. If a tool is marked as requiring
    manual installation, the script displays a message and skips it.

.PARAMETER configPath
    Optional path to the benchmark configuration file. Defaults to benchmarks_config.json in the current directory.

.EXAMPLE
    .\benchmark-tool-downloads.ps1
#>

param (
    [string]$configPath = "benchmarks_config.json"
)

# Ensure required paths
if (-not (Test-Path $configPath)) {
    Write-Error "Configuration file '$configPath' not found."
    exit 1
}

# Load configuration
$configJson = Get-Content $configPath -Raw | ConvertFrom-Json
$tools = $configJson.tools

foreach ($toolName in $tools.PSObject.Properties.Name) {
    $tool = $tools.$toolName

    if ($tool.manual_install) {
        Write-Host "`nNOTICE: '$toolName' must be installed manually." -ForegroundColor Yellow
        if ($tool.install_command) {
            Write-Host "Instructions: $($tool.install_command)"
        } elseif ($tool.download_url) {
            Write-Host "Please download from: $($tool.download_url)"
        } else {
            Write-Host "No download URL provided. Check the README for instructions."
        }
        continue
    }

    $downloadPath = $tool.download_path
    $downloadUrl = $tool.download_url

    if (-not $downloadUrl) {
        Write-Warning "No download URL defined for $toolName. Skipping."
        continue
    }

    if (Test-Path $downloadPath) {
        Write-Host "Already downloaded: $toolName ($downloadPath)"
        continue
    }

    $parentDir = Split-Path $downloadPath
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir | Out-Null
    }

    Write-Host "`nDownloading $toolName from $downloadUrl ..."
    try {
        Invoke-WebRequest -Uri $downloadUrl -OutFile $downloadPath -UseBasicParsing
        Write-Host "Downloaded to $downloadPath"
    }
    catch {
        Write-Error "Failed to download $toolName from $downloadUrl"
    }
}
