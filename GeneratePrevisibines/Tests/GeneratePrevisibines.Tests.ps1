BeforeAll {
    # Import the module
    $ModulePath = Join-Path $PSScriptRoot ".." "GeneratePrevisibines.psd1"
    Import-Module $ModulePath -Force
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
            
            $clone = $config.Clone()
            $clone.PluginName | Should -Be "Test.esp"
            $clone.BuildMode | Should -Be "Filtered"
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
            $paths.Keys | Should -Contain "FO4Directory"
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

AfterAll {
    # Clean up
    Remove-Module GeneratePrevisibines -Force -ErrorAction SilentlyContinue
}
