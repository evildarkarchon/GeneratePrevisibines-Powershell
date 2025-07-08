function Export-PrevisbineConfiguration {
    <#
    .SYNOPSIS
    Exports the current previsbine configuration to a JSON file.
    
    .DESCRIPTION
    Exports a PrevisbineConfig object to a JSON file for later reuse.
    Sensitive paths are preserved as-is for portability.
    
    .PARAMETER Config
    The PrevisbineConfig object to export.
    
    .PARAMETER Path
    The path where the configuration file will be saved.
    
    .PARAMETER Force
    Overwrite the file if it already exists.
    
    .EXAMPLE
    Export-PrevisbineConfiguration -Config $config -Path ".\config.json"
    
    .EXAMPLE
    $config | Export-PrevisbineConfiguration -Path ".\myconfig.json" -Force
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PrevisbineConfig]$Config,
        
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter()]
        [switch]$Force
    )
    
    process {
        try {
            # Validate the configuration before exporting
            if (-not $Config.IsValid()) {
                throw "Configuration is not valid. Please ensure all required paths are set."
            }
            
            # Check if file exists
            if ((Test-Path $Path) -and -not $Force) {
                throw "File already exists at '$Path'. Use -Force to overwrite."
            }
            
            # Create directory if it doesn't exist
            $directory = Split-Path -Path $Path -Parent
            if ($directory -and -not (Test-Path $directory)) {
                if ($PSCmdlet.ShouldProcess($directory, 'Create directory')) {
                    New-Item -ItemType Directory -Path $directory -Force | Out-Null
                }
            }
            
            # Convert to hashtable for cleaner JSON output
            $configData = @{
                FO4EditPath = $Config.FO4EditPath
                CreationKitPath = $Config.CreationKitPath
                ArchiveTool = $Config.ArchiveTool
                Archive2Path = $Config.Archive2Path
                BSArchPath = $Config.BSArchPath
                BuildMode = $Config.BuildMode
                LogPath = $Config.LogPath
                FO4Directory = $Config.FO4Directory
                DataDirectory = $Config.DataDirectory
                PluginName = $Config.PluginName
                WorkingDirectory = $Config.WorkingDirectory
                UseMO2 = $Config.UseMO2
                MO2Path = $Config.MO2Path
                MO2Profile = $Config.MO2Profile
                VerboseLogging = $Config.VerboseLogging
                KeepTempFiles = $Config.KeepTempFiles
                TimeoutMinutes = $Config.TimeoutMinutes
                ExportDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                ExportVersion = '1.0'
            }
            
            if ($PSCmdlet.ShouldProcess($Path, 'Export configuration')) {
                $configData | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Force
                Write-Information "Configuration exported to: $Path" -InformationAction Continue
            }
            
        } catch {
            throw "Failed to export configuration: $_"
        }
    }
}