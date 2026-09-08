param()

$ErrorActionPreference = "SilentlyContinue"

$base = Join-Path $env:LOCALAPPDATA "CarDealerInventoryOverlay"
$overlay = Join-Path $base "Overlay.ps1"
$watchLog = Join-Path $base "watcher.log"

function Log([string]$text) {
    ("{0} {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $text) |
        Out-File -LiteralPath $watchLog -Append -Encoding ascii
}

function Get-CarDealerGame {
    $names = @(
        "CarDealerSimulator-Win64-Shipping",
        "CarDealerSimulator"
    )

    foreach($name in $names){
        $p = Get-Process -Name $name -ErrorAction SilentlyContinue | Select-Object -First 1
        if($p){ return $p }
    }

    # Fallback in case the executable name changes slightly.
    try{
        $p = Get-Process -ErrorAction SilentlyContinue |
            Where-Object { $_.ProcessName -like "CarDealer*" } |
            Select-Object -First 1
        if($p){ return $p }
    }catch{}

    return $null
}

function Overlay-Running {
    try{
        $procs = Get-CimInstance Win32_Process -Filter "Name='powershell.exe'"
        foreach ($p in $procs) {
            if ($p.ProcessId -ne $PID -and
                $p.CommandLine -and
                $p.CommandLine -like "*CarDealerInventoryOverlay*Overlay.ps1*") {
                return $true
            }
        }
    }catch{}
    return $false
}

function Start-Overlay {
    if (-not (Test-Path -LiteralPath $overlay)) {
        Log "ERROR: Overlay.ps1 missing: $overlay"
        return
    }

    if (Overlay-Running) { return }

    try{
        Log "Starting overlay."
        $p = Start-Process powershell.exe -WindowStyle Hidden -PassThru -ArgumentList @(
            "-NoProfile",
            "-ExecutionPolicy", "Bypass",
            "-File", "`"$overlay`""
        )
        if($p){
            Log ("Overlay launch PID {0}." -f $p.Id)
        }
    }catch{
        Log ("ERROR starting overlay: " + $_.Exception.Message)
    }
}

function Stop-Overlay {
    try{
        $procs = Get-CimInstance Win32_Process -Filter "Name='powershell.exe'"
        foreach ($p in $procs) {
            if ($p.ProcessId -ne $PID -and
                $p.CommandLine -and
                $p.CommandLine -like "*CarDealerInventoryOverlay*Overlay.ps1*") {
                Log "Stopping overlay PID $($p.ProcessId)."
                Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
            }
        }
    }catch{}
}

Log ("Persistent watcher v0.45.0.0 started. PID " + $PID)

$gameWasRunning = $false
$launchDelayDone = $false
$lastHeartbeat = Get-Date
$gameMissingSince = $null

while ($true) {
    $game = Get-CarDealerGame

    if ($game) {
        $gameMissingSince=$null
        if (-not $gameWasRunning) {
            Log ("Game detected: " + $game.ProcessName + " PID " + $game.Id)
            $gameWasRunning = $true
            $launchDelayDone = $false
        }

        if (-not $launchDelayDone) {
            Start-Sleep -Seconds 5
            $launchDelayDone = $true
        }

        Start-Overlay
    }
    else {
        if ($gameWasRunning) {
            # A short process-name gap can occur while the game transitions into
            # the shipping executable. Keep the UI alive through that gap.
            if($null -eq $gameMissingSince){
                $gameMissingSince=Get-Date
                Log "Game process temporarily missing; starting 12 second grace period."
            }elseif(((Get-Date)-$gameMissingSince).TotalSeconds -ge 12){
                Log "Game closed after grace period."
                Stop-Overlay
                $gameWasRunning = $false
                $launchDelayDone = $false
                $gameMissingSince=$null
            }
        }
    }

    if(((Get-Date) - $lastHeartbeat).TotalMinutes -ge 5){
        Log ("Watcher heartbeat. GameRunning=" + [bool]$game + " OverlayRunning=" + (Overlay-Running))
        $lastHeartbeat=Get-Date
    }

    Start-Sleep -Seconds 2
}
