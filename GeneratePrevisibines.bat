@echo off
:: GeneratePrevisibines PowerShell Launcher
:: This batch file launches the PowerShell script for users who prefer double-clicking

title GeneratePrevisibines PowerShell Script
echo ==============================================
echo GeneratePrevisibines PowerShell Script
echo ==============================================
echo.

:: Check if PowerShell is available
where pwsh >nul 2>&1
if %errorlevel% == 0 (
    echo Using PowerShell 7...
    pwsh -ExecutionPolicy Bypass -File "%~dp0GeneratePrevisibines.ps1" %*
) else (
    where powershell >nul 2>&1
    if %errorlevel% == 0 (
        echo Using Windows PowerShell...
        powershell -ExecutionPolicy Bypass -File "%~dp0GeneratePrevisibines.ps1" %*
    ) else (
        echo ERROR: PowerShell not found!
        echo Please install PowerShell 5.1 or later
        echo.
        pause
        exit /b 1
    )
)

echo.
echo Script execution completed.
echo.
pause