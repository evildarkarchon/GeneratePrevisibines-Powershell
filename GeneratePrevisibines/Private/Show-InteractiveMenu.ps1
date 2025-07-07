function Show-InteractiveMenu {
    <#
    .SYNOPSIS
    Shows an interactive menu for user choices.
    
    .DESCRIPTION
    Provides a PowerShell equivalent to the batch CHOICE command with customizable options.
    
    .PARAMETER Title
    The title of the menu.
    
    .PARAMETER Message
    The message to display to the user.
    
    .PARAMETER Options
    Array of option objects with Keys and Descriptions.
    
    .PARAMETER DefaultOption
    The default option key if user presses Enter.
    
    .PARAMETER CaseSensitive
    Whether the choices are case-sensitive.
    
    .EXAMPLE
    $options = @(
        @{Key='Y'; Description='Yes'},
        @{Key='N'; Description='No'}
    )
    $result = Show-InteractiveMenu -Title "Confirm Action" -Message "Do you want to continue?" -Options $options -DefaultOption 'Y'
    
    .EXAMPLE
    $stepOptions = @(
        @{Key='1'; Description='Generate Precombines Via CK'},
        @{Key='2'; Description='Merge PrecombineObjects.esp Via xEdit'},
        @{Key='3'; Description='Create BA2 Archive from Precombines'},
        @{Key='0'; Description='Exit'}
    )
    $step = Show-InteractiveMenu -Title "Restart Options" -Message "Restart at step" -Options $stepOptions
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Title,
        
        [Parameter(Mandatory = $true)]
        [string] $Message,
        
        [Parameter(Mandatory = $true)]
        [array] $Options,
        
        [Parameter()]
        [string] $DefaultOption,
        
        [Parameter()]
        [switch] $CaseSensitive
    )
    
    # Display menu header
    Write-Host ""
    Write-Host $Title -ForegroundColor Cyan
    Write-Host ("=" * $Title.Length) -ForegroundColor Cyan
    Write-Host ""
    
    # Display options
    foreach ($option in $Options) {
        $displayKey = if ($DefaultOption -eq $option.Key) { "[$($option.Key)]" } else { " $($option.Key) " }
        Write-Host "$displayKey $($option.Description)" -ForegroundColor White
    }
    
    Write-Host ""
    
    # Get valid keys
    $validKeys = $Options | ForEach-Object { $_.Key }
    
    # Prompt for choice
    do {
        $prompt = "$Message"
        if ($DefaultOption) {
            $prompt += " (default: $DefaultOption)"
        }
        $prompt += ": "
        
        $choice = Read-Host $prompt
        
        # Handle empty input (use default)
        if ([string]::IsNullOrWhiteSpace($choice) -and $DefaultOption) {
            $choice = $DefaultOption
        }
        
        # Check if choice is valid
        if ($CaseSensitive) {
            $isValid = $choice -in $validKeys
        }
        else {
            $isValid = $choice.ToUpper() -in ($validKeys | ForEach-Object { $_.ToUpper() })
            if ($isValid) {
                # Match the case from the original options
                $choice = $validKeys | Where-Object { $_.ToUpper() -eq $choice.ToUpper() }
            }
        }
        
        if (-not $isValid) {
            Write-Host "Invalid choice. Please select from: $($validKeys -join ', ')" -ForegroundColor Red
        }
    } while (-not $isValid)
    
    return $choice
}

