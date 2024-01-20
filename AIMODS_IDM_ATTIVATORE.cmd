@echo off
setlocal DisableDelayedExpansion

:: To activate, run the script with "/act" parameter or change 0 to 1 in the line below
set "_activate=1"

:: To reset the activation and trial, run the script with "/res" parameter or change 0 to 1 in the line below
set "_reset=0"

:: If the value is changed in the lines above or parameter is used, then the script will run in unattended mode

:: Add a custom name in IDM license info; prefer to write it in English in the line below after the equal sign
set "name=AIMODS"
::========================================================================================================================================

:: Set the Path variable; it helps if it is misconfigured in the system
set "PATH=%SystemRoot%\System32;%SystemRoot%\System32\wbem;%SystemRoot%\System32\WindowsPowerShell\v1.0\"
if exist "%SystemRoot%\Sysnative\reg.exe" (
    set "PATH=%SystemRoot%\Sysnative;%SystemRoot%\Sysnative\wbem;%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\;%PATH%"
)

:: Re-launch the script with x64 process if it was initiated by x86 process on x64-bit Windows
:: or with ARM64 process if it was initiated by x86/ARM32 process on ARM64 Windows

set "_cmdf=%~f0"
for %%# in (%*) do (
    if /i "%%#"=="r1" set r1=1
    if /i "%%#"=="r2" set r2=1
    if /i "%%#"=="-qedit" (
        reg add HKCU\Console /v QuickEdit /t REG_DWORD /d "1" /f >nul 2>&1
        rem check the code below admin elevation to understand why it's here
    )
)

if exist %SystemRoot%\Sysnative\cmd.exe if not defined r1 (
    setlocal EnableDelayedExpansion
    start %SystemRoot%\Sysnative\cmd.exe /c ""!_cmdf!" %* r1"
    exit /b
)

:: Re-launch the script with ARM32 process if it was initiated by x64 process on ARM64 Windows

if exist %SystemRoot%\SysArm32\cmd.exe if %PROCESSOR_ARCHITECTURE%==AMD64 if not defined r2 (
    setlocal EnableDelayedExpansion
    start %SystemRoot%\SysArm32\cmd.exe /c ""!_cmdf!" %* r2"
    exit /b
)

::========================================================================================================================================

:: Check if Null service is working; it's important for the batch script
sc query Null | find /i "RUNNING" >nul 2>&1
if %errorlevel% NEQ 0 (
    echo:
    echo Null service is not running; the script may crash...
    echo:
    echo:
    echo Help - %mas%idm-activation-script.html#Troubleshoot
    echo:
    echo:
    ping 127.0.0.1 -n 10 >nul
)
cls

::===============================================================================================================================

@echo off
:: Check LF line ending
pushd "%~dp0"
>nul findstr /v "$" "%~nx0" && (
    echo:
    echo Error: Script either has LF line ending issue or an empty line at the end of the script is missing.
    echo:
    ping 127.0.0.1 -n 6 >nul
    popd
    exit /b
)
popd

::========================================================================================================================================

cls
color 07
title AIMODS ATTIVAZIONE IDM

set "_args="
set "_elev="
set "_unattended=0"

set "_args=%*"
if defined _args set "_args=%_args:"=%"
if defined _args (
    for %%A in (%_args%) do (
        if /i "%%A"=="-el" set "_elev=1"
        if /i "%%A"=="/res" set "_reset=1"
        if /i "%%A"=="/act" set "_activate=1"
    )
)

for %%A in (%_activate% %_reset%) do (
    if "%%A"=="1" set "_unattended=1"
)

::========================================================================================================================================

set "nul1=1>nul"
set "nul2=2>nul"
set "nul6=2^>nul"
set "nul=>nul 2>&1"

set "psc=powershell.exe"
set "winbuild=1"
for /f "tokens=6 delims=[]. " %%G in ('ver') do set "winbuild=%%G"

