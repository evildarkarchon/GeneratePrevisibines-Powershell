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
            # Create plugins.txt file for xEdit
            $pluginsFile = Join-Path $env:TEMP "Plugins.txt"
            $pluginsContent = @()
            foreach ($arg in $Arguments) {
                $pluginsContent += "*$arg"
            }
            $pluginsContent | Out-File -FilePath $pluginsFile -Encoding ASCII
            Write-LogMessage -Message "Created plugins file: $pluginsFile" -Level 'Debug' -LogPath $Config.LogPath
            
            # Build xEdit arguments based on batch file pattern
            $xeditArgs = @()
            $xeditArgs += "-fo4"
            $xeditArgs += "-autoexit"
            $xeditArgs += "-P:`"$pluginsFile`""
            $xeditArgs += "-Script:$ScriptName"
            $xeditArgs += "-Mod:$($Arguments[0])"
            $xeditArgs += "-log:`"$($Config.UnattenedLogfile)`""
            
            Write-LogMessage -Message "Running xEdit: $($Config.FO4EditPath) $($xeditArgs -join ' ')" -Level 'Info' -LogPath $Config.LogPath
            
            # Clear existing log file
            if (Test-Path $Config.UnattenedLogfile) {
                Remove-Item $Config.UnattenedLogfile -Force
                Write-LogMessage -Message "Cleared existing xEdit log file" -Level 'Debug' -LogPath $Config.LogPath
            }
            
            # Start xEdit process in background
            $xeditProcess = Start-Process -FilePath $Config.FO4EditPath `
                -ArgumentList $xeditArgs `
                -WorkingDirectory (Split-Path $Config.FO4EditPath -Parent) `
                -PassThru
            
            # Wait a bit for xEdit to start
            Start-Sleep -Seconds 10
            
            # Send keypresses to handle xEdit's UI (like the batch file does)
            $xeditProcessName = [System.IO.Path]::GetFileNameWithoutExtension($Config.FO4EditPath)
            try {
                Add-Type -AssemblyName System.Windows.Forms
                $wshell = New-Object -ComObject WScript.Shell
                
                # Wait for and activate xEdit window
                Start-Sleep -Seconds 5
                $wshell.AppActivate($xeditProcessName)
                Start-Sleep -Seconds 1
                $wshell.AppActivate("Module Selection")
                $wshell.SendKeys("{ENTER}")
                
                Write-LogMessage -Message "Sent keypress to xEdit to start processing" -Level 'Debug' -LogPath $Config.LogPath
            }
            catch {
                Write-LogMessage -Message "Warning: Could not send keypresses to xEdit: $($_.Exception.Message)" -Level 'Warning' -LogPath $Config.LogPath
            }
            
            # Wait for log file to be created (indicates script is running)
            $timeout = 300  # 5 minutes
            $elapsed = 0
            while (-not (Test-Path $Config.UnattenedLogfile) -and $elapsed -lt $timeout) {
                Start-Sleep -Seconds 5
                $elapsed += 5
            }
            
            if (-not (Test-Path $Config.UnattenedLogfile)) {
                Write-LogMessage -Message "xEdit log file not created within timeout" -Level 'Error' -LogPath $Config.LogPath
                throw "xEdit script failed to start - no log file created"
            }
            
            # Wait for process to complete
            $xeditProcess.WaitForExit()
            
            # Try to close xEdit window gracefully
            Start-Sleep -Seconds 10
            try {
                $processes = Get-Process -Name $xeditProcessName -ErrorAction SilentlyContinue
                foreach ($proc in $processes) {
                    $proc.CloseMainWindow()
                }
                
                # Wait and then force kill if still running
                Start-Sleep -Seconds 15
                $processes = Get-Process -Name $xeditProcessName -ErrorAction SilentlyContinue
                foreach ($proc in $processes) {
                    Write-LogMessage -Message "Force killing xEdit process: $($proc.Id)" -Level 'Warning' -LogPath $Config.LogPath
                    $proc.Kill()
                }
            }
            catch {
                Write-LogMessage -Message "Warning: Could not close xEdit processes: $($_.Exception.Message)" -Level 'Warning' -LogPath $Config.LogPath
            }
            
            # Give MO2 time to move files around
            Start-Sleep -Seconds 10
            
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
