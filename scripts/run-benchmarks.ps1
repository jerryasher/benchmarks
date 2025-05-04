# --- ENV SETUP ---
$env:BENCHMARKS = "C:\beelink\benchmarks"
$env:RESULTS = Join-Path $env:BENCHMARKS "results\$(Get-Date -Format 'yyyy-MM-dd')"
$logFile = Join-Path $env:RESULTS "benchmark_log.csv"
New-Item -Path $env:RESULTS -ItemType Directory -Force | Out-Null

# Start log
if (-not (Test-Path $logFile)) {
    "Timestamp,Tool,Status,Notes" | Out-File $logFile -Encoding UTF8
}

function Log-Result {
    param (
        [string]$Tool,
        [string]$Status,
        [string]$Notes = ""
    )
    $timestamp = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    "$timestamp,$Tool,$Status,""$Notes""" | Out-File $logFile -Encoding UTF8 -Append
}

Write-Host "`n== Starting table-driven benchmark run for $env:COMPUTERNAME ==" -ForegroundColor Cyan

# --- TOOL DEFINITIONS ---
$tools = @(
    @{
        Name = "CPU-Z"
        Path = { Join-Path $env:BENCHMARKS "tools\cpuz\cpuz_x64.exe" }
        Exists = { Test-Path (&$_.Path) }
        Run = { Start-Process -FilePath (&$_.Path) -ArgumentList "/benchmark" -Wait }
        Notes = "Use GUI to export results. Benchmark is under 'Bench' tab."
    },
    @{
        Name = "GPU-Z"
        Path = { Get-ChildItem -Path "$env:BENCHMARKS\tools\gpuz" -Filter "GPU-Z*.exe" | Select-Object -First 1 }
        Exists = { (&$_.Path) -ne $null }
        Run = { Start-Process -FilePath (&$_.Path).FullName }
        Notes = "Enable sensor logging manually."
    },
    @{
        Name = "HWiNFO64"
        Path = { Join-Path $env:BENCHMARKS "tools\hwinfo64\HWiNFO64.exe" }
        Exists = { Test-Path (&$_.Path) }
        Run = {
            $report = Join-Path $env:RESULTS "hwinfo64_report.csv"
            Start-Process -FilePath (&$_.Path) -ArgumentList "/log /sensors /report=$report"
        }
        Notes = "Use GUI to export to CSV via File > Save Report."
    },
    @{
        Name = "CrystalDiskMark"
        Path = { Get-ChildItem -Path "$env:BENCHMARKS\tools\crystaldiskmark" -Filter "DiskMark*.exe" | Select-Object -First 1 }
        Exists = { (&$_.Path) -ne $null }
        Run = { Start-Process -FilePath (&$_.Path).FullName }
        Notes = "Run tests via GUI. Export to clipboard or screenshot."
    },
    @{
        Name = "Geekbench 6"
        Path = { Join-Path "$env:BENCHMARKS\tools\geekbench6\Geekbench 6.exe" }
        Exists = { Test-Path (&$_.Path) }
        Run = { Start-Process -FilePath (&$_.Path) -ArgumentList "--cpu" -Wait }
        Notes = "Benchmark runs automatically. Copy link or export."
    }
)

# --- RUNNER LOOP ---
foreach ($tool in $tools) {
    Write-Host "`n--- Now running: $($tool.Name) ---" -ForegroundColor Magenta

    try {
        if (&$tool.Exists) {
            Write-Host "Found: $($tool.Name). Pausing for review..." -ForegroundColor Green
            Log-Result -Tool $tool.Name -Status "Found"
            Pause

            Write-Host "Running $($tool.Name)..." -ForegroundColor Cyan
            & $tool.Run

            Write-Host "$($tool.Name) complete. $($tool.Notes)" -ForegroundColor Yellow
            Log-Result -Tool $tool.Name -Status "Completed" -Notes $tool.Notes
            Pause
        } else {
            Write-Warning "$($tool.Name) not found. Skipping."
            Log-Result -Tool $tool.Name -Status "Missing" -Notes "Path not found"
        }
    } catch {
        Write-Warning "Error running $($tool.Name): $_"
        Log-Result -Tool $tool.Name -Status "Error" -Notes $_.Exception.Message
    }
}

Write-Host "`n== Benchmark run complete. Results folder: $env:RESULTS ==" -ForegroundColor Cyan
Write-Host "Log file created at: $logFile"
Pause
