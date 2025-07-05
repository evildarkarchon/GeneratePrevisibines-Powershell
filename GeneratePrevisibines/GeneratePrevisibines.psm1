#requires -Version 5.1

# Import all classes first
$classFiles = Get-ChildItem -Path "$PSScriptRoot\Classes" -Filter "*.ps1" -ErrorAction SilentlyContinue
foreach ($classFile in $classFiles) {
    try {
        . $classFile.FullName
        Write-Verbose "Imported class: $($classFile.Name)"
    }
    catch {
        Write-Error "Failed to import class $($classFile.Name): $_"
    }
}

# Import all private functions
$privateFiles = Get-ChildItem -Path "$PSScriptRoot\Private" -Filter "*.ps1" -ErrorAction SilentlyContinue
foreach ($privateFile in $privateFiles) {
    try {
        . $privateFile.FullName
        Write-Verbose "Imported private function: $($privateFile.Name)"
    }
    catch {
        Write-Error "Failed to import private function $($privateFile.Name): $_"
    }
}

# Import all public functions
$publicFiles = Get-ChildItem -Path "$PSScriptRoot\Public" -Filter "*.ps1" -ErrorAction SilentlyContinue
foreach ($publicFile in $publicFiles) {
    try {
        . $publicFile.FullName
        Write-Verbose "Imported public function: $($publicFile.Name)"
    }
    catch {
        Write-Error "Failed to import public function $($publicFile.Name): $_"
    }
}

# Export public functions
$publicFunctions = $publicFiles | ForEach-Object { [System.IO.Path]::GetFileNameWithoutExtension($_.Name) }
Export-ModuleMember -Function $publicFunctions

# Module initialization
Write-Verbose "GeneratePrevisibines module loaded successfully"
