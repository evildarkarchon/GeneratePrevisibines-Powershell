# GitHub Copilot Instructions

This file provides guidance to GitHub Copilot when working with code in this repository.

## Project Overview

This repository contains a PowerShell conversion project for a Fallout 4 modding tool. The original `GeneratePrevisibines.bat` automates the generation of precombined meshes and visibility data (previsbines) using Creation Kit, xEdit, and Archive tools.

## Current State

- **GeneratePrevisibines.bat**: 600+ line batch script that orchestrates multiple external tools
- **previsbine-ps-conversion-plan.md**: Detailed conversion plan outlining the PowerShell module structure
- **Status**: In development - converting from batch to PowerShell module

## Target PowerShell Module Structure

```
GeneratePrevisibines/
├── GeneratePrevisibines.psd1  # Module manifest
├── GeneratePrevisibines.psm1  # Main module
├── Public/
│   └── New-Previsbine.ps1     # Main cmdlet
├── Private/
│   ├── Get-ModToolPaths.ps1   # Registry/path detection
│   ├── Test-Prerequisites.ps1  # Validation functions
│   └── Write-LogMessage.ps1    # Logging functions
├── Classes/
│   └── PrevisbineConfig.ps1   # Configuration class
└── Tests/
    └── GeneratePrevisibines.Tests.ps1
```

## External Dependencies

- **xEdit64.exe/FO4Edit64.exe**: Script extender for Fallout 4 plugin manipulation
- **CreationKit.exe**: Bethesda's official modding tool
- **Archive2.exe/BSArch.exe**: Archive creation tools
- **CKPE (CreationKitPlatformExtended)**: Creation Kit enhancement

## PowerShell Development Guidelines

### Parameter Design
- Use `[CmdletBinding()]` for all advanced functions
- Implement proper parameter validation with `ValidateSet` attributes
- Support `-WhatIf` and `-Confirm` for destructive operations
- Follow PowerShell naming conventions (e.g., `New-Previsbine`)

### Registry Access Patterns
```powershell
# Fallout 4 installation detection
Get-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Bethesda Softworks\Fallout4"
Get-ItemProperty -Path "HKCR:\FO4Script\DefaultIcon"
```

### Error Handling
- Use `try-catch` blocks instead of batch `ERRORLEVEL` checks
- Implement custom error types for specific failure scenarios
- Parse Creation Kit logs for specific error patterns
- Handle MO2 (Mod Organizer 2) file virtualization

### File Operations
- Use `Test-Path` instead of batch `IF EXIST`
- Implement proper path validation with `Resolve-Path`
- Handle long paths and special characters
- Support both absolute and relative paths

### External Tool Integration
- Wrap external tool calls in functions with proper error handling
- Monitor process completion and exit codes
- Parse tool-specific log files for errors
- Handle tool-specific quirks (e.g., Creation Kit's native logging)

### User Interface
- Convert batch `CHOICE` prompts to `Read-Host` or menu systems
- Implement progress reporting with `Write-Progress`
- Use colored output for status messages
- Support both interactive and non-interactive modes

## Key Workflows

1. **Precombine Generation**: Uses Creation Kit to generate optimized mesh data
2. **Plugin Merging**: Uses xEdit scripts to merge ESP files
3. **Archive Creation**: Packages files into BA2 archives
4. **Previs Generation**: Creates visibility data for performance optimization

## Testing Requirements

- Unit tests using Pester framework
- Integration tests with actual Fallout 4 installation
- Test all build modes: clean, filtered, xbox
- Verify MO2 compatibility
- Test error recovery scenarios
- Validate registry access functions

## Code Quality Standards

- Follow PowerShell best practices and style guide
- Implement comprehensive error handling
- Use approved verbs for function names
- Include comment-based help for all public functions
- Maintain compatibility with PowerShell 5.1 and 7+

## Development Commands

```powershell
# Import module for testing
Import-Module ./GeneratePrevisibines.psd1 -Force

# Run tests
Invoke-Pester ./Tests/

# Code analysis
Invoke-ScriptAnalyzer -Path . -Recurse
```

## Important Notes

- This is a specialized tool for Fallout 4 modding
- Requires specific external tools to function
- Must maintain compatibility with existing workflows
- Registry access is required for path discovery
- Error handling is critical due to complex tool interactions
