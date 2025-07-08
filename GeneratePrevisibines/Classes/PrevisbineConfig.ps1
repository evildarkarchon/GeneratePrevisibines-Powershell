<#
.SYNOPSIS
Central configuration class for Fallout 4 previsbine generation operations.

.DESCRIPTION
The PrevisbineConfig class manages all configuration settings, tool paths, and validation
for Fallout 4 previsbine generation. It provides centralized configuration management,
validation, serialization, and tool path management for the GeneratePrevisibines module.

This class serves as the central configuration object passed to all module functions,
ensuring consistent settings and eliminating the need for repetitive parameter passing.

.PROPERTY FO4EditPath
Path to FO4Edit.exe executable for plugin manipulation.

.PROPERTY CreationKitPath
Path to CreationKit.exe for precombine and previs generation.

.PROPERTY CreationKitLogPath
Path to Creation Kit log file for monitoring operations.

.PROPERTY ArchiveTool
Archive tool to use ('Archive2' or 'BSArch') for BA2 creation.

.PROPERTY Archive2Path
Path to Archive2.exe from Creation Kit Tools.

.PROPERTY BSArchPath
Path to BSArch.exe for alternative archiving.

.PROPERTY BuildMode
Build mode setting ('Clean', 'Filtered', or 'Xbox').

.PROPERTY LogPath
Path to module log file for operation logging.

.PROPERTY FO4Directory
Root Fallout 4 installation directory.

.PROPERTY DataDirectory
Fallout 4 Data directory path.

.PROPERTY PluginName
Name of plugin to process (with .esp/.esm/.esl extension).

.PROPERTY WorkingDirectory
Temporary working directory for operations.

.PROPERTY UseMO2
Enable Mod Organizer 2 integration.

.PROPERTY MO2Path
Path to ModOrganizer.exe executable.

.PROPERTY MO2Profile
MO2 profile name to use for operations.

.PROPERTY VerboseLogging
Enable verbose logging for detailed output.

.PROPERTY KeepTempFiles
Preserve temporary files for debugging.

.PROPERTY TimeoutMinutes
Timeout in minutes for external tool operations.

.METHODS
Initialize() - Sets default values for properties
IsValid() - Validates all configuration settings
GetArchiveToolPath() - Returns appropriate archive tool path
GetLogDirectory() - Returns log file directory
Clone() - Creates deep copy of configuration
ToJson() - Serializes configuration to JSON
FromJson() - Deserializes configuration from JSON
SaveToFile() - Saves configuration to file
LoadFromFile() - Loads configuration from file (static method)

.EXAMPLE
$config = [PrevisbineConfig]::new()
$config.PluginName = "MyMod.esp"
$config.BuildMode = "Clean"
if ($config.IsValid()) {
    # Use configuration
}

.EXAMPLE
# Save and load configuration
$config.SaveToFile("config.json")
$loadedConfig = [PrevisbineConfig]::LoadFromFile("config.json")

.EXAMPLE
# Clone configuration for modification
$testConfig = $config.Clone()
$testConfig.VerboseLogging = $true

.NOTES
This class uses PowerShell validation attributes to ensure type safety and valid values.
All file and directory paths are validated when IsValid() is called.
The class supports JSON serialization for configuration persistence.
#>
class PrevisbineConfig {
    [string] $FO4EditPath
    [string] $CreationKitPath
    [string] $CreationKitLogPath
    [ValidateSet('Archive2', 'BSArch')]
    [string] $ArchiveTool = 'Archive2'
    [string] $Archive2Path
    [string] $BSArchPath
    [ValidateSet('Clean', 'Filtered', 'Xbox')]
    [string] $BuildMode = 'Clean'
    [string] $LogPath
    [string] $FO4Directory
    [string] $DataDirectory
    [string] $PluginName
    [string] $WorkingDirectory
    [bool] $UseMO2 = $false
    [string] $MO2Path
    [string] $MO2Profile
    [bool] $VerboseLogging = $false
    [bool] $KeepTempFiles = $false
    [int] $TimeoutMinutes = 60
    
    # Performance optimization: validation caching
    [DateTime] $LastValidationTime = [DateTime]::MinValue
    [bool] $LastValidationResult = $false
    [string[]] $LastValidationErrors = @()
    [TimeSpan] $ValidationCacheTimeout = [TimeSpan]::FromMinutes(5)
    
