function Expand-BA2Archive {
    <#
    .SYNOPSIS
        Expands (extracts) a BA2 archive
        
    .DESCRIPTION
        This function extracts the contents of a BA2 archive using Archive2 tool.
        
    .PARAMETER Config
        The PrevisbineConfig object containing tool paths and settings
        
    .EXAMPLE
        Expand-BA2Archive -Config $config
        
    .NOTES
        This function extracts the archive to the Data directory
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PrevisbineConfig]$Config
    )
    
    begin {
        Write-LogMessage -Message "Starting BA2 archive extraction" -Level 'Info' -LogPath $Config.LogPath
    }
    
    process {
        try {
            $archivePath = Join-Path $Config.DataPath $Config.PluginArchive
            
            if (-not (Test-Path $archivePath)) {
                Write-LogMessage -Message "WARNING - Archive file not found: $archivePath" -Level 'Warning' -LogPath $Config.LogPath
                return
            }
            
            # Use Archive2 to extract the archive
            $extractArgs = @('extract', "`"$archivePath`"", "`"$($Config.DataPath)`"")
            
            Write-LogMessage -Message "Extracting archive: $archivePath" -Level 'Info' -LogPath $Config.LogPath
            Write-LogMessage -Message "Running Archive2: $($Config.Archive2Path) $($extractArgs -join ' ')" -Level 'Debug' -LogPath $Config.LogPath
            
            $extractProcess = Start-Process -FilePath $Config.Archive2Path `
                -ArgumentList $extractArgs `
                -WorkingDirectory $Config.DataPath `
                -Wait `
                -PassThru `
                -RedirectStandardOutput $Config.LogPath `
                -RedirectStandardError $Config.LogPath
            
            if ($extractProcess.ExitCode -ne 0) {
                Write-LogMessage -Message "ERROR - Archive2 extraction failed with exit code: $($extractProcess.ExitCode)" -Level 'Error' -LogPath $Config.LogPath
                throw "Archive2 extraction failed with exit code: $($extractProcess.ExitCode)"
            }
            
            Write-LogMessage -Message "Successfully extracted archive: $archivePath" -Level 'Info' -LogPath $Config.LogPath
        }
        catch {
            Write-LogMessage -Message "ERROR during BA2 archive extraction: $($_.Exception.Message)" -Level 'Error' -LogPath $Config.LogPath
            throw
        }
    }
    
    end {
        Write-LogMessage -Message "Completed BA2 archive extraction" -Level 'Info' -LogPath $Config.LogPath
    }
}