set "_NCS=1"
if %winbuild% LSS 10586 set "_NCS=0"
if %winbuild% GEQ 10586 (
    reg query "HKCU\Console" /v ForceV2 %nul2% | find /i "0x0" %nul1% && (
        set "_NCS=0"
    )
)

if %_NCS% EQU 1 (
    for /F %%a in ('echo prompt $E ^| cmd') do set "esc=%%a"
    set "Red="41;97m""
    set "Gray="100;97m""
    set "Green="42;97m""
    set "Blue="44;97m""
    set "_White="40;37m""
    set "_Green="40;92m""
    set "_Yellow="40;93m""
) else (
    set "Red="Red" "white""
    set "Gray="Darkgray" "white""
    set "Green="DarkGreen" "white""
    set "Blue="Blue" "white""
    set "_White="Black" "Gray""
    set "_Green="Black" "Green""
    set "_Yellow="Black" "Yellow""
)

set "nceline=echo: &echo ==== ERROR ==== &echo:"
set "eline=echo: &call :_color %Red% "==== ERROR ====" &echo:"
set "line=___________________________________________________________________________________________________"
set "_buf={$W=$Host.UI.RawUI.WindowSize;$B=$Host.UI.RawUI.BufferSize;$W.Height=34;$B.Height=300;$Host.UI.RawUI.WindowSize=$W;$Host.UI.RawUI.BufferSize=$B;}"

::========================================================================================================================================

if %winbuild% LSS 7600 (
    %nceline%
    echo Unsupported OS version Detected [%winbuild%].
    echo Project is supported only for Windows 7/8/8.1/10/11 and their Server equivalent.
    goto done2
)

for %%# in (powershell.exe) do @if "%%~$PATH:#"=="" (
    %nceline%
    echo Unable to find powershell.exe in the system.
    goto done2
)

::========================================================================================================================================
:: Elevate script as admin and pass arguments to prevent loop
>nul fltmc || (
    if not defined _elev %psc% "start cmd.exe -arg '/c \"!_PSarg:'=''!\"' -verb runas" && exit /b
    %eline%
    echo This script requires admin privileges.
    echo To do so, right-click on this script and select 'Run as administrator'.
    goto done2
)

::========================================================================================================================================

:: Disable QuickEdit for this cmd.exe session without making permanent changes to the registry
:: Added because clicking on the script window pauses the operation, leading to confusion

if %_unattended%==1 set quedit=1
for %%# in (%_args%) do (
    if /i "%%#"=="-qedit" set quedit=1
)

reg query HKCU\Console /v QuickEdit %nul2% | find /i "0x0" %nul1% || (
    if not defined quedit (
        reg add HKCU\Console /v QuickEdit /t REG_DWORD /d "0" /f %nul1%
        start cmd.exe /c ""!_batf!" %_args% -qedit"
        rem QuickEdit reset code is added at the start of the script instead of here because it takes time to reflect in some cases
        exit /b
    )
)

::========================================================================================================================================

:: Check if script is running in a terminal app and relaunches it with conhost.exe if needed

if %_unattended%==1 set wtrel=1
for %%# in (%_args%) do (
    if /i "%%#"=="-wt" set wtrel=1
)

if %winbuild% GEQ 17763 (
    set terminal=1

    if not defined wtrel (
        set test=TermTest-%random%
        title !test!
        %psc% "(Get-Process | Where-Object { $_.MainWindowTitle -like '*!test!*' }).ProcessName" | find /i "cmd" %nul1% && (set terminal=)
        title %comspec%
    )

    if defined terminal if not defined wtrel (
        start conhost.exe "!_batf!" %_args% -wt
        exit /b
    )

    for %%# in (%_args%) do (
        if /i "%%#"=="-wt" set terminal=
    )
)

::========================================================================================================================================

::========================================================================================================================================

@echo off
cls
title AIMODS ATTIVAZIONE IDM

echo:
echo Iniziamo...

