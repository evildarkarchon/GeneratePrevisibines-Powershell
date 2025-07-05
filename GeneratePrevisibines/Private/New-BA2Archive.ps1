function New-BA2Archive {
    <#
    .SYNOPSIS
    Creates BA2 archives for precombine and previs data.
    
    .DESCRIPTION
    Creates BA2 archives using Archive2.exe or BSArch.exe for storing
    precombine and previs data files.
    
    .PARAMETER Config
    PrevisbineConfig object containing tool paths and settings.
    
    .PARAMETER SourcePath
    Path to the source files to archive.
    
    .PARAMETER ArchiveName
    Name of the archive to create.
    
    .PARAMETER WhatIf
    Shows what would be executed without actually running the process.
    
    .EXAMPLE
    New-BA2Archive -Config $config -SourcePath "C:\Temp\Meshes" -ArchiveName "MyMod - Main.ba2"
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory = $true)]
        [PrevisbineConfig] $Config,
        
        [Parameter(Mandatory = $true)]
        [string] $SourcePath,
        
        [Parameter(Mandatory = $true)]
        [string] $ArchiveName,
        
        [Parameter()]
        [switch] $WhatIf
    )
    
    Write-LogMessage "Creating archive: $ArchiveName" -Level Info -LogPath $Config.LogPath
    
    if (-not (Test-Path $SourcePath)) {
        throw "Source path not found: $SourcePath"
    }
    
    $archiveToolPath = $Config.GetArchiveToolPath()
    if (-not $archiveToolPath -or -not (Test-Path $archiveToolPath)) {
        throw "Archive tool not found: $archiveToolPath"
    }
    
    # Prepare output path
    $outputPath = Join-Path $Config.DataDirectory $ArchiveName
    Write-LogMessage "Output archive path: $outputPath" -Level Info -LogPath $Config.LogPath
    
    # Prepare arguments based on archive tool
    $arguments = @()
    
    if ($Config.ArchiveTool -eq 'BSArch') {
        # BSArch arguments
        $arguments += @(
            'create'
            '-ba2'
            '-format:DDS'
            '-compression:7'
            '-multithreaded'
            """$outputPath"""
            """$SourcePath"""
        )
    }
    else {
        # Archive2 arguments
        $arguments += @(
            """$outputPath"""
            '-create'
            '-format:DDS'
            '-compression:7'
            '-root:""' + $SourcePath + '""'
            '-file:""' + $SourcePath + '\**\*""'
        )
    }
    
    $argumentString = $arguments -join ' '
    Write-LogMessage "$($Config.ArchiveTool) arguments: $argumentString" -Level Info -LogPath $Config.LogPath
    
    if ($WhatIf) {
        Write-Host "Would execute: $archiveToolPath $argumentString" -ForegroundColor Yellow
        return @{
            Success     = $true
            Message     = "WhatIf: Would create archive"
            ArchivePath = $outputPath
        }
    }
    
    if ($PSCmdlet.ShouldProcess($ArchiveName, "Create BA2 archive")) {
        try {
            Write-LogMessage "Starting $($Config.ArchiveTool) archive creation..." -Level Info -LogPath $Config.LogPath
            
            # Prepare log file for archive tool output
            $archiveLogPath = Join-Path $Config.WorkingDirectory "$($Config.ArchiveTool)_archive.log"
            
            # Start archive tool process
            $processInfo = @{
                FilePath               = $archiveToolPath
                ArgumentList           = $arguments
                WorkingDirectory       = Split-Path $archiveToolPath -Parent
                Wait                   = $true
                PassThru               = $true
                WindowStyle            = 'Hidden'
                RedirectStandardOutput = $archiveLogPath
                RedirectStandardError  = $archiveLogPath
            }
            
            Write-LogMessage "Executing: $archiveToolPath $argumentString" -Level Info -LogPath $Config.LogPath
            
            $process = Start-Process @processInfo
            
            # Monitor process
            $timeout = New-TimeSpan -Minutes $Config.TimeoutMinutes
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            while (-not $process.HasExited -and $stopwatch.Elapsed -lt $timeout) {
                Start-Sleep -Seconds 2
                
                # Check log for progress/errors
                if (Test-Path $archiveLogPath) {
                    $logContent = Get-Content $archiveLogPath -Raw -ErrorAction SilentlyContinue
                    if ($logContent) {
                        # Check for specific error patterns
                        if ($logContent -match "ERROR|FAILED|Exception") {
                            Write-LogMessage "Archive tool error detected in log" -Level Error -LogPath $Config.LogPath
                        }
                    }
                }
            }
            
            if (-not $process.HasExited) {
                Write-LogMessage "Archive tool process timeout after $($Config.TimeoutMinutes) minutes" -Level Error -LogPath $Config.LogPath
                $process.Kill()
                throw "Archive tool process timed out"
            }
            
            $exitCode = $process.ExitCode
            Write-LogMessage "Archive tool process completed with exit code: $exitCode" -Level Info -LogPath $Config.LogPath
            
            # Verify archive was created
            if (Test-Path $outputPath) {
                $archiveSize = (Get-Item $outputPath).Length
                Write-LogMessage "Archive created successfully: $outputPath ($archiveSize bytes)" -Level Info -LogPath $Config.LogPath
                
                return @{
                    Success     = $true
                    Message     = "Archive created successfully"
                    ArchivePath = $outputPath
                    ArchiveSize = $archiveSize
                    ExitCode    = $exitCode
                }
            }
            else {
                Write-LogMessage "Archive file not found after creation: $outputPath" -Level Error -LogPath $Config.LogPath
                return @{
                    Success  = $false
                    Message  = "Archive file not created"
                    ExitCode = $exitCode
                }
            }
        }
        catch {
            Write-LogMessage "Error during archive creation: $_" -Level Error -LogPath $Config.LogPath
            throw "Archive creation failed: $_"
        }
    }
    else {
        Write-LogMessage "Archive creation cancelled by user" -Level Info -LogPath $Config.LogPath
        return @{
            Success = $false
            Message = "Operation cancelled by user"
        }
    }
}
