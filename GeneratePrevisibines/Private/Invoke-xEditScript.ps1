function Invoke-xEditScript {
    <#
    .SYNOPSIS
        Invokes xEdit/FO4Edit with the specified script
        
    .DESCRIPTION
        This function runs xEdit/FO4Edit with the specified script and arguments.
        It handles process monitoring and log file analysis.
        
    .PARAMETER ScriptName
        The name of the script to run (e.g., 'Batch_FO4MergePrevisandCleanRefr.pas')
        
    .PARAMETER Arguments
        Arguments to pass to the script
        
    .PARAMETER Config
        The PrevisbineConfig object containing tool paths and settings
        
    .EXAMPLE
        Invoke-xEditScript -ScriptName 'Batch_FO4MergePrevisandCleanRefr.pas' -Arguments @('MyMod.esp', 'Previs.esp') -Config $config
        
    .NOTES
        This function expects the script to be available in xEdit's script directory
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,
        
        [Parameter(Mandatory = $true)]
        [PrevisbineConfig]$Config
    )
    
    begin {
        Write-LogMessage -Message "Starting xEdit script: $ScriptName" -Level 'Info' -LogPath $Config.LogPath
    }
    
    process {
        try {
            # Build xEdit arguments
            $xeditArgs = @()
            
            # Add script name
            $xeditArgs += "-script:`"$ScriptName`""
            
            # Add script arguments
            foreach ($arg in $Arguments) {
                $xeditArgs += "`"$arg`""
            }
            
            # Add unattended mode
            $xeditArgs += "-nobuildrefs"
            
            Write-LogMessage -Message "Running xEdit: $($Config.FO4EditPath) $($xeditArgs -join ' ')" -Level 'Info' -LogPath $Config.LogPath
            
            # Clear existing log file
            if (Test-Path $Config.UnattenedLogfile) {
                Remove-Item $Config.UnattenedLogfile -Force
                Write-LogMessage -Message "Cleared existing xEdit log file" -Level 'Debug' -LogPath $Config.LogPath
            }
            
            # Start xEdit process
            $xeditProcess = Start-Process -FilePath $Config.FO4EditPath `
                -ArgumentList $xeditArgs `
                -WorkingDirectory (Split-Path $Config.FO4EditPath -Parent) `
                -PassThru `
                -Wait
            
            Write-LogMessage -Message "xEdit process completed with exit code: $($xeditProcess.ExitCode)" -Level 'Info' -LogPath $Config.LogPath
            
            # Analyze log file if it exists
            if (Test-Path $Config.UnattenedLogfile) {
                $logContent = Get-Content $Config.UnattenedLogfile -Raw
                Write-LogMessage -Message "xEdit log file found, analyzing results" -Level 'Debug' -LogPath $Config.LogPath
                
                # Check for completion status
                if ($logContent -match "Completed: No Errors\.") {
                    Write-LogMessage -Message "xEdit script completed successfully with no errors" -Level 'Info' -LogPath $Config.LogPath
                } else {
                    Write-LogMessage -Message "xEdit script may have encountered errors - check log file: $($Config.UnattenedLogfile)" -Level 'Warning' -LogPath $Config.LogPath
                }
                
                # Log any error lines
                $errorLines = $logContent -split "`n" | Where-Object { $_ -match "ERROR|FATAL" }
                foreach ($errorLine in $errorLines) {
                    Write-LogMessage -Message "xEdit Error: $errorLine" -Level 'Warning' -LogPath $Config.LogPath
                }
            } else {
                Write-LogMessage -Message "WARNING - xEdit log file not found at: $($Config.UnattenedLogfile)" -Level 'Warning' -LogPath $Config.LogPath
            }
            
            # Check if process completed successfully
            if ($xeditProcess.ExitCode -ne 0) {
                Write-LogMessage -Message "WARNING - xEdit process completed with non-zero exit code: $($xeditProcess.ExitCode)" -Level 'Warning' -LogPath $Config.LogPath
            }
        }
        catch {
            Write-LogMessage -Message "ERROR during xEdit script execution: $($_.Exception.Message)" -Level 'Error' -LogPath $Config.LogPath
            throw
        }
    }
    
    end {
        Write-LogMessage -Message "Completed xEdit script: $ScriptName" -Level 'Info' -LogPath $Config.LogPath
    }
}
