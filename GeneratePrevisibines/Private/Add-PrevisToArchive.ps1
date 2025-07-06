function Add-PrevisToArchive {
    <#
    .SYNOPSIS
        Adds previs files to the BA2 archive
        
    .DESCRIPTION
        This function adds visibility (previs) files to the BA2 archive. It handles both
        Archive2 and BSArch tools and can merge with existing archives or create new ones.
        
    .PARAMETER FolderName
        The name of the folder to archive (typically "vis")
        
    .PARAMETER Config
        The PrevisbineConfig object containing tool paths and settings
        
    .EXAMPLE
        Add-PrevisToArchive -FolderName "vis" -Config $config
        
    .NOTES
        This function handles the final archiving step for previs files
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FolderName,
        
        [Parameter(Mandatory = $true)]
        [PrevisbineConfig]$Config
    )
    
    begin {
        Write-LogMessage -Message "Starting previs archive process for folder: $FolderName" -Level 'Info' -LogPath $Config.LogPath
        Write-ProgressMessage -Activity "Adding Previs to Archive" -Status "Preparing archive for $FolderName"
    }
    
    process {
        try {
            # Check if visibility files exist
            $visPath = Join-Path $Config.DataPath $FolderName
            if (-not (Test-Path $visPath)) {
                Write-LogMessage -Message "WARNING - No Visibility files found to archive at: $visPath" -Level 'Warning' -LogPath $Config.LogPath
                return
            }
            
            # Check if any UVD files exist
            $uvdFiles = Get-ChildItem -Path $visPath -Filter "*.uvd" -Recurse
            if ($uvdFiles.Count -eq 0) {
                Write-LogMessage -Message "WARNING - No UVD files found in visibility directory: $visPath" -Level 'Warning' -LogPath $Config.LogPath
                return
            }
            
            Write-LogMessage -Message "8 - Adding Previs files to BA2 Archive" -Level 'Info' -LogPath $Config.LogPath
            Write-ProgressMessage -Activity "Adding Previs to Archive" -Status "Processing archive operations"
            
            $archivePath = Join-Path $Config.DataPath $Config.PluginArchive
            $archiveExists = Test-Path $archivePath
            
            if ($PSCmdlet.ShouldProcess($visPath, "Add to archive $($Config.PluginArchive)")) {
                if ($archiveExists) {
                    # Archive exists, need to merge
                    Write-LogMessage -Message "Archive exists, merging with existing archive: $archivePath" -Level 'Info' -LogPath $Config.LogPath
                    Add-ToExistingArchive -FolderName $FolderName -Config $Config
                } else {
                    # Create new archive
                    Write-LogMessage -Message "Creating new archive: $archivePath" -Level 'Info' -LogPath $Config.LogPath
                    New-ArchiveOnly -FolderName $FolderName -Config $Config
                }
                
                # Clean up vis directory if using Archive2
                if ($Config.ArchiveTool -eq 'Archive2') {
                    Write-LogMessage -Message "Cleaning up vis directory (Archive2 mode)" -Level 'Info' -LogPath $Config.LogPath
                    Remove-Item -Path $visPath -Recurse -Force
                }
                
                Write-ProgressMessage -Activity "Adding Previs to Archive" -Status "Archive operations completed"
            }
        }
        catch {
            Write-LogMessage -Message "ERROR during previs archive process: $($_.Exception.Message)" -Level 'Error' -LogPath $Config.LogPath
            throw
        }
    }
    
    end {
        Write-LogMessage -Message "Completed previs archive process for folder: $FolderName" -Level 'Info' -LogPath $Config.LogPath
    }
}

