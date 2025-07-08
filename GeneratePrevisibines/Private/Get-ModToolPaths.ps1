# Module-level cache for registry lookups to optimize repeated queries
$script:RegistryCache = @{}

function Get-CachedRegistryValue {
    <#
    .SYNOPSIS
    Gets a registry value with caching to improve performance.
    
    .PARAMETER Path
    Registry path to read from.
    
    .PARAMETER Property
    Property name to read (optional).
    
    .EXAMPLE
    Get-CachedRegistryValue -Path "HKLM:\SOFTWARE\WOW6432Node\Bethesda Softworks\Fallout4"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path,
        
        [Parameter()]
        [string] $Property
    )
    
    $cacheKey = if ($Property) { "$Path::$Property" } else { $Path }
    
    if (-not $script:RegistryCache.ContainsKey($cacheKey)) {
        try {
            if ($Property) {
                $script:RegistryCache[$cacheKey] = Get-ItemProperty -Path $Path -Name $Property -ErrorAction SilentlyContinue
            } else {
                $script:RegistryCache[$cacheKey] = Get-ItemProperty -Path $Path -ErrorAction SilentlyContinue
            }
        } catch {
            $script:RegistryCache[$cacheKey] = $null
        }
    }
    
    return $script:RegistryCache[$cacheKey]
}

function Get-ModToolPaths {
    <#
    .SYNOPSIS
    Discovers paths to Fallout 4 modding tools through registry and common locations.
    
    .DESCRIPTION
    Searches for FO4Edit, Creation Kit, Archive tools, and other modding utilities
    using Windows registry entries and common installation directories.
    
    .PARAMETER ToolName
    Specific tool to search for. If not specified, searches for all tools.
    
    .PARAMETER IncludeFallbacks
    Include fallback search locations if registry lookup fails.
    
    .EXAMPLE
    Get-ModToolPaths
    
    .EXAMPLE
    Get-ModToolPaths -ToolName "FO4Edit"
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('FO4Edit', 'CreationKit', 'Archive2', 'BSArch', 'MO2')]
        [string] $ToolName = 'All',
        
        [Parameter()]
        [switch] $IncludeFallbacks
    )
    
    $toolPaths = @{}
    
    # Search for Fallout 4 installation first
    $fo4Path = Get-FO4InstallPath
    if ($fo4Path) {
        $toolPaths['FO4Directory'] = $fo4Path
        $toolPaths['DataDirectory'] = Join-Path $fo4Path 'Data'
    }
    
    # Search for each tool
    if ($ToolName -eq 'All' -or $ToolName -eq 'FO4Edit') {
        $toolPaths['FO4Edit'] = Find-FO4EditPath -IncludeFallbacks:$IncludeFallbacks
    }
    
    if ($ToolName -eq 'All' -or $ToolName -eq 'CreationKit') {
        $toolPaths['CreationKit'] = Find-CreationKitPath -IncludeFallbacks:$IncludeFallbacks
    }
    
    if ($ToolName -eq 'All' -or $ToolName -eq 'Archive2') {
        $toolPaths['Archive2'] = Find-Archive2Path -IncludeFallbacks:$IncludeFallbacks
    }
    
    if ($ToolName -eq 'All' -or $ToolName -eq 'BSArch') {
        $toolPaths['BSArch'] = Find-BSArchPath -IncludeFallbacks:$IncludeFallbacks
    }
    
    if ($ToolName -eq 'All' -or $ToolName -eq 'MO2') {
        $toolPaths['MO2'] = Find-MO2Path -IncludeFallbacks:$IncludeFallbacks
    }
    
    return $toolPaths
}

function Get-FO4InstallPath {
    <#
    .SYNOPSIS
    Finds the Fallout 4 installation directory.
    
    .DESCRIPTION
    Searches registry keys and common Steam/GOG locations for Fallout 4.
    
    .EXAMPLE
    Get-FO4InstallPath
    #>
    [CmdletBinding()]
    param()
    
    $registryPath = 'HKLM:\SOFTWARE\WOW6432Node\Bethesda Softworks\Fallout4'
    
    # Try registry first using cached lookup
    try {
        if (Test-Path $registryPath) {
            $regKey = Get-CachedRegistryValue -Path $registryPath
            
            if ($regKey) {
                # Check for common property names
                $pathProperties = @('Installed Path', 'InstallPath', 'Path')
                foreach ($prop in $pathProperties) {
                    if ($regKey.$prop -and (Test-Path $regKey.$prop)) {
                        Write-LogMessage "Found FO4 path in registry: $($regKey.$prop)" -Level Debug
                        return $regKey.$prop
                    }
                }
                
                # Handle DefaultIcon format (contains exe path)
                if ($regKey.'(default)' -and $regKey.'(default)' -match '^"([^"]+)"') {
                    $exePath = $matches[1]
                    $installPath = Split-Path $exePath -Parent
                    if (Test-Path $installPath) {
                        Write-LogMessage "Found FO4 path from DefaultIcon: $installPath" -Level Debug
                        return $installPath
                    }
                }
            }
        }
    }
    catch {
        Write-LogMessage "Error reading registry path $registryPath`: $_" -Level Debug
    }
    
    # Try common Steam locations
    $steamPaths = @(
        "${env:ProgramFiles(x86)}\Steam\steamapps\common\Fallout 4",
        "${env:ProgramFiles}\Steam\steamapps\common\Fallout 4",
        "C:\Steam\steamapps\common\Fallout 4"
    )
    
    foreach ($path in $steamPaths) {
        if (Test-Path $path) {
            Write-LogMessage "Found FO4 path in Steam location: $path" -Level Debug
            return $path
        }
    }
    
    Write-LogMessage "Could not find Fallout 4 installation path" -Level Warning
    return $null
}

