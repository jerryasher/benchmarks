# Windows Benchmark Toolkit

This suite automates the downloading, installation, running, and
parsing of benchmark tools on Windows, enabling both one-off and
long-term performance tracking. It is script-driven, modular, and uses
JSON configuration files to define tool behaviors.

It should work on any Windows machine. The current test system is a
Beelink EQR-6 with Ryzen 9 6900HX and Radeon Graphics.  A simple,
modular benchmarking framework for Windows systems.

# Guidelines

## Writing Guidelines

When modifying files in this project, please follow these principles:

- **Minimal necessary changes**: Only modify what's required to make
  the files work together correctly.

- **Preserve structure and intent**: Keep the original format,
  organization, and purpose of each file.

- **Document changes**: When making changes, clearly explain why
    they're needed.

- **72 Colums**: Strive to wrap columns in code and markdown files at
    72 columns

- **Scripting**: Scripts can be written in Powershell 5 or Python 3

- UTF-8 will be used throughout

- All files should have a final linefeed

- Ask if a pester test or similar test can be written for the current
  script.

## Purpose

This project aims to:

- Track performance across software/hardware changes (e.g., drivers,
  software install, OS updates).  
- Collect reproducible benchmark results in wide CSV format.
- Support modular tools: you can plug in new benchmarks easily.
- Emphasize automation without administrative privileges or bloat.

Originally designed for the Beelink EQr6 (AMD Ryzen 9 6900HX), but
adaptable to any Windows environment with PowerShell and Python.

# Requirements

