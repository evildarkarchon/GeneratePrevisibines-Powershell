#!/usr/bin/env pwsh
<#
.SYNOPSIS
Standalone script for generating Fallout 4 precombines and previs data.

.DESCRIPTION
This is a standalone script version of the GeneratePrevisibines PowerShell module.
It provides the same functionality as the module but can be run directly without installation.

The script will automatically detect if the GeneratePrevisibines module is installed and use it,
or fall back to the bundled module version included in this distribution.

.PARAMETER PluginName
Name of the plugin (.esp/.esm/.esl) to process. If not specified, user will be prompted.

.PARAMETER BuildMode
Build mode to use: Clean, Filtered, or Xbox. If not specified, user will be prompted.

.PARAMETER FO4Directory
Path to the Fallout 4 installation directory. If not specified, auto-detection will be attempted.

.PARAMETER FO4EditPath
Path to the FO4Edit executable. If not specified, auto-detection will be attempted.

.PARAMETER UseBSArch
Use BSArch instead of Archive2 for archive operations.

.PARAMETER UseMO2
Use Mod Organizer 2 for mod management.

.PARAMETER MO2Profile
MO2 profile to use when UseMO2 is enabled.

.PARAMETER NonInteractive
Run in non-interactive mode without user prompts.

.PARAMETER LogPath
Path to the log file. If not specified, a temporary log file will be created.

.PARAMETER VerboseLogging
Enable verbose logging output.

.PARAMETER KeepTempFiles
Keep temporary files after completion (useful for debugging).

.PARAMETER TimeoutMinutes
Timeout in minutes for external tool operations (default: 60).

.PARAMETER StartFromStep
Start from a specific step number (1-8). Useful for resuming after failures.

.PARAMETER WhatIf
Show what would be done without actually performing the operations.

.PARAMETER Confirm
Prompt for confirmation before performing destructive operations.

.EXAMPLE
./GeneratePrevisibines.ps1

Starts the interactive previsbine generation process.

.EXAMPLE
./GeneratePrevisibines.ps1 -PluginName "MyMod.esp" -BuildMode Clean -NonInteractive

Runs the script in non-interactive mode for MyMod.esp with Clean build mode.

.EXAMPLE
./GeneratePrevisibines.ps1 -PluginName "MyMod.esp" -BuildMode Filtered -UseBSArch -VerboseLogging

Runs with Filtered mode, BSArch archiver, and verbose logging.

.NOTES
This script is part of the GeneratePrevisibines PowerShell project - a modern PowerShell
replacement for the original batch script that automates Fallout 4 precombine and previs
generation using Creation Kit, xEdit, and archive tools.

The script requires the following external tools:
- Creation Kit (CreationKit.exe)
- xEdit/FO4Edit (FO4Edit.exe or xEdit64.exe)
- Archive tool (Archive2.exe or BSArch.exe)
- CreationKitPlatformExtended (CKPE) for enhanced Creation Kit functionality

For more information, see the bundled GeneratePrevisibines module documentation.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
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
    [string] $FO4Directory,
    
    [Parameter()]
    [string] $FO4EditPath,
    
    [Parameter()]
    [switch] $UseBSArch,
    
    [Parameter()]
    [switch] $UseMO2,
    
    [Parameter()]
    [string] $MO2Profile,
    
    [Parameter()]
    [switch] $NonInteractive,
    
    [Parameter()]
    [string] $LogPath,
    
    [Parameter()]
    [switch] $VerboseLogging,
    
    [Parameter()]
    [switch] $KeepTempFiles,
    
    [Parameter()]
    [ValidateRange(1, 180)]
    [int] $TimeoutMinutes = 60,
    
    [Parameter()]
    [ValidateRange(1, 8)]
    [int] $StartFromStep = 1,
    
    [Parameter()]
    [switch] $SkipValidation
)

# Script header
Write-Host ""
Write-Host "=== GeneratePrevisibines PowerShell Script ===" -ForegroundColor Green
Write-Host "Standalone script for Fallout 4 precombine and previs generation" -ForegroundColor Cyan
Write-Host ""

# Get script directory
$ScriptRoot = $PSScriptRoot
$ModulePath = Join-Path $ScriptRoot "GeneratePrevisibines"

# Check PowerShell version
if ($PSVersionTable.PSVersion -lt [Version]'5.1') {
    Write-Error "This script requires PowerShell 5.1 or later. Current version: $($PSVersionTable.PSVersion)"
    exit 1
}

# Function to check if module is already loaded/available
function Test-ModuleAvailability {
    param([string]$ModuleName)
    
    # Check if module is already loaded
    if (Get-Module -Name $ModuleName -ErrorAction SilentlyContinue) {
        return @{
            Available = $true
            Source = "Loaded"
            Path = (Get-Module -Name $ModuleName).Path
        }
    }
    
    # Check if module is available for import
    if (Get-Module -Name $ModuleName -ListAvailable -ErrorAction SilentlyContinue) {
        return @{
            Available = $true
            Source = "Available"
            Path = (Get-Module -Name $ModuleName -ListAvailable | Select-Object -First 1).Path
        }
    }
    
    return @{
        Available = $false
        Source = "NotFound"
        Path = $null
    }
}

