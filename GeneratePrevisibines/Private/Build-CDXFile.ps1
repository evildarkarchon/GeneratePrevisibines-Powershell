function Build-CDXFile {
    <#
    .SYNOPSIS
        Builds a CDX (Combined Data Index) file using Creation Kit
        
    .DESCRIPTION
        This function builds a CDX file using Creation Kit's BuildCDX operation.
        This is only used in Clean build mode.
        
    .PARAMETER PluginName
        The name of the plugin (without extension) to build CDX for
        
    .PARAMETER Config
        The PrevisbineConfig object containing tool paths and settings
        
    .EXAMPLE
        Build-CDXFile -PluginName "MyMod" -Config $config
        
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
        Write-LogMessage -Message "Starting CDX file build for plugin: $PluginName" -Level 'Info' -LogPath $Config.LogPath
        Write-ProgressMessage -Activity "Building CDX File" -Status "Preparing CDX build for $PluginName"
    }
    
    process {
        try {
            # Only build CDX in Clean mode
            if ($Config.BuildMode -ne 'Clean') {
                Write-LogMessage -Message "Skipping CDX build - not in Clean mode (current mode: $($Config.BuildMode))" -Level 'Info' -LogPath $Config.LogPath
                return
            }
            
            Write-LogMessage -Message "5 - Building CDX Via CK" -Level 'Info' -LogPath $Config.LogPath
            Write-ProgressMessage -Activity "Building CDX File" -Status "Running Creation Kit BuildCDX operation"
            
            # Run Creation Kit BuildCDX operation
            $outputFile = "$PluginName.cdx"
            $arguments = ""
            
            if ($PSCmdlet.ShouldProcess($outputFile, "Build CDX file")) {
                Invoke-CreationKit -Operation 'BuildCDX' -OutputFile $outputFile -Arguments $arguments -Config $Config
                
                # Verify CDX file was created
                $cdxFile = Join-Path $Config.DataPath $outputFile
                if (Test-Path $cdxFile) {
                    Write-LogMessage -Message "Successfully created CDX file: $cdxFile" -Level 'Info' -LogPath $Config.LogPath
                    Write-ProgressMessage -Activity "Building CDX File" -Status "CDX build completed successfully"
                } else {
                    Write-LogMessage -Message "WARNING - BuildCDX may not have created CDX file: $cdxFile" -Level 'Warning' -LogPath $Config.LogPath
                }
            }
        }
        catch {
            Write-LogMessage -Message "ERROR during CDX build: $($_.Exception.Message)" -Level 'Error' -LogPath $Config.LogPath
            throw
        }
    }
    
    end {
        Write-LogMessage -Message "Completed CDX file build for plugin: $PluginName" -Level 'Info' -LogPath $Config.LogPath
    }
}
