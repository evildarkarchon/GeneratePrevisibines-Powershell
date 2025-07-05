# GeneratePrevisibines PowerShell Module

A PowerShell module for generating Fallout 4 precombines and previs data using Creation Kit, xEdit, and Archive tools. This module provides a modern, PowerShell-native replacement for the original batch script functionality.

## Features

- **Automated Tool Discovery**: Automatically detects FO4Edit, Creation Kit, and Archive tools through registry and common locations
- **Multiple Build Modes**: Support for Clean, Filtered, and Xbox build modes
- **Mod Organizer 2 Integration**: Built-in support for MO2 workflows
- **Comprehensive Logging**: Detailed logging with multiple levels and file output
- **Validation Framework**: Thorough prerequisite validation before processing
- **PowerShell Native**: Full support for PowerShell features like `-WhatIf`, `-Confirm`, and pipeline operations

## Requirements

### External Tools
- **Creation Kit** (CreationKit.exe) - Bethesda's official modding tool
- **xEdit/FO4Edit** - Script extender for Fallout 4 plugin manipulation
- **Archive Tool** - Archive2.exe (from Creation Kit) or BSArch.exe
- **CKPE** - CreationKitPlatformExtended for enhanced Creation Kit functionality

### PowerShell
- PowerShell 5.1 or later
- Windows operating system (required for external tools)

## Installation

1. Clone or download the module to your PowerShell modules directory
2. Import the module:
   ```powershell
   Import-Module .\GeneratePrevisibines\GeneratePrevisibines.psd1
   ```

## Usage

### Basic Usage

Generate precombines and previs for a plugin:
```powershell
Start-PrevisbineGeneration -PluginName "MyMod.esp"
```

### Advanced Usage

```powershell
# Use filtered build mode with BSArch
Start-PrevisbineGeneration -PluginName "MyMod.esp" -BuildMode Filtered -UseBSArch

# Use with Mod Organizer 2
Start-PrevisbineGeneration -PluginName "MyMod.esp" -UseMO2 -MO2Profile "Default"

# Specify custom paths and enable verbose logging
Start-PrevisbineGeneration -PluginName "MyMod.esp" -FO4Directory "C:\Games\Fallout 4" -VerboseLogging

# Test what would be done without actually doing it
Start-PrevisbineGeneration -PluginName "MyMod.esp" -WhatIf
```

### Configuration

The module uses a configuration class to manage settings:

```powershell
# Create and configure manually
$config = [PrevisbineConfig]::new()
$config.PluginName = "MyMod.esp"
$config.BuildMode = "Clean"
$config.FO4Directory = "C:\Games\Fallout 4"

# Validate configuration
$config.IsValid()
```

## Build Modes

- **Clean**: Full clean build, generates all precombines and previs data
- **Filtered**: Uses filtering to optimize generation process
- **Xbox**: Optimized for Xbox platform constraints

## Logging

The module provides comprehensive logging functionality:

- **Console Output**: Colored output for different log levels
- **File Logging**: Detailed logs written to file
- **Progress Reporting**: Visual progress bars for long operations
- **Session Management**: Structured logging sessions with metadata

## Tool Path Discovery

The module automatically discovers tool paths through:

1. **Windows Registry**: Checks standard registry locations for installed tools
2. **Common Locations**: Searches typical installation directories
3. **Fallback Locations**: Additional search paths for non-standard installations

## Error Handling

- Comprehensive prerequisite validation
- Detailed error messages with context
- Graceful failure handling
- Recovery suggestions for common issues

## Testing

Run the included tests:
```powershell
# Install Pester if not already installed
Install-Module -Name Pester -Force

# Run tests
Invoke-Pester .\GeneratePrevisibines\Tests\
```

## Development Status

This module is currently in active development. The foundation and core infrastructure are complete, but individual workflow functions are still being implemented.

### Completed Components
- [x] Module structure and manifest
- [x] Configuration class (PrevisbineConfig)
- [x] Logging framework
- [x] Tool path discovery
- [x] Prerequisite validation
- [x] Main cmdlet interface
- [x] Basic test suite

### In Progress
- [ ] Creation Kit wrapper functions
- [ ] xEdit script execution
- [ ] Archive tool integration
- [ ] MO2 integration
- [ ] Workflow orchestration

## Contributing

This is a specialized tool for Fallout 4 modding. Contributions are welcome, especially:

- External tool integration improvements
- Additional validation logic
- Performance optimizations
- Test coverage expansion
- Documentation improvements

## License

This project is provided as-is for the Fallout 4 modding community. Please respect the licenses of the external tools this module integrates with.

## Troubleshooting

### Common Issues

1. **Tools Not Found**: Ensure Creation Kit, FO4Edit, and Archive tools are properly installed
2. **Registry Access**: Some tool detection requires registry access
3. **Permissions**: Ensure appropriate file system permissions for working directories
4. **CKPE Configuration**: CreationKitPlatformExtended must be properly configured

### Debug Mode

Enable verbose logging for troubleshooting:
```powershell
Start-PrevisbineGeneration -PluginName "MyMod.esp" -VerboseLogging -KeepTempFiles
```

Check the log file for detailed information about the process and any errors encountered.
