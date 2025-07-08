function Import-PrevisbineConfiguration {
    <#
    .SYNOPSIS
    Imports a previsbine configuration from a JSON file.
    
    .DESCRIPTION
    Imports a previously exported PrevisbineConfig from a JSON file.
    The imported configuration is validated before being returned.
    
    .PARAMETER Path
    The path to the configuration file to import.
    
    .PARAMETER SkipValidation
    Skip validation of the imported configuration.
    
    .EXAMPLE
    $config = Import-PrevisbineConfiguration -Path ".\config.json"
    
    .EXAMPLE
    Import-PrevisbineConfiguration -Path ".\config.json" | Start-PrevisbineGeneration
    #>
    [CmdletBinding()]
    [OutputType([PrevisbineConfig])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('FullName')]
        [string]$Path,
        
        [Parameter()]
        [switch]$SkipValidation
    )
    
    process {
        try {
            # Check if file exists
            if (-not (Test-Path $Path)) {
                throw "Configuration file not found: $Path"
            }
            
            # Read and parse JSON
            $jsonContent = Get-Content -Path $Path -Raw
            $configData = $jsonContent | ConvertFrom-Json
            
            # Create new config object
            $config = [PrevisbineConfig]::new()
            
            # Map properties
            $propertyMapping = @{
                'FO4EditPath' = 'FO4EditPath'
                'CreationKitPath' = 'CreationKitPath'
                'ArchiveTool' = 'ArchiveTool'
                'Archive2Path' = 'Archive2Path'
                'BSArchPath' = 'BSArchPath'
                'BuildMode' = 'BuildMode'
                'LogPath' = 'LogPath'
                'FO4Directory' = 'FO4Directory'
                'DataDirectory' = 'DataDirectory'
                'PluginName' = 'PluginName'
                'WorkingDirectory' = 'WorkingDirectory'
                'UseMO2' = 'UseMO2'
                'MO2Path' = 'MO2Path'
                'MO2Profile' = 'MO2Profile'
                'VerboseLogging' = 'VerboseLogging'
                'KeepTempFiles' = 'KeepTempFiles'
                'TimeoutMinutes' = 'TimeoutMinutes'
            }
            
            foreach ($property in $propertyMapping.Keys) {
                if ($null -ne $configData.$property) {
                    $config.$property = $configData.$property
                }
            }
            
            # Validate unless skipped
            if (-not $SkipValidation) {
                if (-not $config.IsValid()) {
                    throw "Imported configuration is not valid. Use -SkipValidation to bypass validation."
                }
            }
            
            Write-Information "Configuration imported from: $Path" -InformationAction Continue
            if ($configData.ExportDate) {
                Write-Information "Configuration was exported on: $($configData.ExportDate)" -InformationAction Continue
            }
            
            # Return the configuration
            $config
            
        } catch {
            throw "Failed to import configuration: $_"
        }
    }
}