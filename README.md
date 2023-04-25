# Delayed Start Script

## About
Script to delay start of X processes by Y seconds

## Configuration
The script has a set of configurable parameters located in the top of the file. Setting these values should be enough to get it up and running.
```bat
set /a enable_evt_logging=1
set /a enable_cmd_tracing=1
set /a delayed_time=60*2
set delayed_processes=explorer.exe notepad.exe
set delayed_services=MSSQL$SQLEXPRESS
```

If no processes and/or services are required set the variable to an empty value.
```bat
set delayed_processes=
set delayed_services=
```

**Note:** Logging to the Windows Event Log might require admin privileges.

The full script is displayed below.
```bat
:: Script init
@echo off
setlocal enabledelayedexpansion

:: Configurable Properties
set /a enable_evt_logging=1
set /a enable_cmd_tracing=1
set /a delayed_time=60*2
set delayed_processes=explorer.exe notepad.exe
set delayed_services=MSSQL$SQLEXPRESS

:: Windows Event Log Properties
set evt_src=DELAYED_START_BAT
set evt_log=APPLICATION
set evt_err=ERROR
set evt_war=WARNING
set evt_inf=INFORMATION

:: Windows Event Id:s
set /a evt_id_script=100
set /a evt_id_process=200
set /a evt_id_service=300

:: Main Entry Point
goto :__main__

:: Helper Functions
:fn_is_admin
    (net session)>nul 2>&1
    if %errorlevel% equ 0 (
        set is_admin=1
    ) else (
        set is_admin=0
    )
exit /b 0

:fn_log
    :: Extract all paramters that contains the full message to log
    :: 1 = Type, 2 = Id, 3* = Message (rest)
    set args=%*
    call set rest=%%args:*%2 =%%

    :: Stack Trace CMD
    if %enable_cmd_tracing% equ 1 echo %rest%

    :: Windows Event Log
    call :fn_is_admin
    if %enable_evt_logging% equ 1 if %is_admin% equ 1 (
        (eventcreate /t %1 /l %evt_log% /so %evt_src% /id %2 /d "%rest%")>nul
    )
exit /b 0

:fn_start_process
    call :fn_log %evt_inf% %evt_id_process% Starting process '%1'

    ((start %1) && (
        call :fn_log %evt_inf% %evt_id_process% Started process '%1'
    ) || (
        call :fn_log %evt_err% %evt_id_script% Failed to !start process '%1'
    ))
exit /b 0

:fn_start_service
    call :fn_log %evt_inf% %evt_id_service% Starting service '%1'

    ((net start %1) && (
        call :fn_log %evt_inf% %evt_id_service% Started service '%1'
    ) || (
        call :fn_log %evt_err% %evt_id_script% Failed to !start service '%1'
    ))
exit /b 0

:__main__
    :: Start Trace
    call :fn_log %evt_inf% %evt_id_script% Starting script '%0'

    :: Wait For Y Seconds
    call :fn_log %evt_inf% %evt_id_script% Waiting !for %delayed_time% seconds...
    (timeout /t %delayed_time% /nobreak)>nul

    :: Start Each Process
    for %%a in (%delayed_processes%) do (
        call :fn_start_process %%a
    )

    :: Start Each Service
    for %%b in (%delayed_services%) do (
        call :fn_start_service %%b
    )

    :: End Trace
    call :fn_log %evt_inf% %evt_id_script% Exiting script '%0'

endlocal
exit /b 0
```

## Author
[Qulle](https://github.com/qulle/)