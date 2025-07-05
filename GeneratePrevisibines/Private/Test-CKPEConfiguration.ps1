function Test-CKPEConfiguration {
    <#
    .SYNOPSIS
    Validates CreationKit Platform Extended (CKPE) configuration.
    
    .DESCRIPTION
    Checks that CKPE is properly configured for previsbine generation,
    including handle settings and logging configuration.
    
    .PARAMETER CreationKitPath
    Path to the Creation Kit executable.
    
    .EXAMPLE
    Test-CKPEConfiguration -CreationKitPath "C:\Games\Fallout 4\CreationKit.exe"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $CreationKitPath
    )
    
    $result = @{
        IsValid    = $true
        Errors     = @()
        Warnings   = @()
        LogPath    = $null
        ConfigFile = $null
    }
    
    if (-not (Test-Path $CreationKitPath)) {
        $result.IsValid = $false
        $result.Errors += "Creation Kit not found at: $CreationKitPath"
        return $result
    }
    
    $ckDir = Split-Path $CreationKitPath -Parent
    
    # Check for CKPE DLL
    $ckpeDll = Join-Path $ckDir 'winhttp.dll'
    if (-not (Test-Path $ckpeDll)) {
        $result.IsValid = $false
        $result.Errors += "CKPE (winhttp.dll) not found. CreationKit Platform Extended is required."
        return $result
    }
    
    # Look for CKPE configuration files in order of preference
    $configFiles = @(
        'CreationKitPlatformExtended.toml',
        'CreationKitPlatformExtended.ini',
        'fallout4_test.ini'
    )
    
    $configFile = $null
    foreach ($file in $configFiles) {
        $filePath = Join-Path $ckDir $file
        if (Test-Path $filePath) {
            $configFile = $filePath
            $result.ConfigFile = $configFile
            break
        }
    }
    
    if (-not $configFile) {
        $result.IsValid = $false
        $result.Errors += "CKPE configuration file not found. Looking for: $($configFiles -join ', ')"
        return $result
    }
    
    # Parse configuration based on file type
    $logPath = $null
    $handleSetting = $null
    $configFileName = Split-Path $configFile -Leaf
    
    if ($configFileName -eq 'CreationKitPlatformExtended.toml') {
        # TOML format (modern CKPE)
        $content = Get-Content $configFile -Raw
        
        # Look for sOutputFile setting
        if ($content -match 'sOutputFile\s*=\s*["\'']([^"\'']*)["\'']') {
            $logPath = $matches[1]
        }
        
        # Look for handle setting
        if ($content -match 'bBSPointerHandleExtremly\s*=\s*true') {
            $handleSetting = $true
        }
    }
    elseif ($configFileName -eq 'CreationKitPlatformExtended.ini') {
        # INI format (modern CKPE)
        $content = Get-Content $configFile
        
        # Look for sOutputFile setting
        $logSetting = $content | Where-Object { $_ -match '^sOutputFile\s*=' }
        if ($logSetting) {
            $logPath = ($logSetting -split '=', 2)[1].Trim().Trim('"').Trim("'")
        }
        
        # Look for handle setting
        $handleSettingLine = $content | Where-Object { $_ -match '^bBSPointerHandleExtremly\s*=' }
        if ($handleSettingLine) {
            $handleSetting = ($handleSettingLine -split '=', 2)[1].Trim() -eq '1'
        }
    }
    else {
        # Legacy INI format (fallout4_test.ini)
        $content = Get-Content $configFile
        
        # Look for OutputFile setting
        $logSetting = $content | Where-Object { $_ -match '^OutputFile\s*=' }
        if ($logSetting) {
            $logPath = ($logSetting -split '=', 2)[1].Trim().Trim('"').Trim("'")
        }
        
        # Look for handle setting
        $handleSettingLine = $content | Where-Object { $_ -match '^BSHandleRefObjectPatch\s*=' }
        if ($handleSettingLine) {
            $handleSetting = ($handleSettingLine -split '=', 2)[1].Trim() -eq '1'
        }
    }
    
    # Validate log path
    if (-not $logPath) {
        $result.IsValid = $false
        $result.Errors += "CKPE logging not configured. Set sOutputFile (TOML) or OutputFile (INI) in $configFile"
        return $result
    }
    
    # Convert relative path to absolute
    if (-not [System.IO.Path]::IsPathRooted($logPath)) {
        $logPath = Join-Path $ckDir $logPath
    }
    
    $result.LogPath = $logPath
    
    # Validate handle setting
    if (-not $handleSetting) {
        $result.Warnings += "CKPE handle extension not enabled. This may cause issues with large mods."
    }
    
    # Check if log directory exists
    $logDir = Split-Path $logPath -Parent
    if (-not (Test-Path $logDir)) {
        try {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        catch {
            $result.IsValid = $false
            $result.Errors += "Cannot create log directory: $logDir"
            return $result
        }
    }
    
    return $result
}