function Add-ToExistingArchive {
    <#
    .SYNOPSIS
        Adds files to an existing archive
        
    .DESCRIPTION
        Internal function to handle merging files into an existing BA2 archive
        
    .PARAMETER FolderName
        The name of the folder to add to the archive
        
    .PARAMETER Config
        The PrevisbineConfig object containing tool paths and settings
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FolderName,
        
        [Parameter(Mandatory = $true)]
        [PrevisbineConfig]$Config
    )
    
    if ($Config.ArchiveTool -eq 'Archive2') {
        # Archive2 method - extract, add, repack
        Write-LogMessage -Message "Using Archive2 method for existing archive" -Level 'Info' -LogPath $Config.LogPath
        
        # Extract existing archive
        Expand-BA2Archive -Config $Config
        
        # Wait for extraction to complete
        Start-Sleep -Seconds 5
        
        # Delete the old archive
        $archivePath = Join-Path $Config.DataPath $Config.PluginArchive
        Remove-Item -Path $archivePath -Force
        
        # Check if we have precombined meshes
        $precombinedPath = Join-Path $Config.DataPath "meshes\precombined"
        if (Test-Path $precombinedPath) {
            $nifFiles = Get-ChildItem -Path $precombinedPath -Filter "*.nif" -Recurse
            if ($nifFiles.Count -gt 0) {
                # Archive both precombined and vis
                New-BA2Archive -Folders @("meshes\precombined", $FolderName) -Config $Config
                # Clean up precombined directory
                Remove-Item -Path (Join-Path $Config.DataPath "meshes\Precombined") -Recurse -Force
            } else {
                # Archive only vis
                New-BA2Archive -Folders @($FolderName) -Config $Config
            }
        } else {
            # Archive only vis
            New-BA2Archive -Folders @($FolderName) -Config $Config
        }
    } else {
        # BSArch method - extract to temp, merge, repack
        Write-LogMessage -Message "Using BSArch method for existing archive" -Level 'Info' -LogPath $Config.LogPath
        
        $tempPath = Join-Path $Config.DataPath "BSArchTemp"
        if (-not (Test-Path $tempPath)) {
            New-Item -Path $tempPath -ItemType Directory -Force | Out-Null
        }
        
        # Move folder to temp location
        $sourcePath = Join-Path $Config.DataPath $FolderName
        $destPath = Join-Path $tempPath $FolderName
        Move-Item -Path $sourcePath -Destination $destPath
        
        # Create archive with BSArch
        $archivePath = Join-Path $Config.DataPath $Config.PluginArchive
        $bsArchArgs = @('Pack', $tempPath, $archivePath, '-mt', '-fo4', '-z')
        
        Write-LogMessage -Message "Creating $($Config.Arch2Quals) Archive $($Config.PluginArchive) of meshes\precombined,$FolderName" -Level 'Info' -LogPath $Config.LogPath
        
        $result = Start-Process -FilePath $Config.BSArchPath -ArgumentList $bsArchArgs -WorkingDirectory $Config.DataPath -Wait -PassThru -RedirectStandardOutput $Config.LogPath -RedirectStandardError $Config.LogPath
        
        if ($result.ExitCode -ne 0) {
            # Restore files on failure
            Move-Item -Path $destPath -Destination $sourcePath
            Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
            throw "BSArch failed with error $($result.ExitCode)"
        }
        
        # Clean up temp directory
        Remove-Item -Path $tempPath -Recurse -Force
    }
}

function New-ArchiveOnly {
    <#
    .SYNOPSIS
        Creates a new archive with only the specified folder
        
    .DESCRIPTION
        Internal function to create a new BA2 archive containing only the specified folder
        
    .PARAMETER FolderName
        The name of the folder to archive
        
    .PARAMETER Config
        The PrevisbineConfig object containing tool paths and settings
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FolderName,
        
        [Parameter(Mandatory = $true)]
        [PrevisbineConfig]$Config
    )
    
    Write-LogMessage -Message "Creating new archive with folder: $FolderName" -Level 'Info' -LogPath $Config.LogPath
    New-BA2Archive -Folders @($FolderName) -Config $Config
}