# Function to import bundled module
function Import-BundledModule {
    param([string]$ModulePath)
    
    try {
        if (-not (Test-Path $ModulePath)) {
            throw "Bundled module not found at: $ModulePath"
        }
        
        $manifestPath = Join-Path $ModulePath "GeneratePrevisibines.psd1"
        if (-not (Test-Path $manifestPath)) {
            throw "Module manifest not found at: $manifestPath"
        }
        
        Write-Host "Loading bundled GeneratePrevisibines module..." -ForegroundColor Yellow
        Import-Module $manifestPath -Force -ErrorAction Stop
        
        $loadedModule = Get-Module -Name "GeneratePrevisibines"
        Write-Host "Successfully loaded bundled module v$($loadedModule.Version)" -ForegroundColor Green
        
        return $true
    }
    catch {
        Write-Error "Failed to load bundled module: $_"
        return $false
    }
}

# Try to determine the best module source
Write-Host "Checking for GeneratePrevisibines module..." -ForegroundColor Yellow

$moduleStatus = Test-ModuleAvailability -ModuleName "GeneratePrevisibines"

if ($moduleStatus.Available) {
    Write-Host "Found installed GeneratePrevisibines module: $($moduleStatus.Source)" -ForegroundColor Green
    Write-Host "Module path: $($moduleStatus.Path)" -ForegroundColor Cyan
    
    try {
        if ($moduleStatus.Source -eq "Available") {
            Import-Module GeneratePrevisibines -Force -ErrorAction Stop
        }
        
        $loadedModule = Get-Module -Name "GeneratePrevisibines"
        Write-Host "Using installed module v$($loadedModule.Version)" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to use installed module: $_"
        Write-Host "Falling back to bundled module..." -ForegroundColor Yellow
        
        if (-not (Import-BundledModule -ModulePath $ModulePath)) {
            Write-Error "Failed to load both installed and bundled modules."
            exit 1
        }
    }
}
else {
    Write-Host "No installed GeneratePrevisibines module found" -ForegroundColor Yellow
    Write-Host "Using bundled module..." -ForegroundColor Yellow
    
    if (-not (Import-BundledModule -ModulePath $ModulePath)) {
        Write-Error "Failed to load bundled module. Please ensure the GeneratePrevisibines module directory is present alongside this script."
        exit 1
    }
}

# Verify the module is loaded and has the required function
try {
    $command = Get-Command -Name "Start-PrevisbineGeneration" -ErrorAction Stop
    Write-Host "Successfully verified Start-PrevisbineGeneration command" -ForegroundColor Green
}
catch {
    Write-Error "Failed to find Start-PrevisbineGeneration command. Module may not be loaded correctly."
    exit 1
}

# Build parameter hashtable for splatting
$params = @{}

if ($PluginName) { $params['PluginName'] = $PluginName }
if ($BuildMode) { $params['BuildMode'] = $BuildMode }
if ($FO4Directory) { $params['FO4Directory'] = $FO4Directory }
if ($FO4EditPath) { $params['FO4EditPath'] = $FO4EditPath }
if ($UseBSArch) { $params['UseBSArch'] = $UseBSArch }
if ($UseMO2) { $params['UseMO2'] = $UseMO2 }
if ($MO2Profile) { $params['MO2Profile'] = $MO2Profile }
if ($NonInteractive) { $params['NonInteractive'] = $NonInteractive }
if ($LogPath) { $params['LogPath'] = $LogPath }
if ($VerboseLogging) { $params['VerboseLogging'] = $VerboseLogging }
if ($KeepTempFiles) { $params['KeepTempFiles'] = $KeepTempFiles }
if ($TimeoutMinutes -ne 60) { $params['TimeoutMinutes'] = $TimeoutMinutes }
if ($StartFromStep -ne 1) { $params['StartFromStep'] = $StartFromStep }
if ($SkipValidation) { $params['SkipValidation'] = $SkipValidation }
if ($WhatIf) { $params['WhatIf'] = $WhatIf }
if ($Confirm) { $params['Confirm'] = $Confirm }

# Show transition message
Write-Host ""
Write-Host "Starting GeneratePrevisibines module..." -ForegroundColor Green
Write-Host "----------------------------------------" -ForegroundColor Cyan

# Execute the main function
try {
    Start-PrevisbineGeneration @params
}
catch {
    Write-Host ""
    Write-Host "Script execution failed:" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    
    if ($_.Exception.InnerException) {
        Write-Host "Details: $($_.Exception.InnerException.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "For more information, check the log file or run with -VerboseLogging" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Script completed successfully!" -ForegroundColor Green