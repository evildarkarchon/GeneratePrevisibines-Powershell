function Merge-PrecombineObjects {
    <#
    .SYNOPSIS
    Merges precombine objects using xEdit/FO4Edit scripts.
    
    .DESCRIPTION
    Executes xEdit scripts to merge precombine objects into the target plugin.
    This function handles the xEdit execution, script monitoring, and result validation.
    
    .PARAMETER Config
    PrevisbineConfig object containing tool paths and settings.
    
    .PARAMETER WhatIf
    Shows what would be executed without actually running the process.
    
    .EXAMPLE
    Merge-PrecombineObjects -Config $config
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [PrevisbineConfig] $Config,
        
        [Parameter()]
        [switch] $WhatIf
    )
    
    Write-LogMessage "Starting precombine object merge for: $($Config.PluginName)" -Level Info -LogPath $Config.LogPath
    
    if (-not $Config.FO4EditPath -or -not (Test-Path $Config.FO4EditPath)) {
        throw "FO4Edit path not found: $($Config.FO4EditPath)"
    }
    
    # Prepare xEdit arguments for precombine merge
    $arguments = @(
        "-script:""PrecombineMerge.pas"""
        "-nobuildrefs"
        "-autoload"
        "-autoexit"
    )
    
    # Add plugin-specific arguments
    if ($Config.PluginName) {
        $arguments += "-edit:""$($Config.PluginName)"""
    }
    
    $argumentString = $arguments -join ' '
    Write-LogMessage "xEdit arguments: $argumentString" -Level Info -LogPath $Config.LogPath
    
    if ($WhatIf) {
        Write-Host "Would execute: $($Config.FO4EditPath) $argumentString" -ForegroundColor Yellow
        return @{
            Success = $true
            Message = "WhatIf: Would merge precombine objects"
        }
    }
    
    if ($PSCmdlet.ShouldProcess($Config.PluginName, "Merge precombine objects using xEdit")) {
        try {
            Write-LogMessage "Starting xEdit precombine merge..." -Level Info -LogPath $Config.LogPath
            
            # Prepare log file for xEdit output
            $xEditLogPath = Join-Path $Config.WorkingDirectory "xEdit_PrecombineMerge.log"
            
            # Start xEdit process
            $processInfo = @{
                FilePath = $Config.FO4EditPath
                ArgumentList = $arguments
                WorkingDirectory = Split-Path $Config.FO4EditPath -Parent
                Wait = $true
                PassThru = $true
                WindowStyle = 'Normal'
                RedirectStandardOutput = $xEditLogPath
                RedirectStandardError = $xEditLogPath
            }
            
            Write-LogMessage "Executing: $($Config.FO4EditPath) $argumentString" -Level Info -LogPath $Config.LogPath
            
            $process = Start-Process @processInfo
            
            # Monitor process
            $timeout = New-TimeSpan -Minutes $Config.TimeoutMinutes
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            while (-not $process.HasExited -and $stopwatch.Elapsed -lt $timeout) {
                Start-Sleep -Seconds 5
                
                # Check log for progress/errors
                if (Test-Path $xEditLogPath) {
                    $logContent = Get-Content $xEditLogPath -Raw -ErrorAction SilentlyContinue
                    if ($logContent) {
                        # Check for specific error patterns
                        if ($logContent -match "EXCEPTION|ERROR|FATAL") {
                            Write-LogMessage "xEdit error detected in log" -Level Error -LogPath $Config.LogPath
                        }
                        
                        if ($logContent -match "Script finished") {
                            Write-LogMessage "xEdit script completed" -Level Info -LogPath $Config.LogPath
                            break
                        }
                    }
                }
            }
            
            if (-not $process.HasExited) {
                Write-LogMessage "xEdit process timeout after $($Config.TimeoutMinutes) minutes" -Level Error -LogPath $Config.LogPath
                $process.Kill()
                throw "xEdit process timed out"
            }
            
            $exitCode = $process.ExitCode
            Write-LogMessage "xEdit process completed with exit code: $exitCode" -Level Info -LogPath $Config.LogPath
            
            # Analyze log for success/failure
            if (Test-Path $xEditLogPath) {
                $logContent = Get-Content $xEditLogPath -Raw
                
                if ($logContent -match "Script finished" -and $exitCode -eq 0) {
                    Write-LogMessage "Precombine merge completed successfully" -Level Info -LogPath $Config.LogPath
                    return @{
                        Success = $true
                        Message = "Precombine merge completed successfully"
                        ExitCode = $exitCode
                    }
                }
                else {
                    Write-LogMessage "Precombine merge failed - check log for details" -Level Error -LogPath $Config.LogPath
                    return @{
                        Success = $false
                        Message = "Precombine merge failed"
                        ExitCode = $exitCode
                    }
                }
            }
            else {
                Write-LogMessage "xEdit log file not found after execution" -Level Warning -LogPath $Config.LogPath
                return @{
                    Success = $false
                    Message = "xEdit log file not found"
                    ExitCode = $exitCode
                }
            }
        }
        catch {
            Write-LogMessage "Error during precombine merge: $_" -Level Error -LogPath $Config.LogPath
            throw "Precombine merge failed: $_"
        }
    }
    else {
        Write-LogMessage "Precombine merge cancelled by user" -Level Info -LogPath $Config.LogPath
        return @{
            Success = $false
            Message = "Operation cancelled by user"
        }
    }
}