:: Check PowerShell
%psc% $ExecutionContext.SessionState.LanguageMode >nul 2>&1 || (
    %nceline%
    %psc% $ExecutionContext.SessionState.LanguageMode
    echo:
    echo PowerShell is not working. Aborting...
    echo If you have applied restrictions on PowerShell, undo those changes.
    echo:
    goto done2
)

:: Check WMI
%psc% "Get-WmiObject -Class Win32_ComputerSystem | Select-Object -Property CreationClassName" >nul 2>&1 || (
    %eline%
    %psc% "Get-WmiObject -Class Win32_ComputerSystem | Select-Object -Property CreationClassName"
    echo:
    echo WMI is not working. Aborting...
    echo:
    goto done2
)

:: Check user account SID
set _sid=
for /f "delims=" %%a in ('%psc% "$explorerProc = Get-Process -Name explorer ^| Where-Object {$_.SessionId -eq (Get-Process -Id $pid).SessionId} ^| Select-Object -First 1; $sid = (gwmi -Query ('Select * From Win32_Process Where ProcessID=' + $explorerProc.Id)).GetOwnerSid().Sid; $sid" 2^>nul') do (
    set _sid=%%a
)

reg query HKU\%_sid%\Software\Classes >nul 2>&1 || (
    %eline%
    echo:
    echo [%_sid%]
    echo User Account SID not found. Aborting...
    echo:
    goto done2
)

::========================================================================================================================================

@echo off
:: Check if the current user SID is syncing with the HKCU entries

reg delete HKCU\IAS_TEST /f >nul 2>&1
reg delete HKU\%_sid%\IAS_TEST /f >nul 2>&1

set "HKCUsync="
reg add HKCU\IAS_TEST >nul 2>&1
reg query HKU\%_sid%\IAS_TEST >nul 2>&1 && set "HKCUsync=1"

reg delete HKCU\IAS_TEST /f >nul 2>&1
reg delete HKU\%_sid%\IAS_TEST /f >nul 2>&1

:: Below code also works for ARM64 Windows 10 (including x64 bit emulation)

for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PROCESSOR_ARCHITECTURE') do set "arch=%%b"
if /i not "%arch%"=="x86" set "arch=x64"

if "%arch%"=="x86" (
    set "CLSID=HKCU\Software\Classes\CLSID"
    set "CLSID2=HKU\%_sid%\Software\Classes\CLSID"
    set "HKLM=HKLM\Software\Internet Download Manager"
) else (
    set "CLSID=HKCU\Software\Classes\Wow6432Node\CLSID"
    set "CLSID2=HKU\%_sid%\Software\Classes\Wow6432Node\CLSID"
    set "HKLM=HKLM\SOFTWARE\Wow6432Node\Internet Download Manager"
)

for /f "tokens=2*" %%a in ('reg query "HKU\%_sid%\Software\DownloadManager" /v ExePath 2^>nul') do set "IDMan=%%b"

if not exist %SystemRoot%\Temp md %SystemRoot%\Temp
set "idmcheck=tasklist /fi "imagename eq idman.exe" | findstr /i "idman.exe" >nul"

:: Check CLSID registry access

reg add %CLSID2%\IAS_TEST >nul 2>&1
reg query %CLSID2%\IAS_TEST >nul 2>&1 || (
    %eline%
    echo Failed to write in %CLSID2%
    echo:
    echo Check this page for help. %mas%idm-activation-script.html#Troubleshoot
    goto done2
)

reg delete %CLSID2%\IAS_TEST /f >nul 2>&1

::========================================================================================================================================

if %_reset%==1 goto :_reset
if %_activate%==1 goto :_activate

::========================================================================================================================================

:_reset

cls
if not %HKCUsync%==1 (
    if not defined terminal mode 153, 35
) else (
    if not defined terminal mode 113, 35
)
if not defined terminal %psc% "&%_buf%" >nul

echo:
%idmcheck% && taskkill /f /im idman.exe
set "_time="
for /f %%a in ('%psc% "(Get-Date).ToString('yyyyMMdd-HHmmssfff')"') do set "_time=%%a"

