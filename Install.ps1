#!/usr/bin/env pwsh
<#
.SYNOPSIS
Installation script for GeneratePrevisibines PowerShell module.

.DESCRIPTION
This script installs the GeneratePrevisibines module to the user's PowerShell modules directory,
making it available for import. It handles version checking, backup of existing versions,
and verification of the installation.

.PARAMETER InstallPath
Custom installation path. If not specified, uses the standard user modules directory.

.PARAMETER Force
Force installation even if a newer version exists.

.PARAMETER WhatIf
Show what would be done without actually installing.

.EXAMPLE
./Install.ps1

.EXAMPLE
./Install.ps1 -InstallPath "C:\CustomModules" -Force

.NOTES
Requires PowerShell 5.1 or later.
Run with administrator privileges for system-wide installation.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [string] $InstallPath,
    
    [Parameter()]
    [switch] $Force,
    
    [Parameter()]
    [switch] $AllUsers
)

# Check PowerShell version
if ($PSVersionTable.PSVersion -lt [Version]'5.1') {
    Write-Error "This module requires PowerShell 5.1 or later. Current version: $($PSVersionTable.PSVersion)"
    exit 1
}

# Get script directory (where module files are located)
$ScriptRoot = $PSScriptRoot
$ModuleSourcePath = Join-Path $ScriptRoot "GeneratePrevisibines"

# Validate source module exists
if (-not (Test-Path $ModuleSourcePath)) {
    Write-Error "Module source not found at: $ModuleSourcePath"
    exit 1
}

# Validate module manifest
$ManifestPath = Join-Path $ModuleSourcePath "GeneratePrevisibines.psd1"
try {
    $ModuleInfo = Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop
    Write-Host "Installing GeneratePrevisibines v$($ModuleInfo.Version)..." -ForegroundColor Green
}
catch {
    Write-Error "Invalid module manifest: $_"
    exit 1
}

# Determine installation path
if (-not $InstallPath) {
    if ($AllUsers) {
        $InstallPath = "$env:ProgramFiles\PowerShell\Modules"
        if (-not (Test-Path $InstallPath)) {
            $InstallPath = "$env:ProgramFiles\WindowsPowerShell\Modules"
        }
    }
    else {
        $InstallPath = "$env:USERPROFILE\Documents\PowerShell\Modules"
        if (-not (Test-Path (Split-Path $InstallPath))) {
            $InstallPath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules"
        }
    }
}

$ModuleDestPath = Join-Path $InstallPath "GeneratePrevisibines"
$VersionDestPath = Join-Path $ModuleDestPath $ModuleInfo.Version

Write-Host "Installation path: $VersionDestPath" -ForegroundColor Cyan

# Check if module is already installed
if (Test-Path $ModuleDestPath) {
    $ExistingVersions = Get-ChildItem $ModuleDestPath -Directory | Where-Object { $_.Name -match '^\d+\.\d+\.\d+' }
    
    if ($ExistingVersions) {
        $LatestVersion = $ExistingVersions | Sort-Object { [Version]$_.Name } | Select-Object -Last 1
        Write-Host "Found existing version: $($LatestVersion.Name)" -ForegroundColor Yellow
        
        if ([Version]$LatestVersion.Name -ge $ModuleInfo.Version -and -not $Force) {
            Write-Warning "A newer or equal version ($($LatestVersion.Name)) is already installed."
            Write-Host "Use -Force to override or uninstall the existing version first."
            return
        }
    }
}

# Create installation directory
if ($PSCmdlet.ShouldProcess($VersionDestPath, "Create module directory")) {
    try {
        if (-not (Test-Path $VersionDestPath)) {
            New-Item -Path $VersionDestPath -ItemType Directory -Force | Out-Null
            Write-Host "Created directory: $VersionDestPath" -ForegroundColor Green
        }
    }
    catch {
        Write-Error "Failed to create installation directory: $_"
        exit 1
    }
}

# Copy module files
if ($PSCmdlet.ShouldProcess($ModuleSourcePath, "Copy module files")) {
    try {
        $FilesToCopy = @(
            "GeneratePrevisibines.psd1",
            "GeneratePrevisibines.psm1",
            "Classes",
            "Private", 
            "Public",
            "en-US"
        )
        
        foreach ($Item in $FilesToCopy) {
            $SourceItem = Join-Path $ModuleSourcePath $Item
            $DestItem = Join-Path $VersionDestPath $Item
            
            if (Test-Path $SourceItem) {
                if (Test-Path $DestItem) {
                    Remove-Item $DestItem -Recurse -Force
                }
                
                if ((Get-Item $SourceItem).PSIsContainer) {
                    Copy-Item $SourceItem $DestItem -Recurse -Force
                }
                else {
                    Copy-Item $SourceItem $DestItem -Force
                }
                
                Write-Verbose "Copied: $Item"
            }
        }
        
        Write-Host "Module files copied successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to copy module files: $_"
        exit 1
    }
}

# Verify installation
if ($PSCmdlet.ShouldProcess("GeneratePrevisibines", "Verify installation")) {
    try {
        # Test the installed module
        $InstalledManifest = Join-Path $VersionDestPath "GeneratePrevisibines.psd1"
        $TestResult = Test-ModuleManifest -Path $InstalledManifest -ErrorAction Stop
        
        Write-Host "`nInstallation completed successfully!" -ForegroundColor Green
        Write-Host "Module: GeneratePrevisibines v$($TestResult.Version)" -ForegroundColor White
        Write-Host "Location: $VersionDestPath" -ForegroundColor White
        
        # Try to import the module
        Write-Host "`nTesting module import..." -ForegroundColor Cyan
        Import-Module GeneratePrevisibines -Force -ErrorAction Stop
        
        $LoadedModule = Get-Module GeneratePrevisibines
        Write-Host "Module imported successfully: v$($LoadedModule.Version)" -ForegroundColor Green
        
        Write-Host "`nYou can now use: Import-Module GeneratePrevisibines" -ForegroundColor Yellow
        Write-Host "To get started: Get-Help Start-PrevisbineGeneration -Examples" -ForegroundColor Yellow
    }
    catch {
        Write-Warning "Installation completed but verification failed: $_"
        Write-Host "The module may still work correctly. Try importing it manually." -ForegroundColor Yellow
    }
}

Write-Host "`nInstallation complete!" -ForegroundColor Green