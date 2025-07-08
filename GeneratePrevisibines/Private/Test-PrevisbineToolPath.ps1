function Test-PrevisbineToolPath {
    <#
    .SYNOPSIS
    Tests if a tool path is valid and accessible.
    
    .DESCRIPTION
    Validates tool paths for previsbine generation, checking if the file exists
    and optionally validating specific tool requirements.
    
    .PARAMETER Path
    The path to the tool executable to validate.
    
    .PARAMETER ToolType
    The type of tool being validated (FO4Edit, CreationKit, Archive2, BSArch).
    
    .PARAMETER PassThru
    Returns the path if valid, otherwise returns nothing.
    
    .EXAMPLE
    "C:\Games\FO4Edit\FO4Edit.exe" | Test-PrevisbineToolPath -ToolType FO4Edit
    
    .EXAMPLE
    Get-ModToolPaths | ForEach-Object { $_.FO4Edit } | Test-PrevisbineToolPath -ToolType FO4Edit -PassThru
    
    .EXAMPLE
    @("C:\Path1\FO4Edit.exe", "C:\Path2\xEdit64.exe") | Test-PrevisbineToolPath -ToolType FO4Edit
    #>
    [CmdletBinding()]
    [OutputType([string], [bool])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('FullName', 'PSPath')]
        [string]$Path,
        
        [Parameter()]
        [ValidateSet('FO4Edit', 'CreationKit', 'Archive2', 'BSArch')]
        [string]$ToolType,
        
        [Parameter()]
        [switch]$PassThru
    )
    
    process {
        try {
            # Basic existence check
            if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
                if ($PassThru) {
                    return
                } else {
                    Write-Output $false
                    return
                }
            }
            
            # Tool-specific validation
            $isValid = $true
            switch ($ToolType) {
                'FO4Edit' {
                    $fileName = Split-Path -Path $Path -Leaf
                    if ($fileName -notmatch '^(FO4Edit|xEdit64?)\.exe$') {
                        Write-Warning "File '$fileName' does not match expected FO4Edit executable names"
                        $isValid = $false
                    }
                }
                'CreationKit' {
                    $fileName = Split-Path -Path $Path -Leaf
                    if ($fileName -ne 'CreationKit.exe') {
                        Write-Warning "File '$fileName' is not CreationKit.exe"
                        $isValid = $false
                    }
                }
                'Archive2' {
                    $fileName = Split-Path -Path $Path -Leaf
                    if ($fileName -ne 'Archive2.exe') {
                        Write-Warning "File '$fileName' is not Archive2.exe"
                        $isValid = $false
                    }
                }
                'BSArch' {
                    $fileName = Split-Path -Path $Path -Leaf
                    if ($fileName -ne 'BSArch.exe') {
                        Write-Warning "File '$fileName' is not BSArch.exe"
                        $isValid = $false
                    }
                }
            }
            
            if ($PassThru) {
                if ($isValid) {
                    Write-Output $Path
                }
            } else {
                Write-Output $isValid
            }
            
        } catch {
            Write-Error "Failed to test tool path '$Path': $_"
            if (-not $PassThru) {
                Write-Output $false
            }
        }
    }
}