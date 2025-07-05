enum LogLevel {
    Debug = 0
    Info = 1
    Warning = 2
    Error = 3
    Critical = 4
}

function Write-LogMessage {
    <#
    .SYNOPSIS
    Writes a log message with specified level and formatting.
    
    .DESCRIPTION
    Provides centralized logging functionality for the GeneratePrevisibines module.
    Supports multiple log levels, file output, and console output with colors.
    
    .PARAMETER Message
    The message to log.
    
    .PARAMETER Level
    The log level (Debug, Info, Warning, Error, Critical).
    
    .PARAMETER LogPath
    Path to the log file. If not specified, logs to console only.
    
    .PARAMETER NoConsole
    Suppress console output.
    
    .PARAMETER NoTimestamp
    Suppress timestamp in log output.
    
    .EXAMPLE
    Write-LogMessage "Starting precombine generation" -Level Info
    
    .EXAMPLE
    Write-LogMessage "Failed to find Creation Kit" -Level Error -LogPath "C:\Logs\previsbine.log"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Message,
        
        [Parameter()]
        [LogLevel] $Level = [LogLevel]::Info,
        
        [Parameter()]
        [string] $LogPath,
        
        [Parameter()]
        [switch] $NoConsole,
        
        [Parameter()]
        [switch] $NoTimestamp
    )
    
    # Create timestamp
    $timestamp = if ($NoTimestamp) { "" } else { "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] " }
    
    # Create level prefix
    $levelPrefix = switch ($Level) {
        ([LogLevel]::Debug) { "[DEBUG] " }
        ([LogLevel]::Info) { "[INFO] " }
        ([LogLevel]::Warning) { "[WARN] " }
        ([LogLevel]::Error) { "[ERROR] " }
        ([LogLevel]::Critical) { "[CRITICAL] " }
    }
    
    # Format the complete message
    $formattedMessage = "$timestamp$levelPrefix$Message"
    
    # Write to console if not suppressed
    if (-not $NoConsole) {
        $consoleColor = switch ($Level) {
            ([LogLevel]::Debug) { 'Gray' }
            ([LogLevel]::Info) { 'White' }
            ([LogLevel]::Warning) { 'Yellow' }
            ([LogLevel]::Error) { 'Red' }
            ([LogLevel]::Critical) { 'Magenta' }
        }
        
        Write-Host $formattedMessage -ForegroundColor $consoleColor
    }
    
    # Write to file if path is specified
    if ($LogPath) {
        try {
            # Ensure log directory exists
            $logDir = Split-Path -Path $LogPath -Parent
            if (-not (Test-Path $logDir)) {
                New-Item -Path $logDir -ItemType Directory -Force | Out-Null
            }
            
            # Append to log file
            $formattedMessage | Out-File -FilePath $LogPath -Append -Encoding UTF8
        }
        catch {
            Write-Warning "Failed to write to log file '$LogPath': $_"
        }
    }
}

function Start-LogSession {
    <#
    .SYNOPSIS
    Starts a new log session with header information.
    
    .DESCRIPTION
    Creates a new log session with system information and module version.
    
    .PARAMETER LogPath
    Path to the log file.
    
    .PARAMETER SessionName
    Name of the session (defaults to 'GeneratePrevisibines').
    
    .EXAMPLE
    Start-LogSession -LogPath "C:\Logs\previsbine.log" -SessionName "Precombine Generation"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $LogPath,
        
        [Parameter()]
        [string] $SessionName = "GeneratePrevisibines"
    )
    
    $separator = "=" * 60
    $moduleVersion = (Get-Module GeneratePrevisibines).Version
    
    Write-LogMessage $separator -Level Info -LogPath $LogPath -NoConsole
    Write-LogMessage "SESSION START: $SessionName" -Level Info -LogPath $LogPath -NoConsole
    Write-LogMessage "Module Version: $moduleVersion" -Level Info -LogPath $LogPath -NoConsole
    Write-LogMessage "PowerShell Version: $($PSVersionTable.PSVersion)" -Level Info -LogPath $LogPath -NoConsole
    Write-LogMessage "OS: $($PSVersionTable.OS)" -Level Info -LogPath $LogPath -NoConsole
    Write-LogMessage "User: $($env:USERNAME)" -Level Info -LogPath $LogPath -NoConsole
    Write-LogMessage "Computer: $($env:COMPUTERNAME)" -Level Info -LogPath $LogPath -NoConsole
    Write-LogMessage $separator -Level Info -LogPath $LogPath -NoConsole
}

function Stop-LogSession {
    <#
    .SYNOPSIS
    Ends the current log session.
    
    .DESCRIPTION
    Writes session end information to the log.
    
    .PARAMETER LogPath
    Path to the log file.
    
    .PARAMETER SessionName
    Name of the session (defaults to 'GeneratePrevisibines').
    
    .EXAMPLE
    Stop-LogSession -LogPath "C:\Logs\previsbine.log"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $LogPath,
        
        [Parameter()]
        [string] $SessionName = "GeneratePrevisibines"
    )
    
    $separator = "=" * 60
    
    Write-LogMessage $separator -Level Info -LogPath $LogPath -NoConsole
    Write-LogMessage "SESSION END: $SessionName" -Level Info -LogPath $LogPath -NoConsole
    Write-LogMessage $separator -Level Info -LogPath $LogPath -NoConsole
}

function Write-ProgressMessage {
    <#
    .SYNOPSIS
    Writes a progress message with optional progress bar.
    
    .DESCRIPTION
    Combines logging with progress bar display for long-running operations.
    
    .PARAMETER Activity
    The activity being performed.
    
    .PARAMETER Status
    The current status message.
    
    .PARAMETER PercentComplete
    The percentage complete (0-100).
    
    .PARAMETER LogPath
    Path to the log file.
    
    .PARAMETER LogLevel
    Log level for the message.
    
    .EXAMPLE
    Write-ProgressMessage -Activity "Generating Precombines" -Status "Processing plugins..." -PercentComplete 25
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $Activity,
        
        [Parameter(Mandatory = $true)]
        [string] $Status,
        
        [Parameter()]
        [int] $PercentComplete = -1,
        
        [Parameter()]
        [string] $LogPath,
        
        [Parameter()]
        [LogLevel] $LogLevel = [LogLevel]::Info
    )
    
    # Write to log
    if ($LogPath) {
        Write-LogMessage "$Activity - $Status" -Level $LogLevel -LogPath $LogPath -NoConsole
    }
    
    # Show progress bar
    if ($PercentComplete -ge 0) {
        Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete
    }
    else {
        Write-Progress -Activity $Activity -Status $Status
    }
}
