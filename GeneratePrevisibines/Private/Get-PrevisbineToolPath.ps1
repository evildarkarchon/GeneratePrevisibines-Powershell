function Get-PrevisbineToolPath {
    <#
    .SYNOPSIS
    Gets paths to Fallout 4 modding tools as objects suitable for pipeline processing.
    
    .DESCRIPTION
    Discovers paths to Fallout 4 modding tools through registry and common locations,
    returning them as objects that can be piped to other cmdlets for validation or processing.
    
    .PARAMETER ToolName
    Specific tool to search for. If not specified, searches for all tools.
    
    .PARAMETER IncludeFallbacks
    Include fallback search locations if registry lookup fails.
    
    .EXAMPLE
    Get-PrevisbineToolPath | Test-PrevisbineToolPath -PassThru
    
    .EXAMPLE
    Get-PrevisbineToolPath -ToolName FO4Edit | Where-Object { $_.IsFound }
    
    .EXAMPLE
    Get-PrevisbineToolPath | Export-Csv -Path "tool-paths.csv"
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateSet('FO4Edit', 'CreationKit', 'Archive2', 'BSArch', 'MO2', 'All')]
        [string[]] $ToolName = 'All',
        
        [Parameter()]
        [switch] $IncludeFallbacks
    )
    
    begin {
        # Import private functions if needed
        $privatePath = Join-Path -Path $PSScriptRoot -ChildPath '..\Private\Get-ModToolPaths.ps1'
        if (Test-Path $privatePath) {
            . $privatePath
        }
    }
    
    process {
        foreach ($tool in $ToolName) {
            $toolsToSearch = if ($tool -eq 'All') {
                @('FO4Edit', 'CreationKit', 'Archive2', 'BSArch', 'MO2')
            } else {
                @($tool)
            }
            
            foreach ($searchTool in $toolsToSearch) {
                # Get tool paths using existing function
                $paths = Get-ModToolPaths -ToolName $searchTool -IncludeFallbacks:$IncludeFallbacks
                
                # Convert to objects
                switch ($searchTool) {
                    'FO4Edit' {
                        [PSCustomObject]@{
                            ToolName = 'FO4Edit'
                            ToolType = 'FO4Edit'
                            Path = $paths['FO4Edit']
                            IsFound = [bool]$paths['FO4Edit']
                            Source = if ($paths['FO4Edit']) { 'Registry/Search' } else { 'NotFound' }
                        }
                    }
                    'CreationKit' {
                        [PSCustomObject]@{
                            ToolName = 'CreationKit'
                            ToolType = 'CreationKit'
                            Path = $paths['CreationKit']
                            IsFound = [bool]$paths['CreationKit']
                            Source = if ($paths['CreationKit']) { 'Registry/Search' } else { 'NotFound' }
                        }
                    }
                    'Archive2' {
                        [PSCustomObject]@{
                            ToolName = 'Archive2'
                            ToolType = 'Archive2'
                            Path = $paths['Archive2']
                            IsFound = [bool]$paths['Archive2']
                            Source = if ($paths['Archive2']) { 'Registry/Search' } else { 'NotFound' }
                        }
                    }
                    'BSArch' {
                        [PSCustomObject]@{
                            ToolName = 'BSArch'
                            ToolType = 'BSArch'
                            Path = $paths['BSArch']
                            IsFound = [bool]$paths['BSArch']
                            Source = if ($paths['BSArch']) { 'Registry/Search' } else { 'NotFound' }
                        }
                    }
                    'MO2' {
                        [PSCustomObject]@{
                            ToolName = 'Mod Organizer 2'
                            ToolType = 'MO2'
                            Path = $paths['MO2']
                            IsFound = [bool]$paths['MO2']
                            Source = if ($paths['MO2']) { 'Registry/Search' } else { 'NotFound' }
                        }
                    }
                }
            }
        }
    }
}