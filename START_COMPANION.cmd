@echo off
setlocal EnableExtensions
set "SRC=%~dp0"
set "RUNTIME=%LOCALAPPDATA%\CarDealerInventoryOverlay"
set "WATCHER=%RUNTIME%\GameWatcher.ps1"

if not exist "%RUNTIME%" mkdir "%RUNTIME%" >nul 2>&1
if not exist "%SRC%Overlay\Overlay.ps1" goto fail
if not exist "%SRC%Overlay\GameWatcher.ps1" goto fail

copy /Y "%SRC%Overlay\Overlay.ps1" "%RUNTIME%\Overlay.ps1" >nul || goto fail
copy /Y "%SRC%Overlay\GameWatcher.ps1" "%RUNTIME%\GameWatcher.ps1" >nul || goto fail
copy /Y "%SRC%Overlay\Catalog.json" "%RUNTIME%\Catalog.json" >nul || goto fail
copy /Y "%SRC%Overlay\LaunchOverlay.vbs" "%RUNTIME%\LaunchOverlay.vbs" >nul || goto fail
if exist "%SRC%Assets" (
  if exist "%RUNTIME%\Assets" rmdir /S /Q "%RUNTIME%\Assets" >nul 2>&1
  xcopy /E /I /H /Y "%SRC%Assets" "%RUNTIME%\Assets" >nul || goto fail
)

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$me=$PID; Get-CimInstance Win32_Process -Filter \"Name='powershell.exe'\" | Where-Object {$_.ProcessId -ne $me -and $_.CommandLine -like '*CarDealerInventoryOverlay*GameWatcher.ps1*'} | ForEach-Object {Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue}"

start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%WATCHER%"
timeout /t 2 /nobreak >nul
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$ok=Get-CimInstance Win32_Process -Filter \"Name='powershell.exe'\" | Where-Object {$_.CommandLine -like '*CarDealerInventoryOverlay*GameWatcher.ps1*'}; if($ok){Write-Host 'Watcher confirmed running.'}else{Write-Host 'WARNING: watcher did not stay running.'}"

REM If the game is already open, start the synchronized UI immediately too.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
 "$g=Get-Process -Name 'CarDealerSimulator-Win64-Shipping' -ErrorAction SilentlyContinue | Select-Object -First 1; if($g){Start-Process powershell.exe -WindowStyle Hidden -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','\"%RUNTIME%\Overlay.ps1\"'}"

exit /b 0
:fail
echo ERROR: Could not synchronize/start the Companion.
echo Extract the full ZIP and run INSTALL.cmd first.
pause
exit /b 1
