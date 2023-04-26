# Delayed Start Script

## About
Script to delay start of X processes and/or services by Y seconds.

## Configuration
The script has a set of configurable parameters located in the top of the file. Setting these values should be enough to get it up and running.
```bat
set /a enable_evt_logging=1
set /a enable_cmd_tracing=1
set /a delay=60*5
set delayed_processes=explorer.exe notepad.exe
set delayed_services=MSSQL$SQLEXPRESS
```

If no processes or services are required set the variable to an empty value.
```bat
set delayed_processes=
set delayed_services=
```

**Note:** Logging to the Windows Event Log might require admin privileges.

The full script is displayed below.
```bat
:: Script Init
@echo off
setlocal enabledelayedexpansion

:: Configurable Properties
set /a enable_evt_logging=1
set /a enable_cmd_tracing=1
set /a delay=60*5
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
    ((net session)>nul 2>&1) && (
        set /a is_admin=1
    ) || (
        set /a is_admin=0
    )
exit /b 0

:fn_trace
    if %enable_cmd_tracing% equ 1 (
        echo %*
    )
exit /b 0

:fn_log
    :: Extract all paramters that contains the full message to log
    :: 1 = Type, 2 = Id, 3* = Message (rest)
    set args=%*
    call set rest=%%args:*%2 =%%

    :: Stack Trace CMD
    call :fn_trace %rest%

    :: Windows Event Log
    if %enable_evt_logging% equ 1 if %is_admin% equ 1 (
        (eventcreate /t %1 /l %evt_log% /so %evt_src% /id %2 /d "%rest%")>nul
    )
exit /b 0

:fn_start_process
    call :fn_log %evt_inf% %evt_id_process% Starting process '%1'

    ((start %1)>nul 2>&1) && (
        call :fn_log %evt_inf% %evt_id_process% Started process '%1'
    ) || (
        call :fn_log %evt_err% %evt_id_script% Failed to !start process '%1'
    )
exit /b 0

:fn_start_service
    call :fn_log %evt_inf% %evt_id_service% Starting service '%1'

    ((net start %1)>nul 2>&1) && (
        call :fn_log %evt_inf% %evt_id_service% Started service '%1'
    ) || (
        call :fn_log %evt_err% %evt_id_script% Failed to !start service '%1'
    )
exit /b 0

:__main__
    :: Check If Admin Privileges
    call :fn_is_admin

    :: Start Trace
    call :fn_log %evt_inf% %evt_id_script% Starting script '%0'

    :: Trace If Not Admin Privileges
    if %is_admin% equ 0 (
        call :fn_trace No admin privileges
    )

    :: Wait For Y Seconds
    call :fn_log %evt_inf% %evt_id_script% Waiting !for %delay% seconds...
    (timeout /t %delay% /nobreak)>nul

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