function Save-PrevisbineConfigurationProfile {
    <#
    .SYNOPSIS
    Saves a previsbine configuration as a named profile.
    
    .DESCRIPTION
    Saves a PrevisbineConfig object as a named profile in the user's profile directory.
    Profiles are stored in $HOME\.GeneratePrevisibines\Profiles\
    
    .PARAMETER Config
    The PrevisbineConfig object to save.
    
    .PARAMETER Name
    The name for the profile.
    
    .PARAMETER Force
    Overwrite an existing profile with the same name.
    
    .EXAMPLE
    Save-PrevisbineConfigurationProfile -Config $config -Name "MyMod"
    
    .EXAMPLE
    $config | Save-PrevisbineConfigurationProfile -Name "XboxBuild" -Force
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PrevisbineConfig]$Config,
        
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        
        [Parameter()]
        [switch]$Force
    )
    
    process {
        try {
            # Create profile directory if it doesn't exist
            $profilePath = Join-Path -Path $HOME -ChildPath '.GeneratePrevisibines\Profiles'
            if (-not (Test-Path $profilePath)) {
                if ($PSCmdlet.ShouldProcess($profilePath, 'Create profile directory')) {
                    New-Item -ItemType Directory -Path $profilePath -Force | Out-Null
                }
            }
            
            # Build profile file path
            $profileFilePath = Join-Path -Path $profilePath -ChildPath "$Name.json"
            
            # Check if profile exists
            if ((Test-Path $profileFilePath) -and -not $Force) {
                throw "Profile '$Name' already exists. Use -Force to overwrite."
            }
            
            # Export configuration to profile
            if ($PSCmdlet.ShouldProcess($Name, 'Save configuration profile')) {
                Export-PrevisbineConfiguration -Config $Config -Path $profileFilePath -Force
                Write-Information "Profile '$Name' saved successfully." -InformationAction Continue
            }
            
        } catch {
            throw "Failed to save configuration profile: $_"
        }
    }
}