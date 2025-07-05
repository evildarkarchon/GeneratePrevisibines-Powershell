function Test-Prerequisites {
    <#
    .SYNOPSIS
    Validates that all required tools and dependencies are available.
    
    .DESCRIPTION
    Performs comprehensive validation of the environment before starting
    previsbine generation process.
    
    .PARAMETER Config
    PrevisbineConfig object containing tool paths and settings.
    
    .PARAMETER SkipToolValidation
    Skip validation of external tools (for testing).
    
    .EXAMPLE
    Test-Prerequisites -Config $config
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PrevisbineConfig] $Config,
        
        [Parameter()]
        [switch] $SkipToolValidation
    )
    
    $validationResults = @{
        Success = $true
        Errors = @()
        Warnings = @()
    }
    
    Write-LogMessage "Starting prerequisite validation..." -Level Info -LogPath $Config.LogPath
    
    # Test basic configuration
    if (-not $Config.IsValid()) {
        $validationResults.Success = $false
        $validationResults.Errors += "Configuration validation failed"
        return $validationResults
    }
    
    # Test tool availability
    if (-not $SkipToolValidation) {
        $toolTests = @(
            @{ Name = "FO4Edit"; Path = $Config.FO4EditPath },
            @{ Name = "Creation Kit"; Path = $Config.CreationKitPath },
            @{ Name = "Archive Tool"; Path = $Config.GetArchiveToolPath() }
        )
        
        foreach ($tool in $toolTests) {
            $result = Test-ToolAvailability -ToolName $tool.Name -ToolPath $tool.Path
            if (-not $result.Success) {
                $validationResults.Success = $false
                $validationResults.Errors += $result.Error
            }
            if ($result.Warning) {
                $validationResults.Warnings += $result.Warning
            }
        }
    }
    
    # Test directory permissions
    $dirTests = @(
        @{ Name = "FO4 Directory"; Path = $Config.FO4Directory },
        @{ Name = "Data Directory"; Path = $Config.DataDirectory },
        @{ Name = "Working Directory"; Path = $Config.WorkingDirectory }
    )
    
    foreach ($dir in $dirTests) {
        $result = Test-DirectoryAccess -DirectoryName $dir.Name -DirectoryPath $dir.Path
        if (-not $result.Success) {
            $validationResults.Success = $false
            $validationResults.Errors += $result.Error
        }
        if ($result.Warning) {
            $validationResults.Warnings += $result.Warning
        }
    }
    
    # Test MO2 configuration if enabled
    if ($Config.UseMO2) {
        $result = Test-MO2Configuration -Config $Config
        if (-not $result.Success) {
            $validationResults.Success = $false
            $validationResults.Errors += $result.Error
        }
        if ($result.Warning) {
            $validationResults.Warnings += $result.Warning
        }
    }
    
    # Test plugin name validity
    $pluginValidation = Test-PluginName -PluginName $Config.PluginName -FO4Directory $Config.FO4Directory
    if (-not $pluginValidation.IsValid) {
        $validationResults.Success = $false
        $validationResults.Errors += $pluginValidation.Errors
    }
    $validationResults.Warnings += $pluginValidation.Warnings
    
    # Test CKPE configuration
    $ckpeValidation = Test-CKPEConfiguration -CreationKitPath $Config.CreationKitPath
    if (-not $ckpeValidation.IsValid) {
        $validationResults.Success = $false
        $validationResults.Errors += $ckpeValidation.Errors
    }
    $validationResults.Warnings += $ckpeValidation.Warnings
    
    # Test tool versions
    $versionValidation = Test-ToolVersions -Config $Config
    if (-not $versionValidation.IsValid) {
        $validationResults.Warnings += $versionValidation.Errors
    }
    $validationResults.Warnings += $versionValidation.Warnings
    
    # Test disk space
    $result = Test-DiskSpace -WorkingDirectory $Config.WorkingDirectory
    if (-not $result.Success) {
        $validationResults.Warnings += $result.Warning
    }
    
    # Log results
    if ($validationResults.Success) {
        Write-LogMessage "All prerequisites validated successfully" -Level Info -LogPath $Config.LogPath
    }
    else {
        Write-LogMessage "Prerequisite validation failed" -Level Error -LogPath $Config.LogPath
        foreach ($error in $validationResults.Errors) {
            Write-LogMessage "  ERROR: $error" -Level Error -LogPath $Config.LogPath
        }
    }
    
    if ($validationResults.Warnings.Count -gt 0) {
        foreach ($warning in $validationResults.Warnings) {
            Write-LogMessage "  WARNING: $warning" -Level Warning -LogPath $Config.LogPath
        }
    }
    
    return $validationResults
}

