function Expand-BA2Archive {
    <#
    .SYNOPSIS
        Extracts files from a BA2 archive
        
    .DESCRIPTION
        This function extracts files from a BA2 archive using Archive2.exe.
        This is needed for the AddToArchive functionality where we need to extract
        existing archives, add new files, and re-archive them.
        
    .PARAMETER Config
        The PrevisbineConfig object containing tool paths and settings
        
    .PARAMETER ArchivePath
        Path to the BA2 archive to extract (defaults to the plugin archive)
        
    .PARAMETER DestinationPath
        Path where files should be extracted (defaults to the data directory)
        
    .EXAMPLE
        Expand-BA2Archive -Config $config -ArchivePath "C:\Game\Data\MyMod - Main.ba2"
        
    .NOTES
        This function only works with Archive2.exe as BSArch extraction is handled differently
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PrevisbineConfig]$Config,
        
        [Parameter()]
        [string]$ArchivePath,
        
        [Parameter()]
        [string]$DestinationPath
    )
    
    begin {
        Write-LogMessage -Message "Starting BA2 archive extraction" -Level 'Info' -LogPath $Config.LogPath
        
        # Set default paths if not provided
        if (-not $ArchivePath) {
            $ArchivePath = Join-Path $Config.DataDirectory $Config.PluginArchive
        }
        
        if (-not $DestinationPath) {
            $DestinationPath = $Config.DataDirectory
        }
        
        if (-not (Test-Path $ArchivePath)) {
            throw "Archive file not found: $ArchivePath"
        }
        
        # Only Archive2 supports extraction in this context
        if ($Config.ArchiveTool -eq 'BSArch') {
            throw "BSArch extraction not supported in this context. Use Archive2 for extract operations."
        }
        
        $archive2Path = Join-Path (Split-Path $Config.CreationKitPath -Parent) "Tools\Archive2\Archive2.exe"
        if (-not (Test-Path $archive2Path)) {
            throw "Archive2.exe not found at: $archive2Path"
        }
    }
    
    process {
        try {
            # Build Archive2 extraction arguments
            $extractArgs = @()
            $extractArgs += "`"$ArchivePath`""
            $extractArgs += "-e=."
            $extractArgs += "-q"  # Quiet mode
            
            Write-LogMessage -Message "Running Archive2: $archive2Path $($extractArgs -join ' ')" -Level 'Info' -LogPath $Config.LogPath
            Write-LogMessage -Message "Extraction destination: $DestinationPath" -Level 'Info' -LogPath $Config.LogPath
            
            # Start Archive2 extraction process
            $extractProcess = Start-Process -FilePath $archive2Path `
                -ArgumentList $extractArgs `
                -WorkingDirectory $DestinationPath `
                -PassThru `
                -Wait `
                -WindowStyle Hidden
            
            Write-LogMessage -Message "Archive2 extraction completed with exit code: $($extractProcess.ExitCode)" -Level 'Info' -LogPath $Config.LogPath
            
            # Check if extraction was successful
            if ($extractProcess.ExitCode -ne 0) {
                throw "Archive2 extraction failed with exit code: $($extractProcess.ExitCode)"
            }
            
            Write-LogMessage -Message "Successfully extracted archive: $ArchivePath" -Level 'Info' -LogPath $Config.LogPath
        }
        catch {
            Write-LogMessage -Message "ERROR during archive extraction: $($_.Exception.Message)" -Level 'Error' -LogPath $Config.LogPath
            throw
        }
    }
    
    end {
        Write-LogMessage -Message "Completed BA2 archive extraction: $ArchivePath" -Level 'Info' -LogPath $Config.LogPath
    }
}
