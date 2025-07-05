# Installation Methods Analysis for GeneratePrevisibines PowerShell Module

## Target Audience Analysis

### User Profile
- **Primary Users**: Fallout 4 modders who use Creation Kit and xEdit
- **Technical Level**: Varies from beginners to advanced
  - Many are comfortable with batch files but may not know PowerShell
  - Familiar with mod managers like Mod Organizer 2 (MO2)
  - Used to drag-and-drop installations
  - May have limited administrative privileges

### Current Usage Pattern
- Users currently download and run a single .bat file
- Often run from within MO2's virtual file system
- Need access to specific directories for Creation Kit and xEdit
- Expect tools to auto-detect game installations

## External Dependencies

### Required Tools (User Must Have)
1. **Fallout 4** - Base game installation
2. **Creation Kit** - Official Bethesda modding tool
3. **xEdit/FO4Edit** - Community modding tool
4. **CKPE (Creation Kit Platform Extended)** - CK enhancement
5. **Archive2.exe or BSArch.exe** - Archive tools (comes with CK)

### Integration Requirements
- Must work within MO2's virtual file system
- Needs registry access for auto-detection
- Requires ability to launch external executables
- Must handle file paths with spaces

## Recommended Installation Methods (Ranked by User-Friendliness)

### 1. **Standalone Script Package (Recommended)**
**Format**: ZIP file with PowerShell scripts and installer

**Structure**:
```
GeneratePrevisibines-PS-v1.0.zip
├── Install.bat                    # One-click installer
├── GeneratePrevisibines.ps1       # Main script
├── Modules/                       # Module files
│   ├── GeneratePrevisibines.psd1
│   ├── GeneratePrevisibines.psm1
│   └── Private/
├── Run-GeneratePrevisibines.bat   # Wrapper for easy execution
├── README.txt                     # Simple instructions
└── Uninstall.bat                 # Clean removal
```

**Advantages**:
- Familiar ZIP distribution like other mods
- One-click installation via batch wrapper
- No PowerShell knowledge required
- Can be managed by MO2 as a tool

**Installation Process**:
1. Download ZIP
2. Extract to preferred location (e.g., MO2 tools folder)
3. Run Install.bat (handles module registration)
4. Add to MO2 as executable tool

### 2. **PowerShell Gallery Module**
**Format**: Published PowerShell module

**Installation Command**:
```powershell
Install-Module -Name GeneratePrevisibines -Scope CurrentUser
```

**Advantages**:
- Standard PowerShell distribution method
- Easy updates via `Update-Module`
- No manual file management
- Automatic dependency handling

**Disadvantages**:
- Requires PowerShell knowledge
- May need execution policy changes
- Less familiar to modding community
- Harder to integrate with MO2

### 3. **Portable Executable Package**
**Format**: Self-contained folder with all scripts

**Structure**:
```
GeneratePrevisibines-Portable/
├── GeneratePrevisibines.exe       # PS2EXE compiled wrapper
├── Modules/                       # Embedded modules
├── Config/                        # Default configurations
│   └── settings.json
└── README.html                    # Rich documentation
```

**Advantages**:
- No PowerShell setup required
- Works like traditional executables
- Can include embedded help system
- Easy MO2 integration

**Disadvantages**:
- Antivirus false positives common with PS2EXE
- Larger file size
- Updates require full re-download

### 4. **Nexus Mod Manager Package**
**Format**: FOMOD installer package

**Structure**:
```
fomod/
├── info.xml
├── ModuleConfig.xml               # FOMOD installer config
└── GeneratePrevisibines/
    └── [Module files]
```

**Advantages**:
- Native to modding community
- Guided installation process
- Can configure during install
- Version tracking on Nexus

**Disadvantages**:
- Requires mod manager
- Not standard for tools
- Limited to Nexus ecosystem

### 5. **GitHub Release with Installer Script**
**Format**: GitHub release with PowerShell installer

**Installation**:
```powershell
irm https://github.com/user/repo/install.ps1 | iex
```

**Advantages**:
- Modern distribution method
- Easy updates
- Version control
- Issue tracking

**Disadvantages**:
- Requires internet during install
- PowerShell execution policy issues
- Less familiar to mod community

## Recommended Hybrid Approach

### Primary Distribution: Standalone Script Package
1. **Main Package** (GeneratePrevisibines-v1.0.zip)
   - Include batch wrappers for all operations
   - Self-contained module structure
   - MO2-ready configuration

2. **Installation Features**:
   ```batch
   @echo off
   :: Install.bat - Handles all setup
   powershell -ExecutionPolicy Bypass -File "%~dp0\Scripts\Install.ps1"
   ```

3. **Execution Wrapper**:
   ```batch
   @echo off
   :: Run-GeneratePrevisibines.bat
   powershell -ExecutionPolicy Bypass -Command "& {Import-Module '%~dp0\Modules\GeneratePrevisibines.psd1' -Force; New-Previsbine %*}"
   ```

### Secondary Distribution: PowerShell Gallery
- For advanced users who prefer standard PS modules
- Enables easy updates and dependency management
- Can coexist with standalone installation

### MO2 Integration Strategy

1. **Tool Configuration**:
   ```ini
   [Tools]
   GeneratePrevisibines\executable=Tools/GeneratePrevisibines/Run-GeneratePrevisibines.bat
   GeneratePrevisibines\arguments=
   GeneratePrevisibines\hide=false
   ```

2. **Virtual File System Compatibility**:
   - Detect MO2 environment variables
   - Use relative paths when possible
   - Handle VFS path translation

## Installation Helper Features

### Auto-Detection Script
```powershell
# Detect-Environment.ps1
$InstallInfo = @{
    Fallout4Path = Get-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Bethesda Softworks\Fallout4" -ErrorAction SilentlyContinue
    xEditPath = Get-ItemProperty -Path "HKCR:\FO4Script\DefaultIcon" -ErrorAction SilentlyContinue
    MO2Detected = Test-Path env:MANAGED_GAME
    PowerShellVersion = $PSVersionTable.PSVersion
}
```

### First-Run Configuration
- Wizard-style setup for paths
- Validate all dependencies
- Create default configuration
- Test run with minimal operation

## Documentation Requirements

### For Each Installation Method
1. **Quick Start Guide** (1 page)
   - Screenshots of installation
   - Basic usage example
   - Troubleshooting tips

2. **Video Tutorial**
   - Installation walkthrough
   - MO2 setup
   - First previsbine generation

3. **Migration Guide**
   - From batch to PowerShell
   - Preserving existing configurations
   - Command translation table

## Conclusion

**Recommended Primary Method**: Standalone Script Package with batch wrappers
- Maintains familiarity for existing users
- Requires no PowerShell knowledge
- Integrates seamlessly with MO2
- Provides upgrade path to full PowerShell usage

**Long-term Strategy**:
1. Start with standalone package for immediate adoption
2. Add PowerShell Gallery for advanced users
3. Gather feedback and iterate on installation process
4. Eventually transition community to native PowerShell usage