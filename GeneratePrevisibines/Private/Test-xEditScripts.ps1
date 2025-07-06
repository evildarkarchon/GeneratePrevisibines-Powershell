function Test-xEditScripts {
    <#
    .SYNOPSIS
        Validates that required xEdit scripts are present and have correct versions
        
    .DESCRIPTION
        This function checks that the required xEdit scripts exist and have the minimum
        required versions for previsbine generation.
        
    .PARAMETER Config
        The PrevisbineConfig object containing tool paths and settings
        
    .EXAMPLE
        Test-xEditScripts -Config $config
        
    .NOTES
        Checks for:
        - Batch_FO4MergePrevisandCleanRefr.pas (V2.2)
        - Batch_FO4MergeCombinedObjectsAndCheck.pas (V1.5)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PrevisbineConfig]$Config
    )
    
    begin {
        Write-LogMessage -Message "Checking required xEdit scripts" -Level 'Info' -LogPath $Config.LogPath
        
        $result = @{
            IsValid = $true
            Errors = @()
            Warnings = @()
            ScriptInfo = @{}
        }
        
        # Define required scripts and their minimum versions
        $requiredScripts = @{
            'Batch_FO4MergePrevisandCleanRefr.pas' = 'V2.2'
            'Batch_FO4MergeCombinedObjectsAndCheck.pas' = 'V1.5'
        }
        
        # Get xEdit scripts directory
        $xEditDir = Split-Path $Config.FO4EditPath -Parent
        $scriptsDir = Join-Path $xEditDir "Edit Scripts"
        
        if (-not (Test-Path $scriptsDir)) {
            $result.IsValid = $false
            $result.Errors += "xEdit Scripts directory not found: $scriptsDir"
            return $result
        }
    }
    
    process {
        try {
            foreach ($scriptName in $requiredScripts.Keys) {
                $requiredVersion = $requiredScripts[$scriptName]
                $scriptPath = Join-Path $scriptsDir $scriptName
                
                Write-LogMessage -Message "Checking script: $scriptName" -Level 'Debug' -LogPath $Config.LogPath
                
                if (-not (Test-Path $scriptPath)) {
                    $result.IsValid = $false
                    $result.Errors += "Required xEdit Script missing: $scriptName"
                    continue
                }
                
                # Check script version by searching for version string in file
                try {
                    $scriptContent = Get-Content $scriptPath -Raw -ErrorAction Stop
                    
                    if ($scriptContent -match $requiredVersion) {
                        Write-LogMessage -Message "Script $scriptName version $requiredVersion found" -Level 'Info' -LogPath $Config.LogPath
                        $result.ScriptInfo[$scriptName] = @{
                            Path = $scriptPath
                            Version = $requiredVersion
                            Status = 'Valid'
                        }
                    } else {
                        $result.IsValid = $false
                        $result.Errors += "Old Script $scriptName found, $requiredVersion required"
                        $result.ScriptInfo[$scriptName] = @{
                            Path = $scriptPath
                            Version = 'Unknown'
                            Status = 'Invalid'
                        }
                    }
                }
                catch {
                    $result.Warnings += "Could not read script file $scriptName : $($_.Exception.Message)"
                    $result.ScriptInfo[$scriptName] = @{
                        Path = $scriptPath
                        Version = 'Unknown'
                        Status = 'Error'
                    }
                }
            }
            
            # Also check for BSArch.exe in xEdit directory (set by batch file)
            $bsArchPath = Join-Path $xEditDir "BSArch.exe"
            if (Test-Path $bsArchPath) {
                Write-LogMessage -Message "BSArch.exe found in xEdit directory: $bsArchPath" -Level 'Info' -LogPath $Config.LogPath
                $result.ScriptInfo['BSArch'] = @{
                    Path = $bsArchPath
                    Version = 'Available'
                    Status = 'Valid'
                }
            } else {
                Write-LogMessage -Message "BSArch.exe not found in xEdit directory (will use system path if BSArch is selected)" -Level 'Debug' -LogPath $Config.LogPath
            }
        }
        catch {
            Write-LogMessage -Message "ERROR during xEdit script validation: $($_.Exception.Message)" -Level 'Error' -LogPath $Config.LogPath
            $result.IsValid = $false
            $result.Errors += "Script validation failed: $($_.Exception.Message)"
        }
    }
    
    end {
        if ($result.IsValid) {
            Write-LogMessage -Message "All required xEdit scripts validated successfully" -Level 'Info' -LogPath $Config.LogPath
        } else {
            Write-LogMessage -Message "xEdit script validation failed with errors" -Level 'Error' -LogPath $Config.LogPath
        }
        
        return $result
    }
}
