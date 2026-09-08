@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Car Dealer Companion v0.45.0.0 Uninstaller

echo ============================================================
echo  CAR DEALER COMPANION v0.45.0.0 - UNINSTALL
echo ============================================================
echo.

call :ResolveGame
if errorlevel 1 (
  echo.
  echo Game installation could not be resolved automatically.
  echo The Companion's LocalAppData files and startup entry can still be removed.
  echo.
)

set "OVERLAY_DIR=%LOCALAPPDATA%\CarDealerInventoryOverlay"

REM Stop Companion-owned watcher / overlay processes.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "Get-CimInstance Win32_Process ^| Where-Object {($_.Name -match 'powershell|wscript') -and $_.CommandLine -match 'CarDealerInventoryOverlay|LaunchWatcher|GameWatcher'} ^| ForEach-Object {Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue}" >nul 2>&1

REM Remove startup registration.
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v "CarDealerCompanionWatcher" /f >nul 2>&1

REM Remove installed UE4SS Companion mod when game was located.
if defined MODS_DIR (
  if exist "%MODS_DIR%\CarDealerInventoryReader" rd /s /q "%MODS_DIR%\CarDealerInventoryReader"

  REM Remove obsolete Companion helper mod folders from old/private builds.
  for %%M in (
    CarDealerDiscoverySweep
    CarDealerSafeDiscovery
    CarDealerFittedPartsProbe
    CarDealerFittedPartsTest
    CarDealerVehicleDetailsTest
    CarDealerVehicleDisplayNameTest
    CarDealerMyAdsDiscovery
    CarDealerUsedCarsDiscovery
    CarDealerDeepVehicleDiscovery
    CarDealerScannerDiscovery
    CarDealerVehicleTrunkDiscovery
    CarDealerVehicleSalesDiscovery
    CarDealerCarsDiscoverySweep2
    CarDealerRuntimeIconProbe
    CarDealerPhotoZoneProbe
  ) do (
    if exist "%MODS_DIR%\%%M" rd /s /q "%MODS_DIR%\%%M"
  )

  if exist "%MODS_DIR%\mods.txt" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
      "$p='%MODS_DIR%\mods.txt'; $names=@('CarDealerInventoryReader','CarDealerDiscoverySweep','CarDealerSafeDiscovery','CarDealerFittedPartsProbe','CarDealerFittedPartsTest','CarDealerVehicleDetailsTest','CarDealerVehicleDisplayNameTest','CarDealerMyAdsDiscovery','CarDealerUsedCarsDiscovery','CarDealerDeepVehicleDiscovery','CarDealerScannerDiscovery','CarDealerVehicleTrunkDiscovery','CarDealerVehicleSalesDiscovery','CarDealerCarsDiscoverySweep2','CarDealerRuntimeIconProbe','CarDealerPhotoZoneProbe'); if(Test-Path -LiteralPath $p){$t=Get-Content -LiteralPath $p; $t=$t ^| Where-Object {$line=$_; -not ($names ^| Where-Object {$line -match ('(?i)^\s*'+[regex]::Escape($_)+'\s*:')})}; Set-Content -LiteralPath $p -Value $t -Encoding ASCII}" >nul 2>&1
  )
)

REM Remove runtime program files but preserve user settings/cache/save-like data.
if exist "%OVERLAY_DIR%\GameWatcher.ps1" del /q "%OVERLAY_DIR%\GameWatcher.ps1"
if exist "%OVERLAY_DIR%\LaunchOverlay.vbs" del /q "%OVERLAY_DIR%\LaunchOverlay.vbs"
if exist "%OVERLAY_DIR%\LaunchWatcher.vbs" del /q "%OVERLAY_DIR%\LaunchWatcher.vbs"
if exist "%OVERLAY_DIR%\Overlay.ps1" del /q "%OVERLAY_DIR%\Overlay.ps1"
if exist "%OVERLAY_DIR%\Catalog.json" del /q "%OVERLAY_DIR%\Catalog.json"
if exist "%OVERLAY_DIR%\overlay.pid" del /q "%OVERLAY_DIR%\overlay.pid"
if exist "%OVERLAY_DIR%\overlay_start.log" del /q "%OVERLAY_DIR%\overlay_start.log"

echo.
echo Car Dealer Companion has been uninstalled.
echo UE4SS itself was not removed.
echo Personal Companion cache/settings are preserved.
echo.
pause
exit /b 0
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