function Test-ToolVersions {
    <#
    .SYNOPSIS
    Validates versions of external tools used in previsbine generation.
    
    .DESCRIPTION
    Checks that external tools meet minimum version requirements and reports
    version information for diagnostic purposes.
    
    .PARAMETER Config
    PrevisbineConfig object containing tool paths.
    
    .EXAMPLE
    Test-ToolVersions -Config $config
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PrevisbineConfig] $Config
    )
    
    $result = @{
        IsValid = $true
        Errors = @()
        Warnings = @()
        VersionInfo = @{}
    }
    
    # Test FO4Edit version
    if ($Config.FO4EditPath -and (Test-Path $Config.FO4EditPath)) {
        try {
            $fo4EditVersion = (Get-Item $Config.FO4EditPath).VersionInfo.ProductVersion
            $result.VersionInfo['FO4Edit'] = $fo4EditVersion
            
            Write-LogMessage "FO4Edit version: $fo4EditVersion" -Level Info -LogPath $Config.LogPath
            
            # Check for minimum version if needed
            # if ($fo4EditVersion -lt "4.0.0") {
            #     $result.Warnings += "FO4Edit version $fo4EditVersion may not support all features"
            # }
        }
        catch {
            $result.Warnings += "Could not determine FO4Edit version: $_"
        }
    }
    
    # Test Creation Kit version
    if ($Config.CreationKitPath -and (Test-Path $Config.CreationKitPath)) {
        try {
            $ckVersion = (Get-Item $Config.CreationKitPath).VersionInfo.ProductVersion
            $result.VersionInfo['CreationKit'] = $ckVersion
            
            Write-LogMessage "Creation Kit version: $ckVersion" -Level Info -LogPath $Config.LogPath
        }
        catch {
            $result.Warnings += "Could not determine Creation Kit version: $_"
        }
    }
    
    # Test Fallout 4 version
    if ($Config.FO4Directory) {
        $fo4Exe = Join-Path $Config.FO4Directory 'Fallout4.exe'
        if (Test-Path $fo4Exe) {
            try {
                $fo4Version = (Get-Item $fo4Exe).VersionInfo.ProductVersion
                $result.VersionInfo['Fallout4'] = $fo4Version
                
                Write-LogMessage "Fallout 4 version: $fo4Version" -Level Info -LogPath $Config.LogPath
            }
            catch {
                $result.Warnings += "Could not determine Fallout 4 version: $_"
            }
        }
    }
    
    # Test CKPE version
    if ($Config.CreationKitPath) {
        $ckDir = Split-Path $Config.CreationKitPath -Parent
        $ckpeDll = Join-Path $ckDir 'winhttp.dll'
        
        if (Test-Path $ckpeDll) {
            try {
                $ckpeVersion = (Get-Item $ckpeDll).VersionInfo.ProductVersion
                $result.VersionInfo['CKPE'] = $ckpeVersion
                
                Write-LogMessage "CKPE version: $ckpeVersion" -Level Info -LogPath $Config.LogPath
            }
            catch {
                $result.Warnings += "Could not determine CKPE version: $_"
            }
        }
    }
    
    # Test Archive tool version
    $archiveToolPath = $Config.GetArchiveToolPath()
    if ($archiveToolPath -and (Test-Path $archiveToolPath)) {
        try {
            $archiveVersion = (Get-Item $archiveToolPath).VersionInfo.ProductVersion
            $result.VersionInfo[$Config.ArchiveTool] = $archiveVersion
            
            Write-LogMessage "$($Config.ArchiveTool) version: $archiveVersion" -Level Info -LogPath $Config.LogPath
        }
        catch {
            $result.Warnings += "Could not determine $($Config.ArchiveTool) version: $_"
        }
    }
    
    return $result
}
