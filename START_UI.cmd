@echo off
setlocal EnableExtensions
set "SRC=%~dp0"
set "RUNTIME=%LOCALAPPDATA%\CarDealerInventoryOverlay"
set "OVERLAY=%RUNTIME%\Overlay.ps1"

if not exist "%RUNTIME%" mkdir "%RUNTIME%" >nul 2>&1
if not exist "%SRC%Overlay\Overlay.ps1" goto fail
if not exist "%SRC%Overlay\GameWatcher.ps1" goto fail
if not exist "%SRC%Overlay\Catalog.json" goto fail
if not exist "%SRC%Overlay\LaunchOverlay.vbs" goto fail

REM Always synchronize the current build. Previous builds only copied when the
REM runtime was missing, which could launch an older UI after an upgrade.
copy /Y "%SRC%Overlay\Overlay.ps1" "%RUNTIME%\Overlay.ps1" >nul || goto fail
copy /Y "%SRC%Overlay\GameWatcher.ps1" "%RUNTIME%\GameWatcher.ps1" >nul || goto fail
copy /Y "%SRC%Overlay\Catalog.json" "%RUNTIME%\Catalog.json" >nul || goto fail
copy /Y "%SRC%Overlay\LaunchOverlay.vbs" "%RUNTIME%\LaunchOverlay.vbs" >nul || goto fail
if exist "%SRC%Assets" (
  if exist "%RUNTIME%\Assets" rmdir /S /Q "%RUNTIME%\Assets" >nul 2>&1
  xcopy /E /I /H /Y "%SRC%Assets" "%RUNTIME%\Assets" >nul || goto fail
)

REM Close only an existing Companion overlay, not the persistent watcher.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "Get-CimInstance Win32_Process -Filter \"Name='powershell.exe'\" | Where-Object {$_.CommandLine -like '*CarDealerInventoryOverlay*Overlay.ps1*'} | ForEach-Object {Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue}"

timeout /t 1 /nobreak >nul
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%OVERLAY%"

timeout /t 2 /nobreak >nul
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$ok=Get-CimInstance Win32_Process -Filter \"Name='powershell.exe'\" | Where-Object {$_.CommandLine -like '*CarDealerInventoryOverlay*Overlay.ps1*'}; if($ok){Write-Host 'Companion UI confirmed running.'; exit 0}else{Write-Host 'WARNING: Companion UI did not stay running. Check %%LOCALAPPDATA%%\CarDealerInventoryOverlay\overlay_error.log'; exit 1}"
exit /b %errorlevel%

:fail
echo ERROR: Could not synchronize or start the Companion UI.
echo Extract the full ZIP and try again.
pause
exit /b 1