- Windows 10/11
- PowerShell 5
- Python 3 (currently using [WinPython](https://winpython.github.io/))
- Environment variables:
  - `WINPYROOT` — root of WinPython installation 
       (e.g., `C:\winpy`)
  - `WINPYTHON` — full path to Python executable 
       (e.g., `c:/Winpy/Winpython64-3.12.9.0slim/WPy64-31290/python/`)


# Specifications

## Project Directory Structure

```
README.md            # This README.md file, a project readme
run-benchmark.ps1    # Top level script to run the suite
config.json          # the json configuration file definining each benchmark tool
scripts/             # PowerShell and Python scripts
tools/               # Installed benchmark tools
tests/               # Pester tests (and any others)
logs/                # Logs from running of each tool
pytorch/             # PyTorch benchmark output and logs
results/             # Processed .log files (.results) and csvs
summary/             # CSVs and human-readable summaries
archive/             # Archived raw logs and processed results files
```

## PowerShell Script Overview

| Script                | Purpose                                                                 |
|-----------------------|-------------------------------------------------------------------------|
| `run-benchmark.ps1`   | Top level script to run the benchmark suite.                            |
| `tool-download.ps1`   | Downloads benchmark tools listed in `config.json`.                      |
| `tool-install.ps1`    | Installs tools or shows manual instructions (e.g., for Cinebench).      |
| `tool-cleanup.ps1`    | Deletes downloaded and installed files.                                 |

## Benchmark Configuration (config.json)

Defines metadata for each benchmark tool, including how to download,
install, and run them. Each tool is defined as a JSON object with the
following structure:

```json
{
  "tool-name": {
    "long_name": "Full Tool Name",
    "short_name": "Brief name",
    "description": "Description of what the tool tests",
    "function": "Category of benchmark (CPU, Disk, etc.)",
    "download": {
      "download_url": "https://example.com/download/url",
      "manual_download": true|false,
      "download_instructions": ""
      },
    "install": {
      "install_dir": "tools/tool-name",
      "install_command": "Command or script to install",
      "manual_install": true|false,
      "install_instructions": "",
      "uninstall_command": "Command or script to uninstall"
    },
    "requirements": "Notes about dependencies",
    "runner": {
      "command": "Command to execute the benchmark",
      "log_file_pattern": "Pattern for naming log files",
      "requires_admin": true|false
    },
    "parser": {
      "method": "regex|script",
      "regex_patterns": {
        "Metric1": "regex pattern with (capture group)",
        "Metric2": "another regex pattern"
      },
      "custom_parser": "parse_script.py"
    },
    "enabled": true|false
  }
}
```

### Key Fields

| Field            | Description                                                              |
|------------------|--------------------------------------------------------------------------|
| `long_name`      | Full name of the benchmark tool                                          |
| `short_name`     | Abbreviation or short name used in reports                               |
| `description`    | Brief description of what the tool measures                              |
| `function`       | Category of benchmark (e.g., CPU, Disk, ML)                              |
| `download_url`   | HTTP(s) source for download                                              |
| `install_dir`    | Path where the tool should be installed                                  |
| `install_command`| Shell command to install the tool or instructions for manual installation|
| `uninstall_command`| Shell command to uninstall the tool or instructions for manual removal |
| `manual_install` | If `true`, will instruct the user to install manually                    |
| `requirements`   | Dependencies required for the benchmark to function                      |
| `runner`         | Object containing command execution details                              |
| `parser`         | Object containing result parsing information                             |
| `enabled`        | Boolean flag indicating if this tool should be used                      |

## Adding a New Benchmark Tool

To add a new benchmark:

1. Add a new entry to `config.json`.

## Download Configuration

Some tools cannot be downloaded programmatically due to licensing or
authentication (e.g., Cinebench) as indicated by `manual_download`. In
these cases the download_instructions will be presented to the user.

### Install Configuration

The `install object` defines how to install/uninstall the benchmark tool

Some tools may require manual installation indicated by the
`manual_install field`. For these, the `install_instructions` will be
presented to the user

### Runner Configuration

The `runner` object defines how to execute the benchmark:

| Field             | Description                                                 |
|-------------------|-------------------------------------------------------------|
| `command`         | Command line to execute the benchmark                       |
| `log_file_pattern`| Pattern for log file names (with `{timestamp}` placeholder) |
| `requires_admin`  | Whether admin privileges are required to run                 |

Each benchmark run's output will be placed in a file named `YYYY-MM-DD
HH-MM_<tool>_<toolversion>.log`

### Process/Parse Configuration

The `parser` object defines how to extract metrics from benchmark's
log file. Output from the process/parse stage will be placed in a file
named `YYYY-MM-DD HH-MM_<tool>_<toolversion>.csv`. This file will be a
wide format CSV.

| Field           | Description                                                 |
|-----------------|-------------------------------------------------------------|
| `method`        | Parsing method: `regex` or `script`                         |
| `regex_patterns`| Dictionary of metric names to regex patterns with capture groups |
| `custom_parser` | Path to Python script for custom parsing (if `method` is `script`) |

#### Results Format

All benchmark results should be written as **wide CSV** under
`benchmarks/results/`.

- Each **row** = one run of a tool.
- Each **column** = one metric or system detail (e.g., CPU, FPS, time).
- Timestamp and tool name included in each row.

## Tests

+ Pester should be installed by
+ Pester tests can be run from the top level directory by

    Invoke-Pester -Path .\tests\Tests.ps1

+ PyTests should be installed by

+ Pytests can be run by

# Currently Supported Benchmarks

* CPU-Z
* Cinebench
* CrystalDiskMark
* Geekbench
* PyTorch (custom benchmark)

# Design Principles

* Steps are separated into separate scripts that strive for
  idempotency
* Execution and parsing are separated
* Raw logs are archived after parsing
* Scripts fail gracefully and verify success
* Future CLI summaries will visualize trends
* Parsers may use regex or custom Python
* Powershell tests can use pester (or similar)
* Python tests can use pytest (or similar)

# Documentation

* Documentation related to usage, functionality or algorithm is
  embedded directly in scripts where possible

* This README should have a major section labled Derived which
  contains locations to collect proposed derived Guidelines,
  Requirements and Specifications if otherwise unsure of where in the
  document to place them

# Derived

## Guidelines
## Requirements
## Specifications