    # Constructor
    PrevisbineConfig() {
        $this.Initialize()
    }
    
    # Initialize default values
    [void] Initialize() {
        $this.LogPath = Join-Path -Path $env:TEMP -ChildPath "GeneratePrevisibines_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        $this.WorkingDirectory = $env:TEMP
        $this.TimeoutMinutes = 60
        # Set CreationKit log path to default location
        if ($this.CreationKitPath) {
            $ckDir = Split-Path $this.CreationKitPath -Parent
            $this.CreationKitLogPath = Join-Path $ckDir "CreationKitCustom.log"
        }
    }
    
    # Validate configuration with caching for performance
    [bool] IsValid() {
        $now = [DateTime]::Now
        
        # Check if we have a cached result that's still valid
        if (($now - $this.LastValidationTime) -lt $this.ValidationCacheTimeout) {
            return $this.LastValidationResult
        }
        
        # Run validation and cache result
        $result = $this.ValidateInternal()
        $this.LastValidationTime = $now
        $this.LastValidationResult = $result.IsValid
        $this.LastValidationErrors = $result.Errors
        
        return $this.LastValidationResult
    }
    
    # Internal validation method (not cached)
    [PSCustomObject] ValidateInternal() {
        $errors = @()
        
        # Check required paths
        if (-not $this.FO4EditPath -or -not (Test-Path $this.FO4EditPath)) {
            $errors += "FO4Edit path is not set or file does not exist: $($this.FO4EditPath)"
        }
        
        if (-not $this.CreationKitPath -or -not (Test-Path $this.CreationKitPath)) {
            $errors += "Creation Kit path is not set or file does not exist: $($this.CreationKitPath)"
        }
        
        # Check archive tool
        switch ($this.ArchiveTool) {
            'Archive2' {
                if (-not $this.Archive2Path -or -not (Test-Path $this.Archive2Path)) {
                    $errors += "Archive2 path is not set or file does not exist: $($this.Archive2Path)"
                }
            }
            'BSArch' {
                if (-not $this.BSArchPath -or -not (Test-Path $this.BSArchPath)) {
                    $errors += "BSArch path is not set or file does not exist: $($this.BSArchPath)"
                }
            }
        }
        
        # Check FO4 directory
        if (-not $this.FO4Directory -or -not (Test-Path $this.FO4Directory)) {
            $errors += "Fallout 4 directory is not set or does not exist: $($this.FO4Directory)"
        }
        
        # Check data directory
        if (-not $this.DataDirectory -or -not (Test-Path $this.DataDirectory)) {
            $errors += "Data directory is not set or does not exist: $($this.DataDirectory)"
        }
        
        # Check plugin name
        if (-not $this.PluginName) {
            $errors += "Plugin name is not set"
        }
        
        # Check MO2 settings if enabled
        if ($this.UseMO2) {
            if (-not $this.MO2Path -or -not (Test-Path $this.MO2Path)) {
                $errors += "MO2 is enabled but MO2 path is not set or does not exist: $($this.MO2Path)"
            }
            if (-not $this.MO2Profile) {
                $errors += "MO2 is enabled but MO2 profile is not set"
            }
        }
        
        # Return validation result object
        return [PSCustomObject]@{
            IsValid = ($errors.Count -eq 0)
            Errors  = $errors
        }
    }
    
    # Get cached validation errors
    [string[]] GetValidationErrors() {
        return $this.LastValidationErrors
    }
    
    # Force revalidation (clears cache)
    [void] ClearValidationCache() {
        $this.LastValidationTime = [DateTime]::MinValue
    }
    
    # Get the appropriate archive tool path
    [string] GetArchiveToolPath() {
        switch ($this.ArchiveTool) {
            'Archive2' { return $this.Archive2Path }
            'BSArch' { return $this.BSArchPath }
            default {
                throw "Unknown archive tool: $($this.ArchiveTool)" # This should ideally not be reached due to ValidateSet
            }
        }
        # This should never be reached, but PowerShell requires all paths to return a value
        return ""
    }
    
    # Get log directory
    [string] GetLogDirectory() {
        return Split-Path -Path $this.LogPath -Parent
    }
    