function Test-ToolAvailability {
    <#
    .SYNOPSIS
    Tests if a specific tool is available and functional.
    
    .DESCRIPTION
    Validates that a tool exists and can be executed.
    
    .PARAMETER ToolName
    Name of the tool for error messages.
    
    .PARAMETER ToolPath
    Path to the tool executable.
    
    .EXAMPLE
    Test-ToolAvailability -ToolName "FO4Edit" -ToolPath "C:\FO4Edit\FO4Edit.exe"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ToolName,
        
        [Parameter(Mandatory = $true)]
        [string] $ToolPath
    )
    
    $result = @{
        Success = $true
        Error = $null
        Warning = $null
    }
    
    # Check if file exists
    if (-not (Test-Path $ToolPath -PathType Leaf)) {
        $result.Success = $false
        $result.Error = "$ToolName not found at: $ToolPath"
        return $result
    }
    
    # Check if file is executable
    try {
        $fileInfo = Get-Item $ToolPath
        if ($fileInfo.Extension -ne '.exe') {
            $result.Warning = "$ToolName does not have .exe extension: $ToolPath"
        }
    }
    catch {
        $result.Success = $false
        $result.Error = "Cannot access $ToolName at: $ToolPath"
        return $result
    }
    
    # Tool-specific validation
    switch ($ToolName) {
        "FO4Edit" {
            # Check for required FO4Edit files
            $fo4EditDir = Split-Path $ToolPath -Parent
            $requiredFiles = @('Edit Scripts', 'Delphi32.dll')
            
            foreach ($file in $requiredFiles) {
                $filePath = Join-Path $fo4EditDir $file
                if (-not (Test-Path $filePath)) {
                    $result.Warning = "$ToolName installation may be incomplete - missing: $file"
                }
            }
        }
        
        "Creation Kit" {
            # Check for CK dependencies
            $ckDir = Split-Path $ToolPath -Parent
            $requiredFiles = @('CreationKit.ini')
            
            foreach ($file in $requiredFiles) {
                $filePath = Join-Path $ckDir $file
                if (-not (Test-Path $filePath)) {
                    $result.Warning = "$ToolName may not be properly configured - missing: $file"
                }
            }
        }
    }
    
    return $result
}

function Test-DirectoryAccess {
    <#
    .SYNOPSIS
    Tests directory access permissions.
    
    .DESCRIPTION
    Validates that a directory exists and has appropriate permissions.
    
    .PARAMETER DirectoryName
    Name of the directory for error messages.
    
    .PARAMETER DirectoryPath
    Path to the directory.
    
    .EXAMPLE
    Test-DirectoryAccess -DirectoryName "FO4 Directory" -DirectoryPath "C:\Games\Fallout 4"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $DirectoryName,
        
        [Parameter(Mandatory = $true)]
        [string] $DirectoryPath
    )
    
    $result = @{
        Success = $true
        Error = $null
        Warning = $null
    }
    
    # Check if directory exists
    if (-not (Test-Path $DirectoryPath -PathType Container)) {
        $result.Success = $false
        $result.Error = "$DirectoryName does not exist: $DirectoryPath"
        return $result
    }
    
    # Test read access
    try {
        Get-ChildItem $DirectoryPath -ErrorAction Stop | Out-Null
    }
    catch {
        $result.Success = $false
        $result.Error = "Cannot read $DirectoryName`: $DirectoryPath"
        return $result
    }
    
    # Test write access
    try {
        $testFile = Join-Path $DirectoryPath "previsbine_test_$(Get-Random).tmp"
        "test" | Out-File -FilePath $testFile -ErrorAction Stop
        Remove-Item $testFile -ErrorAction Stop
    }
    catch {
        $result.Warning = "Limited write access to $DirectoryName`: $DirectoryPath"
    }
    
    return $result
}

function Test-MO2Configuration {
    <#
    .SYNOPSIS
    Tests Mod Organizer 2 configuration.
    
    .DESCRIPTION
    Validates MO2 installation and profile configuration.
    
    .PARAMETER Config
    PrevisbineConfig object containing MO2 settings.
    
    .EXAMPLE
    Test-MO2Configuration -Config $config
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PrevisbineConfig] $Config
    )
    
    $result = @{
        Success = $true
        Error = $null
        Warning = $null
    }
    
    # Check MO2 executable
    if (-not (Test-Path $Config.MO2Path -PathType Leaf)) {
        $result.Success = $false
        $result.Error = "MO2 executable not found: $($Config.MO2Path)"
        return $result
    }
    
    # Check MO2 profile
    $mo2Dir = Split-Path $Config.MO2Path -Parent
    $profilesDir = Join-Path $mo2Dir "profiles"
    $profileDir = Join-Path $profilesDir $Config.MO2Profile
    
    if (-not (Test-Path $profileDir -PathType Container)) {
        $result.Success = $false
        $result.Error = "MO2 profile not found: $($Config.MO2Profile)"
        return $result
    }
    
    # Check profile configuration
    $profileIni = Join-Path $profileDir "settings.ini"
    if (-not (Test-Path $profileIni)) {
        $result.Warning = "MO2 profile settings.ini not found, profile may be incomplete"
    }
    
    return $result
}

