# Windows Benchmark Suite - Project Overview

This suite automates the downloading, installation, running, and parsing
of benchmark tools on Windows, enabling both one-off and long-term
performance tracking. It is script-driven, modular, and uses JSON
configuration files to define tool behaviors.

It should work on any Windows machine. The current test system is a
Beelink EQR-6 with Ryzen 9 6900HX and Radeon Graphics.

## Goal

Build a PowerShell- and Python-driven system to benchmark and analyze:

* CPU performance
* Disk performance
* System-wide compute (e.g., Geekbench, PyTorch)

## Requirements

* Windows 11
* PowerShell 5 (default on Windows 11)
* WinPython Slim, installed at `$WINPYROOT`
* Python executable path stored in `$WINPYTHON`

## Directory Structure

All paths are relative to the root `benchmarks/` directory:

```
README.md            # This README.md file, a project readme
archive/             # Archived raw logs and processed results files
configs/             # Config JSONs (benchmark definitions)
logs/                # Logs from running of each tool
pytorch/             # PyTorch benchmark output and logs
results/             # Processed .log files (.results) and csvs
scripts/             # PowerShell and Python scripts
summary/             # CSVs and human-readable summaries
tools/               # Installed benchmark tools
```

### Environment Variables

* `BENCHMARKS` = path to benchmark root directory
* `WINPYROOT` = Root of WinPython installation
* `WINPYTHON` = Full path to Python executable

## Configuration - benchmarks\configs

| File                            | Purpose                                      |
| `benchmarks-config.json`          | Configuration for all tools                  |


## Scripts - benchmarks\scripts

| Script                            | Purpose                                      |
| --------------------------------- | -------------------------------------------- |
| `tool-download.ps1`    | Downloads benchmark tools                    |
| `tool-install.ps1`                    | Run install commands (may require admin rights) |
| `tool-cleanup.ps1`                    | uninstalls tools and deletes them including downloaded zips, exes, etc. |
| `run-benchmarks.ps1`                        | Execute tools, rename logs with timestamps      |
| `run-benchmarks-pytorch.py`            | Custom PyTorch benchmarking script           |
| `process-benchmarks-pytorch.py`                | Parses PyTorch benchmark output into metrics |
| `cleanup-results.ps1` | Cleanup and archiving of results             |

## Scripts To Write

| Script                                      | Purpose                                         |
| ------------------------------------------- | ----------------------------------------------- |
| `process-benchmarks.ps1` | Parse `.log` outputs to wide-format CSV         |
| `analyze-benchmarks.ps1` | Analyze trends |

Scripts include CLI usage samples, clear structure, and user pauses
between phases. All scripts except cleanup scripts are safe to rerun (idempotent).

## Python Notes

* WinPython "slim" is installed at `$WINPYROOT`. It includes many useful
  packages but you must install PyTorch explicitly.
* Scripts assume Python is available via `$WINPYTHON`.

## Script Conventions

Each PowerShell or Python script should:

* Begin with a comment block describing purpose and CLI usage
* Python scripts should include a shebang (even on Windows, for documentation)
* Use logical phases: download, install, run, parse, cleanup
* Be idempotent (safe to re-run without reinitialization)
* Wrap lines and comments at 72 characters where practical
* Named using hyphens and not underscores

## Adding New Tools

To add a new benchmark tool:

1. Add an entry to `configs/benchmarks-config.json`
2. Include download URL, install command, run command, and parser info
3. Mark the tool as `"enabled": true`
4. Re-run the scripts—no core code changes required

## Tool Configuration

Each entry in `benchmarks-config.json` contains:

* `long_name`, `short_name`, `description`
* `function`: benchmark purpose (e.g. CPU, disk, ML)
* `download_url`, `install_dir`, `install_command`
* `runner`: includes command, log file pattern, requires\_admin
* `parser`: includes method, regex patterns
* `custom_parser`: Python script to use, if any
* `requirements`: informational field for user to check
* `enabled`: whether the tool is active

## Supported Benchmarks

* CPU-Z
* Cinebench
* CrystalDiskMark
* Geekbench
* PyTorch (custom benchmark)

## Output Format

* **Log naming**: `YYYY-MM-DD HH-MM_tool_version.log`
* **CSV format**: Wide format

  * One row per benchmark run
  * One column per metric
  * Timestamp columns included

## Design Principles

* Execution and parsing are separated
* Raw logs are archived after parsing
* Scripts fail gracefully and verify success
* Future CLI summaries will visualize trends
* Parsers may use regex or custom Python

## Documentation Guidelines

* README and script comments should wrap at 72 columns
* Documentation is embedded directly in scripts where possible
* Guidelines, Requirements, Derived Requirements, Dependencies
  should be collected in the README under sections
  Guidelines, Requirements, Derived Requirements, Dependencies

---

## TODO

* Expand PyTorch benchmark support and automation
* Implement trend visualization and summaries
