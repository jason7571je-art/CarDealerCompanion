@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Car Dealer Companion v0.45.0.0 Installer

echo ============================================================
echo  CAR DEALER COMPANION v0.45.0.0
echo ============================================================
echo.

call :ResolveGame
if errorlevel 1 goto :Fail

echo Game folder:
echo   %GAME_ROOT%
echo.
echo UE4SS Mods folder:
echo   %MODS_DIR%
echo.

if not exist "%MODS_DIR%" (
  echo ERROR: UE4SS Mods folder not found.
  echo.
  echo Car Dealer Companion requires UE4SS to be installed first.
  echo Install UE4SS into this game's Win64 folder, then run INSTALL.cmd again.
  echo.
  pause
  exit /b 1
)

set "OVERLAY_DIR=%LOCALAPPDATA%\CarDealerInventoryOverlay"
set "MOD_DIR=%MODS_DIR%\CarDealerInventoryReader"

echo Installing Companion files...
if not exist "%MOD_DIR%" mkdir "%MOD_DIR%" >nul 2>&1
if not exist "%MOD_DIR%\Scripts" mkdir "%MOD_DIR%\Scripts" >nul 2>&1
if not exist "%OVERLAY_DIR%" mkdir "%OVERLAY_DIR%" >nul 2>&1

copy /y "%~dp0CarDealerInventoryReader\enabled.txt" "%MOD_DIR%\enabled.txt" >nul
copy /y "%~dp0CarDealerInventoryReader\Scripts\main.lua" "%MOD_DIR%\Scripts\main.lua" >nul

for %%F in (
  "Catalog.json"
  "GameWatcher.ps1"
  "LaunchOverlay.vbs"
  "LaunchWatcher.vbs"
  "Overlay.ps1"
) do (
  copy /y "%~dp0Overlay\%%~F" "%OVERLAY_DIR%\%%~F" >nul
)

REM Legacy Car Dealer Companion helper mods are disabled during upgrade only.
REM They are NOT included in this release.
if exist "%MODS_DIR%\mods.txt" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
    "$p='%MODS_DIR%\mods.txt'; $old=@('CarDealerFittedPartsProbe','CarDealerFittedPartsTest','CarDealerVehicleDetailsTest','CarDealerVehicleDisplayNameTest','CarDealerMyAdsDiscovery','CarDealerUsedCarsDiscovery','CarDealerDeepVehicleDiscovery','CarDealerScannerDiscovery','CarDealerVehicleTrunkDiscovery','CarDealerVehicleSalesDiscovery','CarDealerCarsDiscoverySweep2','CarDealerRuntimeIconProbe','CarDealerPhotoZoneProbe'); if(Test-Path -LiteralPath $p){$t=Get-Content -LiteralPath $p; foreach($n in $old){$t=$t -replace ('(?im)^\s*'+[regex]::Escape($n)+'\s*:\s*1\s*$'),($n+' : 0')}; Set-Content -LiteralPath $p -Value $t -Encoding ASCII}" >nul 2>&1
)

REM Register per-user watcher startup.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "CarDealerCompanionWatcher" /t REG_SZ /d "wscript.exe \"%OVERLAY_DIR%\LaunchWatcher.vbs\"" /f >nul

REM Stop any stale Companion watcher/overlay and start the installed watcher.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "Get-CimInstance Win32_Process ^| Where-Object {($_.Name -match 'powershell|wscript') -and $_.CommandLine -match 'CarDealerInventoryOverlay|LaunchWatcher|GameWatcher'} ^| ForEach-Object {Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue}" >nul 2>&1

start "" wscript.exe "%OVERLAY_DIR%\LaunchWatcher.vbs"

echo.
echo Installation complete.
echo.
echo UI hotkey : F1 (show/focus/hide Companion)
echo.
echo The Companion watcher starts with Windows for the current user
echo and launches the UI when Car Dealer Simulator is running.
echo.
pause
exit /b 0

:Fail
echo.
echo Installation cancelled.
pause
exit /b 1
:ResolveGame
set "GAME_ROOT="
set "MODS_DIR="

REM 1) Known default Steam locations.
for %%G in (
  "C:\Program Files (x86)\Steam\steamapps\common\Car Dealer Simulator"
  "C:\Program Files\Steam\steamapps\common\Car Dealer Simulator"
) do (
  if exist "%%~G\CarDealerSimulator\Binaries\Win64" (
    set "GAME_ROOT=%%~G"
    goto :GameResolved
  )
)

REM 2) Ask Steam itself for install path from registry.
set "STEAM_ROOT="
for /f "tokens=2,*" %%A in ('reg query "HKCU\Software\Valve\Steam" /v SteamPath 2^>nul ^| find /i "SteamPath"') do set "STEAM_ROOT=%%B"
if not defined STEAM_ROOT (
  for /f "tokens=2,*" %%A in ('reg query "HKLM\SOFTWARE\WOW6432Node\Valve\Steam" /v InstallPath 2^>nul ^| find /i "InstallPath"') do set "STEAM_ROOT=%%B"
)

if defined STEAM_ROOT (
  set "STEAM_ROOT=%STEAM_ROOT:/=\%"
  if exist "%STEAM_ROOT%\steamapps\common\Car Dealer Simulator\CarDealerSimulator\Binaries\Win64" (
    set "GAME_ROOT=%STEAM_ROOT%\steamapps\common\Car Dealer Simulator"
    goto :GameResolved
  )

  REM 3) Parse Steam libraryfolders.vdf for additional libraries.
  if exist "%STEAM_ROOT%\steamapps\libraryfolders.vdf" (
    for /f "tokens=2,*" %%A in ('findstr /i /c:"path" "%STEAM_ROOT%\steamapps\libraryfolders.vdf"') do (
      set "LIB=%%B"
      call :NormalizeLibrary
      if defined LIB (
        if exist "!LIB!\steamapps\common\Car Dealer Simulator\CarDealerSimulator\Binaries\Win64" (
          set "GAME_ROOT=!LIB!\steamapps\common\Car Dealer Simulator"
          goto :GameResolvedDelayed
        )
      )
    )
  )
)

REM 4) Manual fallback.
echo.
echo Car Dealer Simulator was not found automatically.
echo Please paste the game's main folder, for example:
echo D:\SteamLibrary\steamapps\common\Car Dealer Simulator
echo.
set /p "GAME_ROOT=Game folder: "
set "GAME_ROOT=%GAME_ROOT:"=%"
if not exist "%GAME_ROOT%\CarDealerSimulator\Binaries\Win64" (
  echo.
  echo ERROR: This does not appear to be the Car Dealer Simulator folder.
  echo Expected:
  echo   %GAME_ROOT%\CarDealerSimulator\Binaries\Win64
  exit /b 1
)

:GameResolved
set "MODS_DIR=%GAME_ROOT%\CarDealerSimulator\Binaries\Win64\ue4ss\Mods"
exit /b 0

:GameResolvedDelayed
for %%# in ("!GAME_ROOT!") do set "GAME_ROOT=%%~#"
set "MODS_DIR=%GAME_ROOT%\CarDealerSimulator\Binaries\Win64\ue4ss\Mods"
exit /b 0

:NormalizeLibrary
set "LIB=!LIB:"=!"
set "LIB=!LIB:\\=\!"
set "LIB=!LIB:/=\!"
exit /b 0