function Test-CKPEConfiguration {
    <#
    .SYNOPSIS
    Tests Creation Kit Platform Extended configuration.
    
    .DESCRIPTION
    Validates CKPE installation and configuration.
    
    .PARAMETER Config
    PrevisbineConfig object containing CK settings.
    
    .EXAMPLE
    Test-CKPEConfiguration -Config $config
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PrevisbineConfig] $Config
    )
    
    $result = @{
        Success = $true
        Error = $null
        Warning = $null
    }
    
    $ckDir = Split-Path $Config.CreationKitPath -Parent
    $ckpeConfig = Join-Path $ckDir "CreationKitPlatformExtended.ini"
    
    if (-not (Test-Path $ckpeConfig)) {
        $result.Success = $false
        $result.Error = "CKPE configuration not found. Please install and configure CreationKitPlatformExtended."
        return $result
    }
    
    # Parse CKPE configuration to find log path
    try {
        $ckpeContent = Get-Content $ckpeConfig -ErrorAction Stop
        $logSection = $false
        
        foreach ($line in $ckpeContent) {
            if ($line -match '^\s*\[Log\]') {
                $logSection = $true
                continue
            }
            if ($line -match '^\s*\[' -and $logSection) {
                break
            }
            if ($logSection -and $line -match '^\s*Directory\s*=\s*(.+)') {
                $logDir = $matches[1].Trim()
                if (-not (Test-Path $logDir -PathType Container)) {
                    $result.Warning = "CKPE log directory does not exist: $logDir"
                }
            }
        }
    }
    catch {
        $result.Warning = "Could not parse CKPE configuration: $_"
    }
    
    return $result
}

function Test-PluginName {
    <#
    .SYNOPSIS
    Tests plugin name validity.
    
    .DESCRIPTION
    Validates that plugin name follows proper naming conventions.
    
    .PARAMETER PluginName
    Name of the plugin to validate.
    
    .EXAMPLE
    Test-PluginName -PluginName "MyMod.esp"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $PluginName
    )
    
    $result = @{
        Success = $true
        Error = $null
        Warning = $null
    }
    
    # Check if plugin name is empty
    if (-not $PluginName) {
        $result.Success = $false
        $result.Error = "Plugin name cannot be empty"
        return $result
    }
    
    # Check plugin extension
    $validExtensions = @('.esp', '.esm', '.esl')
    $extension = [System.IO.Path]::GetExtension($PluginName)
    
    if ($extension -notin $validExtensions) {
        $result.Success = $false
        $result.Error = "Plugin must have a valid extension (.esp, .esm, .esl): $PluginName"
        return $result
    }
    
    # Check for invalid characters
    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
    foreach ($char in $invalidChars) {
        if ($PluginName.Contains($char)) {
            $result.Success = $false
            $result.Error = "Plugin name contains invalid character '$char': $PluginName"
            return $result
        }
    }
    
    # Check length
    if ($PluginName.Length -gt 255) {
        $result.Success = $false
        $result.Error = "Plugin name is too long (max 255 characters): $PluginName"
        return $result
    }
    
    return $result
}

function Test-DiskSpace {
    <#
    .SYNOPSIS
    Tests available disk space.
    
    .DESCRIPTION
    Validates that sufficient disk space is available for the operation.
    
    .PARAMETER WorkingDirectory
    Working directory to check space for.
    
    .PARAMETER RequiredGB
    Required space in GB (default: 5).
    
    .EXAMPLE
    Test-DiskSpace -WorkingDirectory "C:\Temp"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $WorkingDirectory,
        
        [Parameter()]
        [double] $RequiredGB = 5.0
    )
    
    $result = @{
        Success = $true
        Error = $null
        Warning = $null
    }
    
    try {
        $drive = Get-PSDrive -Name ([System.IO.Path]::GetPathRoot($WorkingDirectory).TrimEnd('\')[0])
        $freeSpaceGB = $drive.Free / 1GB
        
        if ($freeSpaceGB -lt $RequiredGB) {
            $result.Success = $false
            $result.Warning = "Low disk space: $([math]::Round($freeSpaceGB, 2)) GB available, $RequiredGB GB recommended"
        }
    }
    catch {
        $result.Warning = "Could not check disk space: $_"
    }
    
    return $result
}