function Find-FO4EditPath {
    <#
    .SYNOPSIS
    Finds FO4Edit installation path.
    
    .DESCRIPTION
    Searches for FO4Edit.exe or xEdit64.exe in common locations.
    
    .PARAMETER IncludeFallbacks
    Include fallback search locations.
    
    .EXAMPLE
    Find-FO4EditPath
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch] $IncludeFallbacks
    )
    
    $executableNames = @('FO4Edit.exe', 'FO4Edit64.exe', 'xEdit64.exe', 'xEdit.exe')
    
    # Try registry first using cached lookup
    try {
        $regPath = 'HKCR:\FO4Script\DefaultIcon'
        if (Test-Path $regPath) {
            $regKey = Get-CachedRegistryValue -Path $regPath
            if ($regKey -and $regKey.'(default)' -and $regKey.'(default)' -match '^"([^"]+)"') {
                $exePath = $matches[1]
                if (Test-Path $exePath) {
                    Write-LogMessage "Found FO4Edit path in registry: $exePath" -Level Debug
                    return $exePath
                }
            }
        }
    }
    catch {
        Write-LogMessage "Error reading FO4Edit registry: $_" -Level Debug
    }
    
    if ($IncludeFallbacks) {
        # Search common locations
        $searchPaths = @(
            "${env:ProgramFiles(x86)}\FO4Edit",
            "${env:ProgramFiles}\FO4Edit",
            "${env:ProgramFiles(x86)}\xEdit",
            "${env:ProgramFiles}\xEdit",
            "C:\FO4Edit",
            "C:\xEdit"
        )
        
        foreach ($basePath in $searchPaths) {
            foreach ($exeName in $executableNames) {
                $fullPath = Join-Path $basePath $exeName
                if (Test-Path $fullPath) {
                    Write-LogMessage "Found FO4Edit at: $fullPath" -Level Debug
                    return $fullPath
                }
            }
        }
    }
    
    Write-LogMessage "Could not find FO4Edit installation" -Level Warning
    return $null
}

function Find-CreationKitPath {
    <#
    .SYNOPSIS
    Finds Creation Kit installation path.
    
    .DESCRIPTION
    Searches for CreationKit.exe in Fallout 4 directory and common locations.
    
    .PARAMETER IncludeFallbacks
    Include fallback search locations.
    
    .EXAMPLE
    Find-CreationKitPath
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch] $IncludeFallbacks
    )
    
    # Try in FO4 directory first
    $fo4Path = Get-FO4InstallPath
    if ($fo4Path) {
        $ckPath = Join-Path $fo4Path 'CreationKit.exe'
        if (Test-Path $ckPath) {
            Write-LogMessage "Found Creation Kit in FO4 directory: $ckPath" -Level Debug
            return $ckPath
        }
    }
    
    if ($IncludeFallbacks) {
        # Search common locations
        $searchPaths = @(
            "${env:ProgramFiles(x86)}\Steam\steamapps\common\Fallout 4",
            "${env:ProgramFiles}\Steam\steamapps\common\Fallout 4",
            "${env:ProgramFiles(x86)}\Bethesda.net Launcher\games\Fallout4",
            "${env:ProgramFiles}\Bethesda.net Launcher\games\Fallout4"
        )
        
        foreach ($basePath in $searchPaths) {
            $ckPath = Join-Path $basePath 'CreationKit.exe'
            if (Test-Path $ckPath) {
                Write-LogMessage "Found Creation Kit at: $ckPath" -Level Debug
                return $ckPath
            }
        }
    }
    
    Write-LogMessage "Could not find Creation Kit installation" -Level Warning
    return $null
}

