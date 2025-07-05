# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains a PowerShell conversion project for a Fallout 4 modding tool. The original GeneratePrevisibines.bat automates the generation of precombined meshes and visibility data (previsbines) using Creation Kit, xEdit, and Archive tools.

## Development Commands

### PowerShell Module Development
```powershell
# Import module for testing (once created)
Import-Module ./GeneratePrevisibines.psd1 -Force

# Run Pester tests (once implemented)
Invoke-Pester ./Tests/

# Check script analysis
Invoke-ScriptAnalyzer -Path . -Recurse
```

### Testing the Original Batch Script
```batch
# Run with default settings
GeneratePrevisibines.bat

# Run with specific parameters
GeneratePrevisibines.bat -clean -bsarch -FO4:C:\Games\Fallout4 MyPatch.esp
```

## Architecture & Key Components

### Current State
- **GeneratePrevisibines.bat**: 600+ line batch script that orchestrates multiple external tools
- **previsbine-ps-conversion-plan.md**: Detailed conversion plan outlining the PowerShell module structure

### Planned PowerShell Module Structure
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

### External Dependencies
- **xEdit64.exe/FO4Edit64.exe**: Script extender for Fallout 4 plugin manipulation
- **CreationKit.exe**: Bethesda's official modding tool
- **Archive2.exe/BSArch.exe**: Archive creation tools
- **CKPE (CreationKitPlatformExtended)**: Creation Kit enhancement

### Key Workflows
1. **Precombine Generation**: Uses Creation Kit to generate optimized mesh data
2. **Plugin Merging**: Uses xEdit scripts to merge ESP files
3. **Archive Creation**: Packages files into BA2 archives
4. **Previs Generation**: Creates visibility data for performance optimization

## Development Guidelines

### Registry Access
The tool reads from Windows registry to locate Fallout 4 installation:
- `HKLM:\SOFTWARE\Wow6432Node\Bethesda Softworks\Fallout4`
- `HKCR\FO4Script\DefaultIcon`

### Error Handling Patterns
- Check for required tools before execution
- Validate directory states (empty/exists)
- Parse Creation Kit logs for specific error patterns
- Handle MO2 (Mod Organizer 2) file virtualization

### PowerShell Conversion Considerations
- Replace batch CHOICE prompts with Read-Host or menu systems
- Convert ERRORLEVEL checks to try-catch blocks
- Use Test-Path instead of IF EXIST
- Implement proper parameter validation with ValidateSet attributes
- Support -WhatIf and -Confirm for safety

### Testing Requirements
- Must test with actual Fallout 4 installation
- Requires Creation Kit and xEdit tools
- Test all build modes: clean, filtered, xbox
- Verify MO2 compatibility
- Test error recovery scenarios
