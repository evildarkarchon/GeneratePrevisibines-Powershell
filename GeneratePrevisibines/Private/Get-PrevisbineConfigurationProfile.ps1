function Get-PrevisbineConfigurationProfile {
    <#
    .SYNOPSIS
    Gets available previsbine configuration profiles.
    
    .DESCRIPTION
    Retrieves saved configuration profiles from the user's profile directory.
    Profiles are stored in $HOME\.GeneratePrevisibines\Profiles\
    
    .PARAMETER Name
    The name of a specific profile to retrieve. If not specified, returns all profiles.
    
    .EXAMPLE
    Get-PrevisbineConfigurationProfile
    
    .EXAMPLE
    Get-PrevisbineConfigurationProfile -Name "MyMod"
    
    .EXAMPLE
    Get-PrevisbineConfigurationProfile | Where-Object { $_.BuildMode -eq 'Xbox' }
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$Name
    )
    
    begin {
        $profilePath = Join-Path -Path $HOME -ChildPath '.GeneratePrevisibines\Profiles'
        if (-not (Test-Path $profilePath)) {
            Write-Verbose "Profile directory does not exist: $profilePath"
            return
        }
    }
    
    process {
        try {
            # Get profile files
            $profileFiles = if ($Name) {
                foreach ($profileName in $Name) {
                    $filePath = Join-Path -Path $profilePath -ChildPath "$profileName.json"
                    if (Test-Path $filePath) {
                        Get-Item $filePath
                    } else {
                        Write-Warning "Profile not found: $profileName"
                    }
                }
            } else {
                Get-ChildItem -Path $profilePath -Filter '*.json'
            }
            
            # Process each profile
            foreach ($file in $profileFiles) {
                try {
                    $profileData = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
                    
                    # Add profile metadata
                    $profile = [PSCustomObject]@{
                        Name = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
                        Path = $file.FullName
                        BuildMode = $profileData.BuildMode
                        PluginName = $profileData.PluginName
                        ArchiveTool = $profileData.ArchiveTool
                        UseMO2 = $profileData.UseMO2
                        LastModified = $file.LastWriteTime
                        ExportDate = $profileData.ExportDate
                        Configuration = $profileData
                    }
                    
                    # Output profile
                    $profile
                    
                } catch {
                    Write-Warning "Failed to read profile '$($file.Name)': $_"
                }
            }
            
        } catch {
            throw "Failed to get configuration profiles: $_"
        }
    }
}