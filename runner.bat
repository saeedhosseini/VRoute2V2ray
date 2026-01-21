@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "BASEDIR=%~dp0"
set "OVPNDIR=%BASEDIR%ovpn"
set "SETFILE=%BASEDIR%settings.ini"
set "ENVFILE=%BASEDIR%.env"

call :loadSettings

:menu
cls
echo ==========================================
echo   OVPN Gateway Menu
echo ==========================================
echo Host IP   : !HOST_IP!
echo Xray Port : !XRAY_PORT!  (LAN -> host port)
echo User      : !VPN_USER!
echo ==========================================
echo.
echo 1) Settings (Host IP + Port + Username + Password)
echo 2) Select OVPN Config (UDP/TCP + Server 2..13)
echo 3) Start
echo 4) Stop
echo 5) Restart
echo 6) Status
echo 7) Tail Logs (ovpn_client)
echo 8) Generate Client JSON (vmess) to client.json
echo 0) Exit
echo.
set /p M=Select:

if "%M%"=="1" goto setall
if "%M%"=="2" goto selectcfg
if "%M%"=="3" goto start
if "%M%"=="4" goto stop
if "%M%"=="5" goto restart
if "%M%"=="6" goto status
if "%M%"=="7" goto logs
if "%M%"=="8" goto genclient
if "%M%"=="0" exit /b
goto menu

:setall
cls
echo ===== Settings =====
echo NOTE: In CMD password will be visible while typing.
echo.
set /p HIP=Host IP (blank = keep !HOST_IP!):
if not "%HIP%"=="" set "HOST_IP=%HIP%"

set /p PR=Port (blank = keep !XRAY_PORT!, default 8443):
if not "%PR%"=="" set "XRAY_PORT=%PR%"

set /p U=Username (blank = keep !VPN_USER!):
if not "%U%"=="" set "VPN_USER=%U%"

set /p P=Password (blank = keep current password):
if not "%P%"=="" set "VPN_PASS=%P%"

call :saveSettings
call :saveEnv

echo.
echo Saved settings.ini and .env
pause
goto menu

:selectcfg
cls
echo Select Protocol:
echo 1) UDP
echo 2) TCP
echo.
set "PROTO="
set /p PSEL=Enter 1 or 2:
if "%PSEL%"=="1" set "PROTO=UDP"
if "%PSEL%"=="2" set "PROTO=TCP"
if not defined PROTO (
  echo Invalid choice.
  pause
  goto menu
)

echo.
echo Select Server Number (2..13):
set /p SNUM=Enter server number:

for /f "delims=0123456789" %%A in ("%SNUM%") do (
  echo Invalid number.
  pause
  goto menu
)

if %SNUM% LSS 2 (echo Range is 2..13 & pause & goto menu)
if %SNUM% GTR 13 (echo Range is 2..13 & pause & goto menu)

set "CFG=VS%SNUM%_%PROTO%.ovpn"
set "SRC=%OVPNDIR%\%CFG%"
set "DST=%OVPNDIR%\ACTIVE.ovpn"

if not exist "%SRC%" (
  echo [ERROR] Not found: %SRC%
  dir /b "%OVPNDIR%\VS*_%PROTO%.ovpn"
  pause
  goto menu
)

copy /Y "%SRC%" "%DST%" >nul
echo.
echo ACTIVE.ovpn updated to: %CFG%
echo.

set /p R=Restart now? (Y to restart):
if /I "%R%"=="Y" (
  call :doStop
  call :doStart
) else (
  echo Skipped restart.
  pause
)
goto menu

:start
call :doStart
pause
goto menu

:stop
call :doStop
pause
goto menu

:restart
call :doStop
call :doStart
pause
goto menu

:status
cd /d "%BASEDIR%"
docker compose ps -a
pause
goto menu

:logs
cd /d "%BASEDIR%"
echo === ovpn_client logs (Ctrl+C to stop) ===
docker logs -f ovpn_client
goto menu

:genclient
cd /d "%BASEDIR%"
if not exist "%SETFILE%" call :saveSettings
set "OUT=%BASEDIR%client.json"
> "%OUT%" (
  echo { 
  echo   "v": "2",
  echo   "ps": "Company-OVPN-GW",
  echo   "add": "!HOST_IP!",
  echo   "port": "!XRAY_PORT!",
  echo   "id": "!VMESS_UUID!",
  echo   "aid": "0",
  echo   "net": "tcp",
  echo   "type": "none",
  echo   "host": "",
  echo   "path": "",
  echo   "tls": ""
  echo }
)
echo.
echo Wrote: %OUT%
pause
goto menu

:doStart
cd /d "%BASEDIR%"

REM write auth.txt from settings (single source of truth)
if not exist "%OVPNDIR%" (
  echo [ERROR] ovpn folder not found: %OVPNDIR%
  exit /b 1
)
> "%OVPNDIR%\auth.txt" (
  echo %VPN_USER%
  echo %VPN_PASS%
)

REM ensure .env is synced
call :saveEnv

docker compose up -d
echo.
docker logs --tail 6 ovpn_client
exit /b 0

:doStop
cd /d "%BASEDIR%"
docker compose down --remove-orphans
exit /b 0

:loadSettings
REM defaults
set "HOST_IP=192.168.103.61"
set "XRAY_PORT=8443"
set "VPN_USER="
set "VPN_PASS="
set "VMESS_UUID=6f9d7d2a-9c8c-4d29-9cf2-9f1b5b0a3a01"

if exist "%SETFILE%" (
  for /f "usebackq tokens=1,* delims==" %%A in ("%SETFILE%") do (
    if /I "%%A"=="HOST_IP" set "HOST_IP=%%B"
    if /I "%%A"=="XRAY_PORT" set "XRAY_PORT=%%B"
    if /I "%%A"=="VPN_USER" set "VPN_USER=%%B"
    if /I "%%A"=="VPN_PASS" set "VPN_PASS=%%B"
    if /I "%%A"=="VMESS_UUID" set "VMESS_UUID=%%B"
  )
)
exit /b 0

:saveSettings
> "%SETFILE%" (
  echo HOST_IP=%HOST_IP%
  echo XRAY_PORT=%XRAY_PORT%
  echo VPN_USER=%VPN_USER%
  echo VPN_PASS=%VPN_PASS%
  echo VMESS_UUID=%VMESS_UUID%
)
exit /b 0

:saveEnv
> "%ENVFILE%" (
  echo XRAY_PORT=%XRAY_PORT%
)
exit /b 0
