# Batch to PowerShell Conversion Plan: GeneratePrevisibines

## Overview
Converting a 600+ line batch file that automates Fallout 4 previsbine generation using Creation Kit, xEdit, and Archive tools.

## Phase 1: Analysis and Planning (Preparation)

### 1.1 Code Analysis
- [ ] Document all external dependencies:
  - [ ] xEdit64.exe/FO4Edit64.exe
  - [ ] Creation Kit (CreationKit.exe)
  - [ ] Archive2.exe
  - [ ] BSArch.exe
  - [ ] CKPE (CreationKitPlatformExtended)
  - [ ] Registry keys used
- [ ] Map all command-line parameters and their behaviors
- [ ] Identify all file I/O operations
- [ ] Document all user interaction points
- [ ] List all error conditions and handling

### 1.2 Architecture Planning
- [ ] Design PowerShell module structure
- [ ] Plan parameter sets for cmdlets
- [ ] Design configuration management approach
- [ ] Plan logging strategy
- [ ] Design error handling framework

### 1.3 Testing Strategy
- [ ] Set up test environment with Fallout 4 mod tools
- [ ] Create test cases for each major function
- [ ] Plan regression testing approach
- [ ] Document expected behaviors

## Phase 2: Foundation Setup

### 2.1 Create Module Structure
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

### 2.2 Core Infrastructure
- [ ] Implement configuration class with properties:
  - [ ] FO4EditPath
  - [ ] CreationKitPath
  - [ ] ArchiveTool (Archive2/BSArch)
  - [ ] BuildMode (clean/filtered/xbox)
  - [ ] LogPath
- [ ] Create logging framework with levels
- [ ] Implement parameter validation attributes
- [ ] Create custom error types

### 2.3 Path Discovery Functions
- [ ] Convert registry reading logic:
  ```powershell
  Get-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Bethesda Softworks\Fallout4"
  ```
- [ ] Implement tool discovery with fallbacks
- [ ] Add MO2 detection logic
- [ ] Create path validation functions

## Phase 3: Core Function Conversion

### 3.1 Parameter Processing
- [ ] Convert command-line parsing to PowerShell parameters:
  ```powershell
  [CmdletBinding()]
  param(
      [Parameter()]
      [ValidateSet('Clean', 'Filtered', 'Xbox')]
      [string]$BuildMode = 'Clean',
      
      [Parameter()]
      [switch]$UseBSArch,
      
      [Parameter()]
      [string]$FO4Directory,
      
      [Parameter()]
      [string]$PluginName
  )
  ```

### 3.2 Validation Functions
- [ ] Convert file/directory checks to Test-Path
- [ ] Implement CKPE configuration validation
- [ ] Create plugin name validation
- [ ] Add version checking for tools

### 3.3 Main Workflow Functions
- [ ] Implement each major step as a separate function:
  - [ ] `Start-PrecombineGeneration`
  - [ ] `Merge-PrecombineObjects`
  - [ ] `New-BA2Archive`
  - [ ] `Compress-PSGFile`
  - [ ] `Build-CDXFile`
  - [ ] `Start-PrevisGeneration`
  - [ ] `Merge-PrevisESP`
  - [ ] `Add-PrevisToArchive`

## Phase 4: External Tool Integration

### 4.1 Creation Kit Wrapper
- [ ] Convert `RunCK` function:
  ```powershell
  function Invoke-CreationKit {
      param(
          [string]$Operation,
          [string]$OutputFile,
          [string]$Arguments
      )
      # Implementation
  }
  ```
- [ ] Handle DLL renaming for ENB compatibility
- [ ] Implement log parsing for errors
- [ ] Add timeout handling

### 4.2 xEdit Script Execution
- [ ] Convert `RunScript` function
- [ ] Implement automated keypress sending
- [ ] Handle process monitoring
- [ ] Parse script output logs

### 4.3 Archive Tool Wrappers
- [ ] Implement Archive2 wrapper
- [ ] Implement BSArch wrapper
- [ ] Handle file extraction/repacking
- [ ] Add compression options

## Phase 5: User Interface and Experience

### 5.1 Interactive Mode
- [ ] Convert CHOICE prompts to PowerShell:
  ```powershell
  $choice = Read-Host "Plugin already exists. Use it? [Y/N/C]"
  ```
- [ ] Implement step selection menu
- [ ] Add progress reporting
- [ ] Create colored output for status

### 5.2 Non-Interactive Mode
- [ ] Support fully automated execution
- [ ] Implement `-WhatIf` support
- [ ] Add `-Confirm` for destructive operations
- [ ] Create verbose output option

### 5.3 Error Handling
- [ ] Convert error detection patterns
- [ ] Implement try-catch blocks
- [ ] Add recovery options
- [ ] Create detailed error messages

## Phase 6: Advanced Features

### 6.1 Pipeline Support
- [ ] Make functions accept pipeline input
- [ ] Output objects for further processing
- [ ] Support multiple plugin processing

### 6.2 Configuration Management
- [ ] Add JSON/XML configuration file support
- [ ] Implement profile system
- [ ] Cache discovered paths
- [ ] Add preset configurations

### 6.3 Parallel Processing
- [ ] Identify parallelizable operations
- [ ] Implement job-based processing
- [ ] Add throttling controls

## Phase 7: Testing and Documentation

### 7.1 Unit Tests
- [ ] Test each private function
- [ ] Mock external tool calls
- [ ] Validate parameter handling
- [ ] Test error conditions

### 7.2 Integration Tests
- [ ] Test full workflow with test data
- [ ] Validate MO2 compatibility
- [ ] Test different build modes
- [ ] Verify archive creation

### 7.3 Documentation
- [ ] Write comment-based help for all functions
- [ ] Create README with examples
- [ ] Document troubleshooting steps
- [ ] Add migration guide from batch

## Phase 8: Optimization and Polish

### 8.1 Performance
- [ ] Profile execution times
- [ ] Optimize file operations
- [ ] Reduce redundant checks
- [ ] Implement caching where appropriate

### 8.2 Compatibility
- [ ] Test on Windows PowerShell 5.1
- [ ] Test on PowerShell Core 7+
- [ ] Validate with different FO4 versions
- [ ] Test with various mod managers

### 8.3 Final Polish
- [ ] Add telemetry/analytics (optional)
- [ ] Implement update checking
- [ ] Create installer script
- [ ] Package for distribution

## Implementation Priority Order

1. **Critical Path First**
   - Path discovery and validation
   - Basic CK execution wrapper
   - Simple archive creation

2. **Core Workflow**
   - Precombine generation
   - Previs generation
   - Basic merging

3. **Enhanced Features**
   - Build modes
   - Interactive menus
   - Advanced error handling

4. **Nice-to-Have**
   - Parallel processing
   - Configuration files
   - Update checking

## Migration Considerations

### Breaking Changes
- Parameter names will follow PowerShell conventions
- Exit codes will be exceptions instead
- Paths will use PowerShell providers

### Compatibility Layer
- Consider creating wrapper script for backward compatibility
- Map old parameters to new cmdlet parameters
- Provide batch file that calls PowerShell module

### Data Migration
- Preserve existing log file formats
- Maintain plugin naming conventions
- Keep archive structure identical

## Success Criteria

- [ ] All original functionality preserved
- [ ] Improved error messages and handling
- [ ] Faster execution through optimization
- [ ] Better integration with PowerShell ecosystem
- [ ] Comprehensive help and documentation
- [ ] Unit test coverage > 80%
- [ ] Successfully tested with real FO4 mods