function Start-PrecombineGeneration {
    <#
    .SYNOPSIS
    Starts the precombine generation process using Creation Kit.
    
    .DESCRIPTION
    Initiates the Creation Kit precombine generation process for the specified plugin.
    This function handles the Creation Kit execution, log monitoring, and error detection.
    
    .PARAMETER Config
    PrevisbineConfig object containing tool paths and settings.
    
    .PARAMETER WhatIf
    Shows what would be executed without actually running the process.
    
    .EXAMPLE
    Start-PrecombineGeneration -Config $config
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [PrevisbineConfig] $Config,
        
        [Parameter()]
        [switch] $WhatIf
    )
    
    Write-LogMessage "Starting precombine generation for: $($Config.PluginName)" -Level Info -LogPath $Config.LogPath
    
    if (-not $Config.CreationKitPath -or -not (Test-Path $Config.CreationKitPath)) {
        throw "Creation Kit path not found: $($Config.CreationKitPath)"
    }
    
    # Get CKPE configuration for log monitoring
    $ckpeConfig = Test-CKPEConfiguration -CreationKitPath $Config.CreationKitPath
    if (-not $ckpeConfig.IsValid) {
        throw "CKPE configuration invalid: $($ckpeConfig.Errors -join '; ')"
    }
    
    $logPath = $ckpeConfig.LogPath
    Write-LogMessage "Using Creation Kit log: $logPath" -Level Info -LogPath $Config.LogPath
    
    # Clear existing log file
    if (Test-Path $logPath) {
        try {
            Remove-Item $logPath -Force
            Write-LogMessage "Cleared existing Creation Kit log" -Level Info -LogPath $Config.LogPath
        }
        catch {
            Write-LogMessage "Warning: Could not clear existing CK log: $_" -Level Warning -LogPath $Config.LogPath
        }
    }
    
    # Prepare Creation Kit arguments
    $arguments = @(
        "-GeneratePreCombinedObjects:""$($Config.PluginName)"""
    )
    
    # Add build mode specific arguments
    switch ($Config.BuildMode) {
        'Filtered' {
            $arguments += "-FilteredOnly"
        }
        'Xbox' {
            $arguments += "-XboxOne"
        }
        # Clean mode uses default arguments
    }
    
    $argumentString = $arguments -join ' '
    Write-LogMessage "Creation Kit arguments: $argumentString" -Level Info -LogPath $Config.LogPath
    
    if ($WhatIf) {
        Write-Host "Would execute: $($Config.CreationKitPath) $argumentString" -ForegroundColor Yellow
        return @{
            Success = $true
            Message = "WhatIf: Would start precombine generation"
        }
    }
    
    if ($PSCmdlet.ShouldProcess($Config.PluginName, "Generate precombines using Creation Kit")) {
        try {
            Write-LogMessage "Starting Creation Kit precombine generation..." -Level Info -LogPath $Config.LogPath
            
            # Start Creation Kit process
            $processInfo = @{
                FilePath = $Config.CreationKitPath
                ArgumentList = $arguments
                WorkingDirectory = Split-Path $Config.CreationKitPath -Parent
                Wait = $true
                PassThru = $true
                WindowStyle = 'Normal'
            }
            
            Write-LogMessage "Executing: $($Config.CreationKitPath) $argumentString" -Level Info -LogPath $Config.LogPath
            
            $process = Start-Process @processInfo
            
            # Monitor process and log
            $timeout = New-TimeSpan -Minutes $Config.TimeoutMinutes
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            while (-not $process.HasExited -and $stopwatch.Elapsed -lt $timeout) {
                Start-Sleep -Seconds 5
                
                # Check log for progress/errors
                if (Test-Path $logPath) {
                    $logContent = Get-Content $logPath -Raw -ErrorAction SilentlyContinue
                    if ($logContent) {
                        # Check for specific error patterns
                        if ($logContent -match "OUT OF HANDLE ARRAY ENTRIES") {
                            Write-LogMessage "Creation Kit ran out of reference handles" -Level Error -LogPath $Config.LogPath
                            $process.Kill()
                            throw "Creation Kit ran out of reference handles. Enable CKPE handle extension."
                        }
                        
                        if ($logContent -match "EXCEPTION.*access violation") {
                            Write-LogMessage "Creation Kit access violation detected" -Level Error -LogPath $Config.LogPath
                            $process.Kill()
                            throw "Creation Kit crashed with access violation"
                        }
                    }
                }
            }
            
            if (-not $process.HasExited) {
                Write-LogMessage "Creation Kit process timeout after $($Config.TimeoutMinutes) minutes" -Level Error -LogPath $Config.LogPath
                $process.Kill()
                throw "Creation Kit process timed out"
            }
            
            $exitCode = $process.ExitCode
            Write-LogMessage "Creation Kit process completed with exit code: $exitCode" -Level Info -LogPath $Config.LogPath
            
            # Analyze log for success/failure
            if (Test-Path $logPath) {
                $logContent = Get-Content $logPath -Raw
                
                if ($logContent -match "Precombine generation completed successfully") {
                    Write-LogMessage "Precombine generation completed successfully" -Level Info -LogPath $Config.LogPath
                    return @{
                        Success = $true
                        Message = "Precombine generation completed successfully"
                        ExitCode = $exitCode
                    }
                }
                else {
                    Write-LogMessage "Precombine generation may have failed - check log for details" -Level Warning -LogPath $Config.LogPath
                    return @{
                        Success = $false
                        Message = "Precombine generation completed but success not confirmed"
                        ExitCode = $exitCode
                    }
                }
            }
            else {
                Write-LogMessage "Creation Kit log file not found after execution" -Level Warning -LogPath $Config.LogPath
                return @{
                    Success = $false
                    Message = "Creation Kit log file not found"
                    ExitCode = $exitCode
                }
            }
        }
        catch {
            Write-LogMessage "Error during precombine generation: $_" -Level Error -LogPath $Config.LogPath
            throw "Precombine generation failed: $_"
        }
    }
    else {
        Write-LogMessage "Precombine generation cancelled by user" -Level Info -LogPath $Config.LogPath
        return @{
            Success = $false
            Message = "Operation cancelled by user"
        }
    }
}
