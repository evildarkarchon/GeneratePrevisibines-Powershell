<#
.SYNOPSIS
    PowerShell procedure to build precombine/Previs for Fallout 4 mods.
.DESCRIPTION
    Builds precombine/Previs using prompted Plugin "Seed" (or xPrevisPatch.esp)
    Call with optional parameter (clean, filtered or xbox) to change the build mode. Clean is default.
    Otherwise if called with modname.esp then that mod will get new Previsbines (doesn't prompt for mod or pause on completion).
    If run from xEdit directory then that version of xEdit64.exe/FO4Edit64.exe will be used.
.NOTES
    Author: PJM (Original batch version V2.5 Feb 2025)
    PowerShell conversion: March 2025
#>

param (
    [Parameter(Position = 0)]
    [string]$BuildModeOrPlugin = "clean"
)

# Run the main function
Start-PrevisbineBuilder

# Global variables
$script:FO4Edit = ""
$script:locCreationKit = ""
$script:CK = "CreationKit.exe"
$script:CreationKitlog = ""
$script:Archive = ""
$script:CKPEini = "CreationKitPlatformExtended.ini"
$script:CKPEHandleSetting = "bBSPointerHandleExtremly"
$script:CKPELogSetting = "sOutputFile"
$script:UnattenedLogfile = ""

$script:NoPrompt = $false
$script:BuildMode = "clean"
$script:PluginName = ""
$script:PluginNameExt = ""
$script:PluginArchive = ""
$script:Logfile = ""
$script:PluginPath = ""

# Main script execution
function Start-PrevisbineBuilder {
    # Initialize environment and check requirements
    if (-not (Initialize-Environment)) {
        if (-not $script:NoPrompt) {
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        return
    }

    # Process parameters
    if (-not (Invoke-Parameters)) {
        if (-not $script:NoPrompt) {
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        return
    }

    # Check if plugin exists and handle accordingly
    if (-not (Test-PluginExists)) {
        if (-not $script:NoPrompt) {
            Write-Host "Press any key to continue..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        return
    }

    # Start precombine process
    Start-Precombines

    # Restore any disabled DLLs at the end
    Restore-DisabledDlls
}

# Functions for each processing step
function Start-Precombines {
    # Check if precombine directory has files
    $precombDir = Join-Path $script:locCreationKit "Data\meshes\precombined"
    if ((Test-Path $precombDir) -and (Get-ChildItem -Path $precombDir -Filter "*.nif" -Recurse)) {
        if ($script:NoPrompt) {
            Write-Host "ERROR - Precombine directory (Data\meshes\precombined) not empty" -ForegroundColor Red
            return $false
        }

        $choices = @(
            [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Clean directory")
            [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Exit")
        )

        $decision = $Host.UI.PromptForChoice("", "Precombine directory (Data\meshes\precombined) needs to be empty. Clean it? [Y/N]", $choices, 0)

        if ($decision -eq 0) {
            Remove-Item -Path $precombDir -Recurse -Force
        }
        else {
            return $false
        }
    }

    # Check if archive exists
    $pluginArchivePath = Join-Path $script:locCreationKit "Data\$($script:PluginArchive)"
    if (Test-Path $pluginArchivePath) {
        Write-Host "ERROR - This Plugin already has an Archive" -ForegroundColor Red
        return $false
    }

    # Check if previs directory has files
    $previsDir = Join-Path $script:locCreationKit "Data\vis"
    if ((Test-Path $previsDir) -and (Get-ChildItem -Path $previsDir -Filter "*.uvd" -Recurse)) {
        Write-Host "ERROR - Previs directory (Data\vis) not empty" -ForegroundColor Red
        return $false
    }

    # Clean up any existing files
    $combinedObjectsPath = Join-Path $script:locCreationKit "Data\CombinedObjects.esp"
    if (Test-Path $combinedObjectsPath) {
        Remove-Item -Path $combinedObjectsPath -Force
    }

    $geometryPsgPath = Join-Path $script:locCreationKit "Data\$($script:PluginName) - Geometry.psg"
    if (Test-Path $geometryPsgPath) {
        Remove-Item -Path $geometryPsgPath -Force
    }

    if (Test-Path $script:Logfile) {
        Remove-Item -Path $script:Logfile -Force
    }

    # Run CK to generate precombines
    if ($script:BuildMode -eq "clean") {
        if (-not (Invoke-CK -Option "GeneratePrecombined" -OutputFile "CombinedObjects.esp" -Qualifiers "clean all")) {
            return $false
        }

        if (-not (Test-Path $geometryPsgPath)) {
            Write-Host "ERROR - GeneratePrecombined failed to create psg file" -ForegroundColor Red
            return $false
        }
    }
    else {
        if (-not (Invoke-CK -Option "GeneratePrecombined" -OutputFile "CombinedObjects.esp" -Qualifiers "filtered all")) {
            return $false
        }
    }

    # Check for precombined meshes
    if (-not ((Test-Path $precombDir) -and (Get-ChildItem -Path $precombDir -Filter "*.nif" -Recurse))) {
        Write-Host "ERROR - GeneratePrecombined failed to create any Precombines" -ForegroundColor Red
        return $false
    }

    # Check for handle array errors
    if ((Test-Path $script:CreationKitlog) -and (Select-String -Path $script:CreationKitlog -Pattern "DEFAULT: OUT OF HANDLE ARRAY ENTRIES" -Quiet)) {
        Write-Host "ERROR - GeneratePrecombined ran out of Reference Handles" -ForegroundColor Red
        return $false
    }

    return Start-PrecombMerge
}

function Start-PrecombMerge {
    # Check for precombined meshes
    $precombDir = Join-Path $script:locCreationKit "Data\meshes\precombined"
    if (-not ((Test-Path $precombDir) -and (Get-ChildItem -Path $precombDir -Filter "*.nif" -Recurse))) {
        Write-Host "ERROR - No Precombined meshes found" -ForegroundColor Red
        return $false
    }

    # Run FO4Edit script to merge CombinedObjects.esp into the plugin
    if (-not (Invoke-Script -ScriptName "Batch_FO4MergeCombinedObjectsAndCheck.pas" -Plugin1 $script:PluginNameExt -Plugin2 "CombinedObjects.esp")) {
        return $false
    }

    # Check for errors in log
    if ((Test-Path $script:UnattenedLogfile) -and (Select-String -Path $script:UnattenedLogfile -Pattern "Error: " -Quiet)) {
        Write-Host "WARNING - Merge Precombines had errors" -ForegroundColor Yellow
    }

    return Start-ArchivePrecomb
}

function Start-ArchivePrecomb {
    # Check for precombined meshes
    $precombDir = Join-Path $script:locCreationKit "Data\meshes\precombined"
    if (-not ((Test-Path $precombDir) -and (Get-ChildItem -Path $precombDir -Filter "*.nif" -Recurse))) {
        return Start-CompressPSG
    }

    # Archive precombines
    if (-not (Invoke-Archive -Path "meshes\precombined")) {
        return $false
    }

    # Remove the precombined directory
    Remove-Item -Path $precombDir -Recurse -Force -ErrorAction SilentlyContinue

    return Start-CompressPSG
}

function Start-CompressPSG {
    # Only compress PSG in clean mode
    if ($script:BuildMode -ne "clean") {
        return Start-BuildCDX
    }

    $geometryPsgPath = Join-Path $script:locCreationKit "Data\$($script:PluginName) - Geometry.psg"
    if (-not (Test-Path $geometryPsgPath)) {
        Write-Host "ERROR - No Geometry file to Compress" -ForegroundColor Red
        return $false
    }

    # Run CK to compress PSG
    if (-not (Invoke-CK -Option "CompressPSG" -OutputFile "$($script:PluginName) - Geometry.csg" -Qualifiers "")) {
        return $false
    }

    # Remove the original PSG file
    Remove-Item -Path $geometryPsgPath -Force -ErrorAction SilentlyContinue

    return Start-BuildCDX
}

function Start-BuildCDX {
    # Only build CDX in clean mode
    if ($script:BuildMode -ne "clean") {
        return Start-Previs
    }

    # Run CK to build CDX
    if (-not (Invoke-CK -Option "BuildCDX" -OutputFile "$($script:PluginName).cdx" -Qualifiers "")) {
        return $false
    }

    return Start-Previs
}

function Start-Previs {
    # Check if previs directory has files
    $previsDir = Join-Path $script:locCreationKit "Data\vis"
    if ((Test-Path $previsDir) -and (Get-ChildItem -Path $previsDir -Filter "*.uvd" -Recurse)) {
        if ($script:NoPrompt) {
            Write-Host "ERROR - Previs directory (Data\vis) not empty" -ForegroundColor Red
            return $false
        }

        $choices = @(
            [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Clean directory")
            [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Exit")
        )

        $decision = $Host.UI.PromptForChoice("", "Previs directory (Data\vis) needs to be empty. Clean it? [Y/N]", $choices, 0)

        if ($decision -eq 0) {
            Remove-Item -Path $previsDir -Recurse -Force
        }
        else {
            return $false
        }
    }

    # Clean up any existing Previs.esp
    $previsEspPath = Join-Path $script:locCreationKit "Data\Previs.esp"
    if (Test-Path $previsEspPath) {
        Remove-Item -Path $previsEspPath -Force
    }

    # Run CK to generate previs data
    if (-not (Invoke-CK -Option "GeneratePreVisData" -OutputFile "Previs.esp" -Qualifiers "clean all")) {
        return $false
    }

    # Check for visibility task errors
    if ((Test-Path $script:CreationKitlog) -and (Select-String -Path $script:CreationKitlog -Pattern "ERROR: visibility task did not complete." -Quiet)) {
        Write-Host "WARNING - GeneratePreVisData failed to build at least one Cluster uvd" -ForegroundColor Yellow
    }

    return Start-PrevisMerge
}

function Start-PrevisMerge {
    # Check for vis files
    $previsDir = Join-Path $script:locCreationKit "Data\vis"
    if (-not ((Test-Path $previsDir) -and (Get-ChildItem -Path $previsDir -Filter "*.uvd" -Recurse))) {
        Write-Host "ERROR - No Visibility files Generated" -ForegroundColor Red
        return $false
    }

    # Check for Previs.esp
    $previsEspPath = Join-Path $script:locCreationKit "Data\Previs.esp"
    if (-not (Test-Path $previsEspPath)) {
        Write-Host "ERROR - No Previs.esp Generated" -ForegroundColor Red
        return $false
    }

    # Run FO4Edit script to merge Previs.esp into the plugin
    if (-not (Invoke-Script -ScriptName "Batch_FO4MergePrevisandCleanRefr.pas" -Plugin1 $script:PluginNameExt -Plugin2 "Previs.esp")) {
        return $false
    }

    # Check for errors in log
    if ((Test-Path $script:UnattenedLogfile) -and -not (Select-String -Path $script:UnattenedLogfile -Pattern "Completed: No Errors." -Quiet)) {
        Write-Host "WARNING - Merge Previs had errors" -ForegroundColor Yellow
    }

    return Start-FinalArchive
}

function Start-FinalArchive {
    # Check for vis files
    $previsDir = Join-Path $script:locCreationKit "Data\vis"
    if (-not ((Test-Path $previsDir) -and (Get-ChildItem -Path $previsDir -Filter "*.uvd" -Recurse))) {
        Write-Host "WARNING - No Visibility files found to archive" -ForegroundColor Yellow
        return Start-Finish
    }

    # Add vis files to archive
    if (-not (Invoke-AddToArchive -Path "vis")) {
        return $false
    }

    # Remove the vis directory
    Remove-Item -Path $previsDir -Recurse -Force -ErrorAction SilentlyContinue

    return Start-Finish
}

function Start-Finish {
    Add-Content -Path $script:Logfile -Value "Build of Patch $($script:PluginName) Complete."
    Write-Host "Build of Patch $($script:PluginName) Complete."
    Write-Host "====================================================="
    Write-Host "Patch Files created:"
    Write-Host "    $($script:PluginNameExt)"

    if ($script:BuildMode -eq "clean") {
        Write-Host "    $($script:PluginName) - Geometry.csg"
        Write-Host "    $($script:PluginName).cdx"
    }

    Write-Host "    $($script:PluginArchive)"
    Write-Host ""
    Write-Host "Move ALL these files into a zip/7z archive and install it"
    Write-Host "====================================================="

    if (-not $script:NoPrompt) {
        $choices = @(
            [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Remove working files")
            [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Keep working files")
        )

        $decision = $Host.UI.PromptForChoice("", "Remove working files [Y]? ", $choices, 0)

        if ($decision -eq 0) {
            # Remove working files
            $combinedObjectsPath = Join-Path $script:locCreationKit "Data\CombinedObjects.esp"
            if (Test-Path $combinedObjectsPath) {
                Remove-Item -Path $combinedObjectsPath -Force
            }

            $previsEspPath = Join-Path $script:locCreationKit "Data\Previs.esp"
            if (Test-Path $previsEspPath) {
                Remove-Item -Path $previsEspPath -Force
            }
        }
    }

    # Restore any disabled DLLs
    Restore-DisabledDlls

    Write-Host "See Log at $($script:Logfile)"

    if (-not $script:NoPrompt) {
        Write-Host "Press any key to continue..."
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }

    return $true
}

# Initialize paths and check environment
function Initialize-Environment {
    Write-Host "================================================================="
    Write-Host "Automatic Previsbine Builder (PowerShell conversion of V2.5 PJM Feb 2025)"
    Write-Host ""

    # Find xEdit location. First try current directory
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

    $script:FO4Edit = Join-Path $scriptDir "FO4Edit64.exe"
    if (-not (Test-Path $script:FO4Edit)) {
        $script:FO4Edit = Join-Path $scriptDir "xEdit64.exe"
    }
    if (-not (Test-Path $script:FO4Edit)) {
        $script:FO4Edit = Join-Path $scriptDir "FO4Edit.exe"
    }
    if (-not (Test-Path $script:FO4Edit)) {
        $script:FO4Edit = Join-Path $scriptDir "xEdit.exe"
    }

    if (-not (Test-Path $script:FO4Edit)) {
        try {
            $regValue = (Get-ItemProperty -Path "HKCR:\FO4Script\DefaultIcon" -Name "(Default)" -ErrorAction Stop)."(Default)"
            $script:FO4Edit = $regValue
        }
        catch {
            # If registry lookup fails, you can uncomment and set the path manually
            # $script:FO4Edit = "C:\Program Files (x86)\FO4Edit\FO4Edit.exe"
        }
    }

    # Find Fallout4.exe/CK location
    try {
        $script:locCreationKit = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Bethesda Softworks\Fallout4" -Name "installed path" -ErrorAction Stop)."installed path"
    }
    catch {
        # If registry lookup fails, you can uncomment and set the path manually
        # $script:locCreationKit = "C:\Program Files (x86)\Steam\steamapps\common\Fallout 4\"
    }

    # Ensure paths end with backslash
    if (-not $script:locCreationKit.EndsWith('\')) {
        $script:locCreationKit += '\'
    }

    # Set up remaining paths
    $script:CreationKitlog = Join-Path $script:locCreationKit "ck.log"
    $script:Archive = Join-Path $script:locCreationKit "tools\archive2\archive2.exe"
    $script:UnattenedLogfile = Join-Path $env:TEMP "UnattendedScript.log"

    # Check for required files
    $fallout4Path = Join-Path $script:locCreationKit "Fallout4.exe"
    if (-not (Test-Path $fallout4Path)) {
        Write-Host "ERROR - Fallout4 cannot be found. Run Fallout4Launcher.exe once to fix" -ForegroundColor Red
        return $false
    }

    if (-not (Test-Path $script:FO4Edit)) {
        Write-Host "ERROR - FO4Edit/xEdit directory not found. Run this script from that directory" -ForegroundColor Red
        return $false
    }

    # Display versions
    Write-Host -NoNewline "Using $($script:FO4Edit) V"
    (Get-Item -Path $script:FO4Edit).VersionInfo.ProductVersion

    Write-Host -NoNewline "Using $($fallout4Path) V"
    (Get-Item -Path $fallout4Path).VersionInfo.ProductVersion

    $ckPath = Join-Path $script:locCreationKit $script:CK
    if (-not (Test-Path $ckPath)) {
        Write-Host "ERROR - $($script:CK) cannot be found. Creation Kit must be installed" -ForegroundColor Red
        return $false
    }

    $winhttpPath = Join-Path $script:locCreationKit "winhttp.dll"
    if (-not (Test-Path $winhttpPath)) {
        Write-Host "ERROR - CKPE not installed. You may not get a successful Patch without it" -ForegroundColor Red
        return $false
    }

    if (-not (Test-Path $script:Archive)) {
        Write-Host "ERROR - Archive2.exe not found. Creation Kit not properly installed" -ForegroundColor Red
        return $false
    }

    Write-Host -NoNewline "Using ... $($script:CK) V"
    (Get-Item -Path $ckPath).VersionInfo.ProductVersion

    Write-Host -NoNewline "Using ... CKPE V"
    (Get-Item -Path $winhttpPath).VersionInfo.ProductVersion
    Write-Host ""

    # Check required scripts
    if (-not (Check-Scripts -xEditPath $script:FO4Edit -ScriptName "Batch_FO4MergePrevisandCleanRefr.pas" -RequiredVersion "V2.2")) {
        return $false
    }

    if (-not (Check-Scripts -xEditPath $script:FO4Edit -ScriptName "Batch_FO4MergeCombinedObjectsAndCheck.pas" -RequiredVersion "V1.5")) {
        return $false
    }

    # Check if CK logging is redirected to a file
    $ckpeIniPath = Join-Path $script:locCreationKit $script:CKPEini
    if (-not (Test-Path $ckpeIniPath)) {
        $script:CKPEini = "fallout4_test.ini"
        $script:CKPEHandleSetting = "BSHandleRefObjectPatch"
        $script:CKPELogSetting = "OutputFile"
        $ckpeIniPath = Join-Path $script:locCreationKit $script:CKPEini

        if (-not (Test-Path $ckpeIniPath)) {
            Write-Host "ERROR - CKPE not installed properly. No settings file found" -ForegroundColor Red
            return $false
        }
    }

    $iniContent = Get-Content -Path $ckpeIniPath -Raw
    if (-not ($iniContent -match "$($script:CKPELogSetting)=ck.log")) {
        Write-Host "Logging not set in $($script:CKPEini), so no errors will be recorded."
        Write-Host "To fix, set $($script:CKPELogSetting)=CK.log in this ini."
        Write-Host ""
    }

    if (-not ($iniContent -match "$($script:CKPEHandleSetting)=true")) {
        Write-Host "Increased Reference Limit not enabled, Precombine Phase may fail."
        Write-Host "To fix, set $($script:CKPEHandleSetting)=true in $($script:CKPEini)."
        Write-Host ""
    }

    return $true
}
# Process parameters and get plugin name
function Invoke-Parameters {
    # Check Build mode etc from parameters
    $script:NoPrompt = $false
    $script:BuildMode = "clean"
    Write-Host "Build Previsbines ($($script:BuildMode)) for Seed/Patch Plugin you specify."
    Write-Host "If you use MO2 then this must be run from within MO2"
    Write-Host ""
    Write-Host "Specify the name for the Patch (If no extension then assumes .esp)"
    Write-Host "If it does not exist then xPrevisPatch.esp will be renamed to it."
    Write-Host "================================================================="

    if (-not [string]::IsNullOrEmpty($BuildModeOrPlugin)) {
        if ($BuildModeOrPlugin -match '^-?(filtered|xbox|clean)') {
            $script:BuildMode = $BuildModeOrPlugin -replace '^-', ''
        }
        else {
            # It's a plugin name
            $script:PluginName = $BuildModeOrPlugin
            $script:NoPrompt = $true
            if (-not (Set-PluginName)) {
                return $false
            }
        }
    }
    else {

        if (-not (Get-PluginName)) {
            return $false
        }
    }
    Write-Host "Building Previsbines ($($script:BuildMode)) for Patch $($script:PluginNameExt)"
    Write-Host "================================================================="
    # Set up remaining variables
    $script:PluginArchive = "$($script:PluginName) - Main.ba2"
    $script:Logfile = Join-Path $env:TEMP "$($script:PluginName).log"
    $script:PluginPath = Join-Path $script:locCreationKit "Data\$($script:PluginNameExt)"

    return $true
}
# Check if plugin exists and handle accordingly
function Test-PluginExists {
    # If the specified mod already exists, check what to do with it
    if (Test-Path $script:PluginPath) {
        if ($script:NoPrompt) {
            # Skip the prompt and proceed with existing plugin
            return $true
        }

        $choices = @(
            [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Use existing plugin")
            [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Exit")
            [System.Management.Automation.Host.ChoiceDescription]::new("&Continue", "Rerun from failed step")
        )

        $decision = $Host.UI.PromptForChoice("", "Plugin already exists, Use It? [Y], Exit [N], Rerun from failed step [C]", $choices, 0)

        if ($decision -eq 0) {
            # Use existing plugin
            return $true
        }
        elseif ($decision -eq 1) {
            # Exit
            return $false
        }
        else {
            # Rerun from step
            return Get-ContinueStep
        }
    }

    # Plugin does not exist, try to use xPrevisPatch.esp as seed
    $pluginArchivePath = Join-Path $script:locCreationKit "Data\$($script:PluginArchive)"
    if (Test-Path $pluginArchivePath) {
        Write-Host "ERROR - This Plugin already has an Archive" -ForegroundColor Red
        return $false
    }

    if ($script:NoPrompt) {
        Write-Host "ERROR - Plugin $($script:PluginNameExt) does not exist" -ForegroundColor Red
        return $false
    }

    $xPrevisPatchPath = Join-Path $script:locCreationKit "Data\xPrevisPatch.esp"
    if (-not (Test-Path $xPrevisPatchPath)) {
        Write-Host "ERROR - Specified Plugin or xPrevisPatch does not exist" -ForegroundColor Red
        return $false
    }

    $choices = @(
        [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Rename xPrevisPatch.esp")
        [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Exit")
    )

    $decision = $Host.UI.PromptForChoice("", "Plugin does not exist, Rename xPrevisPatch.esp to this? [Y/N]", $choices, 0)

    if ($decision -eq 0) {
        # Rename xPrevisPatch.esp
        Copy-Item -Path $xPrevisPatchPath -Destination $script:PluginPath -Force

        # Let MO2 do its thing before we check this worked...
        Start-Sleep -Seconds 5

        if (-not (Test-Path $script:PluginPath)) {
            Write-Host "ERROR - Copy of seed to plugin failed" -ForegroundColor Red
            return $false
        }

        return $true
    }

    return $false
}
# Get plugin name from user
function Get-PluginName {
    $script:PluginName = Read-Host -Prompt "Enter Patch Plugin name (return to exit)"

    if ([string]::IsNullOrEmpty($script:PluginName)) {
        return $false
    }

    return Set-PluginName
}

# Process and validate plugin name
function Set-PluginName {
    # Check for spaces in name if clean build mode
    if ($script:BuildMode -eq "clean") {
        $pluginNoSpace = $script:PluginName -replace " ", ""
        if ($pluginNoSpace -ne $script:PluginName) {
            Write-Host "ERROR - Plugin name cannot contain spaces, Please choose another." -ForegroundColor Red
            if ($script:NoPrompt) {
                return $false
            }
            return Get-PluginName
        }
    }

    # Check for extension
    if ($script:PluginName -match "\.(esp|esm|esl)$") {
        # Extension specified
        $script:PluginNameExt = $script:PluginName
        $script:PluginName = [System.IO.Path]::GetFileNameWithoutExtension($script:PluginName)
    }
    else {
        # No extension, assume .esp
        $script:PluginNameExt = "$($script:PluginName).esp"
    }

    # Don't allow reserved name
    if ($script:PluginName -eq "xprevispatch") {
        Write-Host "ERROR - This plugin name is reserved, Please choose another." -ForegroundColor Red
        if ($script:NoPrompt) {
            return $false
        }
        return Get-PluginName
    }

    return $true
}

# Check if plugin exists and handle accordingly
function Test-PluginExists {
    # If the specified mod already exists, check what to do with it
    if (Test-Path $script:PluginPath) {
        if ($script:NoPrompt) {
            # Skip the prompt and proceed with existing plugin
            return $true
        }

        $choices = @(
            [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Use existing plugin")
            [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Exit")
            [System.Management.Automation.Host.ChoiceDescription]::new("&Continue", "Rerun from failed step")
        )

        $decision = $Host.UI.PromptForChoice("", "Plugin already exists, Use It? [Y], Exit [N], Rerun from failed step [C]", $choices, 0)

        if ($decision -eq 0) {
            # Use existing plugin
            return $true
        }
        elseif ($decision -eq 1) {
            # Exit
            return $false
        }
        else {
            # Rerun from step
            return Get-ContinueStep
        }
    }

    # Plugin does not exist, try to use xPrevisPatch.esp as seed
    $pluginArchivePath = Join-Path $script:locCreationKit "Data\$($script:PluginArchive)"
    if (Test-Path $pluginArchivePath) {
        Write-Host "ERROR - This Plugin already has an Archive" -ForegroundColor Red
        return $false
    }

    if ($script:NoPrompt) {
        Write-Host "ERROR - Plugin $($script:PluginNameExt) does not exist" -ForegroundColor Red
        return $false
    }

    $xPrevisPatchPath = Join-Path $script:locCreationKit "Data\xPrevisPatch.esp"
    if (-not (Test-Path $xPrevisPatchPath)) {
        Write-Host "ERROR - Specified Plugin or xPrevisPatch does not exist" -ForegroundColor Red
        return $false
    }

    $choices = @(
        [System.Management.Automation.Host.ChoiceDescription]::new("&Yes", "Rename xPrevisPatch.esp")
        [System.Management.Automation.Host.ChoiceDescription]::new("&No", "Exit")
    )

    $decision = $Host.UI.PromptForChoice("", "Plugin does not exist, Rename xPrevisPatch.esp to this? [Y/N]", $choices, 0)

    if ($decision -eq 0) {
        # Rename xPrevisPatch.esp
        Copy-Item -Path $xPrevisPatchPath -Destination $script:PluginPath -Force

        # Let MO2 do its thing before we check this worked...
        Start-Sleep -Seconds 5

        if (-not (Test-Path $script:PluginPath)) {
            Write-Host "ERROR - Copy of seed to plugin failed" -ForegroundColor Red
            return $false
        }

        return $true
    }

    return $false
}