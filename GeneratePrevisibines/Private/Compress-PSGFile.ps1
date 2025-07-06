function Compress-PSGFile {
    <#
    .SYNOPSIS
        Compresses a PSG (Precombined Static Geometry) file to CSG format using Creation Kit
        
    .DESCRIPTION
        This function compresses a PSG file to CSG format using Creation Kit's CompressPSG operation.
        The original PSG file is deleted after successful compression.
        
    .PARAMETER PluginName
        The name of the plugin (without extension) to compress
        
    .PARAMETER Config
        The PrevisbineConfig object containing tool paths and settings
        
    .EXAMPLE
        Compress-PSGFile -PluginName "MyMod" -Config $config
        
    .NOTES
        This function is only used in Clean build mode
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PluginName,
        
        [Parameter(Mandatory = $true)]
        [PrevisbineConfig]$Config
    )
    
    begin {
        Write-LogMessage -Message "Starting PSG file compression for plugin: $PluginName" -Level 'Info' -LogPath $Config.LogPath
        Write-ProgressMessage -Activity "Compressing PSG File" -Status "Preparing compression for $PluginName"
    }
    
    process {
        try {
            # Check if PSG file exists
            $psgFile = Join-Path $Config.DataPath "$PluginName - Geometry.psg"
            if (-not (Test-Path $psgFile)) {
                Write-LogMessage -Message "ERROR - No Geometry file to Compress at: $psgFile" -Level 'Error' -LogPath $Config.LogPath
                throw "No Geometry file to Compress"
            }
            
            Write-LogMessage -Message "4 - Compressing PSG Via CK" -Level 'Info' -LogPath $Config.LogPath
            Write-ProgressMessage -Activity "Compressing PSG File" -Status "Running Creation Kit CompressPSG operation"
            
            # Run Creation Kit CompressPSG operation
            $outputFile = "$PluginName - Geometry.csg"
            $arguments = ""
            
            if ($PSCmdlet.ShouldProcess($psgFile, "Compress PSG to CSG")) {
                Invoke-CreationKit -Operation 'CompressPSG' -OutputFile $outputFile -Arguments $arguments -Config $Config
                
                # Verify CSG file was created
                $csgFile = Join-Path $Config.DataPath $outputFile
                if (Test-Path $csgFile) {
                    Write-LogMessage -Message "Successfully created CSG file: $csgFile" -Level 'Info' -LogPath $Config.LogPath
                    
                    # Delete the original PSG file
                    Write-LogMessage -Message "Removing original PSG file: $psgFile" -Level 'Info' -LogPath $Config.LogPath
                    Remove-Item -Path $psgFile -Force
                    
                    Write-ProgressMessage -Activity "Compressing PSG File" -Status "Compression completed successfully"
                } else {
                    Write-LogMessage -Message "ERROR - CompressPSG failed to create CSG file: $csgFile" -Level 'Error' -LogPath $Config.LogPath
                    throw "CompressPSG failed to create CSG file"
                }
            }
        }
        catch {
            Write-LogMessage -Message "ERROR during PSG compression: $($_.Exception.Message)" -Level 'Error' -LogPath $Config.LogPath
            throw
        }
    }
    
    end {
        Write-LogMessage -Message "Completed PSG file compression for plugin: $PluginName" -Level 'Info' -LogPath $Config.LogPath
    }
}