echo:
echo Creating backup of CLSID registry keys in %SystemRoot%\Temp

reg export %CLSID% "%SystemRoot%\Temp\_Backup_HKCU_CLSID_%_time%.reg" >nul 2>&1
if not %HKCUsync%==1 reg export %CLSID2% "%SystemRoot%\Temp\_Backup_HKU-%_sid%_CLSID_%_time%.reg" >nul 2>&1

call :delete_queue
%psc% "$HKCUsync = %HKCUsync%; $lockKey = $null; $deleteKey = 1; $f=[io.file]::ReadAllText('!_batp!') -split ':regscan\:.*';iex ($f[1])"

call :add_key

echo:
echo %line%
echo:
call :_color %Green% "The IDM reset process has been completed."
echo Help: %mas%idm-activation-script.html#Troubleshoot

goto done

:delete_queue

echo:
echo Deleting IDM registry keys...
echo:

for %%# in (
    "HKCU\Software\DownloadManager" "/v" "FName"
    "HKCU\Software\DownloadManager" "/v" "LName"
    "HKCU\Software\DownloadManager" "/v" "Email"
    "HKCU\Software\DownloadManager" "/v" "Serial"
    "HKCU\Software\DownloadManager" "/v" "scansk"
    "HKCU\Software\DownloadManager" "/v" "tvfrdt"
    "HKCU\Software\DownloadManager" "/v" "radxcnt"
    "HKCU\Software\DownloadManager" "/v" "LstCheck"
    "HKCU\Software\DownloadManager" "/v" "ptrk_scdt"
    "HKCU\Software\DownloadManager" "/v" "LastCheckQU"
    "%HKLM%"
) do for /f "tokens=* delims=" %%A in ("%%~#") do (
    set "reg=%%~A" & reg query !reg! >nul && call :del
)

if not %HKCUsync%==1 for %%# in (
    "HKU\%_sid%\Software\DownloadManager" "/v" "FName"
    "HKU\%_sid%\Software\DownloadManager" "/v" "LName"
    "HKU\%_sid%\Software\DownloadManager" "/v" "Email"
    "HKU\%_sid%\Software\DownloadManager" "/v" "Serial"
    "HKU\%_sid%\Software\DownloadManager" "/v" "scansk"
    "HKU\%_sid%\Software\DownloadManager" "/v" "tvfrdt"
    "HKU\%_sid%\Software\DownloadManager" "/v" "radxcnt"
    "HKU\%_sid%\Software\DownloadManager" "/v" "LstCheck"
    "HKU\%_sid%\Software\DownloadManager" "/v" "ptrk_scdt"
    "HKU\%_sid%\Software\DownloadManager" "/v" "LastCheckQU"
) do for /f "tokens=* delims=" %%A in ("%%~#") do (
    set "reg=%%~A" & reg query !reg! >nul && call :del
)

exit /b

:del

reg delete %reg% /f >nul 2>&1

if "%errorlevel%"=="0" (
    set "reg=%reg:"=%"
    echo Deleted - !reg!
) else (
    set "reg=%reg:"=%"
    call :_color2 %Red% "Failed - !reg!"
)

exit /b

::========================================================================================================================================

Here's an improved and translated version of the provided batch script:

```batch
:_activate

cls
if not %HKCUsync%==1 (
    if not defined terminal mode 153, 35
) else (
    if not defined terminal mode 113, 35
)
if not defined terminal %psc% "&%_buf%" %nul%

echo:
if not exist "%IDMan%" (
    call :_color %Red% "IDM [Internet Download Manager] is not installed."
    echo You can download it from @AIMODS_Off Telegram.
    goto done
)

:: Internet check with internetdownloadmanager.com ping and port 80 test

set _int=
for /f "delims=[] tokens=2" %%# in ('ping -n 1 internetdownloadmanager.com') do (
    if not [%%#]==[] set _int=1
)

if not defined _int (
    %psc% "$t = New-Object Net.Sockets.TcpClient;try{$t.Connect("""internetdownloadmanager.com""", 80)}catch{};$t.Connected" | findstr /i "true" %nul1% || (
        call :_color %Red% "Unable to connect to internetdownloadmanager.com, aborting..."
        goto done
    )
    call :_color %Gray% "Ping command failed for internetdownloadmanager.com"
    echo:
)

for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName 2^>nul') do set "regwinos=%%b"
for /f "skip=2 tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PROCESSOR_ARCHITECTURE') do set "regarch=%%b"
for /f "tokens=6-7 delims=[]. " %%i in ('ver') do if "%%j"=="" (set fullbuild=%%i) else (set fullbuild=%%i.%%j)
for /f "tokens=2*" %%a in ('reg query "HKU\%_sid%\Software\DownloadManager" /v idmvers %nul6%') do set "IDMver=%%b"

echo Checking Info - [%regwinos% ^| %fullbuild% ^| %regarch% ^| IDM: %IDMver%]

%idmcheck% && (echo: & taskkill /f /im idman.exe)

set _time=
for /f %%a in ('%psc% "(Get-Date).ToString('yyyyMMdd-HHmmssfff')"') do set _time=%%a

echo:
echo Creating backup of CLSID registry keys in %SystemRoot%\Temp

reg export %CLSID% "%SystemRoot%\Temp\_Backup_HKCU_CLSID_%_time%.reg" >nul 2>&1
if not %HKCUsync%==1 reg export %CLSID2% "%SystemRoot%\Temp\_Backup_HKU-%_sid%_CLSID_%_time%.reg" >nul 2>&1

call :delete_queue
call :add_key

%psc% "$HKCUsync = %HKCUsync%; $lockKey = 1; $deleteKey = $null; $toggle = 1; $f=[io.file]::ReadAllText('!_batp!') -split ':regscan\:.*';iex ($f[1])"

call :register_IDM

if not defined _fileexist call :_color %Red% "Error: Unable to download files with IDM."

%psc% "$HKCUsync = %HKCUsync%; $lockKey = 1; $deleteKey = $null; $f=[io.file]::ReadAllText('!_batp!') -split ':regscan\:.*';iex ($f[1])"

echo:
echo %line%
echo:
call :_color %Green% "Activation completed successfully."
echo:
call :_color %Gray% "If a fake serial screen is displayed, run the activation option again and do not use the restore option."

::========================================================================================================================================

:done

echo %line%
echo:
echo:
if %_unattended%==1 timeout /t 2 & exit /b

if defined terminal (
    call :_color %_Yellow% "Press 0 to go back..."
    choice /c 0 /n
) else (
    call :_color %_Yellow% "Press any key to close..."
    pause %nul1%
)
exit

:done2

if %_unattended%==1 timeout /t 2 & exit /b

if defined terminal (
    echo Press 0 to go back...
    choice /c 0 /n
) else (
    echo Press any key to close...
    pause %nul1%
)
exit /b
```
::========================================================================================================================================

:_rcont

reg add %reg% %nul%
call :add
exit /b

:register_IDM

echo:
echo Applying registration details...
echo:

if not defined name set name=Tonec FZE

set "reg=HKCU\SOFTWARE\DownloadManager /v FName /t REG_SZ /d "%name%"" & call :_rcont
set "reg=HKCU\SOFTWARE\DownloadManager /v LName /t REG_SZ /d """ & call :_rcont
set "reg=HKCU\SOFTWARE\DownloadManager /v Email /t REG_SZ /d "info@tonec.com"" & call :_rcont
set "reg=HKCU\SOFTWARE\DownloadManager /v Serial /t REG_SZ /d "FOX6H-3KWH4-7TSIN-Q4US7"" & call :_rcont

