<#
.SYNOPSIS
    Installs or extracts benchmark tools based on benchmarks_config.json.

.DESCRIPTION
    This script reads tool definitions from the benchmark config JSON file and performs
    installation steps for each tool. These may include unzipping archives or checking
    for prerequisites.

.PARAMETER configPath
    Optional path to the configuration JSON. Defaults to 'benchmarks_config.json'.

.EXAMPLE
    .\benchmark-tool-install.ps1
#>

param (
    [string]$configPath = "benchmarks_config.json"
)

# Ensure configuration file exists
if (-not (Test-Path $configPath)) {
    Write-Error "Configuration file '$configPath' not found."
    exit 1
}

$configJson = Get-Content $configPath -Raw | ConvertFrom-Json
$tools = $configJson.tools

foreach ($toolName in $tools.PSObject.Properties.Name) {
    $tool = $tools.$toolName

    if ($tool.manual_install) {
        Write-Host "\nNOTICE: '$toolName' requires manual installation." -ForegroundColor Yellow
        if ($tool.install_command) {
            Write-Host "Instructions: $($tool.install_command)"
        }
        continue
    }

    $archive = $tool.download_path
    $dest = $tool.install_path
    $installCommand = $tool.install_command

    if (-not (Test-Path $archive)) {
        Write-Warning "$toolName: Archive not found at '$archive'. Skipping."
        continue
    }

    if ($installCommand) {
        Write-Host "\nRunning install command for $toolName..."
        Invoke-Expression $installCommand
        continue
    }

    if ($archive -like "*.zip") {
        Write-Host "\nExtracting $toolName to '$dest'..."
        if (-not (Test-Path $dest)) {
            New-Item -ItemType Directory -Path $dest | Out-Null
        }
        Expand-Archive -Path $archive -DestinationPath $dest -Force
        Write-Host "$toolName installed to '$dest'"
    } else {
        Write-Warning "$toolName has an unsupported archive format: $archive"
    }
}
