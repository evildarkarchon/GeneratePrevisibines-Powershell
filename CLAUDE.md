# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GeneratePrevisibines-Powershell is a PowerShell module that automates the generation of Fallout 4 precombined meshes and visibility data (previsbines). It's a conversion of a 600+ line batch script into a modern PowerShell module with proper error handling, logging, and PowerShell native features.

## Development Environment

- Windows Subsystem for Linux (WSL) environment with access to Windows executables
- PowerShell 7 installed and available
- Development requires access to Fallout 4 modding tools (Creation Kit, xEdit, Archive tools)

## Key Architecture Decisions

### Module Structure
```
GeneratePrevisibines/
├── GeneratePrevisibines.psd1      # Module manifest
├── GeneratePrevisibines.psm1      # Module loader
├── Classes/
│   └── PrevisbineConfig.ps1       # Central configuration class
├── Public/
│   └── Start-PrevisbineGeneration.ps1  # Main cmdlet (entry point)
├── Private/                       # Internal functions (20+ files)
│   ├── Tool wrappers (Invoke-CreationKit, Invoke-xEditScript)
│   ├── Archive operations (New-BA2Archive, Expand-BA2Archive)
│   ├── Workflow functions (Start-PrecombineGeneration)
│   └── Utilities (Write-LogMessage, Test-Prerequisites)
└── Tests/
    └── GeneratePrevisibines.Tests.ps1  # Pester test suite
```

### External Tool Dependencies
- **Creation Kit**: Bethesda's official modding tool (CreationKit.exe)
- **xEdit/FO4Edit**: Plugin manipulation tool
- **Archive Tools**: Archive2.exe (preferred) or BSArch.exe
- **CKPE**: CreationKitPlatformExtended (optional enhancement)

## Critical Implementation Details

### Tool Path Discovery
The module uses registry-based tool discovery with fallback paths:
```powershell
# Registry paths checked:
"HKLM:\SOFTWARE\WOW6432Node\Bethesda Softworks\Fallout4"
"HKLM:\SOFTWARE\Bethesda Softworks\Fallout4"
```

### Configuration Management
All settings flow through the `PrevisbineConfig` class which:
- Validates all paths and settings
- Manages build modes (Clean, Filtered, Xbox)
- Handles Mod Organizer 2 integration
- Provides centralized configuration for all functions

### Error Handling Pattern
```powershell
try {
    # Operation
} catch {
    Write-LogMessage -Message "Error: $_" -Level Error -Config $Config
    throw "Failed to perform operation: $_"
}
```

## Development Guidelines

### PowerShell Best Practices
- Use approved verbs for function names
- Implement -WhatIf and -Confirm for destructive operations
- Support pipeline input where appropriate
- Use ShouldProcess for user confirmation
- Avoid aliases in scripts
- Use full parameter names

### Function Patterns
```powershell
function Verb-Noun {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [PrevisbineConfig]$Config
    )
    # Implementation
}
```

### Testing Requirements
- All public functions must have Pester tests
- Test coverage for error conditions
- Mock external tool calls in tests
- Validate parameter validation logic

## Testing Commands

```powershell
# Run all tests
Invoke-Pester .\GeneratePrevisibines\Tests\

# Run with verbose output
Invoke-Pester .\GeneratePrevisibines\Tests\ -Verbose

# Import module for testing
Remove-Module GeneratePrevisibines -Force -ErrorAction SilentlyContinue
Import-Module .\GeneratePrevisibines\GeneratePrevisibines.psd1 -Force

# Run code analysis
Invoke-ScriptAnalyzer -Path .\GeneratePrevisibines\ -Recurse

# Test the main cmdlet
Start-PrevisbineGeneration -PluginName "TestMod.esp" -WhatIf
```

## Current Status

### Completed Phases
- Phase 1-4: Module structure, configuration, core functions, external tool integration
- Interactive mode implementation
- Comprehensive error handling and logging
- Tool discovery and validation

### In Progress
- Phase 5: User Interface refinements
- Additional test coverage
- Performance optimizations

### Pending
- Phase 6-8: Advanced features, comprehensive testing, final optimizations
- PowerShell Gallery publishing preparation

## Common Development Tasks

### Adding a New Private Function
1. Create file in `Private/` directory
2. Follow naming convention: `Verb-Noun.ps1`
3. Add appropriate error handling and logging
4. Function will auto-load via module loader

### Modifying Tool Integration
Tool wrapper functions in `Private/` follow a consistent pattern:
- Accept `PrevisbineConfig` parameter
- Use `Start-Process` with proper error handling
- Log all operations
- Return meaningful error messages

### Working with the Configuration Class
```powershell
$config = [PrevisbineConfig]::new()
$config.PluginName = "MyMod.esp"
$config.BuildMode = "Clean"
$config.IsValid()  # Validates all settings
```

## Troubleshooting

### Module Won't Load
```powershell
# Check manifest validity
Test-ModuleManifest .\GeneratePrevisibines\GeneratePrevisibines.psd1

# Import with verbose to see errors
Import-Module .\GeneratePrevisibines\GeneratePrevisibines.psd1 -Force -Verbose
```

### Tool Path Issues
- Check registry entries for Fallout 4 installation
- Verify tools exist in expected locations
- Use `-SkipToolValidation` for testing without tools

### Testing Without External Tools
Many functions support `-SkipToolValidation` parameter for testing without actual tool installations.