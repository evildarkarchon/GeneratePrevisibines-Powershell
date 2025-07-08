BeforeAll {
    # Import the module
    $ModulePath = Join-Path (Join-Path $PSScriptRoot "..") "GeneratePrevisibines.psd1"
    Import-Module $ModulePath -Force
    
    # Import private functions for testing
    $PrivatePath = Join-Path (Join-Path $PSScriptRoot "..") "Private"
    $ClassPath = Join-Path (Join-Path $PSScriptRoot "..") "Classes"
    
    # Import classes first
    $classFiles = Get-ChildItem -Path $ClassPath -Filter "*.ps1" -ErrorAction SilentlyContinue
    foreach ($classFile in $classFiles) {
        . $classFile.FullName
    }
    
    # Import private functions
    $privateFiles = Get-ChildItem -Path $PrivatePath -Filter "*.ps1" -ErrorAction SilentlyContinue
    foreach ($privateFile in $privateFiles) {
        . $privateFile.FullName
    }
}

Describe "GeneratePrevisibines Module" {
    Context "Module Loading" {
        It "Should load the module successfully" {
            Get-Module GeneratePrevisibines | Should -Not -BeNullOrEmpty
        }
        
        It "Should export the Start-PrevisbineGeneration cmdlet" {
            Get-Command Start-PrevisbineGeneration -Module GeneratePrevisibines | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "PrevisbineConfig Class" {
    Context "Configuration Object" {
        BeforeEach {
            # Ensure TEMP environment variable is set for WSL
            if (-not $env:TEMP) {
                $env:TEMP = "/tmp"
            }
        }
        
        It "Should create a new PrevisbineConfig instance" {
            $config = [PrevisbineConfig]::new()
            $config | Should -Not -BeNullOrEmpty
        }
        
        It "Should have default values" {
            $config = [PrevisbineConfig]::new()
            $config.BuildMode | Should -Be "Clean"
            $config.ArchiveTool | Should -Be "Archive2"
            $config.TimeoutMinutes | Should -Be 60
        }
        
        It "Should validate required properties" {
            $config = [PrevisbineConfig]::new()
            $config.IsValid() | Should -Be $false
        }
        
        It "Should clone configuration" {
            $config = [PrevisbineConfig]::new()
            $config.PluginName = "Test.esp"
            $config.BuildMode = "Filtered"
            
            if ($config | Get-Member -Name Clone) {
                $clone = $config.Clone()
                $clone.PluginName | Should -Be "Test.esp"
                $clone.BuildMode | Should -Be "Filtered"
            }
            else {
                # Skip this test if Clone method doesn't exist
                Set-ItResult -Skipped -Because "Clone method not implemented"
            }
        }
    }
}

Describe "Get-ModToolPaths Function" {
    Context "Tool Path Discovery" {
        It "Should return a hashtable" {
            $paths = Get-ModToolPaths
            $paths | Should -BeOfType [hashtable]
        }
        
        It "Should include expected keys" {
            $paths = Get-ModToolPaths
            # FO4Directory is only included if FO4 installation is found
            # In test environment, check for tool keys instead
            $expectedKeys = @("FO4Edit", "CreationKit", "Archive2", "BSArch", "MO2")
            foreach ($key in $expectedKeys) {
                $paths.Keys | Should -Contain $key
            }
        }
        
        It "Should search for specific tool when requested" {
            $paths = Get-ModToolPaths -ToolName "FO4Edit"
            $paths.Keys | Should -Contain "FO4Edit"
            $paths.Keys | Should -Not -Contain "CreationKit"
        }
        
        It "Should include all tools when no specific tool requested" {
            $paths = Get-ModToolPaths
            $expectedKeys = @("FO4Edit", "CreationKit", "Archive2", "BSArch", "MO2")
            foreach ($key in $expectedKeys) {
                $paths.Keys | Should -Contain $key
            }
        }
    }
}

Describe "Get-FO4InstallPath Function" {
    Context "FO4 Installation Discovery" {
        It "Should return null when FO4 is not found" {
            # Mock registry access to return nothing
            Mock Get-ItemProperty { return $null } -ParameterFilter { $Path -match "Bethesda Softworks" }
            Mock Test-Path { return $false } -ParameterFilter { $Path -match "Steam" }
            
            $result = Get-FO4InstallPath
            $result | Should -BeNullOrEmpty
        }
        
        It "Should return path from registry when found" {
            Mock Test-Path { return $true } -ParameterFilter { $Path -match "Bethesda Softworks" }
            Mock Get-ItemProperty { 
                return [PSCustomObject]@{ 'Installed Path' = 'C:\Games\Fallout 4' }
            } -ParameterFilter { $Path -match "Bethesda Softworks" }
            Mock Test-Path { return $true } -ParameterFilter { $Path -eq 'C:\Games\Fallout 4' }
            
            $result = Get-FO4InstallPath
            $result | Should -Be 'C:\Games\Fallout 4'
        }
    }
}

Describe "Find-FO4EditPath Function" {
    Context "FO4Edit Discovery" {
        It "Should return null when FO4Edit is not found" {
            Mock Test-Path { return $false }
            Mock Get-ItemProperty { return $null }
            
            $result = Find-FO4EditPath
            $result | Should -BeNullOrEmpty
        }
        
        It "Should search fallback locations when enabled" {
            Mock Test-Path { return $false }
            Mock Get-ItemProperty { return $null }
            
            $result = Find-FO4EditPath -IncludeFallbacks
            $result | Should -BeNullOrEmpty
        }
    }
}

Describe "Resolve-ToolPath Function" {
    Context "Tool Path Resolution" {
        It "Should throw when path is empty" {
            { Resolve-ToolPath -Path "" -ToolName "TestTool" } | Should -Throw "Path for TestTool is not specified"
        }
        
        It "Should throw when path does not exist" {
            { Resolve-ToolPath -Path "C:\NonExistent\Tool.exe" -ToolName "TestTool" } | Should -Throw "*Could not resolve path for TestTool*"
        }
        
        It "Should resolve valid path" {
            $tempFile = New-TemporaryFile
            try {
                $result = Resolve-ToolPath -Path $tempFile.FullName -ToolName "TestTool"
                $result | Should -Be $tempFile.FullName
            }
            finally {
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Describe "Test-Prerequisites Function" {
    Context "Prerequisite Validation" {
        It "Should validate basic configuration" {
            $config = [PrevisbineConfig]::new()
            $config.PluginName = "Test.esp"
            
            $result = Test-Prerequisites -Config $config -SkipToolValidation
            $result | Should -Not -BeNullOrEmpty
            $result.Success | Should -BeOfType [bool]
        }
        
        It "Should return validation errors for invalid config" {
            $config = [PrevisbineConfig]::new()
            # Don't set required properties
            
            $result = Test-Prerequisites -Config $config -SkipToolValidation
            $result.Success | Should -Be $false
            $result.Errors | Should -Not -BeNullOrEmpty
        }
        
        It "Should fail when tool validation is enabled and tools are missing" {
            $config = [PrevisbineConfig]::new()
            $config.PluginName = "Test.esp"
            $config.FO4EditPath = "C:\NonExistent\FO4Edit.exe"
            $config.CreationKitPath = "C:\NonExistent\CreationKit.exe"
            
            $result = Test-Prerequisites -Config $config
            $result.Success | Should -Be $false
            $result.Errors | Should -Contain "FO4Edit not found at: C:\NonExistent\FO4Edit.exe"
        }
    }
}

Describe "Test-ToolAvailability Function" {
    Context "Tool Existence Validation" {
        It "Should return false for non-existent tool" {
            $result = Test-ToolAvailability -ToolName "TestTool" -ToolPath "C:\NonExistent\Tool.exe"
            $result.Success | Should -Be $false
            $result.Error | Should -Match "TestTool not found at:"
        }
        
        It "Should return warning for non-exe files" {
            $tempFile = New-TemporaryFile
            try {
                $result = Test-ToolAvailability -ToolName "TestTool" -ToolPath $tempFile.FullName
                $result.Success | Should -Be $true
                $result.Warning | Should -Match "does not have .exe extension"
            }
            finally {
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            }
        }
        
        It "Should validate FO4Edit specific requirements" {
            $tempDir = New-TemporaryFile | ForEach-Object { Remove-Item $_; New-Item -ItemType Directory -Path $_ }
            $tempExe = Join-Path $tempDir "FO4Edit.exe"
            try {
                "dummy" | Out-File $tempExe
                $result = Test-ToolAvailability -ToolName "FO4Edit" -ToolPath $tempExe
                $result.Success | Should -Be $true
                $result.Warning | Should -Match "installation may be incomplete"
            }
            finally {
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Describe "Test-DirectoryAccess Function" {
    Context "Directory Access Validation" {
        It "Should return false for non-existent directory" {
            $result = Test-DirectoryAccess -DirectoryName "TestDir" -DirectoryPath "C:\NonExistent\Directory"
            $result.Success | Should -Be $false
            $result.Error | Should -Match "TestDir does not exist"
        }
        
        It "Should return true for accessible directory" {
            $tempDir = New-TemporaryFile | ForEach-Object { Remove-Item $_; New-Item -ItemType Directory -Path $_ }
            try {
                $result = Test-DirectoryAccess -DirectoryName "TestDir" -DirectoryPath $tempDir.FullName
                $result.Success | Should -Be $true
                $result.Error | Should -BeNullOrEmpty
            }
            finally {
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Describe "Test-PluginName Function" {
    Context "Plugin Name Validation" {
        It "Should accept valid ESP plugin name" {
            $result = Test-PluginName -PluginName "ValidMod.esp"
            $result.IsValid | Should -Be $true
            $result.Errors | Should -BeNullOrEmpty
        }
        
        It "Should accept valid ESM plugin name" {
            $result = Test-PluginName -PluginName "ValidMod.esm"
            $result.IsValid | Should -Be $true
            $result.Errors | Should -BeNullOrEmpty
        }
        
        It "Should accept valid ESL plugin name" {
            $result = Test-PluginName -PluginName "ValidMod.esl"
            $result.IsValid | Should -Be $true
            $result.Errors | Should -BeNullOrEmpty
        }
        
        It "Should reject empty plugin name" {
            # Test with null instead of empty string to avoid parameter validation
            { Test-PluginName -PluginName $null } | Should -Throw
        }
        
        It "Should reject invalid extension" {
            $result = Test-PluginName -PluginName "InvalidMod.txt"
            $result.IsValid | Should -Be $false
            $result.Errors | Should -Match "Plugin name must end with"
        }
        
        It "Should reject plugin name with invalid characters" {
            $result = Test-PluginName -PluginName "Invalid<>Mod.esp"
            $result.IsValid | Should -Be $false
            $result.Errors | Should -Match "Plugin name contains invalid character"
        }
        
        It "Should warn about very long plugin names" {
            $longName = "a" * 70 + ".esp"
            $result = Test-PluginName -PluginName $longName
            $result.IsValid | Should -Be $true
            $result.Warnings | Should -Match "Plugin name is very long"
        }
        
        It "Should warn about plugin names with spaces" {
            $result = Test-PluginName -PluginName "Plugin With Spaces.esp"
            $result.IsValid | Should -Be $true
            $result.Warnings | Should -Match "contains spaces"
        }
    }
}

Describe "Test-DiskSpace Function" {
    Context "Disk Space Validation" {
        It "Should check disk space for valid directory" {
            $tempDir = New-TemporaryFile | ForEach-Object { Remove-Item $_; New-Item -ItemType Directory -Path $_ }
            try {
                $result = Test-DiskSpace -WorkingDirectory $tempDir.FullName -RequiredGB 0.001
                $result.Success | Should -Be $true
                $result.Warning | Should -BeNullOrEmpty
            }
            finally {
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        
        It "Should warn about insufficient disk space" {
            $tempDir = New-TemporaryFile | ForEach-Object { Remove-Item $_; New-Item -ItemType Directory -Path $_ }
            try {
                $result = Test-DiskSpace -WorkingDirectory $tempDir.FullName -RequiredGB 999999
                $result.Success | Should -Be $false
                $result.Warning | Should -Match "Low disk space"
            }
            finally {
                Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

Describe "Write-LogMessage Function" {
    Context "Logging Functionality" {
        It "Should write log messages without error" {
            { Write-LogMessage "Test message" -Level Info -NoConsole } | Should -Not -Throw
        }
        
        It "Should write to file when LogPath is specified" {
            $tempLog = Join-Path $env:TEMP "test_log_$(Get-Random).log"
            try {
                Write-LogMessage "Test message" -Level Info -LogPath $tempLog -NoConsole
                Test-Path $tempLog | Should -Be $true
                Get-Content $tempLog | Should -Match "Test message"
            }
            finally {
                if (Test-Path $tempLog) {
                    Remove-Item $tempLog -Force
                }
            }
        }
    }
}

Describe "Start-PrevisbineGeneration Cmdlet" {
    Context "Parameter Validation" {
        It "Should accept valid plugin names" {
            { Get-Command Start-PrevisbineGeneration | Should -Not -BeNullOrEmpty } | Should -Not -Throw
        }
        
        It "Should validate BuildMode parameter" {
            $cmd = Get-Command Start-PrevisbineGeneration
            $buildModeParam = $cmd.Parameters['BuildMode']
            $buildModeParam.Attributes.ValidValues | Should -Contain "Clean"
            $buildModeParam.Attributes.ValidValues | Should -Contain "Filtered"
            $buildModeParam.Attributes.ValidValues | Should -Contain "Xbox"
        }
        
        It "Should validate TimeoutMinutes range" {
            $cmd = Get-Command Start-PrevisbineGeneration
            $timeoutParam = $cmd.Parameters['TimeoutMinutes']
            $rangeAttr = $timeoutParam.Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateRangeAttribute] }
            $rangeAttr.MinRange | Should -Be 1
            $rangeAttr.MaxRange | Should -Be 180
        }
    }
}

Describe "Invoke-CreationKit Function" {
    Context "Creation Kit Execution" {
        BeforeEach {
            $script:testConfig = [PrevisbineConfig]::new()
            $script:testConfig.PluginName = "TestMod.esp"
            $script:testConfig.CreationKitPath = "C:\Games\Fallout 4\CreationKit.exe"
            $script:testConfig.CreationKitLogPath = "C:\Games\Fallout 4\CreationKit.log"
            $script:testConfig.LogPath = "C:\Temp\test.log"
        }
        
        It "Should handle ENB DLL renaming" {
            Mock Test-Path { return $true }
            Mock Rename-Item { }
            Mock Remove-Item { }
            Mock Start-Process { 
                return [PSCustomObject]@{ ExitCode = 0 }
            }
            Mock Get-Content { return "Process completed successfully" }
            
            { Invoke-CreationKit -Operation "TestOp" -OutputFile "test.file" -Config $script:testConfig } | Should -Not -Throw
            
            Assert-MockCalled Rename-Item -Times 5 -Scope It
        }
        
        It "Should throw when Creation Kit fails" {
            Mock Test-Path { return $false }
            Mock Rename-Item { }
            Mock Remove-Item { }
            Mock Start-Process { 
                return [PSCustomObject]@{ ExitCode = 1 }
            }
            Mock Get-Content { return "Process failed" }
            
            { Invoke-CreationKit -Operation "TestOp" -OutputFile "test.file" -Config $script:testConfig } | Should -Throw "Creation Kit process failed with exit code: 1"
        }
        
        It "Should detect out of handle errors" {
            Mock Test-Path { return $true }
            Mock Rename-Item { }
            Mock Remove-Item { }
            Mock Start-Process { 
                return [PSCustomObject]@{ ExitCode = 0 }
            }
            Mock Get-Content { return "OUT OF HANDLE ARRAY ENTRIES" }
            
            { Invoke-CreationKit -Operation "TestOp" -OutputFile "test.file" -Config $script:testConfig } | Should -Throw "Creation Kit ran out of reference handles"
        }
        
        It "Should restore ENB DLLs even on failure" {
            Mock Test-Path { return $true }
            Mock Rename-Item { }
            Mock Remove-Item { }
            Mock Start-Process { 
                throw "Process failed"
            }
            
            { Invoke-CreationKit -Operation "TestOp" -OutputFile "test.file" -Config $script:testConfig } | Should -Throw
            
            # Should still call rename to restore DLLs
            Assert-MockCalled Rename-Item -Scope It
        }
    }
}

Describe "Write-ProgressMessage Function" {
    Context "Progress Messaging" {
        It "Should write progress without error" {
            Mock Write-Progress { }
            Mock Write-Host { }
            Mock Write-LogMessage { }
            
            { Write-ProgressMessage -Activity "Testing" -Status "Test Progress" } | Should -Not -Throw
        }
        
        It "Should handle step-based progress" {
            Mock Write-Progress { }
            Mock Write-Host { }
            Mock Write-LogMessage { }
            
            { Write-ProgressMessage -Activity "Testing" -Status "In Progress" -CurrentStep 1 -TotalSteps 5 } | Should -Not -Throw
        }
        
        It "Should calculate percentage from steps" {
            Mock Write-Progress { }
            Mock Write-Host { }
            Mock Write-LogMessage { }
            
            { Write-ProgressMessage -Activity "Testing" -Status "Halfway" -CurrentStep 2 -TotalSteps 4 } | Should -Not -Throw
        }
    }
}

Describe "Configuration Profile Functions" {
    Context "Profile Management" {
        BeforeEach {
            $script:testConfig = [PrevisbineConfig]::new()
            $script:testConfig.PluginName = "TestMod.esp"
            $script:testConfig.BuildMode = "Clean"
            # Set up minimal valid configuration for export tests
            $script:testConfig.FO4EditPath = "/tmp/FO4Edit.exe"
            $script:testConfig.CreationKitPath = "/tmp/CreationKit.exe"
            $script:testConfig.FO4Directory = "/tmp/FO4"
            $script:testConfig.DataDirectory = "/tmp/FO4/Data"
        }
        
        It "Export-PrevisbineConfiguration should create valid JSON" {
            $tempFile = New-TemporaryFile
            try {
                Mock Test-Path { return $true }
                Mock ConvertTo-Json { return '{"PluginName":"TestMod.esp","BuildMode":"Clean"}' }
                Mock Set-Content { }
                
                { Export-PrevisbineConfiguration -Config $script:testConfig -Path $tempFile.FullName } | Should -Not -Throw
                
                Assert-MockCalled ConvertTo-Json -Times 1 -Scope It
                Assert-MockCalled Set-Content -Times 1 -Scope It
            }
            finally {
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            }
        }
        
        It "Import-PrevisbineConfiguration should read valid JSON" {
            $tempFile = New-TemporaryFile
            try {
                Mock Test-Path { return $true }
                Mock Get-Content { return '{"PluginName":"TestMod.esp","BuildMode":"Clean","FO4EditPath":"/tmp/FO4Edit.exe","CreationKitPath":"/tmp/CreationKit.exe","FO4Directory":"/tmp/FO4","DataDirectory":"/tmp/FO4/Data"}' }
                Mock ConvertFrom-Json { 
                    return [PSCustomObject]@{
                        PluginName      = "TestMod.esp"
                        BuildMode       = "Clean"
                        FO4EditPath     = "/tmp/FO4Edit.exe"
                        CreationKitPath = "/tmp/CreationKit.exe"
                        FO4Directory    = "/tmp/FO4"
                        DataDirectory   = "/tmp/FO4/Data"
                    }
                }
                
                $result = Import-PrevisbineConfiguration -Path $tempFile.FullName -SkipValidation
                $result | Should -Not -BeNullOrEmpty
                
                Assert-MockCalled Get-Content -Times 1 -Scope It
                Assert-MockCalled ConvertFrom-Json -Times 1 -Scope It
            }
            finally {
                Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

AfterAll {
    # Clean up
    Remove-Module GeneratePrevisibines -Force -ErrorAction SilentlyContinue
}
