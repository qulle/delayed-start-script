::   About: Script to delay start of X processes by Y seconds
::  Author: Qulle
::    Date: 2023-04-24
:: Version: 1.0.0

:: Script init
@echo off
setlocal enabledelayedexpansion

:: Configurable properties
set /a enable_event_logging=1
set /a enable_stack_tracing=1
set /a delayed_start_time=60*2
set delayed_processes=explorer.exe notepad.exe

:: Windows Event Viewer Options
set event_source=DELAYED_START_BAT
set event_log=APPLICATION
set event_level_error=ERROR
set event_level_warning=WARNING
set event_level_information=INFORMATION

:: Main entry point
goto :__main__

:: Helper functions
:fn_is_admin
    (net session)>nul 2>&1
    if %errorlevel% equ 0 (
        set is_admin=1
    ) else (
        set is_admin=0
    )
exit /b 0

:fn_event_log 
    call :fn_is_admin
    if %enable_event_logging% equ 1 if %is_admin% equ 1 (
        (eventcreate /t %1 /l %event_log% /so %event_source% /id %2 /d %3)>nul
    )
exit /b 0

:fn_trace
    if %enable_stack_tracing% equ 1 echo %*
exit /b 0

:: Main entry point
:__main__
    :: Start trace
    call :fn_trace Starting %0
    call :fn_event_log %event_level_information% 100 Starting

    call :fn_trace  Waiting !for %delayed_start_time% seconds...
    (timeout /t %delayed_start_time% /nobreak)>nul

    :: Start each process
    for %%a in (%delayed_processes%) do (
        call :fn_trace Starting %%a
        call :fn_event_log %event_level_information% 200 %%a
        start %%a
    )

    :: End trace
    call :fn_trace Exiting %0
    call :fn_event_log %event_level_information% 100 Exiting

endlocal
exit /b 0