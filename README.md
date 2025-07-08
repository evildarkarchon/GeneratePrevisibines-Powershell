# GeneratePrevisibines PowerShell - Portable Distribution

A modern PowerShell replacement for the original batch script that automates Fallout 4 precombine and previs generation using Creation Kit, xEdit, and archive tools.

## 🚀 Quick Start

This portable distribution gives you **two ways** to use GeneratePrevisibines:

### Option 1: Standalone Script (Recommended for beginners)
```powershell
# Interactive mode - just run the script
./GeneratePrevisibines.ps1

# Non-interactive mode with parameters
./GeneratePrevisibines.ps1 -PluginName "MyMod.esp" -BuildMode Clean -NonInteractive
```

### Option 2: Install as PowerShell Module (Recommended for advanced users)
```powershell
# Install the module
./Install.ps1

# Use the module
Import-Module GeneratePrevisibines
Start-PrevisbineGeneration -PluginName "MyMod.esp" -BuildMode Clean
```

## 📁 What's Included

```
GeneratePrevisibines-Powershell/
├── GeneratePrevisibines.ps1      # 🎯 Standalone script (run this!)
├── Install.ps1                   # 📦 Module installer
├── GeneratePrevisibines/         # 📚 PowerShell module
│   ├── GeneratePrevisibines.psd1 # Module manifest
│   ├── GeneratePrevisibines.psm1 # Module loader
│   ├── Classes/                  # Configuration classes
│   ├── Public/                   # Public functions
│   ├── Private/                  # Internal functions
│   └── Tests/                    # Unit tests
└── README.md                     # This file
```

## 🔧 Requirements

### PowerShell
- **PowerShell 5.1** or later (PowerShell 7+ recommended)
- Run `$PSVersionTable.PSVersion` to check your version

### External Tools (Auto-detected)
- **Creation Kit** (`CreationKit.exe`)
- **xEdit/FO4Edit** (`FO4Edit.exe` or `xEdit64.exe`)
- **Archive Tool** (`Archive2.exe` or `BSArch.exe`)
- **CKPE** (CreationKitPlatformExtended) for enhanced Creation Kit functionality

### Environment
- **Windows** (or WSL with Windows tool access)
- **Fallout 4** installed and configured
- **Administrator privileges** (recommended)

## 🎮 Usage Examples

### Basic Usage
```powershell
# Interactive mode - prompts for all options
./GeneratePrevisibines.ps1

# Quick non-interactive run
./GeneratePrevisibines.ps1 -PluginName "MyMod.esp" -BuildMode Clean -NonInteractive
```

### Advanced Usage
```powershell
# Use specific build mode and archiver
./GeneratePrevisibines.ps1 -PluginName "MyMod.esp" -BuildMode Filtered -UseBSArch

# Specify custom paths
./GeneratePrevisibines.ps1 -PluginName "MyMod.esp" -FO4Directory "C:\Games\Fallout 4" -FO4EditPath "C:\Tools\xEdit64.exe"

# Enable verbose logging and keep temp files
./GeneratePrevisibines.ps1 -PluginName "MyMod.esp" -VerboseLogging -KeepTempFiles

# Resume from specific step after failure
./GeneratePrevisibines.ps1 -PluginName "MyMod.esp" -StartFromStep 4

# Use with Mod Organizer 2
./GeneratePrevisibines.ps1 -PluginName "MyMod.esp" -UseMO2 -MO2Profile "My Profile"
```

### Module Usage (After Installation)
```powershell
# Install the module first
./Install.ps1

# Import and use
Import-Module GeneratePrevisibines
Start-PrevisbineGeneration -PluginName "MyMod.esp" -BuildMode Clean

# Get help
Get-Help Start-PrevisbineGeneration -Examples
Get-Help Start-PrevisbineGeneration -Full
```

## 🏗️ Build Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| **Clean** | Full clean build with all optimization steps | Final release builds |
| **Filtered** | Faster build, skips some optimization steps | Development/testing |
| **Xbox** | Xbox-compatible build mode | Console mod development |

