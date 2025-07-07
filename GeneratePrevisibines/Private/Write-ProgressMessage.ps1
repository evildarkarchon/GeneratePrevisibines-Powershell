function Write-ProgressMessage {
    <#
    .SYNOPSIS
    Writes a progress message with optional logging and colored output.
    
    .DESCRIPTION
    Displays progress information using Write-Progress and optionally logs the message.
    Supports colored console output and step-based progress tracking.
    
    .PARAMETER Activity
    The activity description.
    
    .PARAMETER Status
    The current status.
    
    .PARAMETER PercentComplete
    The percentage complete (0-100).
    
    .PARAMETER LogPath
    Optional path to log the progress message.
    
    .PARAMETER Id
    The progress ID for nested progress bars.
    
    .PARAMETER CurrentStep
    The current step number (for step-based progress).
    
    .PARAMETER TotalSteps
    The total number of steps (for step-based progress).
    
    .PARAMETER Color
    The color for console output.
    
    .PARAMETER ShowConsole
    Whether to show colored console output in addition to progress bar.
    
    .EXAMPLE
    Write-ProgressMessage -Activity "Processing" -Status "Starting..." -PercentComplete 10
    
    .EXAMPLE
    Write-ProgressMessage -Activity "Phase 1" -Status "Generating precombines" -CurrentStep 1 -TotalSteps 8 -Color Green -ShowConsole
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Activity,
        
        [Parameter(Mandatory = $true)]
        [string] $Status,
        
        [Parameter()]
        [ValidateRange(0, 100)]
        [int] $PercentComplete,
        
        [Parameter()]
        [string] $LogPath,
        
        [Parameter()]
        [int] $Id = 0,
        
        [Parameter()]
        [int] $CurrentStep,
        
        [Parameter()]
        [int] $TotalSteps,
        
        [Parameter()]
        [ValidateSet('Black', 'DarkBlue', 'DarkGreen', 'DarkCyan', 'DarkRed', 'DarkMagenta', 'DarkYellow', 'Gray', 'DarkGray', 'Blue', 'Green', 'Cyan', 'Red', 'Magenta', 'Yellow', 'White')]
        [string] $Color = 'White',
        
        [Parameter()]
        [switch] $ShowConsole
    )
    
    # Calculate percentage from steps if provided
    if ($CurrentStep -and $TotalSteps -and -not $PSBoundParameters.ContainsKey('PercentComplete')) {
        $PercentComplete = [int](($CurrentStep / $TotalSteps) * 100)
    }
    
    # Default to 0 if no percentage provided
    if (-not $PSBoundParameters.ContainsKey('PercentComplete')) {
        $PercentComplete = 0
    }
    
    # Create progress message
    $progressStatus = $Status
    if ($CurrentStep -and $TotalSteps) {
        $progressStatus = "Step $CurrentStep of $TotalSteps - $Status"
    }
    
    # Display progress bar
    Write-Progress -Activity $Activity -Status $progressStatus -PercentComplete $PercentComplete -Id $Id
    
    # Show console output if requested
    if ($ShowConsole) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $consoleMessage = "[$timestamp] $Activity - $Status"
        
        if ($CurrentStep -and $TotalSteps) {
            $consoleMessage = "[$timestamp] Step $CurrentStep/$TotalSteps - $Activity - $Status"
        }
        
        Write-Host $consoleMessage -ForegroundColor $Color
    }
    
    # Log if path provided
    if ($LogPath) {
        $logMessage = "$Activity - $Status"
        if ($CurrentStep -and $TotalSteps) {
            $logMessage = "Step $CurrentStep/$TotalSteps - $Activity - $Status"
        }
        Write-LogMessage $logMessage -Level Info -LogPath $LogPath
    }
}

function Write-StepProgress {
    <#
    .SYNOPSIS
    Writes step-based progress with standardized formatting.
    
    .DESCRIPTION
    Displays progress for multi-step processes with consistent formatting and logging.
    
    .PARAMETER StepNumber
    The current step number.
    
    .PARAMETER TotalSteps
    The total number of steps.
    
    .PARAMETER StepName
    The name of the current step.
    
    .PARAMETER Status
    The current status within the step.
    
    .PARAMETER LogPath
    Optional path to log the progress message.
    
    .EXAMPLE
    Write-StepProgress -StepNumber 3 -TotalSteps 8 -StepName "Archive Creation" -Status "Building BA2 archive"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int] $StepNumber,
        
        [Parameter(Mandatory = $true)]
        [int] $TotalSteps,
        
        [Parameter(Mandatory = $true)]
        [string] $StepName,
        
        [Parameter(Mandatory = $true)]
        [string] $Status,
        
        [Parameter()]
        [string] $LogPath
    )
    
    $activity = "Previsbine Generation"
    $stepStatus = "Step $StepNumber: $StepName - $Status"
    $percentComplete = [int](($StepNumber / $TotalSteps) * 100)
    
    Write-Progress -Activity $activity -Status $stepStatus -PercentComplete $percentComplete
    
    # Also show in console with color
    Write-Host "[$StepNumber/$TotalSteps] $StepName - $Status" -ForegroundColor Cyan
    
    # Log if path provided
    if ($LogPath) {
        Write-LogMessage "Step $StepNumber/$TotalSteps - $StepName - $Status" -Level Info -LogPath $LogPath
    }
}
        $progressMessage = "$Activity - $Status ($PercentComplete%)"
        Write-LogMessage $progressMessage -Level Info -LogPath $LogPath
    }
}
