@echo off
REM Tailscale DERP Server Startup Script for Windows
REM Usage: start.bat [hostname] [http_port] [stun_port]

setlocal enabledelayedexpansion

REM Default configuration
if "%1"=="" (
    if "%DERP_HOSTNAME%"=="" (
        set DERP_HOSTNAME=localhost
    )
) else (
    set DERP_HOSTNAME=%1
)

if "%2"=="" (
    if "%DERP_HTTP_PORT%"=="" (
        set DERP_HTTP_PORT=9003
    )
) else (
    set DERP_HTTP_PORT=%2
)

if "%3"=="" (
    if "%DERP_STUN_PORT%"=="" (
        set DERP_STUN_PORT=9004
    )
) else (
    set DERP_STUN_PORT=%3
)

if "%DERP_VERIFY_CLIENTS%"=="" (
    set DERP_VERIFY_CLIENTS=true
)

REM Find derper binary
set BINARY_NAME=
for %%f in (derper-*.exe derper.exe) do (
    if exist "%%f" (
        set BINARY_NAME=%%f
        goto found
    )
)

echo Error: No derper binary found in current directory
echo Please ensure you have extracted the archive and are in the correct directory
pause
exit /b 1

:found

REM Create necessary directories
if not exist "certs" mkdir certs
if not exist "logs" mkdir logs

echo === Tailscale DERP Server Startup ===
echo Binary: %BINARY_NAME%
echo Hostname: %DERP_HOSTNAME%
echo HTTP Port: %DERP_HTTP_PORT%
echo STUN Port: %DERP_STUN_PORT%
echo Verify Clients: %DERP_VERIFY_CLIENTS%
echo Working Directory: %CD%
echo ==================================

REM Build command
set CMD=%BINARY_NAME% --hostname="%DERP_HOSTNAME%" -certmode manual -certdir ./certs -http-port -1 -a :%DERP_HTTP_PORT% -stun-port %DERP_STUN_PORT%

if "%DERP_VERIFY_CLIENTS%"=="true" (
    set CMD=!CMD! -verify-clients
)

echo Executing: !CMD!
echo.

REM Change to certs directory for certificate generation
cd certs

REM Execute the command
..\%BINARY_NAME% --hostname="%DERP_HOSTNAME%" -certmode manual -certdir ./ -http-port -1 -a :%DERP_HTTP_PORT% -stun-port %DERP_STUN_PORT% %VERIFY_FLAG%