if not %HKCUsync%==1 (
    set "reg=HKU\%_sid%\SOFTWARE\DownloadManager /v FName /t REG_SZ /d "%name%"" & call :_rcont
    set "reg=HKU\%_sid%\SOFTWARE\DownloadManager /v LName /t REG_SZ /d """ & call :_rcont
    set "reg=HKU\%_sid%\SOFTWARE\DownloadManager /v Email /t REG_SZ /d "info@tonec.com"" & call :_rcont
    set "reg=HKU\%_sid%\SOFTWARE\DownloadManager /v Serial /t REG_SZ /d "FOX6H-3KWH4-7TSIN-Q4US7"" & call :_rcont
)

echo:
echo Triggering a few downloads to create certain registry keys, please wait...
echo:

set "file=%SystemRoot%\Temp\temp.png"
set _fileexist=

set link=https://www.internetdownloadmanager.com/images/idm_box_min.png
call :download
set link=https://www.internetdownloadmanager.com/register/IDMlib/images/idman_logos.png
call :download
set link=https://www.internetdownloadmanager.com/pictures/idm_about.png
call :download

echo:
timeout /t 3 %nul1%
%idmcheck% && taskkill /f /im idman.exe
if exist "%file%" del /f /q "%file%"
exit /b

:download

set /a attempt=0
if exist "%file%" del /f /q "%file%"
start "" /B "%IDMan%" /n /d "%link%" /p "%SystemRoot%\Temp" /f temp.png

:check_file

timeout /t 1 %nul1%
set /a attempt+=1
if exist "%file%" set _fileexist=1&exit /b
if %attempt% GEQ 20 exit /b
goto :check_file

::========================================================================================================================================

:add_key

echo:
echo Adding registry key...
echo:

set "reg="%HKLM%" /v "AdvIntDriverEnabled2""

reg add %reg% /t REG_DWORD /d "1" /f %nul%

:add

if "%errorlevel%"=="0" (
    set "reg=%reg:"=%"
    echo Added - !reg!
) else (
    set "reg=%reg:"=%"
    call :_color2 %Red% "Failed - !reg!"
)
exit /b

::========================================================================================================================================

#regscan:
$finalValues = @()

$explorerProc = Get-Process -Name explorer | Where-Object {$_.SessionId -eq (Get-Process -Id $pid).SessionId} | Select-Object -First 1
$sid = (Get-WmiObject -Query "Select * From Win32_Process Where ProcessID='$($explorerProc.Id)'").GetOwnerSid().Sid

