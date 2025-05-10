<#
.SYNOPSIS
    Prints the benchmark tools configuration in a tabular format.

.DESCRIPTION
    Reads the configuration from config.json and displays a table listing
    each tool's name, download type (manual or automatic), and install
    type (manual or automatic).

.PARAMETER ConfigFile
    Specifies the path to the configuration file. Defaults to 'config.json'.

.PARAMETER Help
    Displays this help information. Alias: -h

.EXAMPLE
    .\print-config.ps1
    Displays the configuration table using the default config.json.

.EXAMPLE
    .\print-config.ps1 -ConfigFile "myconfig.json"
    Displays the configuration table from myconfig.json.

.EXAMPLE
    .\print-config.ps1 -h
    Displays this help information.

.NOTES
    File Name      : print-config.ps1
    Prerequisite   : PowerShell 5.0 or later
    Created        : May 8, 2025
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigFile = "config.json",

    [Parameter(Mandatory=$false)]
    [Alias("h")]
    [switch]$Help
)

# Display help if -Help or -h is specified
if ($Help) {
    Get-Help $MyInvocation.MyCommand.Path
    exit 0
}

# Load configuration
Write-Host "Loading configuration from: $ConfigFile"
if (-not (Test-Path -Path $ConfigFile)) {
    Write-Error "Configuration file not found: $ConfigFile"
    exit 1
}
try {
    $Config = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
    Write-Host "Configuration loaded successfully"
} catch {
    Write-Error "Failed to load configuration: $($_.Exception.Message)"
    exit 1
}

# Prepare table data
$TableData = @()
foreach ($ToolName in $Config.PSObject.Properties.Name) {
    $ToolConfig = $Config.$ToolName
    $DownloadType = if ($ToolConfig.download.manual_download) { "Manual" } else { "Automatic" }
    $InstallType = if ($ToolConfig.install.manual_install) { "Manual" } else { "Automatic" }
    $TableData += [PSCustomObject]@{
        "Tool Name" = $ToolConfig.long_name
        "Download"  = $DownloadType
        "Install"   = $InstallType
    }
}

# Display table
Write-Host "`nBenchmark Tools Configuration:"
$TableData | Format-Table -AutoSize | Out-String | Write-Host