function Show-StepSelectionMenu {
    <#
    .SYNOPSIS
    Shows the step selection menu for restarting from a failed step.
    
    .DESCRIPTION
    Displays the available steps for restarting the previsbine generation process.
    
    .PARAMETER BuildMode
    The build mode to determine which steps are available.
    
    .EXAMPLE
    $selectedStep = Show-StepSelectionMenu -BuildMode "Clean"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Clean', 'Filtered', 'Xbox')]
        [string] $BuildMode
    )
    
    $stepOptions = @(
        @{Key = '1'; Description = 'Generate Precombines Via CK' },
        @{Key = '2'; Description = 'Merge PrecombineObjects.esp Via xEdit' },
        @{Key = '3'; Description = 'Create BA2 Archive from Precombines' }
    )
    
    if ($BuildMode -eq 'Clean') {
        $stepOptions += @(
            @{Key = '4'; Description = 'Compress PSG Via CK' },
            @{Key = '5'; Description = 'Build CDX Via CK' }
        )
    }
    
    $stepOptions += @(
        @{Key = '6'; Description = 'Generate Previs Via CK' },
        @{Key = '7'; Description = 'Merge Previs.esp Via xEdit' },
        @{Key = '8'; Description = 'Add Previs files to BA2 Archive' },
        @{Key = '0'; Description = 'Exit' }
    )
    
    return Show-InteractiveMenu -Title "Step Selection" -Message "Restart at step (1-8 or 0 to exit)" -Options $stepOptions
}

function Show-PluginExistsMenu {
    <#
    .SYNOPSIS
    Shows the menu when a plugin already exists.
    
    .DESCRIPTION
    Displays options for handling an existing plugin file.
    
    .PARAMETER PluginName
    The name of the plugin that already exists.
    
    .EXAMPLE
    $action = Show-PluginExistsMenu -PluginName "MyMod.esp"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $PluginName
    )
    
    $options = @(
        @{Key = 'Y'; Description = 'Use existing plugin' },
        @{Key = 'N'; Description = 'Exit' },
        @{Key = 'C'; Description = 'Continue from failed step' }
    )
    
    return Show-InteractiveMenu -Title "Plugin Exists" -Message "Plugin '$PluginName' already exists. Use it?" -Options $options -DefaultOption 'Y'
}

function Show-ConfirmationMenu {
    <#
    .SYNOPSIS
    Shows a simple Yes/No confirmation menu.
    
    .DESCRIPTION
    Displays a Yes/No confirmation dialog with customizable message.
    
    .PARAMETER Message
    The confirmation message to display.
    
    .PARAMETER DefaultOption
    The default option (Y or N).
    
    .EXAMPLE
    $confirmed = Show-ConfirmationMenu -Message "Remove working files?" -DefaultOption 'Y'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Message,
        
        [Parameter()]
        [ValidateSet('Y', 'N')]
        [string] $DefaultOption = 'Y'
    )
    
    $options = @(
        @{Key = 'Y'; Description = 'Yes' },
        @{Key = 'N'; Description = 'No' }
    )
    
    $result = Show-InteractiveMenu -Title "Confirmation" -Message $Message -Options $options -DefaultOption $DefaultOption
    return $result -eq 'Y'
}

function Get-PluginNameInteractive {
    <#
    .SYNOPSIS
    Gets the plugin name from user input with validation.
    
    .DESCRIPTION
    Prompts the user for a plugin name with validation and reserved name checking.
    
    .PARAMETER BuildMode
    The build mode to determine validation rules.
    
    .EXAMPLE
    $pluginName = Get-PluginNameInteractive -BuildMode "Clean"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Clean', 'Filtered', 'Xbox')]
        [string] $BuildMode
    )
    
    Write-Host ""
    Write-Host "Plugin Name Input" -ForegroundColor Cyan
    Write-Host "=================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Specify the name to call your Previs Patch (If no extension then assumes .esp)" -ForegroundColor White
    Write-Host "If it does not exist then xPrevisPatch.esp will be renamed to it." -ForegroundColor White
    Write-Host ""
    
    $reservedNames = @('previs', 'combinedobjects', 'xprevispatch')
    
    do {
        $pluginName = Read-Host "Enter Patch Plugin name (return to exit)"
        
        # Check for exit
        if ([string]::IsNullOrWhiteSpace($pluginName)) {
            return $null
        }
        
        # Check for spaces (not allowed in clean mode)
        if ($BuildMode -eq 'Clean' -and $pluginName -match '\s') {
            Write-Host "ERROR - Plugin name cannot contain spaces in Clean mode. Please choose another." -ForegroundColor Red
            continue
        }
        
        # Extract plugin name without extension for validation
        $nameWithoutExt = $pluginName -replace '\.(esp|esm|esl)$', ''
        
        # Check for reserved names
        if ($nameWithoutExt.ToLower() -in $reservedNames) {
            Write-Host "ERROR - This plugin name is reserved. Please choose another." -ForegroundColor Red
            continue
        }
        
        # Add .esp extension if no extension provided
        if ($pluginName -notmatch '\.(esp|esm|esl)$') {
            $pluginName = "$pluginName.esp"
        }
        
        break
    } while ($true)
    
    return $pluginName
}

