# Windows Benchmark Toolkit

This suite automates the downloading, installation, running, and
parsing of benchmark tools on Windows, enabling both one-off and
long-term performance tracking. It is script-driven, modular, and uses
JSON configuration files to define tool behaviors.

It should work on any Windows machine. The current test system is a
Beelink EQR-6 with Ryzen 9 6900HX and Radeon Graphics.  A simple,
modular benchmarking framework for Windows systems.

## Purpose

This project aims to:

- Track performance across software/hardware changes (e.g., drivers,
  software install, OS updates).  
- Collect reproducible benchmark results in wide CSV format.
- Support modular tools: you can plug in new benchmarks easily.
- Emphasize automation without administrative privileges or bloat.

Originally designed for the Beelink EQr6 (AMD Ryzen 9 6900HX), but
adaptable to any Windows environment with PowerShell and Python.

---

## Setup and Requirements

- Windows 10/11
- PowerShell 5 (no elevation needed)
- Python 3 (currently using [WinPython](https://winpython.github.io/))
- Environment variables:
  - `WINPYROOT` — root of WinPython installation 
       (e.g., `C:\winpy`)
  - `WINPYTHON` — full path to Python executable 
       (e.g., `c:/Winpy/Winpython64-3.12.9.0slim/WPy64-31290/python/`)


---

## Project Directory Structure

```
README.md            # This README.md file, a project readme
run-benchmark.ps1    # Top level script to run the suite
config.json          # the json configuration file definining each benchmark tool
scripts/             # PowerShell and Python scripts
tools/               # Installed benchmark tools
logs/                # Logs from running of each tool
pytorch/             # PyTorch benchmark output and logs
results/             # Processed .log files (.results) and csvs
summary/             # CSVs and human-readable summaries
archive/             # Archived raw logs and processed results files
```

---

## PowerShell Script Overview

| Script                         | Purpose                                                                 |
|--------------------------------|-------------------------------------------------------------------------|
| `benchmark-tool-downloads.ps1` | Downloads benchmark tools listed in `config.json`.                      |
| `benchmark-tool-install.ps1`   | Installs tools or shows manual instructions (e.g., for Cinebench).      |
| `benchmark-tool-cleanup.ps1`   | Deletes downloaded and installed files.                                 |

---

## Benchmark Configuration (config.json)

Defines metadata for each benchmark tool, including how to download, install, and run them.

* `long_name`, `short_name`
* `description`
* `function or category`: benchmark purpose (e.g. CPU, disk, ML)
* `download_url`, `download_instructions`
* `install_dir`, `install_command`, `install instructions`
* `runner`: includes command, log file pattern, requires\_admin
* `parser`: includes method, regex patterns
* `custom_parser`: Python script to use, if any
* `requirements`: informational field containing dependencies
* `enabled`: whether the tool is active

### Supported Fields

| Field            | Description                                                              |
|------------------|--------------------------------------------------------------------------|
| `tool`           | Unique tool name (used in script matching).                             |
| `url`            | HTTP(s) source for download.                                             |
| `destination`    | Path where the file should be stored.                                    |
| `manual_download`| If `true`, will instruct the user to download manually (e.g., Cinebench).|
| `install_command`| Human-readable summary of what installation entails.                     |
| `requirements`   | Dependencies required for the benchmark to function (e.g., Python).      |

---

## Results Format

All benchmark results should be written as **wide CSV** under `benchmarks/results/`.

- Each **row** = one run of a tool.
- Each **column** = one metric or system detail (e.g., CPU, FPS, time).
- Timestamp and tool name included in each row.

---

## Manual Download Requirements

Some tools cannot be downloaded programmatically due to licensing or
authentication (e.g., Cinebench). If download_instructions is a string,
it will be presented to the user.

## Manual Installation Requirements

Some tools may require manual installation

For these, if install instructions is a string, it will be presented
to the user

---

## Adding a New Benchmark Tool

To add a new benchmark:

1. Add a new entry to `config.json`.

---

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

* Steps are separated into separate scripts that strive for
  idempotency
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