function Find-Archive2Path {
    <#
    .SYNOPSIS
    Finds Archive2.exe path.
    
    .DESCRIPTION
    Searches for Archive2.exe in Fallout 4 directory and common locations.
    
    .PARAMETER IncludeFallbacks
    Include fallback search locations.
    
    .EXAMPLE
    Find-Archive2Path
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch] $IncludeFallbacks
    )
    
    # Try in FO4 directory first
    $fo4Path = Get-FO4InstallPath
    if ($fo4Path) {
        $toolsPath = Join-Path $fo4Path 'Tools\Archive2\Archive2.exe'
        if (Test-Path $toolsPath) {
            Write-LogMessage "Found Archive2 in FO4 Tools directory: $toolsPath" -Level Debug
            return $toolsPath
        }
    }
    
    if ($IncludeFallbacks) {
        # Search common locations
        $searchPaths = @(
            "${env:ProgramFiles(x86)}\Steam\steamapps\common\Fallout 4\Tools\Archive2",
            "${env:ProgramFiles}\Steam\steamapps\common\Fallout 4\Tools\Archive2",
            "${env:ProgramFiles(x86)}\Bethesda.net Launcher\games\Fallout4\Tools\Archive2",
            "${env:ProgramFiles}\Bethesda.net Launcher\games\Fallout4\Tools\Archive2"
        )
        
        foreach ($basePath in $searchPaths) {
            $archivePath = Join-Path $basePath 'Archive2.exe'
            if (Test-Path $archivePath) {
                Write-LogMessage "Found Archive2 at: $archivePath" -Level Debug
                return $archivePath
            }
        }
    }
    
    Write-LogMessage "Could not find Archive2 installation" -Level Warning
    return $null
}

function Find-BSArchPath {
    <#
    .SYNOPSIS
    Finds BSArch.exe path.
    
    .DESCRIPTION
    Searches for BSArch.exe in common locations.
    
    .PARAMETER IncludeFallbacks
    Include fallback search locations.
    
    .EXAMPLE
    Find-BSArchPath
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch] $IncludeFallbacks
    )
    
    if ($IncludeFallbacks) {
        # Search common locations
        $searchPaths = @(
            "${env:ProgramFiles(x86)}\BSArch",
            "${env:ProgramFiles}\BSArch",
            "C:\BSArch",
            "C:\Tools\BSArch"
        )

        $fo4EditPath = Find-FO4EditPath -IncludeFallbacks:$IncludeFallbacks
        if ($fo4EditPath) {
            $searchPaths += Split-Path $fo4EditPath -Parent
        }
        
        foreach ($basePath in $searchPaths) {
            if (-not $basePath) { continue }
            $bsarchPath = Join-Path $basePath 'BSArch.exe'
            if (Test-Path $bsarchPath) {
                Write-LogMessage "Found BSArch at: $bsarchPath" -Level Debug
                return $bsarchPath
            }
        }
    }
    
    Write-LogMessage "Could not find BSArch installation" -Level Warning
    return $null
}

function Find-MO2Path {
    <#
    .SYNOPSIS
    Finds Mod Organizer 2 installation path.
    
    .DESCRIPTION
    Searches for ModOrganizer.exe in common locations.
    
    .PARAMETER IncludeFallbacks
    Include fallback search locations.
    
    .EXAMPLE
    Find-MO2Path
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch] $IncludeFallbacks
    )
    
    if ($IncludeFallbacks) {
        # Search common locations
        $searchPaths = @(
            "${env:ProgramFiles(x86)}\Mod Organizer 2",
            "${env:ProgramFiles}\Mod Organizer 2",
            "C:\Mod Organizer 2",
            "C:\Tools\Mod Organizer 2"
        )
        
        foreach ($basePath in $searchPaths) {
            $mo2Path = Join-Path $basePath 'ModOrganizer.exe'
            if (Test-Path $mo2Path) {
                Write-LogMessage "Found MO2 at: $mo2Path" -Level Debug
                return $mo2Path
            }
        }
    }
    
    Write-LogMessage "Could not find Mod Organizer 2 installation" -Level Warning
    return $null
}

function Resolve-ToolPath {
    <#
    .SYNOPSIS
    Resolves and validates a tool path.
    
    .DESCRIPTION
    Normalizes path format and validates that the tool exists.
    
    .PARAMETER Path
    The path to resolve and validate.
    
    .PARAMETER ToolName
    Name of the tool for error messages.
    
    .EXAMPLE
    Resolve-ToolPath -Path "C:\FO4Edit\FO4Edit.exe" -ToolName "FO4Edit"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string] $Path,
        
        [Parameter(Mandatory = $true)]
        [string] $ToolName
    )
    
    if (-not $Path) {
        throw "Path for $ToolName is not specified"
    }
    
    # Resolve relative paths
    try {
        $resolvedPath = Resolve-Path $Path -ErrorAction Stop
        $normalizedPath = $resolvedPath.Path
    }
    catch {
        throw "Could not resolve path for $ToolName`: $Path"
    }
    
    # Validate file exists
    if (-not (Test-Path $normalizedPath -PathType Leaf)) {
        throw "$ToolName not found at: $normalizedPath"
    }
    
    Write-LogMessage "Resolved $ToolName path: $normalizedPath" -Level Debug
    return $normalizedPath
}
