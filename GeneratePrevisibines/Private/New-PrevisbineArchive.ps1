function New-PrevisbineArchive {
    <#
    .SYNOPSIS
    Creates BA2 archives for previsbine data with pipeline support.
    
    .DESCRIPTION
    Creates Bethesda Archive 2 (BA2) files containing previsbine data,
    with support for processing multiple archives through the pipeline.
    
    .PARAMETER InputPath
    Path to the directory containing files to archive.
    
    .PARAMETER OutputPath
    Path for the output BA2 archive.
    
    .PARAMETER Config
    PrevisbineConfig object containing tool paths and settings.
    
    .PARAMETER ArchiveType
    Type of archive to create (Main or Textures).
    
    .PARAMETER Compress
    Enable compression for the archive.
    
    .EXAMPLE
    Get-ChildItem ".\vis\" -Directory | New-PrevisbineArchive -Config $config -ArchiveType Main
    
    .EXAMPLE
    ".\vis\MyMod" | New-PrevisbineArchive -Config $config -OutputPath ".\MyMod.ba2"
    
    .EXAMPLE
    @(".\vis\Mod1", ".\vis\Mod2") | New-PrevisbineArchive -Config $config -Compress
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('FullName', 'PSPath')]
        [string]$InputPath,
        
        [Parameter()]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $true)]
        [PrevisbineConfig]$Config,
        
        [Parameter()]
        [ValidateSet('Main', 'Textures')]
        [string]$ArchiveType = 'Main',
        
        [Parameter()]
        [switch]$Compress
    )
    
    begin {
        # Import private function
        $privatePath = Join-Path -Path $PSScriptRoot -ChildPath '..\Private\New-BA2Archive.ps1'
        if (Test-Path $privatePath) {
            . $privatePath
        }
        
        # Validate config
        if (-not $Config.IsValid()) {
            throw "Invalid configuration provided"
        }
    }
    
    process {
        try {
            # Validate input path
            if (-not (Test-Path -LiteralPath $InputPath)) {
                Write-Error "Input path not found: $InputPath"
                return
            }
            
            # Generate output path if not provided
            if (-not $OutputPath) {
                $baseName = Split-Path -Path $InputPath -Leaf
                $OutputPath = Join-Path -Path (Split-Path -Path $InputPath -Parent) -ChildPath "$baseName - Main.ba2"
            }
            
            # Ensure .ba2 extension
            if ($OutputPath -notmatch '\.ba2$') {
                $OutputPath = "$OutputPath.ba2"
            }
            
            if ($PSCmdlet.ShouldProcess($OutputPath, "Create BA2 archive from $InputPath")) {
                # Call the existing private function
                $result = New-BA2Archive -SourceDir $InputPath -OutputPath $OutputPath -ArchiveType $ArchiveType -Compress:$Compress -Config $Config
                
                # Create output object
                [PSCustomObject]@{
                    InputPath = $InputPath
                    OutputPath = $OutputPath
                    ArchiveType = $ArchiveType
                    Compressed = $Compress
                    Success = $result
                    Size = if ($result -and (Test-Path $OutputPath)) { (Get-Item $OutputPath).Length } else { 0 }
                    CreatedAt = Get-Date
                }
            }
            
        } catch {
            Write-Error "Failed to create archive for '$InputPath': $_"
            
            # Return error object
            [PSCustomObject]@{
                InputPath = $InputPath
                OutputPath = $OutputPath
                ArchiveType = $ArchiveType
                Compressed = $Compress
                Success = $false
                Error = $_.ToString()
                CreatedAt = Get-Date
            }
        }
    }
}