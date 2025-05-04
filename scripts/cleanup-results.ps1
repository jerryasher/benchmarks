<#
.SYNOPSIS
    Archives old benchmark log files.

.DESCRIPTION
    Moves benchmark result logs from the "results" directory to the "archive"
    subfolder, renaming or timestamping as needed. Ensures results are rotated
    cleanly before a new benchmarking run.

.USAGE
    Run from PowerShell:
        .\cleanup_and_archive_results.ps1

.NOTES
    Environment variable $BENCHMARKS should be set to the root of the benchmark suite.
#>

$ResultsDir = "C:\beelink\benchmarks\results"
$ArchiveDir = Join-Path $ResultsDir "archive"

# Create archive folder if it doesn't exist
if (-not (Test-Path $ArchiveDir)) {
    New-Item -Path $ArchiveDir -ItemType Directory | Out-Null
}

# Get all .log files under results, excluding the archive folder
$LogFiles = Get-ChildItem -Path $ResultsDir -Recurse -Filter "*.log" | Where-Object {
    $_.FullName -notlike "*\archive\*"
}

foreach ($file in $LogFiles) {
    $dest = Join-Path $ArchiveDir $file.Name
    try {
        Move-Item -Path $file.FullName -Destination $dest -Force
        Write-Host "Moved $($file.Name) to archive."
    } catch {
        Write-Warning "Failed to move $($file.FullName): $_"
    }
}

Write-Host "Cleanup complete."
