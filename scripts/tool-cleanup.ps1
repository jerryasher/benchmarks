<#
.SYNOPSIS
    Cleanup script for benchmark tools.

.DESCRIPTION
    This script reads benchmarks_config.json and removes installed tools
    and optionally their downloaded files.

.USAGE
    Run from the root benchmark directory:
        .\benchmark-tool-cleanup.ps1 [-DeleteZips]

.PARAMETER DeleteZips
    Optional switch to also delete downloaded zip/exe installers.

.NOTES
    Tools marked as manually installed will not be removed.
#>

param(
    [switch]$DeleteZips
)

$ErrorActionPreference = "Stop"
$configPath = "benchmarks_config.json"

if (-Not (Test-Path $configPath)) {
    Write-Error "Cannot find $configPath"
    exit 1
}

$config = Get-Content $configPath -Raw | ConvertFrom-Json

foreach ($toolName in $config.PSObject.Properties.Name) {
    $tool = $config.$toolName
    $toolId = $toolName
    $installDir = $tool.install_dir
    $downloadUrl = $tool.download_url
    $manual = $tool.manual_download -eq $true

    if ($manual) {
        Write-Warning "$toolId: Manual install - skipping removal."
        continue
    }

    if (Test-Path $installDir) {
        try {
            Remove-Item -Recurse -Force -Path $installDir
            Write-Host "$toolId: Removed install directory $installDir"
        } catch {
            Write-Warning "$toolId: Failed to remove $installDir - $_"
        }
    } else {
        Write-Host "$toolId: Install directory not found, skipping."
    }

    if ($DeleteZips -and $downloadUrl) {
        $filename = Split-Path $downloadUrl -Leaf
        $zipPath = Join-Path "downloads" $filename
        if (Test-Path $zipPath) {
            try {
                Remove-Item -Force $zipPath
                Write-Host "$toolId: Removed download $zipPath"
            } catch {
                Write-Warning "$toolId: Could not delete $zipPath - $_"
            }
        } else {
            Write-Host "$toolId: Download file not found, skipping."
        }
    }
}
