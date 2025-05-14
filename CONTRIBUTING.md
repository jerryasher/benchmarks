# Contributing to Windows Benchmark Toolkit

This document outlines the standards and best practices for contributing
to the Windows Benchmark Toolkit project. These guidelines apply to all
contributors, including humans and LLM assistants.

## Writing Guidelines

When modifying files in this project, please follow these guidelines
intended to make commits focused, trackable, and easy to understand in
the project’s Git history.

- **Minimal necessary changes**: Only modify what's required to make
  the files work together correctly.
  
- **Preserve structure and intent**: Keep the original format,
  organization, and purpose of each file.
  
- **Scripting**: Scripts can be written in Powershell 5.1 (the version
    shipped with Windows 11) or Python 3.11.
  
- **Document changes**: When making changes, clearly explain why
  they're needed. Add inline comments for complex logic. Include a
  clear commit message explaining the purpose of each change

## File Formatting Standards

- Lines must be terminated UNIX style with LF, not with CRLF.
  
- All files must have a final linefeed.
  
- UTF-8 will be used throughout.

## Testing Requirements

- Ask if a Pester test or pytest can be written for any new script.
  
- For PowerShell, follow the [Pester](https://pester.dev) testing framework.
  
- For Python, use [pytest](https://pytest.org) for test implementation.

## Documentation Requirements

### PowerShell Scripts

PowerShell scripts should have a header/documentation/help block that 
provides:

- `.SYNOPSIS` - Brief description
- `.DESCRIPTION` - Detailed description
- `.NOTES` - Additional information
- `.PARAMETER` - Description of each parameter
- `.EXAMPLE` - Usage examples

Additionally, all PowerShell scripts should offer `-Help` and `-h` 
arguments which invoke:
```powershell
GetHelp $MyInvocation.MyCommand.Path
```
and then exit.

### Python Scripts

Python scripts should contain header documentation following PEP 257
including:

- Docstrings for modules, functions, classes, and methods
- Command line usage examples
- Support for `-h` and `--help` arguments

## Naming Conventions

### PowerShell

1. **Functions and Cmdlets**: Use Pascal Case with Verb-Noun format
   - Example: `Get-SystemInfo`, `Install-Benchmark`, `Parse-Results`
   - Follow Microsoft's [approved verb list](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands)

2. **Variables**: Use Pascal Case for public/script-scope variables, 
   camelCase for local variables
   - Example: `$BenchmarkResults` (script scope), `$logDirectory` (local)
   - Avoid abbreviations except for very common ones
   - Use plural nouns for arrays or collections

3. **Parameters**: Use Pascal Case
   - Example: `-ToolName`, `-InstallPath`, `-Force`
   - Use singular form even when accepting multiple values
   - Avoid single-letter parameters except for very common usage

4. **Script Files**: Use Pascal Case with same Verb-Noun format as functions
   - Example: `Install-BenchmarkTools.ps1`, `Get-Results.ps1`

5. **Constants**: Use all uppercase with underscores
   - Example: `$SCRIPT_VERSION`, `$MAX_RETRIES`

6. **Private Functions**: Prefix with an underscore
   - Example: `_ParseLogFile`, `_ValidateConfig`

7. **Boolean Variables**: Consider using "Is" or "Has" prefix
   - Example: `$IsInstalled`, `$HasErrors`

### Python

Follow [PEP 8](https://peps.python.org/pep-0008/) standards with these 
specifics:

1. **Functions**: Use snake_case
   - Example: `parse_results()`, `run_benchmark()`

2. **Variables**: Use snake_case
   - Example: `benchmark_results`, `log_directory`

3. **Classes**: Use PascalCase
   - Example: `BenchmarkRunner`, `ResultParser`

4. **Constants**: Use uppercase with underscores
   - Example: `MAX_RETRIES`, `DEFAULT_TIMEOUT`

5. **Modules**: Use short, lowercase names
   - Example: `parser.py`, `benchmark.py`

## Line Wrapping

To ensure readability in terminals, Git diffs, and text editors, wrap
all text-based output (e.g., Markdown, code, JSON, YAML) at 72–80
columns, preferring 72 columns where possible. Break lines at natural
points (e.g., after punctuation, operators, or logical segments) with
consistent indentation (2 or 4 spaces) for continuation lines.

Regardless of these rules, preserve syntax and functionality, that is,
don't break lines in ways that invalidate the syntax of the underlying
document.

+ **Markdown**: Wrap paragraphs, list items, and table cells. For
  tables, split long cell content across multiple rows with empty
  first-column cells. For lists, indent continuation lines to align
  with the first character of the list item’s text (e.g., two spaces
  after a `-` marker).

+ **Documentation**: Wrap prose, comments, or headings to maintain
  readability within 72–80 columns.

+ **Code**: Format code lines (including comments) to fit within 72–80
  columns, breaking long lines sensibly (e.g., after operators or at
  logical breakpoints) while respecting language-specific style guides.

+ **JSON/YAML**: Wrap long strings, arrays, or nested structures to fit
  within 72–80 columns, using indentation and line breaks to maintain
  clarity.

+ **Other Formats**: Apply the same 72–80 column constraint to any
  text-based output, prioritizing readability and compatibility.

- **Exceptions**: Avoid breaking lines when it harms functionality or
    clarity, such as URLs, long strings in code (e.g., Python
    f-strings), or complex expressions where breaking reduces
    readability. In such cases, keep lines under 120 columns if
    possible and document the rationale in a comment.

+ **Verify** that the output renders correctly in 80-column displays
  (e.g., terminals, Emacs, or Git diffs) without unwanted wrapping or
  truncation.

### Examples

**Markdown Table**:

Instead of:

| Name | Description |
|------|-------------|
| Item | This is a very long description that exceeds the 72 column limit |

Wrap to:

| Name | Description                        |
|------|------------------------------------|
| Item | This is a very long description    |
|      | that exceeds the 72 column limit   |

**Markdown List**:

Instead of:

- This is very long list item exceeds the 72-column limit and needs wrapping

Wrap to:

- This is a long list item that
  exceeds the 72-column limit and
  needs wrapping

## Commit and Push Process

1. Ensure your code follows all the guidelines above
2. Include tests for new functionality
3. Update documentation if needed
4. Test all changes locally before submitting
5. Create focused commits with clear messages explaining the purpose
   of each change.
6. If pushing directly to a branch, ensure each commit is focused and
   follows these guidelines to maintain a clear history. If using pull
   requests, follow the standard PR process on GitHub.


## Specific Instructions for LLMs

For LLM coding assistants working on this project:

1. Follow all guidelines as described above
2. When suggesting changes, explain the reasoning behind them
3. When uncertain about a standard, err on the side of consistency with
   existing code
4. Offer alternative approaches when appropriate, explaining trade-offs
5. Note any assumptions made when implementing solutions
