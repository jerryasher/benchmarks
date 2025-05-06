<#
.SYNOPSIS
    Runs benchmark tools defined in config.json.

.DESCRIPTION
    This script reads the configuration from config.json and runs
    all enabled benchmark tools, collecting their outputs into log files.

.NOTES
    File Name      : run-benchmark.ps1
    Prerequisite   : PowerShell 5.0 or later
    Created        : May 5, 2025
#>

# Script parameters
param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigFile = "config.json",

    [Parameter(Mandatory=$false)]
    [string]$LogDir = "logs",
    
    [Parameter(Mandatory=$false)]
    [string[]]$Tools,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipParsing
)

# Create logs directory if it doesn't exist
if (-not (Test-Path -Path $LogDir)) {
    New-Item -Path $LogDir -ItemType Directory | Out-Null
    Write-Host "Created logs directory: $LogDir"
}

# Load configuration
try {
    $Config = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
    Write-Host "Configuration loaded from $ConfigFile"
} catch {
    Write-Error "Failed to load configuration from $ConfigFile: $_"
    exit 1
}

# Function to run a benchmark tool
function Run-Benchmark {
    param(
        [string]$ToolName,
        [PSCustomObject]$ToolConfig,
        [string]$LogFile
    )
    
    $Command = $ToolConfig.runner.command
    
    # Replace placeholders in the command
    $Command = $Command.Replace("{install_dir}", $ToolConfig.install.install_dir)
    $Command = $Command.Replace("{log_file}", $LogFile)
    
    # Replace environment variables if present
    $Command = [regex]::Replace($Command, '\{Env:(\w+)\}', {
        param($match)
        $envVar = $match.Groups[1].Value
        return [Environment]::GetEnvironmentVariable($envVar)
    })
    
    try {
        Write-Host "Running benchmark command: $Command"
        
        # Check if admin rights are required
        if ($ToolConfig.runner.requires_admin -eq $true) {
            Write-Host "This benchmark requires administrative privileges" -ForegroundColor Yellow
            
            # Check if running as admin
            $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
            
            if (-not $IsAdmin) {
                Write-Error "This benchmark requires administrative privileges. Please run this script as Administrator."
                return $false
            }
        }
        
        # Execute the command
        $Process = Start-Process -FilePath "powershell.exe" -ArgumentList "-Command `"$Command`"" -NoNewWindow -PassThru -Wait
        
        if ($Process.ExitCode -eq 0) {
            Write-Host "Benchmark completed successfully" -ForegroundColor Green
            
            # Check if log file was created
            if (Test-Path -Path $LogFile) {
                $LogSize = (Get-Item -Path $LogFile).Length
                Write-Host "Log file created: $LogFile ($LogSize bytes)"
                return $true
            } else {
                Write-Warning "Benchmark completed but no log file was created"
                return $false
            }
        } else {
            Write-Error "Benchmark failed with exit code $($Process.ExitCode)"
            return $false
        }
    } catch {
        Write-Error "Failed to run benchmark: $_"
        return $false
    }
}

# Function to parse benchmark results using regex patterns
function Parse-RegexResults {
    param(
        [string]$ToolName,
        [PSCustomObject]$ToolConfig,
        [string]$LogFile,
        [string]$ResultsDir
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH-mm"
    $ResultsFile = Join-Path -Path $ResultsDir -ChildPath "$Timestamp`_$ToolName.csv"
    
    try {
        # Read the log file
        $LogContent = Get-Content -Path $LogFile -Raw
        
        # Create a hashtable to store results
        $Results = @{
            "Timestamp" = $Timestamp
            "Tool" = $ToolName
            "LongName" = $ToolConfig.long_name
        }
        
        # Extract metrics using regex patterns
        foreach ($MetricName in $ToolConfig.parser.regex_patterns.PSObject.Properties.Name) {
            $Pattern = $ToolConfig.parser.regex_patterns.$MetricName
            $Match = [regex]::Match($LogContent, $Pattern)
            
            if ($Match.Success -and $Match.Groups.Count -gt 1) {
                $Value = $Match.Groups[1].Value
                $Results[$MetricName] = $Value
            } else {
                Write-Warning "Could not find pattern for metric '$MetricName' in log file"
                $Results[$MetricName] = "N/A"
            }
        }
        
        # Convert the results to CSV
        $ResultsObject = New-Object PSObject -Property $Results
        $ResultsObject | Export-Csv -Path $ResultsFile -NoTypeInformation
        
        Write-Host "Results parsed and saved to $ResultsFile" -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Failed to parse results: $_"
        return $false
    }
}

# Function to parse benchmark results using a custom script
function Parse-CustomResults {
    param(
        [string]$ToolName,
        [PSCustomObject]$ToolConfig,
        [string]$LogFile,
        [string]$ResultsDir
    )
    
    $CustomParser = $ToolConfig.parser.custom_parser
    $ScriptPath = Join-Path -Path "scripts" -ChildPath $CustomParser
    
    if (Test-Path -Path $ScriptPath) {
        try {
            $Timestamp = Get-Date -Format "yyyy-MM-dd HH-mm"
            $ResultsFile = Join-Path -Path $ResultsDir -ChildPath "$Timestamp`_$ToolName.csv"
            
            # Determine how to run the script based on file extension
            $Extension = [System.IO.Path]::GetExtension($ScriptPath)
            
            $Command = ""
            if ($Extension -eq ".py") {
                # Run Python script
                $PythonPath = [Environment]::GetEnvironmentVariable("WINPYTHON")
                if (-not $PythonPath) {
                    $PythonPath = "python"
                }
                
                $Command = "$PythonPath `"$ScriptPath`" `"$LogFile`" `"$ResultsFile`""
            } elseif ($Extension -eq ".ps1") {
                # Run PowerShell script
                $Command = "& `"$ScriptPath`" -LogFile `"$LogFile`" -ResultsFile `"$ResultsFile`""
            } else {
                Write-Error "Unsupported parser script type: $Extension"
                return $false
            }
            
            Write-Host "Running custom parser: $Command"
            Invoke-Expression $Command
            
            if (Test-Path -Path $ResultsFile) {
                Write-Host "Results parsed and saved to $ResultsFile" -ForegroundColor Green
                return $true
            } else {
                Write-Error "Custom parser did not create results file"
                return $false
            }
        } catch {
            Write-Error "Failed to run custom parser: $_"
            return $false
        }
    } else {
        Write-Error "Custom parser script not found: $ScriptPath"
        return $false
    }
}

# Create results directory if it doesn't exist
$ResultsDir = "results"
if (-not (Test-Path -Path $ResultsDir)) {
    New-Item -Path $ResultsDir -ItemType Directory | Out-Null
    Write-Host "Created results directory: $ResultsDir"
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

# Run each selected tool
foreach ($ToolName in $ToolsToProcess) {
    $ToolConfig = $Config.$ToolName
    Write-Host "`nRunning $($ToolConfig.long_name) ($ToolName)..." -ForegroundColor Blue
    
    # Check if tool is enabled (redundant for explicitly specified tools)
    if ($Tools -or $ToolConfig.enabled -eq $true) {
        # Create a timestamped log file name
        $Timestamp = Get-Date -Format "yyyy-MM-dd HH-mm"
        $LogFilePattern = $ToolConfig.runner.log_file_pattern.Replace("{timestamp}", $Timestamp)
        $LogFile = Join-Path -Path $LogDir -ChildPath $LogFilePattern
        
        # Run the benchmark
        $Success = Run-Benchmark -ToolName $ToolName -ToolConfig $ToolConfig -LogFile $LogFile
        
        if ($Success -and -not $SkipParsing) {
            # Parse the results
            Write-Host "Parsing results for $ToolName..."
            
            if ($ToolConfig.parser.method -eq "regex") {
                Parse-RegexResults -ToolName $ToolName -ToolConfig $ToolConfig -LogFile $LogFile -ResultsDir $ResultsDir
            } elseif ($ToolConfig.parser.method -eq "script") {
                Parse-CustomResults -ToolName $ToolName -ToolConfig $ToolConfig -LogFile $LogFile -ResultsDir $ResultsDir
            } else {
                Write-Warning "Unknown parser method: $($ToolConfig.parser.method)"
            }
        }
    } else {
        Write-Host "Tool '$ToolName' is disabled in the configuration, skipping" -ForegroundColor Yellow
    }
}

Write-Host "`nBenchmark process completed!" -ForegroundColor Green