    # Create a copy of the configuration
    [PrevisbineConfig] Clone() {
        $clone = [PrevisbineConfig]::new()
        $clone.FO4EditPath = $this.FO4EditPath
        $clone.CreationKitPath = $this.CreationKitPath
        $clone.ArchiveTool = $this.ArchiveTool
        $clone.Archive2Path = $this.Archive2Path
        $clone.BSArchPath = $this.BSArchPath
        $clone.BuildMode = $this.BuildMode
        $clone.LogPath = $this.LogPath
        $clone.FO4Directory = $this.FO4Directory
        $clone.DataDirectory = $this.DataDirectory
        $clone.PluginName = $this.PluginName
        $clone.WorkingDirectory = $this.WorkingDirectory
        $clone.UseMO2 = $this.UseMO2
        $clone.MO2Path = $this.MO2Path
        $clone.MO2Profile = $this.MO2Profile
        $clone.VerboseLogging = $this.VerboseLogging
        $clone.KeepTempFiles = $this.KeepTempFiles
        $clone.TimeoutMinutes = $this.TimeoutMinutes
        return $clone
    }
    
    # Export configuration to JSON
    [string] ToJson() {
        $configData = @{
            FO4EditPath      = $this.FO4EditPath
            CreationKitPath  = $this.CreationKitPath
            ArchiveTool      = $this.ArchiveTool
            Archive2Path     = $this.Archive2Path
            BSArchPath       = $this.BSArchPath
            BuildMode        = $this.BuildMode
            LogPath          = $this.LogPath
            FO4Directory     = $this.FO4Directory
            DataDirectory    = $this.DataDirectory
            PluginName       = $this.PluginName
            WorkingDirectory = $this.WorkingDirectory
            UseMO2           = $this.UseMO2
            MO2Path          = $this.MO2Path
            MO2Profile       = $this.MO2Profile
            VerboseLogging   = $this.VerboseLogging
            KeepTempFiles    = $this.KeepTempFiles
            TimeoutMinutes   = $this.TimeoutMinutes
            ExportDate       = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            ExportVersion    = '1.0'
        }
        return ($configData | ConvertTo-Json -Depth 10)
    }
    
    # Import configuration from JSON
    [void] FromJson([string]$json) {
        $configData = $json | ConvertFrom-Json
        
        # Map properties
        if ($null -ne $configData.FO4EditPath) { $this.FO4EditPath = $configData.FO4EditPath }
        if ($null -ne $configData.CreationKitPath) { $this.CreationKitPath = $configData.CreationKitPath }
        if ($null -ne $configData.ArchiveTool) { $this.ArchiveTool = $configData.ArchiveTool }
        if ($null -ne $configData.Archive2Path) { $this.Archive2Path = $configData.Archive2Path }
        if ($null -ne $configData.BSArchPath) { $this.BSArchPath = $configData.BSArchPath }
        if ($null -ne $configData.BuildMode) { $this.BuildMode = $configData.BuildMode }
        if ($null -ne $configData.LogPath) { $this.LogPath = $configData.LogPath }
        if ($null -ne $configData.FO4Directory) { $this.FO4Directory = $configData.FO4Directory }
        if ($null -ne $configData.DataDirectory) { $this.DataDirectory = $configData.DataDirectory }
        if ($null -ne $configData.PluginName) { $this.PluginName = $configData.PluginName }
        if ($null -ne $configData.WorkingDirectory) { $this.WorkingDirectory = $configData.WorkingDirectory }
        if ($null -ne $configData.UseMO2) { $this.UseMO2 = $configData.UseMO2 }
        if ($null -ne $configData.MO2Path) { $this.MO2Path = $configData.MO2Path }
        if ($null -ne $configData.MO2Profile) { $this.MO2Profile = $configData.MO2Profile }
        if ($null -ne $configData.VerboseLogging) { $this.VerboseLogging = $configData.VerboseLogging }
        if ($null -ne $configData.KeepTempFiles) { $this.KeepTempFiles = $configData.KeepTempFiles }
        if ($null -ne $configData.TimeoutMinutes) { $this.TimeoutMinutes = $configData.TimeoutMinutes }
    }
    
    # Save configuration to file
    [void] SaveToFile([string]$path) {
        $this.ToJson() | Set-Content -Path $path -Force
    }
    
    # Load configuration from file
    static [PrevisbineConfig] LoadFromFile([string]$path) {
        if (-not (Test-Path $path)) {
            throw "Configuration file not found: $path"
        }
        
        $config = [PrevisbineConfig]::new()
        $json = Get-Content -Path $path -Raw
        $config.FromJson($json)
        return $config
    }
}