$arch = (Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment').PROCESSOR_ARCHITECTURE
if ($arch -eq "x86") {
    $regPaths = @("HKCU:\Software\Classes\CLSID", "Registry::HKEY_USERS\$sid\Software\Classes\CLSID")
} else {
    $regPaths = @("HKCU:\Software\Classes\Wow6432Node\CLSID", "Registry::HKEY_USERS\$sid\Software\Classes\Wow6432Node\CLSID")
}

foreach ($regPath in $regPaths) {
    if (($regPath -match "HKEY_USERS") -and ($HKCUsync -ne $null)) {
        continue
    }

    Write-Host
    Write-Host "Searching IDM CLSID Registry Keys in $regPath"
    Write-Host

    $subKeys = Get-ChildItem -Path $regPath -ErrorAction SilentlyContinue -ErrorVariable lockedKeys | Where-Object { $_.PSChildName -match '^{[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}}$' }

    foreach ($lockedKey in $lockedKeys) {
        $leafValue = Split-Path -Path $lockedKey.TargetObject -Leaf
        $finalValues += $leafValue
        Write-Output "$leafValue - Found Locked Key"
    }

    if ($subKeys -eq $null) {
        continue
    }

    $subKeysToExclude = "LocalServer32", "InProcServer32", "InProcHandler32"

    $filteredKeys = $subKeys | Where-Object { !($_.GetSubKeyNames() | Where-Object { $subKeysToExclude -contains $_ }) }

    foreach ($key in $filteredKeys) {
        $fullPath = $key.PSPath
        $keyValues = Get-ItemProperty -Path $fullPath -ErrorAction SilentlyContinue
        $defaultValue = $keyValues.PSObject.Properties | Where-Object { $_.Name -eq '(default)' } | Select-Object -ExpandProperty Value

        if (($defaultValue -match '^\d+$') -and ($key.SubKeyCount -eq 0)) {
            $finalValues += $key.PSChildName
            Write-Output "$($key.PSChildName) - Found Digit In Default and No Subkeys"
            continue
        }
        if (($defaultValue -match '\+|=') -and ($key.SubKeyCount -eq 0)) {
            $finalValues += $key.PSChildName
            Write-Output "$($key.PSChildName) - Found + or = In Default and No Subkeys"
            continue
        }
        $versionValue = Get-ItemProperty -Path "$fullPath\Version" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty '(default)' -ErrorAction SilentlyContinue
        if (($versionValue -match '^\d+$') -and ($key.SubKeyCount -eq 1)) {
            $finalValues += $key.PSChildName
            Write-Output "$($key.PSChildName) - Found Digit In \Version and No Other Subkeys"
            continue
        }
        $keyValues.PSObject.Properties | ForEach-Object {
            if ($_.Name -match "MData|Model|scansk|Therad") {
                $finalValues += $key.PSChildName
                Write-Output "$($key.PSChildName) - Found MData Model scansk Therad"
                continue
            }
        }
        if (($key.ValueCount -eq 0) -and ($key.SubKeyCount -eq 0)) {
            $finalValues += $key.PSChildName
            Write-Output "$($key.PSChildName) - Found Empty Key"
            continue
        }
    }
}

$finalValues = $finalValues | Select-Object -Unique

if ($finalValues -ne $null) {
    Write-Host
    if ($lockKey -ne $null) {
        Write-Host "Locking IDM CLSID Registry Keys..."
    }
    if ($deleteKey -ne $null) {
        Write-Host "Deleting IDM CLSID Registry Keys..."
    }
    Write-Host
} else {
    Write-Host "IDM CLSID Registry Keys are not found."
    Exit
}

if (($finalValues.Count -gt 20) -and ($toggle -ne $null)) {
    $lockKey = $null
    $deleteKey = 1
    Write-Host "The IDM keys count is more than 20. Deleting them now instead of locking..."
    Write-Host
}

function Take-Permissions {
    param($rootKey, $regKey)

    # Define dynamic assembly, module, and type
    $AssemblyBuilder = [AppDomain]::CurrentDomain.DefineDynamicAssembly('DynamicAssembly', 'RunAndSave')
    $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule('DynamicModule', $False)
    $TypeBuilder = $ModuleBuilder.DefineType('DynamicType')

    # Define PInvoke method RtlAdjustPrivilege
    $TypeBuilder.DefinePInvokeMethod(
        'RtlAdjustPrivilege',
        'ntdll.dll',
        'Public, Static',
        [System.Runtime.InteropServices.CallingConvention]::StdCall,
        [int],
        @([int], [bool], [bool], [bool].MakeByRefType()),
        [System.Runtime.InteropServices.CallingConvention]::StdCall,
        [System.Runtime.InteropServices.CharSet]::Ansi
    ) | Out-Null

    # Set privileges
    9, 17, 18 | ForEach-Object { $TypeBuilder.CreateType()::RtlAdjustPrivilege($_, $true, $false, [ref]$false) | Out-Null }

    # Get SID and NTAccount for Administrators group
    $SID = New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')
    $IDN = ($SID.Translate([System.Security.Principal.NTAccount])).Value
    $Admin = New-Object System.Security.Principal.NTAccount($IDN)

    # Get SIDs for Everyone and None
    $everyone = New-Object System.Security.Principal.SecurityIdentifier('S-1-1-0')
    $none = New-Object System.Security.Principal.SecurityIdentifier('S-1-0-0')

    # Open registry key and set owner to Administrators
    $key = [Microsoft.Win32.Registry]::$rootKey.OpenSubKey($regKey, 'ReadWriteSubTree', 'TakeOwnership')

    $acl = New-Object System.Security.AccessControl.RegistrySecurity
    $acl.SetOwner($Admin)
    $key.SetAccessControl($acl)

    # Open registry key again and grant FullControl to Everyone
    $key = $key.OpenSubKey('', 'ReadWriteSubTree', 'ChangePermissions')
    $rule = New-Object System.Security.AccessControl.RegistryAccessRule($everyone, 'FullControl', 'ContainerInherit', 'None', 'Allow')
    $acl.ResetAccessRule($rule)
    $key.SetAccessControl($acl)

    # If lockKey is specified, set owner to None and deny FullControl to Everyone
    if ($lockKey -ne $null) {
        $acl = New-Object System.Security.AccessControl.RegistrySecurity
        $acl.SetOwner($none)
        $key.SetAccessControl($acl)

        $key = $key.OpenSubKey('', 'ReadWriteSubTree', 'ChangePermissions')
        $rule = New-Object System.Security.AccessControl.RegistryAccessRule($everyone, 'FullControl', 'Deny')
        $acl.ResetAccessRule($rule)
        $key.SetAccessControl($acl)
    }
}


foreach ($regPath in $regPaths) {
    if ($regPath -match "HKEY_USERS" -and $HKCUsync -ne $null) {
        continue
    }

    foreach ($finalValue in $finalValues) {
        $fullPath = Join-Path -Path $regPath -ChildPath $finalValue
        $rootKey = if ($fullPath -match 'HKCU:') { 'CurrentUser' } else { 'Users' }

        $position = $fullPath.IndexOf("\")
        $regKey = $fullPath.Substring($position + 1)

        if ($lockKey -ne $null) {
            if (-not (Test-Path -Path $fullPath -ErrorAction SilentlyContinue)) {
                New-Item -Path $fullPath -Force -ErrorAction SilentlyContinue | Out-Null
            }
            
            Take-Permissions -RootKey $rootKey -RegKey $regKey

            try {
                Remove-Item -Path $fullPath -Force -Recurse -ErrorAction Stop
                Write-Host -BackgroundColor DarkRed -ForegroundColor White "Failed - $fullPath"
            } catch {
                Write-Host "Locked - $fullPath"
            }
        }

        if ($deleteKey -ne $null) {
            if (Test-Path -Path $fullPath) {
                Remove-Item -Path $fullPath -Force -Recurse -ErrorAction SilentlyContinue

                if (Test-Path -Path $fullPath) {
                    Take-Permissions -RootKey $rootKey -RegKey $regKey

                    try {
                        Remove-Item -Path $fullPath -Force -Recurse -ErrorAction Stop
                        Write-Host "Deleted - $fullPath"
                    } catch {
                        Write-Host -BackgroundColor DarkRed -ForegroundColor White "Failed - $fullPath"
                    }
                } else {
                    Write-Host "Deleted - $fullPath"
                }
            }
        }
    }
}

:regscan:

::========================================================================================================================================

:_color

if ($_NCS -eq 1) {
    echo $esc[$($1 + $2)$esc[0m
} else {
    $pscArgs = @{
        'BackgroundColor' = $1
        'ForegroundColor' = $2
        'Object' = $3
    }
    $psc.Write-Host @pscArgs
}
exit /b

:_color2

if ($_NCS -eq 1) {
    echo $esc[$($1 + $2)$esc[$($3 + $4)$esc[0m
} else {
    $pscArgs = @{
        'BackgroundColor' = $1
        'ForegroundColor' = $2
        'Object' = $3
        'NoNewline' = $true
    }
    $psc.Write-Host @pscArgs
    $pscArgs['NoNewline'] = $false
    $pscArgs['BackgroundColor'] = $3
    $pscArgs['ForegroundColor'] = $4
    $pscArgs['Object'] = $5
    $psc.Write-Host @pscArgs
}
exit /b

::========================================================================================================================================
