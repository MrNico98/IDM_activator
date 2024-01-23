@echo off
setlocal EnableDelayedExpansion

:: Check for elevated privileges
net session >nul 2>&1 || (
    echo This script requires elevated privileges. Please run as Administrator.
    exit /b
)

:: Check if Null service is running (essential for the batch script)
sc query Null | find /i "RUNNING" >nul 2>&1 || (
    echo Null service is not running; the script may not work correctly.
    echo:
    echo Help: %mas%idm-activation-script.html#Troubleshoot
    echo:
    echo Press any key to exit...
    pause >nul
    exit /b
)

:: Verify existence of PowerShell script
if not exist ".\Downloader.ps1" (
    echo PowerShell script not found. Exiting...
    exit /b
)

:: Launch the PowerShell script with ExecutionPolicy Bypass
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Downloader.ps1"
