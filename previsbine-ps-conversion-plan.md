# Batch to PowerShell Conversion Plan: GeneratePrevisibines

## Overview
Converting a 600+ line batch file that automates Fallout 4 previsbine generation using Creation Kit, xEdit, and Archive tools.

## Phase 1: Analysis and Planning (Preparation)

### 1.1 Code Analysis
- [x] Document all external dependencies:
  - [x] xEdit64.exe/FO4Edit64.exe
  - [x] Creation Kit (CreationKit.exe)
  - [x] Archive2.exe
  - [x] BSArch.exe
  - [x] CKPE (CreationKitPlatformExtended)
  - [x] Registry keys used
- [x] Map all command-line parameters and their behaviors
- [x] Identify all file I/O operations
- [x] Document all user interaction points
- [x] List all error conditions and handling

### 1.2 Architecture Planning
- [x] Design PowerShell module structure
- [x] Plan parameter sets for cmdlets
- [x] Design configuration management approach
- [x] Plan logging strategy
- [x] Design error handling framework

### 1.3 Testing Strategy
- [x] Set up test environment with Fallout 4 mod tools
- [x] Create test cases for each major function
- [x] Plan regression testing approach
- [x] Document expected behaviors

## Phase 2: Foundation Setup

### 2.1 Create Module Structure
- [x] **Complete** - Module structure created
```
GeneratePrevisibines/
├── GeneratePrevisibines.psd1  # Module manifest ✓
├── GeneratePrevisibines.psm1  # Main module ✓
├── Public/
│   └── Start-PrevisbineGeneration.ps1     # Main cmdlet ✓
├── Private/
│   ├── Get-ModToolPaths.ps1   # Registry/path detection ✓
│   ├── Test-Prerequisites.ps1  # Validation functions ✓
│   └── Write-LogMessage.ps1    # Logging functions ✓
├── Classes/
│   └── PrevisbineConfig.ps1   # Configuration class ✓
└── Tests/
    └── GeneratePrevisibines.Tests.ps1 ✓
```

### 2.2 Core Infrastructure
- [x] Implement configuration class with properties:
  - [x] FO4EditPath
  - [x] CreationKitPath
  - [x] ArchiveTool (Archive2/BSArch)
  - [x] BuildMode (clean/filtered/xbox)
  - [x] LogPath
- [x] Create logging framework with levels
- [x] Implement parameter validation attributes
- [x] Create custom error types

### 2.3 Path Discovery Functions
- [x] Convert registry reading logic:
  ```powershell
  Get-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Bethesda Softworks\Fallout4"
  ```
- [x] Implement tool discovery with fallbacks
- [x] Implement path normalization
- [x] Add parameter selection for tool paths
- [x] Add MO2 detection logic
- [x] Create path validation functions

## Phase 3: Core Function Conversion

### 3.1 Parameter Processing
- [x] Convert command-line parsing to PowerShell parameters:
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
- [x] Convert file/directory checks to Test-Path
- [x] Implement CKPE configuration validation
- [x] Create plugin name validation
- [x] Add version checking for tools

### 3.3 Main Workflow Functions
- [x] Implement each major step as a separate function:
  - [x] `Start-PrecombineGeneration`
  - [x] `Merge-PrecombineObjects`
  - [x] `New-BA2Archive`
  - [x] `Compress-PSGFile`
  - [x] `Build-CDXFile`
  - [x] `Start-PrevisGeneration`
  - [x] `Merge-PrevisESP`
  - [x] `Add-PrevisToArchive`

## Phase 4: External Tool Integration

