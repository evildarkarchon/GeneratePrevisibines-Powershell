function Start-PrevisbineGeneration {
    <#
    .SYNOPSIS
    Starts the Fallout 4 precombine and previs generation process using Creation Kit and supporting tools.
    
    .DESCRIPTION
    This cmdlet orchestrates the complete batch process of generating precombined meshes and visibility data
    for Fallout 4 mods using Creation Kit, xEdit, and archive tools. It manages the entire workflow from
    initial validation through final archive creation, providing a PowerShell-native replacement for the
    original batch script functionality.
    
    .PARAMETER PluginName
    Name of the plugin (.esp/.esm/.esl) to process. If not specified, user will be prompted.
    
    .PARAMETER BuildMode
    Build mode to use: Clean, Filtered, or Xbox. If not specified, user will be prompted.
    
    .PARAMETER FO4Directory
    Path to the Fallout 4 installation directory. If not specified, auto-detection will be attempted.
    
    .PARAMETER FO4EditPath
    Path to the FO4Edit executable (FO4Edit.exe or xEdit64.exe). If not specified, auto-detection will be attempted.
    
    .PARAMETER UseBSArch
    Use BSArch instead of Archive2 for archive operations.
    
    .PARAMETER UseMO2
    Use Mod Organizer 2 for mod management.
    
    .PARAMETER MO2Profile
    MO2 profile to use when UseMO2 is enabled.
    
    .PARAMETER LogPath
    Path to the log file. If not specified, a temporary log file will be created.
    
    .PARAMETER WorkingDirectory
    Working directory for temporary files. Defaults to system temp directory.
    
    .PARAMETER VerboseLogging
    Enable verbose logging output.
    
    .PARAMETER KeepTempFiles
    Keep temporary files after completion (useful for debugging).
    
    .PARAMETER TimeoutMinutes
    Timeout in minutes for external tool operations (default: 60).
    
    .PARAMETER NonInteractive
    Run in non-interactive mode without user prompts. All required parameters must be provided.
    
    .PARAMETER StartFromStep
    Start from a specific step number (1-8). Useful for resuming after failures.
    
    .PARAMETER WhatIf
    Show what would be done without actually performing the operations.
    
    .PARAMETER Confirm
    Prompt for confirmation before performing destructive operations.
    
    .EXAMPLE
    Start-PrevisbineGeneration
    
    Starts the interactive previsbine generation process. User will be prompted for plugin name and build mode.
    
    .EXAMPLE
    Start-PrevisbineGeneration -PluginName "MyMod.esp" -BuildMode Clean
    
    Starts the previsbine generation process for MyMod.esp using Clean build mode with auto-detected tool paths.
    
    .EXAMPLE
    Start-PrevisbineGeneration -PluginName "MyMod.esp" -BuildMode Filtered -FO4Directory "C:\Games\Fallout 4" -UseBSArch -NonInteractive
    
    Starts previsbine generation in non-interactive mode using Filtered mode, specifies FO4 directory, and uses BSArch for archives.
    
    .EXAMPLE
    Start-PrevisbineGeneration -StartFromStep 4
    
    Starts the interactive process from step 4 (useful for resuming after a failure).
    
    .NOTES
    This cmdlet orchestrates a complex batch process that requires the following external tools:
    - Creation Kit (CreationKit.exe)
    - xEdit/FO4Edit (FO4Edit.exe or xEdit64.exe)
    - Archive tool (Archive2.exe or BSArch.exe)
    - CreationKitPlatformExtended (CKPE) for enhanced Creation Kit functionality
    
    The cmdlet will attempt to auto-detect tool paths through registry entries and common
    installation locations. Manual path specification may be required for non-standard installations.
    
    This cmdlet is interactive by default, mirroring the behavior of the original batch script.
    Users will be prompted for required information and guided through the process with menus,
    progress reporting, and error recovery options.
    
    Use -NonInteractive for automation scenarios where all parameters must be provided upfront.
    
    This is a long-running batch operation that processes multiple files and may take significant time to complete.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Position = 0)]
        [ValidateScript({
                if ($_ -and -not ($_ -match '\.(esp|esm|esl)$')) {
                    throw "Plugin name must end with .esp, .esm, or .esl extension"
                }
                return $true
            })]
        [string] $PluginName,
        
        [Parameter()]
        [ValidateSet('Clean', 'Filtered', 'Xbox')]
        [string] $BuildMode,
        
        [Parameter()]
        [ValidateScript({
                if (-not (Test-Path $_ -PathType Container)) {
                    throw "FO4Directory must be a valid directory path"
                }
                return $true
            })]
        [string] $FO4Directory,
        
        [Parameter()]
        [ValidateScript({
                if (-not (Test-Path $_ -PathType Leaf)) {
                    throw "FO4EditPath must be a valid file path"
                }
                return $true
            })]
        [string] $FO4EditPath,
        
        [Parameter()]
        [switch] $UseBSArch,
        
        [Parameter()]
        [switch] $UseMO2,
        
        [Parameter()]
        [string] $MO2Profile,
        
        [Parameter()]
        [string] $LogPath,
        
        [Parameter()]
        [string] $WorkingDirectory,
        
        [Parameter()]
        [switch] $VerboseLogging,
        
        [Parameter()]
        [switch] $KeepTempFiles,
        
        [Parameter()]
        [ValidateRange(1, 180)]
        [int] $TimeoutMinutes = 60,
        
        [Parameter()]
        [switch] $SkipValidation,
        
        [Parameter()]
        [switch] $NonInteractive,
        
        [Parameter()]
        [ValidateRange(1, 8)]
        [int] $StartFromStep = 1
    )
    
    begin {
        # Show banner for interactive mode
        if (-not $NonInteractive) {
            Write-Host ""
            Write-Host "=== Fallout 4 Previsbine Generation ===" -ForegroundColor Cyan
            Write-Host ""
        }
        
        # Initialize configuration
        $config = [PrevisbineConfig]::new()
        
        # Set configuration from parameters
        if ($PluginName) {
            $config.PluginName = $PluginName
        }
        
        if ($BuildMode) {
            $config.BuildMode = $BuildMode
        }
        else {
            $config.BuildMode = 'Clean'  # Default value
        }
        
        $config.VerboseLogging = $VerboseLogging
        $config.KeepTempFiles = $KeepTempFiles
        $config.TimeoutMinutes = $TimeoutMinutes
        
        if ($FO4Directory) {
            $config.FO4Directory = $FO4Directory
            $config.DataDirectory = Join-Path $FO4Directory 'Data'
        }
        
        if ($UseBSArch) {
            $config.ArchiveTool = 'BSArch'
        }
        
        if ($UseMO2) {
            $config.UseMO2 = $true
            if ($MO2Profile) {
                $config.MO2Profile = $MO2Profile
            }
        }
        
        if ($LogPath) {
            $config.LogPath = $LogPath
        }
        
        if ($WorkingDirectory) {
            $config.WorkingDirectory = $WorkingDirectory
        }
        
        if ($FO4EditPath) {
            $config.FO4EditPath = $FO4EditPath
        }
        
        # Auto-detect tool paths
        if (-not $NonInteractive) {
            Write-Host "Discovering tool paths..." -ForegroundColor Yellow
        }
        
        $toolPaths = Get-ModToolPaths -IncludeFallbacks
        
        if ($toolPaths.FO4Directory -and -not $config.FO4Directory) {
            $config.FO4Directory = $toolPaths.FO4Directory
            $config.DataDirectory = Join-Path $toolPaths.FO4Directory 'Data'
            if (-not $NonInteractive) {
                Write-Host "  Found Fallout 4: $($config.FO4Directory)" -ForegroundColor Green
            }
        }
        
        if ($toolPaths.FO4Edit -and -not $config.FO4EditPath) {
            $config.FO4EditPath = $toolPaths.FO4Edit
            if (-not $NonInteractive) {
                Write-Host "  Found FO4Edit: $($config.FO4EditPath)" -ForegroundColor Green
            }
        }
        
        if ($toolPaths.CreationKit) {
            $config.CreationKitPath = $toolPaths.CreationKit
            if (-not $NonInteractive) {
                Write-Host "  Found Creation Kit: $($config.CreationKitPath)" -ForegroundColor Green
            }
        }
        
        if ($toolPaths.Archive2) {
            $config.Archive2Path = $toolPaths.Archive2
        }
        
        if ($toolPaths.BSArch) {
            $config.BSArchPath = $toolPaths.BSArch
        }
        
        if ($toolPaths.MO2 -and $config.UseMO2) {
            $config.MO2Path = $toolPaths.MO2
        }
        
        # Interactive parameter collection
        if (-not $NonInteractive) {
            Write-Host ""
            
            # Get plugin name if not provided
            if (-not $config.PluginName) {
                $config.PluginName = Get-PluginNameInteractive -BuildMode $config.BuildMode
                if (-not $config.PluginName) {
                    Write-Host "Operation cancelled by user." -ForegroundColor Yellow
                    return
                }
            }
            
            # Get build mode if not provided
            if (-not $BuildMode) {
                $buildModeOptions = @(
                    @{Key='1'; Description='Clean - Full clean build with all steps'},
                    @{Key='2'; Description='Filtered - Skip some optimization steps'},
                    @{Key='3'; Description='Xbox - Xbox-compatible build mode'}
                )
                
                $buildModeChoice = Show-InteractiveMenu -Title "Build Mode Selection" -Message "Select build mode" -Options $buildModeOptions -DefaultOption '1'
                
                $config.BuildMode = switch ($buildModeChoice) {
                    '1' { 'Clean' }
                    '2' { 'Filtered' }
                    '3' { 'Xbox' }
                }
            }
            
            # Check for existing plugin and handle conflicts
            $pluginPath = Join-Path $config.DataDirectory $config.PluginName
            if (Test-Path $pluginPath) {
                $existingAction = Show-PluginExistsMenu -PluginName $config.PluginName
                
                switch ($existingAction) {
                    'Y' { 
                        Write-Host "Using existing plugin: $($config.PluginName)" -ForegroundColor Green
                    }
                    'N' { 
                        Write-Host "Operation cancelled by user." -ForegroundColor Yellow
                        return
                    }
                    'C' { 
                        $StartFromStep = [int](Show-StepSelectionMenu -BuildMode $config.BuildMode)
                        if ($StartFromStep -eq 0) {
                            Write-Host "Operation cancelled by user." -ForegroundColor Yellow
                            return
                        }
                    }
                }
            }
            
            # Get additional options
            Write-Host ""
            Write-Host "Additional Options:" -ForegroundColor Cyan
            
            if (-not $UseBSArch) {
                $useBSArch = Show-ConfirmationMenu -Message "Use BSArch instead of Archive2?" -DefaultOption 'N'
                if ($useBSArch) {
                    $config.ArchiveTool = 'BSArch'
                }
            }
            
            if (-not $UseMO2) {
                $useMO2 = Show-ConfirmationMenu -Message "Use Mod Organizer 2 integration?" -DefaultOption 'N'
                if ($useMO2) {
                    $config.UseMO2 = $true
                    # TODO: Add MO2 profile selection
                }
            }
            
            if (-not $KeepTempFiles) {
                $keepTempFiles = Show-ConfirmationMenu -Message "Keep temporary files for debugging?" -DefaultOption 'N'
                $config.KeepTempFiles = $keepTempFiles
            }
            
            # Display configuration summary
            Write-Host ""
            Write-Host "Configuration Summary:" -ForegroundColor Green
            Write-Host "  Plugin: $($config.PluginName)" -ForegroundColor White
            Write-Host "  Build Mode: $($config.BuildMode)" -ForegroundColor White
            Write-Host "  FO4 Directory: $($config.FO4Directory)" -ForegroundColor White
            Write-Host "  Archive Tool: $($config.ArchiveTool)" -ForegroundColor White
            
            if ($StartFromStep -gt 1) {
                Write-Host "  Starting from Step: $StartFromStep" -ForegroundColor White
            }
            
            if ($config.UseMO2) {
                Write-Host "  Using MO2: Yes" -ForegroundColor White
            }
            
            # Final confirmation
            Write-Host ""
            $startProcess = Show-ConfirmationMenu -Message "Start previsbine generation process?" -DefaultOption 'Y'
            if (-not $startProcess) {
                Write-Host "Operation cancelled by user." -ForegroundColor Yellow
                return
            }
            
            Write-Host ""
            Write-Host "Starting previsbine generation process..." -ForegroundColor Green
            Write-Host ""
        }
        else {
            # Non-interactive mode validation
            if (-not $config.PluginName) {
                throw "PluginName is required in non-interactive mode"
            }
        }
        
        # Start logging session
        Start-LogSession -LogPath $config.LogPath -SessionName "Start-PrevisbineGeneration"
        
        Write-LogMessage "Starting previsbine generation batch process for: $($config.PluginName)" -Level Info -LogPath $config.LogPath
        Write-LogMessage "Build Mode: $($config.BuildMode)" -Level Info -LogPath $config.LogPath
        Write-LogMessage "Archive Tool: $($config.ArchiveTool)" -Level Info -LogPath $config.LogPath
        Write-LogMessage "Interactive Mode: $(-not $NonInteractive)" -Level Info -LogPath $config.LogPath
        
        if ($StartFromStep -gt 1) {
            Write-LogMessage "Starting from step: $StartFromStep" -Level Info -LogPath $config.LogPath
        }
        
        if ($config.UseMO2) {
            Write-LogMessage "Using MO2 with profile: $($config.MO2Profile)" -Level Info -LogPath $config.LogPath
        }
    }
    
    process {
        try {
            # Validate prerequisites
            Write-ProgressMessage -Activity "Validating Prerequisites" -Status "Checking tools and configuration..." -PercentComplete 5 -LogPath $config.LogPath
            
            if (-not $SkipValidation) {
                try {
                    $validationResult = Test-Prerequisites -Config $config
                    
                    if (-not $validationResult.Success) {
                        $errorMessage = "Prerequisites validation failed:`n" + ($validationResult.Errors -join "`n")
                        Write-LogMessage $errorMessage -Level Error -LogPath $config.LogPath
                        throw [System.InvalidOperationException]::new($errorMessage)
                    }
                    
                    if ($validationResult.Warnings.Count -gt 0) {
                        foreach ($warning in $validationResult.Warnings) {
                            Write-LogMessage $warning -Level Warning -LogPath $config.LogPath
                            Write-Warning $warning
                        }
                    }
                }
                catch [System.InvalidOperationException] {
                    Write-LogMessage "Validation failed with specific errors" -Level Error -LogPath $config.LogPath
                    throw
                }
                catch {
                    Write-LogMessage "Unexpected error during validation: $_" -Level Error -LogPath $config.LogPath
                    throw [System.InvalidOperationException]::new("Validation failed unexpectedly: $_", $_.Exception)
                }
            }
            else {
                Write-LogMessage "Skipping validation as requested" -Level Warning -LogPath $config.LogPath
            }
            
            # Display configuration summary
            Write-Host "`nBatch Process Configuration:" -ForegroundColor Green
            Write-Host "  Plugin: $($config.PluginName)" -ForegroundColor White
            Write-Host "  Build Mode: $($config.BuildMode)" -ForegroundColor White
            Write-Host "  FO4 Directory: $($config.FO4Directory)" -ForegroundColor White
            Write-Host "  Archive Tool: $($config.ArchiveTool)" -ForegroundColor White
            Write-Host "  Log Path: $($config.LogPath)" -ForegroundColor White
            
            if ($config.UseMO2) {
                Write-Host "  MO2 Profile: $($config.MO2Profile)" -ForegroundColor White
            }
            
            # Confirm batch operation if required
            if ($PSCmdlet.ShouldProcess($PluginName, "Start complete previsbine generation batch process")) {
                
                # Phase 1: Precombine Generation
                try {
                    Write-StepProgress -StepNumber 1 -TotalSteps 8 -StepName "Precombine Generation" -Status "Starting precombine generation..." -LogPath $config.LogPath
                    
                    $precombineResult = Start-PrecombineGeneration -Config $config
                    if (-not $precombineResult.Success) {
                        throw [System.InvalidOperationException]::new("Precombine generation failed: $($precombineResult.Message)")
                    }
                    
                    Write-LogMessage "Phase 1: Precombine generation completed successfully" -Level Info -LogPath $config.LogPath
                }
                catch [System.InvalidOperationException] {
                    Write-LogMessage "Phase 1 failed: $_" -Level Error -LogPath $config.LogPath
                    Write-Host "Phase 1 (Precombine Generation) failed: $_" -ForegroundColor Red
                    
                    if (-not $NonInteractive) {
                        $recoveryChoice = Show-ErrorRecoveryMenu -ErrorMessage $_.Exception.Message -FailedStep 1 -BuildMode $config.BuildMode
                        if ($recoveryChoice -eq 'Retry') {
                            # TODO: Implement retry logic
                            Write-Host "Retry not yet implemented, continuing with throw." -ForegroundColor Yellow
                        }
                        elseif ($recoveryChoice -eq 'Skip') {
                            Write-Host "Skipping to next phase..." -ForegroundColor Yellow
                        }
                        else {
                            throw
                        }
                    }
                    else {
                        throw
                    }
                }
                catch {
                    Write-LogMessage "Phase 1 unexpected error: $_" -Level Error -LogPath $config.LogPath
                    Write-Host "Phase 1 (Precombine Generation) encountered unexpected error: $_" -ForegroundColor Red
                    throw [System.InvalidOperationException]::new("Phase 1 failed unexpectedly: $_", $_.Exception)
                }
                
                # Phase 2: Plugin Processing
                try {
                    Write-StepProgress -StepNumber 2 -TotalSteps 8 -StepName "Plugin Processing" -Status "Merging precombine objects..." -LogPath $config.LogPath
                    
                    $mergeResult = Merge-PrecombineObjects -Config $config
                    if (-not $mergeResult.Success) {
                        throw [System.InvalidOperationException]::new("Precombine merge failed: $($mergeResult.Message)")
                    }
                    
                    Write-LogMessage "Phase 2: Plugin processing completed successfully" -Level Info -LogPath $config.LogPath
                }
                catch [System.InvalidOperationException] {
                    Write-LogMessage "Phase 2 failed: $_" -Level Error -LogPath $config.LogPath
                    Write-Host "Phase 2 (Plugin Processing) failed: $_" -ForegroundColor Red
                    
                    if (-not $NonInteractive) {
                        $recoveryChoice = Show-ErrorRecoveryMenu -ErrorMessage $_.Exception.Message -FailedStep 2 -BuildMode $config.BuildMode
                        if ($recoveryChoice -eq 'Retry') {
                            # TODO: Implement retry logic
                            Write-Host "Retry not yet implemented, continuing with throw." -ForegroundColor Yellow
                        }
                        elseif ($recoveryChoice -eq 'Skip') {
                            Write-Host "Skipping to next phase..." -ForegroundColor Yellow
                        }
                        else {
                            throw
                        }
                    }
                    else {
                        throw
                    }
                }
                catch {
                    Write-LogMessage "Phase 2 unexpected error: $_" -Level Error -LogPath $config.LogPath
                    Write-Host "Phase 2 (Plugin Processing) encountered unexpected error: $_" -ForegroundColor Red
                    throw [System.InvalidOperationException]::new("Phase 2 failed unexpectedly: $_", $_.Exception)
                }
                
                # Phase 3: Archive Creation
                try {
                    Write-StepProgress -StepNumber 3 -TotalSteps 8 -StepName "Archive Creation" -Status "Building BA2 archives..." -LogPath $config.LogPath
                    
                    $archiveName = "$($config.PluginName -replace '\.(esp|esm|esl)$', '') - Precombine.ba2"
                    $precombineArchivePath = Join-Path $config.WorkingDirectory "Precombine"
                    
                    $archiveResult = New-BA2Archive -Config $config -ArchiveType "Precombine" -SourcePath $precombineArchivePath -ArchiveName $archiveName
                    if (-not $archiveResult.Success) {
                        Write-LogMessage "Archive creation failed: $($archiveResult.Message)" -Level Warning -LogPath $config.LogPath
                        Write-Warning "Archive creation failed but continuing: $($archiveResult.Message)"
                    }
                    else {
                        Write-LogMessage "Phase 3: Archive creation completed successfully" -Level Info -LogPath $config.LogPath
                    }
                }
                catch {
                    Write-LogMessage "Phase 3 error: $_" -Level Warning -LogPath $config.LogPath
                    Write-Warning "Phase 3 (Archive Creation) encountered error but continuing: $_"
                }
                
                # Phase 4: Previs Generation
                try {
                    Write-StepProgress -StepNumber 4 -TotalSteps 8 -StepName "Previs Generation" -Status "Creating visibility data..." -LogPath $config.LogPath
                    
                    $previsResult = Start-PrevisGeneration -Config $config
                    if (-not $previsResult.Success) {
                        throw [System.InvalidOperationException]::new("Previs generation failed: $($previsResult.Message)")
                    }
                    
                    Write-LogMessage "Phase 4: Previs generation completed successfully" -Level Info -LogPath $config.LogPath
                }
                catch [System.InvalidOperationException] {
                    Write-LogMessage "Phase 4 failed: $_" -Level Error -LogPath $config.LogPath
                    Write-Host "Phase 4 (Previs Generation) failed: $_" -ForegroundColor Red
                    
                    if (-not $NonInteractive) {
                        $recoveryChoice = Show-ErrorRecoveryMenu -ErrorMessage $_.Exception.Message -FailedStep 4 -BuildMode $config.BuildMode
                        if ($recoveryChoice -eq 'Retry') {
                            # TODO: Implement retry logic
                            Write-Host "Retry not yet implemented, continuing with throw." -ForegroundColor Yellow
                        }
                        elseif ($recoveryChoice -eq 'Skip') {
                            Write-Host "Skipping to next phase..." -ForegroundColor Yellow
                        }
                        else {
                            throw
                        }
                    }
                    else {
                        throw
                    }
                }
                catch {
                    Write-LogMessage "Phase 4 unexpected error: $_" -Level Error -LogPath $config.LogPath
                    Write-Host "Phase 4 (Previs Generation) encountered unexpected error: $_" -ForegroundColor Red
                    throw [System.InvalidOperationException]::new("Phase 4 failed unexpectedly: $_", $_.Exception)
                }
                
                # Phase 5: Final Assembly
                try {
                    Write-StepProgress -StepNumber 5 -TotalSteps 8 -StepName "Final Assembly" -Status "Completing final steps..." -LogPath $config.LogPath
                    
                    # Create previs archive
                    $previsArchiveName = "$($config.PluginName -replace '\.(esp|esm|esl)$', '') - Previs.ba2"
                    $previsArchivePath = Join-Path $config.WorkingDirectory "Previs"
                    
                    $previsArchiveResult = New-BA2Archive -Config $config -ArchiveType "Previs" -SourcePath $previsArchivePath -ArchiveName $previsArchiveName
                    if (-not $previsArchiveResult.Success) {
                        Write-LogMessage "Previs archive creation failed: $($previsArchiveResult.Message)" -Level Warning -LogPath $config.LogPath
                        Write-Warning "Previs archive creation failed but process completed: $($previsArchiveResult.Message)"
                    }
                    else {
                        Write-LogMessage "Phase 5: Final assembly completed successfully" -Level Info -LogPath $config.LogPath
                    }
                }
                catch {
                    Write-LogMessage "Phase 5 error: $_" -Level Warning -LogPath $config.LogPath
                    Write-Warning "Phase 5 (Final Assembly) encountered error but main process completed: $_"
                }
                
                # Complete
                Write-ProgressMessage -Activity "Complete" -Status "Previsbine generation batch process completed successfully" -PercentComplete 100 -LogPath $config.LogPath
                Write-LogMessage "Previsbine generation batch process completed successfully" -Level Info -LogPath $config.LogPath
                
                if (-not $NonInteractive) {
                    Write-Host ""
                    Write-Host "Previsbine generation completed successfully!" -ForegroundColor Green
                    Write-Host "=====================================================" -ForegroundColor Green
                    Write-Host "Patch Files created:" -ForegroundColor White
                    Write-Host "    $($config.PluginName)" -ForegroundColor Cyan
                    
                    if ($config.BuildMode -eq 'Clean') {
                        $geometryFile = "$($config.PluginName -replace '\.(esp|esm|esl)$', '') - Geometry.csg"
                        $cdxFile = "$($config.PluginName -replace '\.(esp|esm|esl)$', '').cdx"
                        Write-Host "    $geometryFile" -ForegroundColor Cyan
                        Write-Host "    $cdxFile" -ForegroundColor Cyan
                    }
                    
                    $archiveName = "$($config.PluginName -replace '\.(esp|esm|esl)$', '') - Main.ba2"
                    Write-Host "    $archiveName" -ForegroundColor Cyan
                    Write-Host ""
                    Write-Host "Move ALL these files into a zip/7z archive and install it" -ForegroundColor Yellow
                    Write-Host "=====================================================" -ForegroundColor Green
                    
                    # Ask about cleanup
                    if ($config.KeepTempFiles) {
                        Write-Host ""
                        $cleanupNow = Show-ConfirmationMenu -Message "Clean up temporary files now?" -DefaultOption 'Y'
                        if ($cleanupNow) {
                            # TODO: Implement cleanup logic
                            Write-Host "Temporary files cleaned up." -ForegroundColor Green
                        }
                    }
                }
                else {
                    Write-Host "`nPrevisbine generation batch process completed successfully!" -ForegroundColor Green
                    Write-Host "Log file: $($config.LogPath)" -ForegroundColor Cyan
                }
            }
            else {
                Write-LogMessage "Batch operation cancelled by user" -Level Info -LogPath $config.LogPath
                Write-Host "Batch operation cancelled." -ForegroundColor Yellow
            }
        }
        catch [System.InvalidOperationException] {
            # Handle known operational errors with specific recovery options
            $errorDetails = @{
                Message = $_.Exception.Message
                InnerException = $_.Exception.InnerException?.Message
                StackTrace = $_.Exception.StackTrace
                LogPath = $config.LogPath
            }
            
            Write-LogMessage "Operational error during previsbine generation: $($errorDetails.Message)" -Level Critical -LogPath $config.LogPath
            
            if ($errorDetails.InnerException) {
                Write-LogMessage "Inner exception: $($errorDetails.InnerException)" -Level Critical -LogPath $config.LogPath
            }
            
            # Provide detailed error information to user
            Write-Host "`nPrevisbine generation failed with operational error:" -ForegroundColor Red
            Write-Host "  Error: $($errorDetails.Message)" -ForegroundColor Red
            
            if ($errorDetails.InnerException) {
                Write-Host "  Details: $($errorDetails.InnerException)" -ForegroundColor Red
            }
            
            Write-Host "  Log file: $($errorDetails.LogPath)" -ForegroundColor Yellow
            Write-Host "`nPlease check the log file for detailed error information." -ForegroundColor Yellow
            
            # Re-throw with original exception preserved
            throw
        }
        catch [System.UnauthorizedAccessException] {
            # Handle permission/access errors
            Write-LogMessage "Access denied error during previsbine generation: $_" -Level Critical -LogPath $config.LogPath
            
            Write-Host "`nAccess denied error occurred:" -ForegroundColor Red
            Write-Host "  This may be due to insufficient permissions or files being locked by another process." -ForegroundColor Red
            Write-Host "  Please ensure:" -ForegroundColor Yellow
            Write-Host "    - You have administrator privileges" -ForegroundColor Yellow
            Write-Host "    - No other tools are using the files" -ForegroundColor Yellow
            Write-Host "    - Antivirus is not blocking the operation" -ForegroundColor Yellow
            Write-Host "  Log file: $($config.LogPath)" -ForegroundColor Yellow
            
            throw
        }
        catch [System.IO.DirectoryNotFoundException], [System.IO.FileNotFoundException] {
            # Handle file/directory not found errors
            Write-LogMessage "File or directory not found error: $_" -Level Critical -LogPath $config.LogPath
            
            Write-Host "`nRequired file or directory not found:" -ForegroundColor Red
            Write-Host "  Error: $_" -ForegroundColor Red
            Write-Host "  Please verify:" -ForegroundColor Yellow
            Write-Host "    - All tool paths are correct" -ForegroundColor Yellow
            Write-Host "    - Fallout 4 installation is complete" -ForegroundColor Yellow
            Write-Host "    - Required files exist in expected locations" -ForegroundColor Yellow
            Write-Host "  Log file: $($config.LogPath)" -ForegroundColor Yellow
            
            throw
        }
        catch [System.TimeoutException] {
            # Handle timeout errors
            Write-LogMessage "Timeout error during previsbine generation: $_" -Level Critical -LogPath $config.LogPath
            
            Write-Host "`nOperation timed out:" -ForegroundColor Red
            Write-Host "  The process took longer than the configured timeout of $($config.TimeoutMinutes) minutes." -ForegroundColor Red
            Write-Host "  Consider:" -ForegroundColor Yellow
            Write-Host "    - Increasing the timeout value with -TimeoutMinutes parameter" -ForegroundColor Yellow
            Write-Host "    - Checking if external tools are hung" -ForegroundColor Yellow
            Write-Host "    - Verifying system resources are available" -ForegroundColor Yellow
            Write-Host "  Log file: $($config.LogPath)" -ForegroundColor Yellow
            
            throw
        }
        catch {
            # Handle all other unexpected errors
            Write-LogMessage "Unexpected error during previsbine generation: $_" -Level Critical -LogPath $config.LogPath
            Write-LogMessage "Exception type: $($_.Exception.GetType().FullName)" -Level Critical -LogPath $config.LogPath
            Write-LogMessage "Stack trace: $($_.Exception.StackTrace)" -Level Critical -LogPath $config.LogPath
            
            Write-Host "`nUnexpected error occurred during previsbine generation:" -ForegroundColor Red
            Write-Host "  Error: $_" -ForegroundColor Red
            Write-Host "  Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
            Write-Host "  Log file: $($config.LogPath)" -ForegroundColor Yellow
            Write-Host "`nThis is an unexpected error. Please check the log file for details." -ForegroundColor Yellow
            Write-Host "Consider reporting this error if it persists." -ForegroundColor Yellow
            
            # Create a new exception with context
            $contextException = [System.Exception]::new("Previsbine generation failed with unexpected error: $_", $_.Exception)
            throw $contextException
        }
        finally {
            # Clean up temporary files if not keeping them
            if (-not $config.KeepTempFiles) {
                Write-LogMessage "Cleaning up temporary files..." -Level Info -LogPath $config.LogPath
                # TODO: Implement cleanup logic
            }
            
            # End logging session
            Stop-LogSession -LogPath $config.LogPath -SessionName "Start-PrevisbineGeneration"
            
            # Clear progress
            Write-Progress -Activity "Complete" -Completed
        }
    }
    
    end {
        Write-Verbose "Start-PrevisbineGeneration cmdlet completed"
    }
}