## 🔧 Parameters

### Common Parameters
- `-PluginName` - Plugin file to process (e.g., "MyMod.esp")
- `-BuildMode` - Build mode: Clean, Filtered, or Xbox
- `-NonInteractive` - Run without user prompts
- `-VerboseLogging` - Enable detailed logging
- `-KeepTempFiles` - Keep temporary files for debugging

### Path Parameters
- `-FO4Directory` - Fallout 4 installation directory
- `-FO4EditPath` - Path to FO4Edit executable
- `-LogPath` - Custom log file path

### Advanced Parameters
- `-UseBSArch` - Use BSArch instead of Archive2
- `-UseMO2` - Enable Mod Organizer 2 integration
- `-MO2Profile` - Specific MO2 profile to use
- `-StartFromStep` - Resume from specific step (1-8)
- `-TimeoutMinutes` - Tool timeout in minutes (default: 60)

## 📋 Process Steps

The script follows these steps:

1. **Precombine Generation** - Generate precombined meshes via Creation Kit
2. **Plugin Processing** - Merge precombine objects via xEdit
3. **Archive Creation** - Create BA2 archives from precombines
4. **PSG Compression** - Compress geometry files (Clean mode only)
5. **CDX Building** - Build CDX files (Clean mode only)
6. **Previs Generation** - Generate visibility data via Creation Kit
7. **Previs Processing** - Merge previs data via xEdit
8. **Final Assembly** - Complete archive creation and cleanup

## 🚨 Troubleshooting

### Common Issues

**"Module not found" Error**
```powershell
# Make sure you're in the correct directory
cd path\to\GeneratePrevisibines-Powershell
./GeneratePrevisibines.ps1
```

**"Tools not found" Error**
```powershell
# Specify tool paths manually
./GeneratePrevisibines.ps1 -FO4Directory "C:\Games\Fallout 4" -FO4EditPath "C:\Tools\xEdit64.exe"
```

**"Access Denied" Error**
- Run PowerShell as Administrator
- Check that no other tools are using the files
- Temporarily disable antivirus file protection

**"Execution Policy" Error**
```powershell
# Set execution policy (run as Administrator)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Debug Mode
```powershell
# Run with maximum verbosity
./GeneratePrevisibines.ps1 -VerboseLogging -KeepTempFiles
```

### Log Files
- Default location: `%TEMP%\GeneratePrevisibines_<timestamp>.log`
- Custom location: Use `-LogPath` parameter
- Always check log files for detailed error information

## 🔍 Validation

The script automatically validates:
- ✅ PowerShell version compatibility
- ✅ Required tool availability
- ✅ Fallout 4 installation
- ✅ CKPE configuration
- ✅ Plugin file existence
- ✅ Directory permissions

Skip validation with `-SkipValidation` (not recommended).

## 🤝 Contributing

This is an open-source project. Contributions welcome!

- Report issues in the GitHub repository
- Submit pull requests for improvements
- Share your configuration profiles
- Help with documentation

## 🔗 Links

- **Original Batch Script**: PJM's Automatic Previsbine Builder
- **Creation Kit**: Bethesda's official modding tool
- **xEdit**: Community plugin editor
- **CKPE**: CreationKitPlatformExtended

## 🎯 Quick Reference

### Most Common Usage
```powershell
# Interactive mode (easiest)
./GeneratePrevisibines.ps1

# Non-interactive mode (automation)
./GeneratePrevisibines.ps1 -PluginName "MyMod.esp" -BuildMode Clean -NonInteractive
```

### Emergency Recovery
```powershell
# Resume from step 4 after failure
./GeneratePrevisibines.ps1 -PluginName "MyMod.esp" -StartFromStep 4

# Debug mode with full logging
./GeneratePrevisibines.ps1 -PluginName "MyMod.esp" -VerboseLogging -KeepTempFiles
```

---

**Happy Modding!** 🎮✨