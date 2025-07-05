using namespace System.ComponentModel.DataAnnotations

class PrevisbineConfig {
    [string] $FO4EditPath
    [string] $CreationKitPath
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
    
    # Constructor
    PrevisbineConfig() {
        $this.Initialize()
    }
    
    # Initialize default values
    [void] Initialize() {
        $this.LogPath = Join-Path -Path $env:TEMP -ChildPath "GeneratePrevisibines_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        $this.WorkingDirectory = $env:TEMP
        $this.TimeoutMinutes = 60
    }
    
    # Validate configuration
    [bool] IsValid() {
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
        
        if ($errors.Count -gt 0) {
            Write-Error ("Configuration validation failed:`n" + ($errors -join "`n"))
            return $false
        }
        
        return $true
    }
    
    # Get the appropriate archive tool path
    [string] GetArchiveToolPath() {
        switch ($this.ArchiveTool) {
            'Archive2' { return $this.Archive2Path }
            'BSArch' { return $this.BSArchPath }
            default { throw "Unknown archive tool: $($this.ArchiveTool)" }
        }
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
}
