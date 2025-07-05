function Write-ProgressMessage {
    <#
    .SYNOPSIS
    Writes a progress message with optional logging.
    
    .DESCRIPTION
    Displays progress information using Write-Progress and optionally logs the message.
    
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
    
    .EXAMPLE
    Write-ProgressMessage -Activity "Processing" -Status "Starting..." -PercentComplete 10
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Activity,
        
        [Parameter(Mandatory = $true)]
        [string] $Status,
        
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 100)]
        [int] $PercentComplete,
        
        [Parameter()]
        [string] $LogPath,
        
        [Parameter()]
        [int] $Id = 0
    )
    
    # Display progress
    Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete -Id $Id
    
    # Log if path provided
    if ($LogPath) {
        $progressMessage = "$Activity - $Status ($PercentComplete%)"
        Write-LogMessage $progressMessage -Level Info -LogPath $LogPath
    }
}