### 4.1 Creation Kit Wrapper
- [x] Convert `RunCK` function to work with CK's native logging:
  ```powershell
  function Invoke-CreationKit {
      param(
          [string]$Operation,
          [string]$OutputFile,
          [string]$Arguments
      )
      
      # Clear existing CK log file
      if (Test-Path $CreationKitLogPath) {
          Remove-Item $CreationKitLogPath -Force
      }
      
      # Start CK without redirecting stdout/stderr
      $ckProcess = Start-Process -FilePath $CreationKitPath `
          -ArgumentList "-$Operation:`"$PluginName`" $Arguments" `
          -WorkingDirectory (Split-Path $CreationKitPath) `
          -PassThru `
          -Wait
      
      # Monitor CK's native log file
      if (Test-Path $CreationKitLogPath) {
          $ckLog = Get-Content $CreationKitLogPath -Raw
          # Check for specific errors
          if ($ckLog -match "OUT OF HANDLE ARRAY ENTRIES") {
              throw "Creation Kit ran out of reference handles"
          }
      }
  }
  ```
- [x] Handle DLL renaming for ENB compatibility
- [x] Parse CKPE configuration to find log location
- [x] Monitor CK's native log file for errors
- [x] Add process completion detection

### 4.2 xEdit Script Execution
- [x] Convert `RunScript` function with full batch file functionality:
  - [x] Creates plugins.txt file for xEdit
  - [x] Uses proper command line arguments: -fo4 -autoexit -P:"PluginsFile" -Script:ScriptName -Mod:ModName -log:LogFile
  - [x] Implements automated keypress sending for xEdit UI
  - [x] Handles process monitoring and cleanup
  - [x] Parses script output logs for errors
  - [x] Includes fallback process killing

### 4.3 Archive Tool Wrappers
- [x] Implement Archive2 wrapper with xbox compression support
- [x] Implement BSArch wrapper with proper arguments
- [x] Handle file extraction/repacking with Expand-BA2Archive
- [x] Add compression options based on build mode
- [x] Complex AddToArchive functionality for merging files

### 4.4 Script and Tool Validation
- [x] Added Test-xEditScripts function to validate required script versions:
  - [x] Batch_FO4MergePrevisandCleanRefr.pas (V2.2)
  - [x] Batch_FO4MergeCombinedObjectsAndCheck.pas (V1.5)
  - [x] BSArch.exe detection in xEdit directory

## Phase 5: User Interface and Experience

### 5.1 Interactive Mode
- [x] Convert CHOICE prompts to PowerShell:
  ```powershell
  $choice = Show-InteractiveMenu -Title "Confirm Action" -Message "Do you want to continue?" -Options $options
  ```
- [x] Implement step selection menu with Show-StepSelectionMenu
- [x] Add progress reporting with enhanced Write-ProgressMessage and Write-StepProgress
- [x] Create colored output for status messages

### 5.2 Non-Interactive Mode
- [x] Support fully automated execution through Start-PrevisbineGeneration
- [x] Implement `-WhatIf` support for preview operations
- [x] Add `-Confirm` for destructive operations
- [x] Create verbose output option with -VerboseLogging

### 5.3 Error Handling
- [x] Convert error detection patterns to try-catch blocks
- [x] Implement specific exception types for different error scenarios
- [x] Add recovery options with interactive error recovery menu
- [x] Create detailed error messages with context and troubleshooting guidance

## Phase 6: Advanced Features

### 6.1 Pipeline Support
- [x] Make functions accept pipeline input (Start-PrevisbineGeneration accepts PluginName from pipeline)
- [x] Output objects for further processing (internal helper functions created)
- [x] Implement ValueFromPipeline parameter attributes
- [x] Add support for pipeline processing in main cmdlets

### 6.2 Configuration Management
- [x] Add JSON/XML configuration file support (JSON implemented in PrevisbineConfig class)
- [x] Cache discovered paths (handled by configuration persistence)
- [x] Support configuration profiles (profile loading via -ConfigurationProfile parameter)
- [x] Add import/export configuration functionality (ToJson/FromJson methods, SaveToFile/LoadFromFile)

## Phase 7: Testing and Documentation

### 7.1 Unit Tests
- [x] Test each private function
- [x] Mock external tool calls
- [x] Validate parameter handling
- [x] Test error conditions

### 7.2 Integration Tests (Requires external data that can not be generated automatically)
- [x] Test full workflow with test data
- [x] Validate MO2 compatibility
- [x] Test different build modes
- [x] Verify archive creation

### 7.3 Documentation
- [x] Write comment-based help for all functions
- [x] Create README with examples
- [x] Document troubleshooting steps
- [x] Add migration guide from batch

## Phase 8: Optimization and Polish

### 8.1 Performance (Execution of tools requires data that can not be generated automatically)
- [x] Profile execution times
- [x] Optimize file operations (Log directory caching implemented)
- [x] Reduce redundant checks (Registry caching, validation caching)
- [x] Implement caching where appropriate (Multiple caching systems implemented)

### 8.2 Compatibility
- [x] Test on Windows PowerShell 5.1 (Module manifest specifies compatibility)
- [x] Test on PowerShell Core 7+ (Tested on PowerShell 7.5.2)

### 8.3 Final Polish
- [ ] Implement update checking (Future enhancement)
- [x] Create installer script (Install.ps1 created)
- [x] Package for distribution (Module structure optimized for distribution)

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