function Show-ErrorRecoveryMenu {
    <#
    .SYNOPSIS
    Shows an error recovery menu when a step fails in interactive mode.
    
    .DESCRIPTION
    Displays recovery options when a processing step fails, allowing users to retry,
    skip to the next step, restart from a different step, or exit.
    
    .PARAMETER ErrorMessage
    The error message from the failed step.
    
    .PARAMETER FailedStep
    The step number that failed.
    
    .PARAMETER BuildMode
    The current build mode to determine available restart steps.
    
    .EXAMPLE
    $recovery = Show-ErrorRecoveryMenu -ErrorMessage "Creation Kit failed" -FailedStep 1 -BuildMode "Clean"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $ErrorMessage,
        
        [Parameter(Mandatory = $true)]
        [int] $FailedStep,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet('Clean', 'Filtered', 'Xbox')]
        [string] $BuildMode
    )
    
    Write-Host ""
    Write-Host "Error Recovery Options" -ForegroundColor Red
    Write-Host "Step $FailedStep failed with error: $ErrorMessage" -ForegroundColor Red
    Write-Host ""
    
    $recoveryOptions = @(
        @{Key = '1'; Description = 'View detailed error information' },
        @{Key = '2'; Description = 'Retry this step' },
        @{Key = '3'; Description = 'Skip to next step (if possible)' },
        @{Key = '4'; Description = 'Restart from a different step' },
        @{Key = '5'; Description = 'Exit and review logs' }
    )
    
    $choice = Show-InteractiveMenu -Title "Error Recovery" -Message "Choose recovery option" -Options $recoveryOptions -DefaultOption '5'
    
    switch ($choice) {
        '1' {
            Write-Host ""
            Write-Host "Detailed Error Information:" -ForegroundColor Yellow
            Write-Host "  Failed Step: $FailedStep" -ForegroundColor White
            Write-Host "  Error: $ErrorMessage" -ForegroundColor White
            Write-Host "  Build Mode: $BuildMode" -ForegroundColor White
            Write-Host ""
            
            # Show the menu again after displaying details
            return Show-ErrorRecoveryMenu -ErrorMessage $ErrorMessage -FailedStep $FailedStep -BuildMode $BuildMode
        }
        '2' {
            return 'Retry'
        }
        '3' {
            # Check if skipping is possible
            $canSkip = $FailedStep -in @(3, 5)  # Archive creation and final assembly can be skipped
            if ($canSkip) {
                $confirmSkip = Show-ConfirmationMenu -Message "Are you sure you want to skip this step? This may result in incomplete output." -DefaultOption 'N'
                if ($confirmSkip) {
                    return 'Skip'
                }
                else {
                    return Show-ErrorRecoveryMenu -ErrorMessage $ErrorMessage -FailedStep $FailedStep -BuildMode $BuildMode
                }
            }
            else {
                Write-Host ""
                Write-Host "This step cannot be skipped as it is required for the process to continue." -ForegroundColor Red
                Write-Host ""
                return Show-ErrorRecoveryMenu -ErrorMessage $ErrorMessage -FailedStep $FailedStep -BuildMode $BuildMode
            }
        }
        '4' {
            $restartStep = Show-StepSelectionMenu -BuildMode $BuildMode
            if ($restartStep -ne '0') {
                return "Restart:$restartStep"
            }
            else {
                return 'Exit'
            }
        }
        '5' {
            return 'Exit'
        }
    }
}
