@echo off
setlocal EnableDelayedExpansion

:: Check if running with elevated privileges
whoami /groups | find "S-1-16-12288" >nul 2>&1
if not %errorlevel% equ 0 (
    echo This script requires elevated privileges. Please run as Administrator.
    exit /b
)

:: Check if Null service is working (important for the batch script)
sc query Null | find /i "RUNNING" >nul 2>&1
if %errorlevel% NEQ 0 (
    echo Null service is not running; the script may not work correctly.
    echo:
    echo Help: %mas%idm-activation-script.html#Troubleshoot
    echo:
    echo Press any key to exit...
    pause >nul
    exit /b
)

:: Launch the PowerShell script with ExecutionPolicy Bypass
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\Downloader.ps1"

:: End of batch script
