# Windows Benchmark Toolkit

A simple, modular benchmarking framework for Windows systems.

## Overview & Purpose

This suite automates the downloading, installation, running, and
parsing of benchmark tools on Windows, enabling both one-off and
long-term performance tracking. It is script-driven, modular, and uses
JSON configuration files to define tool behaviors.

It should work on any Windows machine. The current test system is a
Beelink EQR-6 with Ryzen 9 6900HX and Radeon Graphics. Adaptable to
any Windows environment with PowerShell and Python.

This project aims to:

- Track performance across software/hardware changes (e.g., drivers,
  software install, OS updates)
- Collect reproducible benchmark results in wide CSV format
- Support modular tools: you can plug in new benchmarks easily
- Emphasize automation without administrative privileges or bloat

## Getting Started

### Requirements

- Windows 10/11
- PowerShell 5
- Python 3 (currently [WinPython slim](https://winpython.github.io/))
- Environment variables:
  - `PYTHON` — full path to Python executable
     (e.g., `c:/Winpy/Winpython64-3.12.9.0slim/WPy64-31290/python/`)

### Basic Usage

Assuming user starts in a shell at the root benchmarks directory:

```powershell
# Run the complete benchmark suite
.\run-benchmark.ps1

# Run a specific benchmark
.\run-benchmark.ps1 -Tool "cpu-z"

# Run multiple specific benchmarks
.\run-benchmark.ps1 -Tool "cpu-z","cinebench"

# Download and install tools only
.\scripts\tool-download.ps1
.\scripts\tool-install.ps1

# Print the config
.\scripts\print-config.ps1

# Run the test suite
Invoke-Pester -Path .\tests\Tests.ps1
```

## Project Structure

```
README.md            # This README.md file, a project readme
CONTRIBUTING.md      # Guidelines for contributing to the project
run-benchmark.ps1    # Top level script to run the suite
config.json          # json configuration file defining each benchmark
scripts/             # PowerShell and Python scripts
tools/               # Installed benchmark tools
tests/               # Pester tests (and any others)
logs/                # Logs from running of each tool
pytorch/             # PyTorch benchmark output and logs
results/             # Processed .log files (.results) and csvs
summary/             # CSVs and human-readable summaries
archive/             # Archived raw logs and processed results files
```

## Currently Supported Benchmarks

* **CPU-Z** - CPU benchmark single and multi-thread scores
* **Cinebench** - Renders 3D scenes; benchmark CPU multi and single-core
* **CrystalDiskMark** - Measures disk read/write speeds
* **Geekbench** - Cross-platform benchmark for CPU and GPU compute
* **PyTorch** - Custom benchmark for matrix operations using PyTorch

### Key Scripts

| Script                     | Purpose                                 |
|----------------------------|-----------------------------------------|
| `run-benchmark.ps1`        | Top level script to run the benchmarks  |
| `tool-download.ps1`        | Download benchmarks in `config.json`    |
| `tool-install.ps1`         | Installs tools or shows manual          |
|                            | instructions (e.g., for Cinebench)      |
| `tool-cleanup.ps1`         | Deletes downloaded and installed files  |
| `scripts/print-config.ps1` | Displays benchmark tools config in a    |
|                            | tabular format, showing tool name,      |
|                            | download type (manual/automatic), and   |
|                            | install type (manual/automatic)         |

## Configuration

The `config.json` file defines metadata for each benchmark tool,
including how to download, install, and run them. Each tool is defined
as a JSON object with fields controlling its behavior.

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

| Field             | Description                                         |
|-------------------|-----------------------------------------------------|
| `long_name`       | Full name of the benchmark tool                     |
| `short_name`      | Abbreviation or short name used in reports          |
| `description`     | Brief description of what the tool measures         |
| `function`        | Category of benchmark (e.g., CPU, Disk, ML)         |
| `download_url`    | HTTP(s) source for download                         |
| `manual_download` | If `true`, will instruct user to download manually  |
| `download_inst`   | Download instructions                               |
| `install_dir`     | Path where the tool should be installed             |
| `install_cmd`     | Shell command to install the tool                   |
| `manual_install`  | If `true`, will instruct user to install manually   |
| `install_inst`    | Install instructions                                |
| `uninstall_cmd`   | Shell command to uninstall the tool                 |
| `requirements`    | Dependencies required for the benchmark to function |
| `runner`          | Object containing command execution details         |
| `parser`          | Object containing result parsing information        |
| `enabled`         | Boolean flag indicating if this tool should be used |

### Adding a New Benchmark Tool

To add a new benchmark:

1. Add a new entry to `config.json` following the schema above
2. Place any custom parser scripts in the `scripts/` directory
3. Test the new benchmark independently before adding to the suite

### Download Configuration

Some tools cannot be downloaded programmatically due to licensing or
authentication (e.g., Cinebench) as indicated by `manual_download`. In
these cases the download_inst will be presented to the user. The
benchmark should be downloaded to the install_dir.

### Install Configuration

The `install object` defines how to install/uninstall the benchmark tool

Some tools may require manual installation indicated by the
`manual_install field`. For these, the `install_inst` will be
presented to the user.

Tools are downloaded to the install_dir and then installed (which may
just mean expanded) into that directory.

As much as possible, tools should be installed in a portable manner
not hooking into the windows registry and installed such that deleting
the directory is all that is needed to uninstall them.

### Uninstall Configuration

`uninstall_cmd` is a command to uninstall a tool, usually by removal
of the install directory.

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

### Results Format

All benchmark results should be written as **wide CSV** under
`benchmarks/results/`.

- Each **row** = one run of a tool.
- Each **column** = one metric or system detail (e.g., CPU, FPS, time).
- Timestamp and tool name included in each row.

## Development

### Design Principles

* Steps are separated into separate scripts that each strive for idempotency
* Per tool customization is all specified in the config.json file
  leaving scripts to mostly be loops over the benchmark specified in
  the config file
* Execution and parsing are separated
* Raw logs are archived after parsing
* Scripts fail gracefully and verify success
* Scripts are designed to be idempotent, running them multiple times is fine
* Parsers may use regex or custom Python
* Powershell tests use Pester
* Python tests use pytest
* This README is authoritative and kept up to date and notes
  design decisions, status, and tasks in progress

#### Embedded Documentation

Documentation related to usage, functionality or algorithm is embedded
directly in scripts where possible.

### Testing

Tests are implemented using Pester for PowerShell and pytest for
Python scripts.

To run Pester tests:
```powershell
Invoke-Pester -Path .\tests\Tests.ps1
```

To run Python tests:
```powershell
& $env:WINPYTHON -m pytest .\tests\python_tests\
```

## Troubleshooting

### Common Issues

1. [Placeholder]

### Getting Help

If you encounter issues not covered here, please:
1. Check the existing issues in the Issues section below
2. Look for error messages in the logs/ directory
3. Create a new issue with detailed information about the problem

## TODO

Tasks are placed in three lists: In Progress, Ready,
Waiting/Blocked. Tasks in the Ready list are roughly ordered in terms
of priority. Tasks In Progress should have a status message. Tasks in
Waiting/Blocked should describe what they are waiting on.

### In Progress

### Ready

+ Implement `print-config.ps1`
+ Implement `tool-download.ps1`
+ Implement `tool-install.ps1`
+ Implement `tool-cleanup.ps1`
+ Implement `run-benchmarks.ps1`
+ Implement `cleanup-benchmarks.ps1`
+ Implement `cleanup-results.ps1`
+ Create graphical report visualization
+ Implement summary report generation combining all benchmark results
+ Implement comparison feature between benchmark runs
+ Implement system information collection in benchmark results
+ Create documentation for adding custom parsers
+ Add support for additional benchmark tools (3DMark, PassMark)
+ Add scheduling capability for regular benchmark runs
+ Add error handling for users attempting to run admin-required benchmarks

### Waiting/Blocked


## ISSUES

Each issue has a status:
- [O] - Open, needs investigation
- [I] - Under investigation
- [W] - Workaround available (described)

### Current Issues

### Resolved Issues
