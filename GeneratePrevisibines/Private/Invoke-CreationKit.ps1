function Invoke-CreationKit {
    <#
    .SYNOPSIS
        Invokes Creation Kit with the specified operation
        
    .DESCRIPTION
        This function runs Creation Kit with the specified operation and monitors its execution.
        It handles ENB DLL renaming, process monitoring, and log file analysis.
        
    .PARAMETER Operation
        The Creation Kit operation to perform (e.g., 'CompressPSG', 'BuildCDX', 'GeneratePrecombined')
        
    .PARAMETER OutputFile
        The output file name for the operation
        
    .PARAMETER Arguments
        Additional arguments to pass to Creation Kit
        
    .PARAMETER Config
        The PrevisbineConfig object containing tool paths and settings
        
    .EXAMPLE
        Invoke-CreationKit -Operation 'CompressPSG' -OutputFile 'MyMod - Geometry.csg' -Arguments '' -Config $config
        
    .NOTES
        This function temporarily renames ENB DLL files to prevent conflicts with Creation Kit
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Operation,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputFile,
        
        [Parameter(Mandatory = $false)]
        [string]$Arguments = '',
        
        [Parameter(Mandatory = $true)]
        [PrevisbineConfig]$Config
    )
    
    begin {
        Write-LogMessage -Message "Starting Creation Kit operation: $Operation" -Level 'Info' -LogPath $Config.LogPath
        
        # Get Creation Kit directory
        $ckDirectory = Split-Path $Config.CreationKitPath -Parent
        
        # Define ENB DLL files to temporarily rename
        $enbDlls = @(
            'd3d11.dll',
            'd3d10.dll', 
            'd3d9.dll',
            'dxgi.dll',
            'enbimgui.dll'
        )
        
        # Store original DLL states
        $dllStates = @{}
    }
    
    process {
        try {
            # Temporarily rename ENB DLL files to prevent conflicts
            Write-LogMessage -Message "Temporarily disabling ENB DLL files" -Level 'Info' -LogPath $Config.LogPath
            foreach ($dll in $enbDlls) {
                $dllPath = Join-Path $ckDirectory $dll
                $disabledPath = "$dllPath-PJMdisabled"
                
                if (Test-Path $dllPath) {
                    $dllStates[$dll] = 'existed'
                    Rename-Item -Path $dllPath -NewName "$dll-PJMdisabled" -Force
                    Write-LogMessage -Message "Renamed $dll to $dll-PJMdisabled" -Level 'Debug' -LogPath $Config.LogPath
                } else {
                    $dllStates[$dll] = 'not_existed'
                }
            }
            
            # Clear existing Creation Kit log file
            if (Test-Path $Config.CreationKitLogPath) {
                Remove-Item $Config.CreationKitLogPath -Force
                Write-LogMessage -Message "Cleared existing Creation Kit log file" -Level 'Debug' -LogPath $Config.LogPath
            }
            
            # Build Creation Kit arguments
            $ckArgs = @()
            if ($Arguments) {
                $ckArgs += "-$Operation`:`"$($Config.PluginName)`"", $Arguments
            } else {
                $ckArgs += "-$Operation`:`"$OutputFile`""
            }
            
            Write-LogMessage -Message "Running Creation Kit: $($Config.CreationKitPath) $($ckArgs -join ' ')" -Level 'Info' -LogPath $Config.LogPath
            
            # Start Creation Kit process
            $ckProcess = Start-Process -FilePath $Config.CreationKitPath `
                -ArgumentList $ckArgs `
                -WorkingDirectory $ckDirectory `
                -PassThru `
                -Wait
            
            Write-LogMessage -Message "Creation Kit process completed with exit code: $($ckProcess.ExitCode)" -Level 'Info' -LogPath $Config.LogPath
            
            # Monitor Creation Kit's native log file for errors
            if (Test-Path $Config.CreationKitLogPath) {
                $ckLog = Get-Content $Config.CreationKitLogPath -Raw
                Write-LogMessage -Message "Creation Kit log file found, analyzing for errors" -Level 'Debug' -LogPath $Config.LogPath
                
                # Check for specific error patterns
                if ($ckLog -match "OUT OF HANDLE ARRAY ENTRIES") {
                    Write-LogMessage -Message "ERROR - Creation Kit ran out of reference handles" -Level 'Error' -LogPath $Config.LogPath
                    throw "Creation Kit ran out of reference handles"
                }
                
                if ($ckLog -match "ERROR.*visibility task did not complete") {
                    Write-LogMessage -Message "WARNING - GeneratePreVisData failed to build at least one Cluster uvd" -Level 'Warning' -LogPath $Config.LogPath
                }
                
                # Log any other errors found
                $errorLines = $ckLog -split "`n" | Where-Object { $_ -match "ERROR" }
                foreach ($errorLine in $errorLines) {
                    Write-LogMessage -Message "CK Error: $errorLine" -Level 'Warning' -LogPath $Config.LogPath
                }
            } else {
                Write-LogMessage -Message "WARNING - Creation Kit log file not found at: $($Config.CreationKitLogPath)" -Level 'Warning' -LogPath $Config.LogPath
            }
            
            # Check if process completed successfully
            if ($ckProcess.ExitCode -ne 0) {
                Write-LogMessage -Message "ERROR - Creation Kit process failed with exit code: $($ckProcess.ExitCode)" -Level 'Error' -LogPath $Config.LogPath
                throw "Creation Kit process failed with exit code: $($ckProcess.ExitCode)"
            }
        }
        catch {
            Write-LogMessage -Message "ERROR during Creation Kit operation: $($_.Exception.Message)" -Level 'Error' -LogPath $Config.LogPath
            throw
        }
        finally {
            # Restore ENB DLL files
            Write-LogMessage -Message "Restoring ENB DLL files" -Level 'Info' -LogPath $Config.LogPath
            foreach ($dll in $enbDlls) {
                $dllPath = Join-Path $ckDirectory $dll
                $disabledPath = "$dllPath-PJMdisabled"
                
                if ($dllStates[$dll] -eq 'existed' -and (Test-Path $disabledPath)) {
                    Rename-Item -Path $disabledPath -NewName $dll -Force
                    Write-LogMessage -Message "Restored $dll-PJMdisabled to $dll" -Level 'Debug' -LogPath $Config.LogPath
                }
            }
        }
    }
    
    end {
        Write-LogMessage -Message "Completed Creation Kit operation: $Operation" -Level 'Info' -LogPath $Config.LogPath
    }
}
