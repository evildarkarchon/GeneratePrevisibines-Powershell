function Test-PluginName {
    <#
    .SYNOPSIS
    Validates a plugin name for previsbine generation.
    
    .DESCRIPTION
    Validates that a plugin name follows the correct format and is suitable
    for previsbine generation operations.
    
    .PARAMETER PluginName
    The plugin name to validate.
    
    .PARAMETER FO4Directory
    The Fallout 4 directory to check for the plugin.
    
    .EXAMPLE
    Test-PluginName -PluginName "MyMod.esp" -FO4Directory "C:\Games\Fallout 4"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $PluginName,
        
        [Parameter()]
        [string] $FO4Directory
    )
    
    $result = @{
        IsValid = $true
        Errors = @()
        Warnings = @()
    }
    
    # Check file extension
    if (-not ($PluginName -match '\.(esp|esm|esl)$')) {
        $result.IsValid = $false
        $result.Errors += "Plugin name must end with .esp, .esm, or .esl extension"
        return $result
    }
    
    # Check for problematic characters
    $invalidChars = @('[', ']', '(', ')', '&', '!', '@', '#', '$', '%', '^', '*', '+', '=', '{', '}', '|', '\', ':', ';', '"', "'", '<', '>', '?', ',')
    foreach ($char in $invalidChars) {
        if ($PluginName.Contains($char)) {
            $result.IsValid = $false
            $result.Errors += "Plugin name contains invalid character: '$char'"
        }
    }
    
    # Check for reserved names
    $reservedNames = @(
        'Fallout4.esm', 'DLCRobot.esm', 'DLCworkshop01.esm', 'DLCCoast.esm',
        'DLCworkshop02.esm', 'DLCworkshop03.esm', 'DLCNukaWorld.esm',
        'ccBGSFO4001-PipBoy(Black).esl', 'ccBGSFO4002-PipBoy(Blue).esl',
        'ccBGSFO4003-PipBoy(Camo01).esl', 'ccBGSFO4004-PipBoy(Camo02).esl'
    )
    
    if ($PluginName -in $reservedNames) {
        $result.IsValid = $false
        $result.Errors += "Cannot use reserved plugin name: $PluginName"
        return $result
    }
    
    # Check if plugin exists in Data directory
    if ($FO4Directory) {
        $dataDir = Join-Path $FO4Directory 'Data'
        $pluginPath = Join-Path $dataDir $PluginName
        
        if (-not (Test-Path $pluginPath)) {
            $result.Warnings += "Plugin file not found: $pluginPath"
        }
    }
    
    # Check for common problematic patterns
    if ($PluginName -match '\s+') {
        $result.Warnings += "Plugin name contains spaces, which may cause issues with some tools"
    }
    
    if ($PluginName.Length -gt 64) {
        $result.Warnings += "Plugin name is very long ($($PluginName.Length) characters), which may cause issues"
    }
    
    return $result
}
