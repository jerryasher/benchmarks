# === Cleanup Script: Archive Benchmark Results ===
# Archives old benchmark result folders and optionally deletes raw data

$root = "C:\beelink\benchmarks\results"
$archive = Join-Path $root "archive"
New-Item -Path $archive -ItemType Directory -Force | Out-Null

# Define threshold (days old)
$daysOld = 3

Get-ChildItem -Path $root -Directory | Where-Object {
    $_.Name -match '^\\d{4}-\\d{2}-\\d{2}$' -and
    ($_.LastWriteTime -lt (Get-Date).AddDays(-$daysOld))
} | ForEach-Object {
    $zipPath = Join-Path $archive ($_.Name + ".zip")
    Write-Host "Archiving $($_.FullName) to $zipPath..." -ForegroundColor Cyan
    Compress-Archive -Path $_.FullName -DestinationPath $zipPath -Force
    if (Test-Path $zipPath) {
        Remove-Item -Path $_.FullName -Recurse -Force
        Write-Host "Archived and removed: $($_.FullName)"
    } else {
        Write-Warning "Failed to archive: $($_.FullName)"
    }
}

Write-Host "Cleanup complete. Archived results older than $daysOld days."
