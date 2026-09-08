Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms
$ErrorActionPreference="Stop"
trap { $_ | Out-File -LiteralPath (Join-Path $env:LOCALAPPDATA "CarDealerInventoryOverlay\overlay_error.log") -Append -Encoding ASCII; break }

$script:OverlayBuildVersion="v0.45.0.0"

$base=Join-Path $env:LOCALAPPDATA "CarDealerInventoryOverlay"
New-Item -ItemType Directory -Force -Path $base | Out-Null
try{ $script:OverlayBuildVersion | Out-File -LiteralPath (Join-Path $base "overlay_build_version.txt") -Encoding ASCII -Force }catch{}

# Human-readable development/support diagnostics live with the project rather than
# being hidden in AppData. Fall back to the runtime folder if that location cannot
# be created (for example on another user's PC).
$diagnosticsRoot=Join-Path $env:LOCALAPPDATA "CarDealerInventoryOverlay\Diagnostics"
try{New-Item -ItemType Directory -Force -Path $diagnosticsRoot | Out-Null}catch{$diagnosticsRoot=$base}
$overlayPerformanceLog=Join-Path $diagnosticsRoot "overlay_performance.log"
function Write-OverlayPerformance([string]$message){
 try{("[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"),$message) | Out-File -LiteralPath $overlayPerformanceLog -Append -Encoding ASCII}catch{}
}


# ------------------------------------------------------------
# PACKAGED UI ASSETS
# ------------------------------------------------------------
# Assets are installed locally with the Companion. The runtime never needs
# FModel or any development tool in order to display them.
$assetsRoot=Join-Path $base "Assets"
$assetManifestPath=Join-Path $assetsRoot "asset_manifest.json"
$brandingRoot=Join-Path $assetsRoot "Branding"
$fontsRoot=Join-Path $assetsRoot "Fonts"
$iconsRoot=Join-Path $assetsRoot "Icons"
$carImagesRoot=Join-Path $assetsRoot "Cars"

# Runtime game-icon cache. IMPORTANT: this is deliberately NON-BLOCKING.
# Protected UI startup/F1 behavior must never wait for icon generation.
$script:runtimeIconRoot=Join-Path $base "RuntimeIcons"
function Get-RuntimeIconPath([string]$relativePath){
 if([string]::IsNullOrWhiteSpace($relativePath)){return $null}
 try{
  $safe=[regex]::Replace($relativePath,'[^A-Za-z0-9_-]','_')
  $candidate=Join-Path $script:runtimeIconRoot ($safe+'.png')
  if(Test-Path -LiteralPath $candidate){return $candidate}
 }catch{}
 return $null
}

function Get-CompanionAssetPath([string]$relativePath){
 if([string]::IsNullOrWhiteSpace($relativePath)){return $null}
 try{
  $runtime=Get-RuntimeIconPath $relativePath
  if($runtime){return $runtime}
  $candidate=Join-Path $assetsRoot $relativePath
  if(Test-Path -LiteralPath $candidate){return $candidate}
 }catch{}
 return $null
}

function Get-PackagedCompanionAssetPath([string]$relativePath){
 if([string]::IsNullOrWhiteSpace($relativePath)){return $null}
 try{
  $candidate=Join-Path $assetsRoot $relativePath
  if(Test-Path -LiteralPath $candidate){return $candidate}
 }catch{}
 return $null
}

function New-CompanionBitmapImage([string]$relativePath){
 $path=Get-CompanionAssetPath $relativePath
 if(-not $path){return $null}
 try{
  $bmp=New-Object System.Windows.Media.Imaging.BitmapImage
  $bmp.BeginInit()
  $bmp.CacheOption=[System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
  $bmp.UriSource=New-Object System.Uri($path,[System.UriKind]::Absolute)
  $bmp.EndInit()
  $bmp.Freeze()
  return $bmp
 }catch{
  return $null
 }
}

# v0.44.0.72.12.1.10: Get-PartsRowIconPath / Update-PartsDetail already resolve
# a full absolute path (it may point into RuntimeIcons OR the packaged Assets
# folder). The row/preview code used to strip $assetsRoot back out to build a
# "relative" path and hand it to New-CompanionBitmapImage above, which then
# re-resolves it through Get-CompanionAssetPath. That round trip only works
# when the path is actually under $assetsRoot - for anything resolved from
# RuntimeIcons (i.e. every Parts icon in this build, since no Assets folder
# is packaged) the strip is a no-op, the "relative" path is still the full
# absolute path, and Get-RuntimeIconPath's sanitiser mangles the whole thing
# into a filename that never exists. This loads directly from an already-
# absolute path and skips the broken round trip entirely.
function New-CompanionBitmapImageFromAbsolutePath([string]$absolutePath){
 if([string]::IsNullOrWhiteSpace($absolutePath)){return $null}
 try{
  if(-not (Test-Path -LiteralPath $absolutePath)){return $null}
  $bmp=New-Object System.Windows.Media.Imaging.BitmapImage
  $bmp.BeginInit()
  $bmp.CacheOption=[System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
  $bmp.UriSource=New-Object System.Uri($absolutePath,[System.UriKind]::Absolute)
  $bmp.EndInit()
  $bmp.Freeze()
  return $bmp
 }catch{
  return $null
 }
}


# v0.44.0.66 - vehicle photos are generated at runtime from the user's installed game.
# No extracted Cars photos are distributed in this build.
$script:runtimeCarPhotoRoot=Join-Path $base "RuntimeCarPhotos"
$script:runtimeCarModelAliases=@{
 "cavallaro 280g"="280G";"280g"="280G";"cavallaro 350s"="350s";"350s"="350s"
 "umx 600c"="600C";"600c"="600C";"umx 700r"="700R";"700r"="700R";"umx 800c"="800C";"800c"="800C"
 "harmonia vehicles allegretto"="Allegretto";"allegretto"="Allegretto";"harmonia vehicles andante"="Andante";"andante"="Andante";"harmonia vehicles largo"="Largo";"largo"="Largo"
 "zen motors ascend"="Ascend";"ascend"="Ascend";"zen motors ascendl"="AscendL";"zen motors ascend l"="AscendL";"ascendl"="AscendL";"zen motors horizon"="Horizon";"horizon"="Horizon";"zen motors journey"="Journey";"journey"="Journey";"zen motors rapid"="Rapid";"rapid"="Rapid"
 "aurora outrider"="Aurora";"outrider"="Aurora";"aurora"="Aurora";"aurora highrunner"="Highrunner";"highrunner"="Highrunner"
 "apex motors strike"="Striker";"strike"="Striker";"striker"="Striker";"apex motors vanguard"="Vanguard";"vanguard"="Vanguard"
 "ardena ignis"="Ignis";"ignis"="Ignis";"ardena ventus"="Ventus";"ventus"="Ventus";"ngd nova"="Nova";"nova"="Nova";"ngd pulse"="Pulse";"pulse"="Pulse"
 "offrider boulder"="Boulder";"boulder"="Boulder";"offrider canyon"="Canyon";"canyon"="Canyon";"offrider highland"="Highland";"highland"="Highland";"offrider ridge"="Ridge";"ridge"="Ridge";"offrider summit"="Summit";"summit"="Summit";"offrider trail"="Trail";"trail"="Trail";"offrider ravager"="Ravager";"ravager"="Ravager"
 "phantom tempest"="Tempest";"tempest"="Tempest";"phantom cortega"="Cortega";"cortega"="Cortega";"phantom gale"="Gale";"gale"="Gale";"phantom thunder"="Thunder";"thunder"="Thunder";"phantom thunderx"="ThunderX";"phantom thunder x"="ThunderX";"thunderx"="ThunderX";"phantom voyager"="Voyager";"voyager"="Voyager"
 "cargowise p2"="P2";"p2"="P2";"cargowise p3"="P3";"p3"="P3";"cargowise p4"="P4";"p4"="P4"
 "liftedtruck"="LiftedTruck";"lifted truck"="LiftedTruck";"towtruck"="TowTruck";"tow truck"="TowTruck";"transporter"="TowTruckBig";"vesper"="Vesper";"elevate"="Elevate"
}
function Get-RuntimeCarModelKey([string]$model){
 if([string]::IsNullOrWhiteSpace($model)){return $null}
 $key=($model.Trim().ToLowerInvariant() -replace '\s+',' ')
 if($script:runtimeCarModelAliases.ContainsKey($key)){return [string]$script:runtimeCarModelAliases[$key]}
 $compact=$key -replace '[^a-z0-9]','';$best=$null;$bestLen=0
 foreach($k in $script:runtimeCarModelAliases.Keys){$kc=[string]$k -replace '[^a-z0-9]','';if($kc.Length -ge 3 -and ($compact -eq $kc -or $compact.EndsWith($kc)) -and $kc.Length -gt $bestLen){$best=[string]$script:runtimeCarModelAliases[$k];$bestLen=$kc.Length}}
 return $best
}
function Get-RuntimeCarPhotoPath([string]$model,$color){
 $mk=Get-RuntimeCarModelKey $model;if([string]::IsNullOrWhiteSpace($mk)){return $null}
 $ck=Get-VehiclePaintColorName $color;if([string]::IsNullOrWhiteSpace($ck)){return $null}
 $safeM=$mk -replace '[^A-Za-z0-9_-]','_';$safeC=$ck -replace '[^A-Za-z0-9_-]','_'
 $path=Join-Path $script:runtimeCarPhotoRoot ($safeM+'__'+$safeC+'.png')
 if(Test-Path -LiteralPath $path){return $path}

 # v0.44.0.70: custom paint has no static game photo for the exact arbitrary colour.
 # The reader now creates Model__Custom.png from a stock photo where possible.  While
 # that is being generated (or for an old cache), use any existing photo of the same
 # model rather than leaving the vehicle image blank.
 if($ck -eq 'Custom'){
  try{
   $fallback=Get-ChildItem -LiteralPath $script:runtimeCarPhotoRoot -File -Filter ($safeM+'__*.png') -ErrorAction SilentlyContinue | Select-Object -First 1
   if($null -ne $fallback){return $fallback.FullName}
  }catch{}
 }
 return $null
}
# v0.44.0.78: cache decoded runtime car images by file stamp. Cars UI rebuilds (including
# marking/unmarking a Personal Car) now reuse frozen ImageSource objects instead of
# synchronously decoding the same PNGs again. A changed file stamp automatically refreshes.
$script:runtimeCarBitmapCache=@{}
$script:runtimeCarThumbnailCache=@{}
function Get-RuntimeCarImageStamp([string]$path){
 try{
  $f=Get-Item -LiteralPath $path -ErrorAction Stop
  return (([string]$f.Length)+":"+([string]$f.LastWriteTimeUtc.Ticks))
 }catch{return $null}
}
function New-RuntimeCarBitmap([string]$path){
 if([string]::IsNullOrWhiteSpace($path) -or -not (Test-Path -LiteralPath $path)){return $null}
 try{
  $stamp=Get-RuntimeCarImageStamp $path;if($null -eq $stamp){return $null}
  $key=$path.ToLowerInvariant()
  $cached=$script:runtimeCarBitmapCache[$key]
  if($null -ne $cached -and [string]$cached.Stamp -eq $stamp){return $cached.Image}
  $bmp=New-Object System.Windows.Media.Imaging.BitmapImage
  $bmp.BeginInit()
  $bmp.CacheOption=[System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
  $bmp.CreateOptions=[System.Windows.Media.Imaging.BitmapCreateOptions]::IgnoreImageCache
  $bmp.UriSource=New-Object System.Uri($path,[System.UriKind]::Absolute)
  $bmp.EndInit();$bmp.Freeze()
  $script:runtimeCarBitmapCache[$key]=[pscustomobject]@{Stamp=$stamp;Image=$bmp}
  return $bmp
 }catch{return $null}
}
function New-RuntimeCarThumbnail([string]$path){
 if([string]::IsNullOrWhiteSpace($path) -or -not (Test-Path -LiteralPath $path)){return $null}
 try{
  $stamp=Get-RuntimeCarImageStamp $path;if($null -eq $stamp){return $null}
  $key=$path.ToLowerInvariant()
  $cached=$script:runtimeCarThumbnailCache[$key]
  if($null -ne $cached -and [string]$cached.Stamp -eq $stamp){return $cached.Image}
  # Decode only a small thumbnail instead of expanding the full 1024x1024 PNG.
  $bmp=New-Object System.Windows.Media.Imaging.BitmapImage
  $bmp.BeginInit()
  $bmp.CacheOption=[System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
  $bmp.CreateOptions=[System.Windows.Media.Imaging.BitmapCreateOptions]::IgnoreImageCache
  $bmp.DecodePixelWidth=128
  $bmp.UriSource=New-Object System.Uri($path,[System.UriKind]::Absolute)
  $bmp.EndInit();$bmp.Freeze()
  $script:runtimeCarThumbnailCache[$key]=[pscustomobject]@{Stamp=$stamp;Image=$bmp}
  return $bmp
 }catch{return $null}
}
function Add-CarIconProperty($o){
 if($null -eq $o){return}
 try{
  # v0.44.0.70: keep only the light path on each row.  WPF/PowerShell data binding
  # repeatedly left the Image.Source blank even though the same PNG worked in the
  # Selected Vehicle panel.  The visible row Image is therefore hydrated directly.
  $path=Get-RuntimeCarPhotoPath ([string]$o.Model) $o.Color
  Add-Member -InputObject $o -MemberType NoteProperty -Name CarIconPath -Value $path -Force
  Add-Member -InputObject $o -MemberType NoteProperty -Name HasCarIcon -Value (-not [string]::IsNullOrWhiteSpace($path)) -Force
 }catch{
  try{Add-Member -InputObject $o -MemberType NoteProperty -Name CarIconPath -Value $null -Force;Add-Member -InputObject $o -MemberType NoteProperty -Name HasCarIcon -Value $false -Force}catch{}
 }
}

function Write-IconDiagnostic {
 try{
  $path=Join-Path $diagnosticsRoot "icon_diagnostic.txt"
  $tests=@(
   @{Name="Known working - Scanner";Rel="Icons/Cars/Scanner_128.png"},
   @{Name="Known working - Engine category";Rel="Icons/Parts/engine.png"},
   @{Name="Sport tier badge";Rel="Icons/Parts/Tiers/sport.png"},
   @{Name="Front Bumper";Rel="Icons/Parts/Customization/front_bumper.png"},
   @{Name="Custom Exterior";Rel="Icons/Parts/Customization/exterior.png"}
  )
  $lines=New-Object System.Collections.Generic.List[string]
  [void]$lines.Add("CAR DEALER COMPANION - ICON DIAGNOSTIC")
  [void]$lines.Add("UI strategy: direct Image controls inserted into Parts/Custom rows (no image binding)")
  [void]$lines.Add(("Version: v0.45.0.0"))
  [void]$lines.Add(("Created: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss")))
  [void]$lines.Add(("Assets root: {0}" -f $assetsRoot))
  [void]$lines.Add("")
  foreach($t in $tests){
   $resolved=Get-CompanionAssetPath ([string]$t.Rel)
   $exists=($null -ne $resolved -and (Test-Path -LiteralPath $resolved))
   $size=0
   if($exists){try{$size=(Get-Item -LiteralPath $resolved).Length}catch{}}
   $bmp=$null
   try{$bmp=New-CompanionBitmapImage ([string]$t.Rel)}catch{}
   [void]$lines.Add([string]$t.Name)
   [void]$lines.Add(("  Relative : {0}" -f [string]$t.Rel))
   [void]$lines.Add(("  Resolved : {0}" -f $(if($resolved){$resolved}else{"<null>"})))
   [void]$lines.Add(("  Exists   : {0}" -f $exists))
   [void]$lines.Add(("  Bytes    : {0}" -f $size))
   [void]$lines.Add(("  Decoded  : {0}" -f ($null -ne $bmp)))
   if($null -ne $bmp){[void]$lines.Add(("  Pixels   : {0}x{1}" -f $bmp.PixelWidth,$bmp.PixelHeight))}
   [void]$lines.Add("")
  }
  $lines | Set-Content -LiteralPath $path -Encoding UTF8
 }catch{}
}


$script:assetManifest=$null
if(Test-Path -LiteralPath $assetManifestPath){
 try{$script:assetManifest=(Get-Content -LiteralPath $assetManifestPath -Raw | ConvertFrom-Json)}catch{}
}


$json=Join-Path $base "inventory.json"
$storageJson=Join-Path $base "storage.json"
$repairJson=Join-Path $base "repair_machine.json"
$businessJson=Join-Path $base "business.json"
$contractsJson=Join-Path $base "contracts.json"
$carsRefreshRequest=Join-Path $base "cars_refresh_request.txt"
$carsJson=Join-Path $base "cars_owned.json"
$carsDistanceJson=Join-Path $base "cars_distance.json"

$refreshSettingsPath=Join-Path $base "refresh_settings.ini"
$readerRefreshRequest=Join-Path $base "reader_refresh_request.txt"
$debugLogPath=Join-Path $base "companion_debug.log"
$diagnosticReportPath=Join-Path $base "diagnostic_report.txt"
$diagnosticsFlagPath=Join-Path $base "diagnostics_enabled.flag"

# ------------------------------------------------------------
# REFRESH SETTINGS
# ------------------------------------------------------------
# These settings are intentionally stored outside the save cache. They describe
# how the Companion behaves for the user, so they should survive save changes.
$script:refreshSettings=@{
 "dashboard_seconds"=10
 "contracts_seconds"=30
 "inventory_seconds"=10
 "storage_seconds"=30
 "cars_seconds"=120
 "debug_enabled"=$false
 "diagnostics_enabled"=$false
}
$script:refreshUiInitializing=$false

function Load-RefreshSettings{
 if(-not (Test-Path -LiteralPath $refreshSettingsPath)){return}
 try{
  foreach($line in @(Get-Content -LiteralPath $refreshSettingsPath -ErrorAction Stop)){
   $t=([string]$line).Trim()
   if($t -eq "" -or $t.StartsWith("#") -or -not $t.Contains("=")){continue}
   $pair=$t.Split('=',2)
   $key=$pair[0].Trim().ToLowerInvariant()
   $value=$pair[1].Trim()
   if(-not $script:refreshSettings.ContainsKey($key)){continue}
   if($key -eq "debug_enabled" -or $key -eq "diagnostics_enabled"){
    $script:refreshSettings[$key]=($value.ToLowerInvariant() -eq "true")
   }else{
    $n=0
    if([int]::TryParse($value,[ref]$n)){$script:refreshSettings[$key]=[Math]::Max(0,$n)}
   }
  }
 }catch{}
}
function Save-RefreshSettings{
 try{
  @(
   "# Car Dealer Companion refresh settings",
   ("dashboard_seconds={0}" -f [int]$script:refreshSettings["dashboard_seconds"]),
   ("contracts_seconds={0}" -f [int]$script:refreshSettings["contracts_seconds"]),
   ("inventory_seconds={0}" -f [int]$script:refreshSettings["inventory_seconds"]),
   ("storage_seconds={0}" -f [int]$script:refreshSettings["storage_seconds"]),
   ("cars_seconds={0}" -f [int]$script:refreshSettings["cars_seconds"]),
   ("debug_enabled={0}" -f ([bool]$script:refreshSettings["debug_enabled"]).ToString().ToLowerInvariant()),
   ("diagnostics_enabled={0}" -f ([bool]$script:refreshSettings["diagnostics_enabled"]).ToString().ToLowerInvariant())
  ) | Set-Content -LiteralPath $refreshSettingsPath -Encoding ASCII
 }catch{}
}
function Write-CompanionDebug([string]$message){
 if(-not [bool]$script:refreshSettings["debug_enabled"]){return}
 try{
  ("{0}  {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"),$message) |
   Add-Content -LiteralPath $debugLogPath -Encoding ASCII
 }catch{}
}
function Request-ReaderRefresh([string]$target){
 try{
  Set-Content -LiteralPath $readerRefreshRequest -Value (([string]$target).ToLowerInvariant()+"|"+(Get-Date -Format "yyyy-MM-dd HH:mm:ss")) -Encoding ASCII
  Write-CompanionDebug ("Manual reader refresh requested: "+$target)
  return $true
 }catch{return $false}
}
Load-RefreshSettings
# v0.44.0.57 live-contract migration:
# v0.44.0.67 performance migration: the old 5-second Contracts cadence
# produced visible game-thread hitches. Keep custom values, but move the old
# live-contract default to 30 seconds. Manual REFRESH remains immediate.
if([int]$script:refreshSettings["contracts_seconds"] -eq 5){$script:refreshSettings["contracts_seconds"]=30}
if([int]$script:refreshSettings["cars_seconds"] -eq 600){$script:refreshSettings["cars_seconds"]=120}
Save-RefreshSettings
# v0.44.0.57 performance migration:
# 180 seconds was the old default and lined up with the reported periodic hitch.
# Preserve custom values, but move the untouched legacy default to 10 minutes.
if([int]$script:refreshSettings["cars_seconds"] -eq 180){
 $script:refreshSettings["cars_seconds"]=600
 Save-RefreshSettings
}
Save-RefreshSettings
try{if([bool]$script:refreshSettings["diagnostics_enabled"]){Set-Content -LiteralPath $diagnosticsFlagPath -Value "enabled" -Encoding ASCII}else{Remove-Item -LiteralPath $diagnosticsFlagPath -Force -ErrorAction SilentlyContinue}}catch{}

# ------------------------------------------------------------
# PER-SAVE COMPANION CACHE
# ------------------------------------------------------------
# Live reader files remain shared because they describe the currently loaded
# game. Persistent car-detail cache is separated by the most recently written
# Car Dealer Simulator .sav file so Car1 from one save cannot reuse Car1 data
# from another save.
function Get-CompanionSaveProfile {
 $roots=@(
  (Join-Path $env:LOCALAPPDATA "CarDealerSimulator\Saved\SaveGames"),
  (Join-Path $env:LOCALAPPDATA "Car Dealer Simulator\Saved\SaveGames")
 )
 $candidates=@()
 foreach($r in $roots){
  if(Test-Path -LiteralPath $r){
   try{$candidates+=@(Get-ChildItem -LiteralPath $r -Filter *.sav -File -Recurse -ErrorAction SilentlyContinue)}catch{}
  }
 }
 if($candidates.Count -gt 0){
  $save=@($candidates | Sort-Object LastWriteTime -Descending | Select-Object -First 1)[0]
  $name=[IO.Path]::GetFileNameWithoutExtension($save.Name)
  if([string]::IsNullOrWhiteSpace($name)){$name="CurrentSave"}
  $safe=($name -replace '[^A-Za-z0-9_.-]','_')
  return $safe
 }
 return "CurrentSave"
}

$saveProfile=Get-CompanionSaveProfile
$savesRoot=Join-Path $base "Saves"
$saveCacheRoot=Join-Path $savesRoot $saveProfile
$carDetailsCacheDir=Join-Path $saveCacheRoot "CarDetailsCache"
$startupCacheDir=Join-Path $saveCacheRoot "StartupCache"
$legacyPersonalCarsPath=Join-Path $saveCacheRoot "personal_cars.json"
$personalCarsPath=Join-Path $base "personal_cars.json"

# v0.38.0.2: stable Personal Cars storage. Migration is best-effort only.
try{
 if((-not (Test-Path -LiteralPath $personalCarsPath)) -and (Test-Path -LiteralPath $legacyPersonalCarsPath)){
  Copy-Item -LiteralPath $legacyPersonalCarsPath -Destination $personalCarsPath -Force -ErrorAction SilentlyContinue
 }
}catch{}
$script:personalCars=@{}
$script:updatingPersonalCheck=$false
$script:selectedCarForPersonal=$null
$script:lastCarsJsonStamp=""
$script:forceCarsUiRebuild=$true
$script:selectedCarId=""

function Get-PersonalCarKey([string]$carId){
 if([string]::IsNullOrWhiteSpace($carId)){return ""}
 return $carId.Trim().ToLowerInvariant()
}
function Load-PersonalCars{
 $script:personalCars=@{}
 if(Test-Path $personalCarsPath){
  try{
   $p=(Get-Content $personalCarsPath -Raw)|ConvertFrom-Json
   foreach($id in @($p.carIds)){
    $k=Get-PersonalCarKey ([string]$id)
    if($k -ne ""){$script:personalCars[$k]=$true}
   }
  }catch{}
 }
}
function Save-PersonalCars{
 try{
  @{version=1;carIds=@($script:personalCars.Keys | Sort-Object)} |
   ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $personalCarsPath -Encoding UTF8
 }catch{}
}
function Test-PersonalCar([string]$carId){
 $k=Get-PersonalCarKey $carId
 return ($k -ne "" -and $script:personalCars.ContainsKey($k))
}
Load-PersonalCars
New-Item -ItemType Directory -Force -Path $carDetailsCacheDir | Out-Null
New-Item -ItemType Directory -Force -Path $startupCacheDir | Out-Null
Set-Content -LiteralPath (Join-Path $saveCacheRoot "save_profile.txt") -Value $saveProfile -Encoding ASCII

# ------------------------------------------------------------
# FAST STARTUP CACHE
# ------------------------------------------------------------
# Each save profile keeps the last known-good live JSON files.  On the next
# session they are restored immediately so the Companion opens populated while
# UE4SS waits for the normal safe live-read delay.
$startupFiles=@(
 @($json,"inventory.json"),
 @($storageJson,"storage.json"),
 @($repairJson,"repair_machine.json"),
 @($carsJson,"cars_owned.json"),
 @($businessJson,"business.json")
)

foreach($entry in $startupFiles){
 try{
  $live=[string]$entry[0]
  $cached=Join-Path $startupCacheDir ([string]$entry[1])
  if((-not (Test-Path -LiteralPath $live)) -and (Test-Path -LiteralPath $cached)){
   Copy-Item -LiteralPath $cached -Destination $live -Force
  }
 }catch{}
}

$script:startupCacheStamps=@{}

function Save-StartupCacheFile([string]$livePath,[string]$cacheName){
 try{
  if(-not (Test-Path -LiteralPath $livePath)){return}
  $fi=Get-Item -LiteralPath $livePath -ErrorAction Stop
  $stamp=("{0}|{1}" -f $fi.LastWriteTimeUtc.Ticks,$fi.Length)
  if($script:startupCacheStamps.ContainsKey($cacheName) -and $script:startupCacheStamps[$cacheName] -eq $stamp){return}

  $raw=Get-Content -LiteralPath $livePath -Raw -ErrorAction Stop
  if([string]::IsNullOrWhiteSpace($raw)){return}
  # Validate only when the source file actually changed.
  $null=$raw | ConvertFrom-Json -ErrorAction Stop
  $dest=Join-Path $startupCacheDir $cacheName
  Copy-Item -LiteralPath $livePath -Destination $dest -Force
  $script:startupCacheStamps[$cacheName]=$stamp
 }catch{}
}

$overlayLog=Join-Path $base "overlay_start.log"
("Overlay v0.45.0.0 - release baseline started "+(Get-Date -Format "yyyy-MM-dd HH:mm:ss")+" | Save profile: "+$saveProfile) | Set-Content -LiteralPath $overlayLog -Encoding ASCII
$catalogPath=Join-Path $base "Catalog.json"
$pidPath=Join-Path $base "overlay.pid"

$created=$false
$mutex=New-Object System.Threading.Mutex($true,"Local\CarDealerInventoryOverlay_v08",[ref]$created)
if(-not $created){exit}
Set-Content -LiteralPath $pidPath -Value $PID -Encoding ASCII

Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class CDIHotKey {
 [DllImport("user32.dll")] public static extern bool RegisterHotKey(IntPtr hWnd,int id,uint mods,uint vk);
 [DllImport("user32.dll")] public static extern bool UnregisterHotKey(IntPtr hWnd,int id);
 [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
 [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr hWnd);
 [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vKey);
}
"@

[xml]$x=@"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="Car Dealer Companion"
 Width="1400" Height="850" MinWidth="1000" MinHeight="650" WindowStartupLocation="Manual"
 ResizeMode="CanResizeWithGrip" Topmost="True" ShowInTaskbar="False" Background="#11151B" FontFamily="Lato, Segoe UI" FontSize="14">
 <Window.Resources>
  <SolidColorBrush x:Key="Shell" Color="#11151B"/>
  <SolidColorBrush x:Key="Panel" Color="#171C24"/>
  <SolidColorBrush x:Key="Card" Color="#20262F"/>
  <SolidColorBrush x:Key="CardHover" Color="#28313C"/>
  <SolidColorBrush x:Key="Line" Color="#3B4552"/>
  <SolidColorBrush x:Key="TextMain" Color="#FFF8EB"/>
  <SolidColorBrush x:Key="TextSoft" Color="#BFC7D1"/>
  <SolidColorBrush x:Key="Blue" Color="#3FA9F5"/>
  <SolidColorBrush x:Key="Orange" Color="#D56A27"/>
  <SolidColorBrush x:Key="Green" Color="#65B84A"/>
  <SolidColorBrush x:Key="Red" Color="#D84B3E"/>

  <Style TargetType="TextBlock">
   <Setter Property="Foreground" Value="{StaticResource TextMain}"/>
   <Setter Property="FontSize" Value="14"/>
  </Style>
  <Style TargetType="TabControl">
   <Setter Property="Background" Value="{StaticResource Panel}"/>
   <Setter Property="BorderThickness" Value="0"/>
  </Style>
  <Style x:Key="MainTabControl" TargetType="TabControl">
   <Setter Property="Background" Value="{StaticResource Panel}"/>
   <Setter Property="BorderThickness" Value="0"/>
   <Setter Property="Template">
    <Setter.Value>
     <ControlTemplate TargetType="TabControl">
      <Border Background="{TemplateBinding Background}" BorderBrush="#26303A" BorderThickness="1" CornerRadius="8">
       <ContentPresenter ContentSource="SelectedContent" Margin="0"/>
      </Border>
     </ControlTemplate>
    </Setter.Value>
   </Setter>
  </Style>
  <Style TargetType="TabItem">
   <Setter Property="Foreground" Value="{StaticResource TextMain}"/>
   <Setter Property="FontWeight" Value="SemiBold"/>
   <Setter Property="Padding" Value="4"/>
   <Setter Property="Margin" Value="2,2,2,0"/>
   <Setter Property="Background" Value="Transparent"/>
   <Setter Property="BorderBrush" Value="Transparent"/>
   <Setter Property="Template">
    <Setter.Value>
     <ControlTemplate TargetType="TabItem">
      <Border x:Name="Outer" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="1" CornerRadius="7" Padding="{TemplateBinding Padding}" Margin="0">
       <ContentPresenter ContentSource="Header" HorizontalAlignment="Center" VerticalAlignment="Center"/>
      </Border>
      <ControlTemplate.Triggers>
       <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="Outer" Property="Background" Value="#28313C"/><Setter TargetName="Outer" Property="BorderBrush" Value="#526173"/></Trigger>
       <Trigger Property="IsSelected" Value="True"><Setter TargetName="Outer" Property="Background" Value="#20262F"/><Setter TargetName="Outer" Property="BorderBrush" Value="#3FA9F5"/></Trigger>
      </ControlTemplate.Triggers>
     </ControlTemplate>
    </Setter.Value>
   </Setter>
  </Style>
  <Style TargetType="Button">
   <Setter Property="Background" Value="#263343"/><Setter Property="Foreground" Value="#FFF8E8"/>
   <Setter Property="BorderBrush" Value="#50647A"/><Setter Property="BorderThickness" Value="1"/>
   <Setter Property="Padding" Value="11,7"/><Setter Property="FontWeight" Value="SemiBold"/>
   <Setter Property="FontSize" Value="14"/>
   <Setter Property="Cursor" Value="Hand"/>
   <Setter Property="Template">
    <Setter.Value>
     <ControlTemplate TargetType="Button">
      <Border x:Name="BtnBorder" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="7" Padding="{TemplateBinding Padding}">
       <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
      </Border>
      <ControlTemplate.Triggers>
       <Trigger Property="IsMouseOver" Value="True"><Setter TargetName="BtnBorder" Property="Background" Value="#334357"/><Setter TargetName="BtnBorder" Property="BorderBrush" Value="#6E88A5"/></Trigger>
       <Trigger Property="IsPressed" Value="True"><Setter TargetName="BtnBorder" Property="Background" Value="#1E2835"/></Trigger>
       <Trigger Property="IsEnabled" Value="False"><Setter TargetName="BtnBorder" Property="Opacity" Value="0.45"/></Trigger>
      </ControlTemplate.Triggers>
     </ControlTemplate>
    </Setter.Value>
   </Setter>
  </Style>
  <Style TargetType="GroupBox">
   <Setter Property="Foreground" Value="{StaticResource TextMain}"/><Setter Property="FontWeight" Value="SemiBold"/>
   <Setter Property="Background" Value="{StaticResource Card}"/><Setter Property="BorderBrush" Value="{StaticResource Line}"/>
   <Setter Property="Margin" Value="4"/><Setter Property="Padding" Value="6"/>
  </Style>
  <Style TargetType="ListBox">
   <Setter Property="FontSize" Value="14"/>
   <Setter Property="Background" Value="{StaticResource Panel}"/><Setter Property="Foreground" Value="{StaticResource TextMain}"/>
   <Setter Property="BorderBrush" Value="{StaticResource Line}"/><Setter Property="BorderThickness" Value="1"/>
  </Style>
  <Style TargetType="ListView">
   <Setter Property="FontSize" Value="14"/>
   <Setter Property="Background" Value="{StaticResource Panel}"/><Setter Property="Foreground" Value="{StaticResource TextMain}"/>
   <Setter Property="BorderBrush" Value="{StaticResource Line}"/><Setter Property="BorderThickness" Value="1"/>
   <Setter Property="ScrollViewer.HorizontalScrollBarVisibility" Value="Auto"/>
   <Setter Property="ScrollViewer.VerticalScrollBarVisibility" Value="Auto"/>
  </Style>
  <Style TargetType="ListViewItem">
   <Setter Property="Foreground" Value="{StaticResource TextMain}"/>
   <Setter Property="Background" Value="Transparent"/>
   <Setter Property="Padding" Value="5,4"/>
   <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
   <Style.Triggers>
    <Trigger Property="IsMouseOver" Value="True"><Setter Property="Background" Value="#252E39"/></Trigger>
    <Trigger Property="IsSelected" Value="True"><Setter Property="Background" Value="#7A5209"/><Setter Property="Foreground" Value="White"/></Trigger>
   </Style.Triggers>
  </Style>
  <Style TargetType="GridViewColumnHeader">
   <Setter Property="Background" Value="#242B35"/>
   <Setter Property="Foreground" Value="#FFF8EB"/>
   <Setter Property="BorderBrush" Value="#3B4552"/>
   <Setter Property="BorderThickness" Value="0,0,1,1"/>
   <Setter Property="Padding" Value="7,5"/>
   <Setter Property="FontWeight" Value="SemiBold"/>
   <Setter Property="FontSize" Value="13"/>
   <Setter Property="Template">
    <Setter.Value>
     <ControlTemplate TargetType="GridViewColumnHeader">
      <Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" Padding="{TemplateBinding Padding}">
       <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
      </Border>
     </ControlTemplate>
    </Setter.Value>
   </Setter>
  </Style>
  <Style TargetType="ProgressBar">
   <Setter Property="Height" Value="14"/><Setter Property="Foreground" Value="{StaticResource Green}"/><Setter Property="Background" Value="#10151B"/><Setter Property="BorderBrush" Value="#3B4552"/>
  </Style>
  <Style TargetType="CheckBox"><Setter Property="Foreground" Value="{StaticResource TextMain}"/></Style>
  <Style TargetType="ScrollViewer"><Setter Property="Background" Value="Transparent"/></Style>
 </Window.Resources>
 <Grid>
  <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
  <Border Grid.Row="0" Background="#0F141A" BorderBrush="#D84B3E" BorderThickness="0,0,0,3" Padding="18,12">
   <DockPanel LastChildFill="True">
    <StackPanel DockPanel.Dock="Left">
     <TextBlock Text="CAR DEALER COMPANION" Foreground="#FFF8EB" FontSize="23" FontWeight="Bold"/>
     <TextBlock Name="Status" Text="Waiting for game..." Foreground="#BFC7D1" FontSize="13"/>
    </StackPanel>
    <StackPanel DockPanel.Dock="Right" Orientation="Horizontal" VerticalAlignment="Center">
     <Border Background="#18301E" BorderBrush="#315F3A" BorderThickness="1" CornerRadius="7" Padding="10,5" Margin="5,0"><TextBlock Name="HeaderMoney" Text="MONEY  -" Foreground="#7CD85E" FontWeight="Bold" FontSize="14"/></Border>
     <Border Background="#2A2334" BorderBrush="#57416B" BorderThickness="1" CornerRadius="7" Padding="10,5" Margin="5,0"><TextBlock Name="HeaderXP" Text="XP  -" Foreground="#D6B6FF" FontWeight="Bold" FontSize="14"/></Border>
     <Border Background="#182638" BorderBrush="#315B85" BorderThickness="1" CornerRadius="7" Padding="12,7" Margin="5,0"><TextBlock Name="HeaderReputation" Text="REPUTATION  -" Foreground="#76B9F5" FontWeight="Bold" FontSize="14"/></Border>
     <Border Background="#1A2420" BorderBrush="#3D7650" BorderThickness="1" CornerRadius="7" Padding="12,7" Margin="5,0"><TextBlock Name="HeaderGameClock" Text="DAY -  •  --:--" Foreground="#A9E2B8" FontWeight="Bold" FontSize="14"/></Border>
     <Border Background="#20262F" BorderBrush="#3B4552" BorderThickness="1" CornerRadius="7" Padding="12,7" Margin="8,0,0,0"><TextBlock Text="F1 · SHOW/HIDE" Foreground="White" FontWeight="Bold" FontSize="14"/></Border>
    </StackPanel>
   </DockPanel>
  </Border>
  <Grid Grid.Row="1" Margin="10">
   <Grid.ColumnDefinitions><ColumnDefinition Width="230"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
   <Border Grid.Column="0" Background="#0D1319" BorderBrush="#26303A" BorderThickness="1" CornerRadius="9" Margin="0,0,10,0" Padding="10">
    <DockPanel LastChildFill="True">
     <StackPanel DockPanel.Dock="Top">
      <TextBlock Text="CAR DEALER" FontSize="22" FontWeight="Bold" Foreground="#FFF8EB" HorizontalAlignment="Center" Margin="0,8,0,0"/>
      <TextBlock Text="SIMULATOR" FontSize="15" FontWeight="Bold" Foreground="#E39A2D" HorizontalAlignment="Center" Margin="0,0,0,20"/>
      <Button Name="NavDashboard" FontSize="14" Content="⌂   DASHBOARD" HorizontalContentAlignment="Left" Margin="0,4" Padding="16,12"/>
      <Button Name="NavInventory" FontSize="14" Content="▣   INVENTORY" HorizontalContentAlignment="Left" Margin="0,4" Padding="16,12"/>
      <Button Name="NavParts" FontSize="14" Content="🔧   PARTS" HorizontalContentAlignment="Left" Margin="0,4" Padding="16,12"/>
      <Button Name="NavCars" FontSize="14" Content="🚗   CARS" HorizontalContentAlignment="Left" Margin="0,4" Padding="16,12"/>
      <Button Name="NavEmployees" FontSize="14" Content="👤   EMPLOYEES" HorizontalContentAlignment="Left" Margin="0,4" Padding="16,12"/>
      <Button Name="NavContracts" FontSize="14" Content="▤   CONTRACTS" HorizontalContentAlignment="Left" Margin="0,4" Padding="16,12"/>
      <Button Name="NavAutomatedPlatform" FontSize="14" Content="⚙   AUTOMATION" HorizontalContentAlignment="Left" Margin="0,4" Padding="16,12"/>
      <Button Name="NavRacing" FontSize="14" Content="RACING" HorizontalContentAlignment="Left" Margin="0,4" Padding="16,12"/>
      <Button Name="NavAutoFleet" FontSize="14" Content="▥   AUTOFLEET + DEALERSHIPS" HorizontalContentAlignment="Left" Margin="0,4" Padding="16,12"/>
      <Button Name="NavSettings" FontSize="14" Content="⚙   SETTINGS" HorizontalContentAlignment="Left" Margin="0,4" Padding="16,12"/>
     </StackPanel>
     <StackPanel DockPanel.Dock="Bottom" VerticalAlignment="Bottom">
      <Border Background="#111B18" BorderBrush="#28513A" BorderThickness="1" CornerRadius="7" Padding="10" Margin="0,10,0,0">
       <StackPanel><TextBlock Text="●  CONNECTED" Foreground="#67D56A" FontWeight="Bold" FontSize="14"/><TextBlock Text="Live data from game" Foreground="#8FA0AD" FontSize="12" Margin="0,3,0,0"/></StackPanel>
      </Border>
      <TextBlock Text="Companion v0.45.0.0" Foreground="#72808D" FontSize="11" HorizontalAlignment="Center" Margin="0,12,0,2"/>
     </StackPanel>
    </DockPanel>
   </Border>
   <TabControl Name="Tabs" Grid.Column="1" Style="{StaticResource MainTabControl}" Background="#171C24">
   <TabItem Header="DASHBOARD" Tag="Dashboard"><ScrollViewer VerticalScrollBarVisibility="Auto"><StackPanel Margin="8">
    <TextBlock Text="DASHBOARD" Foreground="#FFF3E3" FontWeight="Bold" FontSize="20" Margin="0,0,0,8"/>
    <UniformGrid Columns="4" Margin="0,0,0,12">
     <Border Background="#20262F" BorderBrush="#C88A21" BorderThickness="1" CornerRadius="8" Padding="12" Margin="0,0,8,0"><StackPanel><TextBlock Text="WORKFLOW CARS" Foreground="#AEB8C3" FontSize="11"/><TextBlock Name="DashWorkflow" Text="-" Foreground="#E39A2D" FontSize="21" FontWeight="Bold" Margin="0,4,0,0"/></StackPanel></Border>
     <Border Background="#20262F" BorderBrush="#315F3A" BorderThickness="1" CornerRadius="8" Padding="12" Margin="0,0,8,0"><StackPanel><TextBlock Text="READY FOR SALE" Foreground="#AEB8C3" FontSize="11"/><TextBlock Name="DashReady" Text="-" Foreground="#67D56A" FontSize="21" FontWeight="Bold" Margin="0,4,0,0"/></StackPanel></Border>
     <Border Background="#20262F" BorderBrush="#315B85" BorderThickness="1" CornerRadius="8" Padding="12" Margin="0,0,8,0"><StackPanel><TextBlock Text="INVENTORY ITEMS" Foreground="#AEB8C3" FontSize="11"/><TextBlock Name="DashInventory" Text="-" Foreground="#76B9F5" FontSize="21" FontWeight="Bold" Margin="0,4,0,0"/></StackPanel></Border>
     <Border Background="#20262F" BorderBrush="#8A3934" BorderThickness="1" CornerRadius="8" Padding="12"><StackPanel><TextBlock Text="PARTS NEED REPAIR" Foreground="#AEB8C3" FontSize="11"/><TextBlock Name="DashRepair" Text="-" Foreground="#F06A5F" FontSize="21" FontWeight="Bold" Margin="0,4,0,0"/></StackPanel></Border>
    </UniformGrid>
    <Grid>
     <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
     <StackPanel Grid.Column="0" Margin="0,0,7,0">
      <TextBlock Text="BUSINESS" Foreground="#FFF3E3" FontWeight="Bold" FontSize="18"/>
      <Border Background="#20262F" BorderBrush="#3B4552" BorderThickness="1" CornerRadius="8" Padding="14" Margin="0,7,0,12">
       <StackPanel>
        <TextBlock Name="BusinessMoney" Text="Money: -" FontWeight="SemiBold" FontSize="14"/>
        <TextBlock Name="BusinessLevel" Text="Level: -" Margin="0,5,0,0" FontSize="14"/>
        <TextBlock Name="BusinessXP" Text="XP: -" Margin="0,5,0,0" FontSize="14"/>
        <TextBlock Name="BusinessReputation" Text="Reputation: -" Margin="0,5,0,0" FontSize="14"/>
        <TextBlock Name="BusinessTonyRep" Text="Tony Rep: -" Margin="0,5,0,0" FontSize="14" Foreground="#9AD8AA"/>
         <TextBlock Name="BusinessGameDay" Text="Game Day: -" Margin="0,5,0,0" FontSize="14"/>
        <TextBlock Name="BusinessGameTime" Text="Game Time: -" Margin="0,5,0,0" FontSize="14"/>
       </StackPanel>
      </Border>
      <TextBlock Text="CONTRACTS SUMMARY" Foreground="#FFF3E3" FontWeight="Bold" FontSize="18"/>
      <Border Background="#20262F" BorderBrush="#C88A21" BorderThickness="1" CornerRadius="8" Padding="14" Margin="0,7,0,12">
       <StackPanel>
        <TextBlock Name="DashContractsSummary" Text="Waiting for contract data..." FontSize="13" TextWrapping="Wrap"/>
        <Button Name="DashboardContractsLink" Content="VIEW CONTRACTS  →" HorizontalAlignment="Left" Margin="0,9,0,0" Padding="0" Background="Transparent" BorderThickness="0" Foreground="#76B9F5" FontSize="12" Cursor="Hand"/>
       </StackPanel>
      </Border>
      <TextBlock Text="TONY'S PAWN SHOP" Foreground="#FFF3E3" FontWeight="Bold" FontSize="18"/>
      <Border Background="#1B2420" BorderBrush="#4F7A5B" BorderThickness="1" CornerRadius="8" Padding="11" Margin="0,7,0,12">
       <StackPanel>
        <TextBlock Name="DashTonyRep" Text="Tony Rep: -" FontSize="13" FontWeight="SemiBold" Foreground="#9AD8AA"/>
        <TextBlock Name="DashTonyRequests" Text="Requests: -" Margin="0,4,0,0" FontSize="12" TextWrapping="Wrap"/>
        <TextBlock Name="DashTonyDeal" Text="Deal of the Day: No deal available" Margin="0,4,0,0" FontSize="12" TextWrapping="Wrap" Foreground="#F2C760"/>
       </StackPanel>
      </Border>
      <TextBlock Text="INVENTORY" Foreground="#FFF3E3" FontWeight="Bold" FontSize="18"/>
      <Border Background="#20262F" BorderBrush="#3B4552" BorderThickness="1" CornerRadius="8" Padding="14" Margin="0,7,0,12">
       <StackPanel>
        <TextBlock Name="Unique" Text="Different items: 0" FontSize="14"/>
        <TextBlock Name="Total" Text="Total items: 0" FontSize="14" Margin="0,4,0,0"/>
        <TextBlock Text="Inventory items are things found/owned in game. Stock warnings are reserved for car parts." Foreground="#8FA0AD" FontSize="12" TextWrapping="Wrap" Margin="0,8,0,0"/>
       </StackPanel>
      </Border>
     </StackPanel>
     <StackPanel Grid.Column="1" Margin="7,0,0,0">
      <TextBlock Text="VEHICLES" Foreground="#FFF3E3" FontWeight="Bold" FontSize="18"/>
      <Border Background="#20262F" BorderBrush="#3B4552" BorderThickness="1" CornerRadius="8" Padding="14" Margin="0,7,0,12">
       <StackPanel>
        <TextBlock Name="VehicleTotal" Text="Total Vehicles: -" FontSize="14"/>
        <TextBlock Name="VehicleOnSale" Text="Cars On Sale: -" Margin="0,4,0,0" FontSize="14"/>
        <TextBlock Name="VehicleReady" Text="Cars Ready For Sale: -" Margin="0,4,0,0" FontSize="14"/>
        <TextBlock Name="VehicleWaiting" Text="Needs Pickup: -" Margin="0,4,0,0" FontSize="14"/>
        <TextBlock Name="VehicleUtility" Text="Utility Vehicles: -" Margin="0,4,0,0" FontSize="14"/>
        <TextBlock Name="VehiclePersonal" Text="Personal Cars: -" Margin="0,4,0,0" FontSize="14"/>
        <TextBlock Name="VehicleGhost" Text="VehicleInfo-only records: -" Margin="0,4,0,0" FontSize="14"/>
       </StackPanel>
      </Border>
      <TextBlock Text="CAR PARTS LOW STOCK" Foreground="#FFF3E3" FontWeight="Bold" FontSize="18"/>
      <ListBox Name="Low" MinHeight="120" Margin="0,7,0,12"/>
     </StackPanel>
    </Grid>
    <TextBlock Text="CURRENT INVENTORY BY GROUP" Foreground="#FFF3E3" FontWeight="Bold" FontSize="18"/>
    <ListBox Name="GroupSummary" MinHeight="115" Margin="0,6,0,0"/>
    <Button Name="DashboardRefreshSettingsLink" Content="Adjust refresh settings  →" HorizontalAlignment="Left" Margin="0,12,0,2" Padding="0" Background="Transparent" BorderThickness="0" Foreground="#76B9F5" FontSize="12" Cursor="Hand"/>
   </StackPanel></ScrollViewer></TabItem>
   <TabItem Header="INVENTORY" Tag="InventoryRoot"/>
   </TabControl>
  </Grid>
  <Border Grid.Row="2" Background="#0F141A" BorderBrush="#343C48" BorderThickness="0,1,0,0" Padding="12,8"><DockPanel>
   <TextBlock Name="Count" Text="0 items" Foreground="#FFF3E3" FontWeight="SemiBold" FontSize="13"/>
   <StackPanel DockPanel.Dock="Right" Orientation="Horizontal">
    <TextBlock Text="Refresh timing: Settings" Foreground="#AAB3BE" FontSize="13" Margin="0,0,18,0"/>
    <TextBlock Text="v0.45.0.0" Foreground="#3FA9F5" FontWeight="Bold" FontSize="13"/>
   </StackPanel>
  </DockPanel></Border>
 </Grid>
</Window>
"@

$r=New-Object System.Xml.XmlNodeReader $x

try{
Add-Type -TypeDefinition @"
using System;
using System.Globalization;
using System.IO;
using System.Windows.Data;
using System.Windows.Media.Imaging;
namespace CarDealerCompanion {
 public sealed class LocalImageConverter : IValueConverter {
  public object Convert(object value, Type targetType, object parameter, CultureInfo culture) {
   try {
    var path = value == null ? null : value.ToString();
    if (String.IsNullOrWhiteSpace(path) || !File.Exists(path)) return null;
    var bmp = new BitmapImage();
    bmp.BeginInit(); bmp.CacheOption = BitmapCacheOption.OnLoad; bmp.UriSource = new Uri(path, UriKind.Absolute); bmp.EndInit(); bmp.Freeze();
    return bmp;
   } catch { return null; }
  }
  public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture) { throw new NotSupportedException(); }
 }
}
"@ -ReferencedAssemblies PresentationFramework,PresentationCore,WindowsBase
}catch{}
$w=[Windows.Markup.XamlReader]::Load($r)
try{$w.Resources["LocalImageConverter"]=New-Object CarDealerCompanion.LocalImageConverter}catch{}
$tabs=$w.FindName("Tabs");$status=$w.FindName("Status");$count=$w.FindName("Count")
$navDashboard=$w.FindName("NavDashboard");$navInventory=$w.FindName("NavInventory");$navParts=$w.FindName("NavParts");$navCars=$w.FindName("NavCars");$navEmployees=$w.FindName("NavEmployees");$navContracts=$w.FindName("NavContracts");$navAutomatedPlatform=$w.FindName("NavAutomatedPlatform");$navRacing=$w.FindName("NavRacing");$navAutoFleet=$w.FindName("NavAutoFleet");$navSettings=$w.FindName("NavSettings")
$dashboardRefreshSettingsLink=$w.FindName("DashboardRefreshSettingsLink")
$dashWorkflow=$w.FindName("DashWorkflow");$dashReady=$w.FindName("DashReady");$dashInventory=$w.FindName("DashInventory");$dashRepair=$w.FindName("DashRepair");$headerReputation=$w.FindName("HeaderReputation");$unique=$w.FindName("Unique");$total=$w.FindName("Total");$low=$w.FindName("Low");$groupSummary=$w.FindName("GroupSummary");$vehicleTotal=$w.FindName("VehicleTotal");$vehicleOnSale=$w.FindName("VehicleOnSale");$vehicleReady=$w.FindName("VehicleReady");$vehicleWaiting=$w.FindName("VehicleWaiting");$vehicleUtility=$w.FindName("VehicleUtility");$vehiclePersonal=$w.FindName("VehiclePersonal");$vehicleGhost=$w.FindName("VehicleGhost");$businessMoney=$w.FindName("BusinessMoney");$businessLevel=$w.FindName("BusinessLevel");$businessXP=$w.FindName("BusinessXP");$businessReputation=$w.FindName("BusinessReputation");$businessTonyRep=$w.FindName("BusinessTonyRep");$businessGameDay=$w.FindName("BusinessGameDay");$businessGameTime=$w.FindName("BusinessGameTime");$headerGameClock=$w.FindName("HeaderGameClock");$dashContractsSummary=$w.FindName("DashContractsSummary");$dashboardContractsLink=$w.FindName("DashboardContractsLink");$headerMoney=$w.FindName("HeaderMoney");$headerXP=$w.FindName("HeaderXP");$dashTonyRep=$w.FindName("DashTonyRep");$dashTonyRequests=$w.FindName("DashTonyRequests");$dashTonyDeal=$w.FindName("DashTonyDeal")
$lists=@{}

foreach($tab in $tabs.Items){
 if($tab.Tag.ToString() -eq "Dashboard" -or $tab.Tag.ToString() -eq "InventoryRoot"){continue}
 $list=New-Object System.Windows.Controls.ListView
 $view=New-Object System.Windows.Controls.GridView
 $c1=New-Object System.Windows.Controls.GridViewColumn;$c1.Header="Item";$c1.Width=145;$c1.DisplayMemberBinding=New-Object System.Windows.Data.Binding("Name");[void]$view.Columns.Add($c1)
 $c2=New-Object System.Windows.Controls.GridViewColumn;$c2.Header="Player";$c2.Width=50;$c2.DisplayMemberBinding=New-Object System.Windows.Data.Binding("Player");[void]$view.Columns.Add($c2)
 $c3=New-Object System.Windows.Controls.GridViewColumn;$c3.Header="Storage";$c3.Width=55;$c3.DisplayMemberBinding=New-Object System.Windows.Data.Binding("Storage");[void]$view.Columns.Add($c3)
$cRepair=New-Object System.Windows.Controls.GridViewColumn;$cRepair.Header="Repair M";$cRepair.Width=62;$cRepair.DisplayMemberBinding=New-Object System.Windows.Data.Binding("RepairMachine");[void]$view.Columns.Add($cRepair)
 $c4=New-Object System.Windows.Controls.GridViewColumn;$c4.Header="100%";$c4.Width=45;$c4.DisplayMemberBinding=New-Object System.Windows.Data.Binding("Full");[void]$view.Columns.Add($c4)
 $c5=New-Object System.Windows.Controls.GridViewColumn;$c5.Header="Repair";$c5.Width=50;$c5.DisplayMemberBinding=New-Object System.Windows.Data.Binding("Repair");[void]$view.Columns.Add($c5)
 $c6=New-Object System.Windows.Controls.GridViewColumn;$c6.Header="Total";$c6.Width=45;$c6.DisplayMemberBinding=New-Object System.Windows.Data.Binding("Qty");[void]$view.Columns.Add($c6)
 $list.View=$view;$tab.Content=$list;$lists[$tab.Tag.ToString()]=$list
}


# ------------------------------------------------------------
# INVENTORY TAB - VISUAL REDESIGN STAGE 1
# ------------------------------------------------------------
# Inventory remains strictly NON-CAR items.  The presentation now mirrors the
# newer Parts page: summary cards, game-style category buttons, live table and
# a selected-item detail panel.  Reader/classification behaviour is unchanged.
$inventoryTab=$tabs.Items[1]

$inventoryRoot=New-Object System.Windows.Controls.Grid
$inventoryRoot.Margin="8"
$inventoryRoot.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height="Auto"}))
$inventoryRoot.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height="Auto"}))
$inventoryRoot.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height="*"}))

$inventoryTitle=New-Object System.Windows.Controls.TextBlock
$inventoryTitle.Text="INVENTORY"
$inventoryTitle.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFF3E3")
$inventoryTitle.FontSize=20
$inventoryTitle.FontWeight="Bold"
$inventoryTitle.Margin="2,0,0,8"
[System.Windows.Controls.Grid]::SetRow($inventoryTitle,0)
$inventoryRoot.Children.Add($inventoryTitle)|Out-Null

$inventorySummary=New-Object System.Windows.Controls.Primitives.UniformGrid
$inventorySummary.Columns=5
$inventorySummary.Margin="0,0,0,10"
[System.Windows.Controls.Grid]::SetRow($inventorySummary,1)

function New-InventorySummaryCard([string]$title,[string]$accent){
 $b=New-Object System.Windows.Controls.Border
 $b.Background=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#20262F")
 $b.BorderBrush=[System.Windows.Media.BrushConverter]::new().ConvertFromString($accent)
 $b.BorderThickness="1";$b.CornerRadius="8";$b.Padding="12,8";$b.Margin="0,0,8,0"
 $sp=New-Object System.Windows.Controls.StackPanel
 $lbl=New-Object System.Windows.Controls.TextBlock
 $lbl.Text=$title;$lbl.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#9EABB8")
 $lbl.FontSize=11;$lbl.FontWeight="SemiBold"
 $val=New-Object System.Windows.Controls.TextBlock
 $val.Text="-";$val.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString($accent)
 $val.FontSize=20;$val.FontWeight="Bold";$val.Margin="0,2,0,0"
 $sp.Children.Add($lbl)|Out-Null;$sp.Children.Add($val)|Out-Null;$b.Child=$sp
 $inventorySummary.Children.Add($b)|Out-Null
 return $val
}

$inventorySummaryTotal=New-InventorySummaryCard "TOTAL ITEMS" "#E39A2D"
$inventorySummaryUnique=New-InventorySummaryCard "DIFFERENT ITEMS" "#67D56A"
$inventorySummaryPlayer=New-InventorySummaryCard "PLAYER" "#76B9F5"
$inventorySummaryStorage=New-InventorySummaryCard "STORAGE" "#D6B6FF"
$inventorySummaryTrunk=New-InventorySummaryCard "TRUNK" "#E6B85C"
$inventoryRoot.Children.Add($inventorySummary)|Out-Null

$inventoryBody=New-Object System.Windows.Controls.Grid
$inventoryBody.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width="*"}))
$inventoryBody.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width="300"}))
[System.Windows.Controls.Grid]::SetRow($inventoryBody,2)

$inventoryTabs=New-Object System.Windows.Controls.TabControl
$inventoryTabs.Margin="0,0,10,0";$inventoryTabs.Background="#171C24"
[System.Windows.Controls.Grid]::SetColumn($inventoryTabs,0)
$inventoryBody.Children.Add($inventoryTabs)|Out-Null

$inventoryDetailBorder=New-Object System.Windows.Controls.Border
$inventoryDetailBorder.Background=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#20262F")
$inventoryDetailBorder.BorderBrush=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#3B4552")
$inventoryDetailBorder.BorderThickness="1";$inventoryDetailBorder.CornerRadius="8";$inventoryDetailBorder.Padding="14"
[System.Windows.Controls.Grid]::SetColumn($inventoryDetailBorder,1)

$inventoryDetailStack=New-Object System.Windows.Controls.StackPanel
$inventoryDetailHeading=New-Object System.Windows.Controls.TextBlock
$inventoryDetailHeading.Text="SELECTED ITEM";$inventoryDetailHeading.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#E39A2D")
$inventoryDetailHeading.FontWeight="Bold";$inventoryDetailHeading.FontSize=13
$inventoryDetailStack.Children.Add($inventoryDetailHeading)|Out-Null

$inventoryDetailName=New-Object System.Windows.Controls.TextBlock
$inventoryDetailName.Text="Select an item from the list";$inventoryDetailName.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFF3E3")
$inventoryDetailName.FontSize=18;$inventoryDetailName.FontWeight="Bold";$inventoryDetailName.TextWrapping="Wrap";$inventoryDetailName.Margin="0,8,0,12"
$inventoryDetailStack.Children.Add($inventoryDetailName)|Out-Null

$inventoryDetailGroup=New-Object System.Windows.Controls.TextBlock
$inventoryDetailGroup.Text="Category: -";$inventoryDetailGroup.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#AEB8C3")
$inventoryDetailGroup.FontSize=13
$inventoryDetailStack.Children.Add($inventoryDetailGroup)|Out-Null

$inventoryDetailTotal=New-Object System.Windows.Controls.TextBlock
$inventoryDetailTotal.Text="Total owned: -";$inventoryDetailTotal.FontSize=14;$inventoryDetailTotal.FontWeight="SemiBold";$inventoryDetailTotal.Margin="0,12,0,0"
$inventoryDetailStack.Children.Add($inventoryDetailTotal)|Out-Null

$inventoryDetailLocations=New-Object System.Windows.Controls.TextBlock
$inventoryDetailLocations.Text="Player: -   Storage: -   Trunk: -";$inventoryDetailLocations.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#BFC7D1")
$inventoryDetailLocations.FontSize=13;$inventoryDetailLocations.TextWrapping="Wrap";$inventoryDetailLocations.Margin="0,5,0,0"
$inventoryDetailStack.Children.Add($inventoryDetailLocations)|Out-Null

$inventoryDetailStatusBorder=New-Object System.Windows.Controls.Border
$inventoryDetailStatusBorder.Background=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#18251D")
$inventoryDetailStatusBorder.BorderBrush=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#315F3A")
$inventoryDetailStatusBorder.BorderThickness="1";$inventoryDetailStatusBorder.CornerRadius="6";$inventoryDetailStatusBorder.Padding="9,6";$inventoryDetailStatusBorder.Margin="0,14,0,0"
$inventoryDetailStatus=New-Object System.Windows.Controls.TextBlock
$inventoryDetailStatus.Text="Select an item to inspect ownership";$inventoryDetailStatus.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#67D56A")
$inventoryDetailStatus.FontWeight="Bold";$inventoryDetailStatus.FontSize=12;$inventoryDetailStatus.TextWrapping="Wrap"
$inventoryDetailStatusBorder.Child=$inventoryDetailStatus
$inventoryDetailStack.Children.Add($inventoryDetailStatusBorder)|Out-Null

$inventoryDetailHint=New-Object System.Windows.Controls.TextBlock
$inventoryDetailHint.Text="Inventory shows non-car items only. Car parts remain under PARTS."
$inventoryDetailHint.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#7F8C99")
$inventoryDetailHint.FontSize=11;$inventoryDetailHint.TextWrapping="Wrap";$inventoryDetailHint.Margin="0,14,0,0"
$inventoryDetailStack.Children.Add($inventoryDetailHint)|Out-Null

# v0.43.10.2 - contained large Selected Inventory preview.
# Uses the same icon chooser as the working Inventory rows and the same
# fixed preview treatment proven on Selected Part in v0.43.10.2.
$inventoryDetailPreviewBorder=New-Object System.Windows.Controls.Border
$inventoryDetailPreviewBorder.Height=205
$inventoryDetailPreviewBorder.Margin="0,14,0,0"
$inventoryDetailPreviewBorder.Padding="10"
$inventoryDetailPreviewBorder.Background=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#11161D")
$inventoryDetailPreviewBorder.BorderBrush=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#343C47")
$inventoryDetailPreviewBorder.BorderThickness="1"
$inventoryDetailPreviewBorder.CornerRadius="6"
$inventoryDetailPreviewBorder.Visibility="Collapsed"

$inventoryDetailPreviewImage=New-Object System.Windows.Controls.Image
$inventoryDetailPreviewImage.MaxWidth=235
$inventoryDetailPreviewImage.MaxHeight=180
$inventoryDetailPreviewImage.Stretch=[System.Windows.Media.Stretch]::Uniform
$inventoryDetailPreviewImage.HorizontalAlignment=[System.Windows.HorizontalAlignment]::Center
$inventoryDetailPreviewImage.VerticalAlignment=[System.Windows.VerticalAlignment]::Center
$inventoryDetailPreviewImage.SnapsToDevicePixels=$true
$inventoryDetailPreviewBorder.Child=$inventoryDetailPreviewImage
$inventoryDetailStack.Children.Add($inventoryDetailPreviewBorder)|Out-Null

$inventoryDetailBorder.Child=$inventoryDetailStack
$inventoryBody.Children.Add($inventoryDetailBorder)|Out-Null
$inventoryRoot.Children.Add($inventoryBody)|Out-Null

function Update-InventoryDetail($item){
 if($null -eq $item){return}
 $inventoryDetailName.Text=[string]$item.Name
 $inventoryDetailGroup.Text="Category: $([string]$item.InventoryGroup)"
 $inventoryDetailTotal.Text="Total owned: $([int]$item.Qty)"
 $inventoryDetailLocations.Text="Player: $([int]$item.Player)   Storage: $([int]$item.Storage)   Trunk: $([int]$item.Trunk)"
 $inventoryDetailStatus.Text="OWNED - found in game"
 $inventoryDetailStatus.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#76B9F5")
 $inventoryDetailStatusBorder.Background=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#182638")
 $inventoryDetailStatusBorder.BorderBrush=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#315B85")

 # Large preview uses the exact same genuine/fallback icon selected for the row.
 try{
  $inventoryDetailPreviewImage.Source=$null
  $inventoryDetailPreviewBorder.Visibility="Collapsed"
  $previewPath=Get-InventoryRowIconPath ([string]$item.InventoryGroup) ([string]$item.Name)
  if(-not [string]::IsNullOrWhiteSpace([string]$previewPath) -and (Test-Path -LiteralPath $previewPath)){
   if($previewPath.StartsWith($assetsRoot,[System.StringComparison]::OrdinalIgnoreCase)){
    $relativePreview=$previewPath.Substring($assetsRoot.Length).TrimStart('\').Replace('\','/')
    $previewBmp=New-CompanionBitmapImage $relativePreview
   }else{
    $previewBmp=New-Object System.Windows.Media.Imaging.BitmapImage
    $previewBmp.BeginInit();$previewBmp.CacheOption=[System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
    $previewBmp.UriSource=New-Object System.Uri($previewPath,[System.UriKind]::Absolute)
    $previewBmp.EndInit();$previewBmp.Freeze()
   }
   if($null -ne $previewBmp){
    $inventoryDetailPreviewImage.Source=$previewBmp
    $inventoryDetailPreviewBorder.Visibility="Visible"
   }
  }
 }catch{
  $inventoryDetailPreviewImage.Source=$null
  $inventoryDetailPreviewBorder.Visibility="Collapsed"
 }
}

function Get-InventoryRowIconPath([string]$inventoryGroup,[string]$name){
 try{
  $fallback=@{
   "Valuables"="GameUI/Inventory/Loot/UI_icn_Collectibles.png";
   "Electronics"="GameUI/Inventory/Loot/UI_icn_ElektronicDevices.png";
   "Tools"="GameUI/Inventory/Loot/UI_icn_Tools.png";
   "Media"="GameUI/Inventory/Loot/UI_icn_CDxDVD.png";
   "Furniture"="GameUI/Inventory/Furniture/UI_Modern_Chair_ico.png";
   "Consumables"="Icons/Inventory/consumables.png";
   "Containers"="GameUI/Inventory/Loot/UI_icn_Lootbox.png";
   "Other"="Icons/Inventory/other.png"
  }
  $lower=([string]$name).ToLowerInvariant()
  $rel=$null
  if($lower -match 'safe|strongbox|vault'){ $rel='GameUI/Inventory/Loot/UI_icn_Safe.png' }
  elseif($lower -match 'jewel|jewell|necklace|bracelet|ring'){ $rel='GameUI/Inventory/Loot/UI_icn_Jewelery.png' }
  elseif($lower -match 'gold'){ $rel='GameUI/Inventory/Loot/UI_icn_Gold.png' }
  elseif($lower -match 'wallet'){ $rel='GameUI/Inventory/Loot/UI_icn_Wallet.png' }
  elseif($lower -match 'lockpick'){ $rel='GameUI/Inventory/Loot/UI_icn_LockPicker.png' }
  elseif($lower -match 'screwdriver|drill|tool'){ $rel='GameUI/Inventory/Loot/UI_icn_Tools.png' }
  elseif($lower -match 'walkie|cb radio'){ $rel='GameUI/Inventory/Loot/UI_icn_CBRadio.png' }
  elseif($lower -match 'ephon|ephone|flip-phone|flip phone|smartphone|cellphone|mobile phone'){ $rel='GameUI/Inventory/Loot/UI_icn_ElektronicDevices.png' }
  elseif($lower -match 'guitar|musical'){ $rel='GameUI/Inventory/Loot/UI_icn_MusicalEquipment.png' }
  elseif($lower -match 'vinyl|record'){ $rel='GameUI/Inventory/Loot/UI_icn_Vinyl.png' }
  elseif($lower -match '\bcd\b|dvd'){ $rel='GameUI/Inventory/Loot/UI_icn_CDxDVD.png' }
  elseif($inventoryGroup -eq 'Furniture'){
   if($lower -match 'chair|armchair|stool|bench'){ $rel='GameUI/Inventory/Furniture/UI_Modern_Chair_ico.png' }
   elseif($lower -match 'table|desk'){ $rel='GameUI/Inventory/Furniture/UI_Modern_Table_ico.png' }
   elseif($lower -match 'lamp'){ $rel='GameUI/Inventory/Furniture/UI_Modern_Lamp_ico.png' }
   elseif($lower -match 'phone'){ $rel='GameUI/Inventory/Furniture/UI_Modern_Phone_ico.png' }
   elseif($lower -match 'picture|painting|artwork'){ $rel='GameUI/Inventory/Furniture/UI_Modern_PictureA_ico.png' }
   elseif($lower -match 'trash|bin'){ $rel='GameUI/Inventory/Furniture/UI_Modern_TrashCan_ico.png' }
   else{$rel='GameUI/Inventory/Furniture/UI_Modern_DecorationA_ico.png'}
  }
  elseif($inventoryGroup -eq 'Consumables'){
   if($lower -match 'cigarette'){ $rel='GameUI/Inventory/Consumables/Cigarette-icon.png' }
   elseif($lower -match 'candy'){ $rel='GameUI/Inventory/Consumables/candy_icon.png' }
  }
  if($rel){$p=Get-CompanionAssetPath $rel;if($p){return $p}}
  if($fallback.ContainsKey($inventoryGroup)){$p=Get-CompanionAssetPath $fallback[$inventoryGroup];if($p){return $p}}
 }catch{}
 return (Get-CompanionAssetPath 'Icons/Inventory/other.png')
}

function New-InventoryHeaderGrid {
 $g=New-Object System.Windows.Controls.Grid
 $g.Margin='4,2,4,0'
 $widths=@(30,220,60,68,60,60)
 $labels=@('', 'Item','Player','Storage','Trunk','Total')
 for($i=0;$i -lt $widths.Count;$i++){
  $cd=New-Object System.Windows.Controls.ColumnDefinition
  $cd.Width=New-Object System.Windows.GridLength([double]$widths[$i])
  [void]$g.ColumnDefinitions.Add($cd)
  $tb=New-Object System.Windows.Controls.TextBlock
  $tb.Text=$labels[$i];$tb.FontWeight='SemiBold';$tb.Foreground='#BFC7D1';$tb.FontSize=11;$tb.Margin='3,2,3,4';$tb.VerticalAlignment='Center'
  [System.Windows.Controls.Grid]::SetColumn($tb,$i);[void]$g.Children.Add($tb)
 }
 return $g
}

function New-InventoryVisualRow($item){
 $li=New-Object System.Windows.Controls.ListViewItem
 $li.Tag=$item;$li.HorizontalContentAlignment='Stretch';$li.Padding='0';$li.Margin='0'
 $g=New-Object System.Windows.Controls.Grid
 $widths=@(30,220,60,68,60,60)
 foreach($w in $widths){$cd=New-Object System.Windows.Controls.ColumnDefinition;$cd.Width=New-Object System.Windows.GridLength([double]$w);[void]$g.ColumnDefinitions.Add($cd)}
 $img=New-Object System.Windows.Controls.Image
 $img.Width=20;$img.Height=20;$img.Stretch='Uniform';$img.HorizontalAlignment='Center';$img.VerticalAlignment='Center';$img.Margin='3'
 try{
  $iconPath=Get-InventoryRowIconPath ([string]$item.InventoryGroup) ([string]$item.Name)
  if($iconPath -and (Test-Path -LiteralPath $iconPath)){
   if($iconPath.StartsWith($assetsRoot,[System.StringComparison]::OrdinalIgnoreCase)){
    $relative=$iconPath.Substring($assetsRoot.Length).TrimStart('\').Replace('\','/')
    $img.Source=New-CompanionBitmapImage $relative
   }else{
    $bmp=New-Object System.Windows.Media.Imaging.BitmapImage
    $bmp.BeginInit();$bmp.CacheOption=[System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
    $bmp.UriSource=New-Object System.Uri($iconPath,[System.UriKind]::Absolute)
    $bmp.EndInit();$bmp.Freeze();$img.Source=$bmp
   }
  }
 }catch{}
 [System.Windows.Controls.Grid]::SetColumn($img,0);[void]$g.Children.Add($img)
 $vals=@([string]$item.Name,[string]$item.Player,[string]$item.Storage,[string]$item.Trunk,[string]$item.Qty)
 for($i=0;$i -lt $vals.Count;$i++){
  $tb=New-Object System.Windows.Controls.TextBlock
  $tb.Text=$vals[$i];$tb.VerticalAlignment='Center';$tb.Margin='4,4,3,4';$tb.TextTrimming='CharacterEllipsis'
  if($i -eq 0){$tb.Foreground='#F3F5F7'}else{$tb.Foreground='#D6DCE3';$tb.HorizontalAlignment='Center'}
  [System.Windows.Controls.Grid]::SetColumn($tb,$i+1);[void]$g.Children.Add($tb)
 }
 $li.Content=$g
 return $li
}
function Add-InventoryVisualItem($list,$item){ [void]$list.Items.Add((New-InventoryVisualRow $item)) }

function Add-InventorySubTab([string]$header,[string]$key){
 $tab=New-Object System.Windows.Controls.TabItem
 $tab.Header=$header
 $dock=New-Object System.Windows.Controls.DockPanel;$dock.LastChildFill=$true
 $headerGrid=New-InventoryHeaderGrid
 [System.Windows.Controls.DockPanel]::SetDock($headerGrid,'Top');[void]$dock.Children.Add($headerGrid)
 $list=New-Object System.Windows.Controls.ListView
 $list.Margin='4,0,4,4';$list.FontSize=13;$list.HorizontalContentAlignment='Stretch'
 $list.Add_SelectionChanged({param($sender,$e) if($null -ne $sender.SelectedItem){$row=$sender.SelectedItem.Tag;if($null -ne $row){Update-InventoryDetail $row}}})
 [void]$dock.Children.Add($list)
 $tab.Content=$dock
 [void]$inventoryTabs.Items.Add($tab)
 $lists[$key]=$list
 return $tab
}

$inventoryAllTab=Add-InventorySubTab "ALL" "InventoryAll"
$inventoryValuablesTab=Add-InventorySubTab "VALUABLES + SAFES" "InventoryValuables"
$inventoryElectronicsTab=Add-InventorySubTab "ELECTRONICS" "InventoryElectronics"
$inventoryToolsTab=Add-InventorySubTab "TOOLS" "InventoryTools"
$inventoryMediaTab=Add-InventorySubTab "MEDIA" "InventoryMedia"
$inventoryFurnitureTab=Add-InventorySubTab "FURNITURE" "InventoryFurniture"
$inventoryConsumablesTab=Add-InventorySubTab "CONSUMABLES" "InventoryConsumables"
$inventoryContainersTab=Add-InventorySubTab "CONTAINERS" "InventoryContainers"
$inventoryOtherTab=Add-InventorySubTab "OTHER" "InventoryOther"
$inventoryTab.Content=$inventoryRoot
# ------------------------------------------------------------
# PARTS TAB - VISUAL REDESIGN STAGE 1
# ------------------------------------------------------------
$partsTab=New-Object System.Windows.Controls.TabItem
$partsTab.Header="PARTS"
$partsTab.Tag="Parts"

$partsRoot=New-Object System.Windows.Controls.Grid
$partsRoot.Margin="8"
$partsRoot.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height="Auto"}))
$partsRoot.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height="Auto"}))
$partsRoot.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height="*"}))

$partsTitle=New-Object System.Windows.Controls.TextBlock
$partsTitle.Text="PARTS INVENTORY"
$partsTitle.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFF3E3")
$partsTitle.FontSize=20
$partsTitle.FontWeight="Bold"
$partsTitle.Margin="2,0,0,8"
[System.Windows.Controls.Grid]::SetRow($partsTitle,0)
$partsRoot.Children.Add($partsTitle)|Out-Null

$partsSummary=New-Object System.Windows.Controls.Primitives.UniformGrid
$partsSummary.Columns=4
$partsSummary.Margin="0,0,0,10"
[System.Windows.Controls.Grid]::SetRow($partsSummary,1)

function New-PartsSummaryCard([string]$title,[string]$accent){
 $b=New-Object System.Windows.Controls.Border
 $b.Background=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#20262F")
 $b.BorderBrush=[System.Windows.Media.BrushConverter]::new().ConvertFromString($accent)
 $b.BorderThickness="1"
 $b.CornerRadius="8"
 $b.Padding="12,8"
 $b.Margin="0,0,8,0"
 $sp=New-Object System.Windows.Controls.StackPanel
 $lbl=New-Object System.Windows.Controls.TextBlock
 $lbl.Text=$title
 $lbl.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#9EABB8")
 $lbl.FontSize=11
 $lbl.FontWeight="SemiBold"
 $val=New-Object System.Windows.Controls.TextBlock
 $val.Text="-"
 $val.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString($accent)
 $val.FontSize=20
 $val.FontWeight="Bold"
 $val.Margin="0,2,0,0"
 $sp.Children.Add($lbl)|Out-Null
 $sp.Children.Add($val)|Out-Null
 $b.Child=$sp
 $partsSummary.Children.Add($b)|Out-Null
 return $val
}

$partsSummaryTotal=New-PartsSummaryCard "TOTAL PARTS" "#E39A2D"
$partsSummaryReady=New-PartsSummaryCard "100% READY" "#67D56A"
$partsSummaryRepair=New-PartsSummaryCard "NEEDS REPAIR" "#E05A4F"
$partsSummaryLow=New-PartsSummaryCard "LOW STOCK" "#F0B84B"
$partsRoot.Children.Add($partsSummary)|Out-Null

$partsBody=New-Object System.Windows.Controls.Grid
$partsBody.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width="*"}))
$partsBody.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width="300"}))
[System.Windows.Controls.Grid]::SetRow($partsBody,2)

$partsTabs=New-Object System.Windows.Controls.TabControl
$partsTabs.Margin="0,0,10,0"
$partsTabs.Background="#171C24"
[System.Windows.Controls.Grid]::SetColumn($partsTabs,0)
$partsBody.Children.Add($partsTabs)|Out-Null

$partsDetailBorder=New-Object System.Windows.Controls.Border
$partsDetailBorder.Background=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#20262F")
$partsDetailBorder.BorderBrush=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#3B4552")
$partsDetailBorder.BorderThickness="1"
$partsDetailBorder.CornerRadius="8"
$partsDetailBorder.Padding="14"
[System.Windows.Controls.Grid]::SetColumn($partsDetailBorder,1)

$partsDetailStack=New-Object System.Windows.Controls.StackPanel
$partsDetailHeading=New-Object System.Windows.Controls.TextBlock
$partsDetailHeading.Text="SELECTED PART"
$partsDetailHeading.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#E39A2D")
$partsDetailHeading.FontWeight="Bold"
$partsDetailHeading.FontSize=13
$partsDetailStack.Children.Add($partsDetailHeading)|Out-Null

$partsDetailName=New-Object System.Windows.Controls.TextBlock
$partsDetailName.Text="Select a part from the list"
$partsDetailName.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFF3E3")
$partsDetailName.FontSize=18
$partsDetailName.FontWeight="Bold"
$partsDetailName.TextWrapping="Wrap"
$partsDetailName.Margin="0,8,0,12"
$partsDetailStack.Children.Add($partsDetailName)|Out-Null

$partsDetailGroup=New-Object System.Windows.Controls.TextBlock
$partsDetailGroup.Text="Category: -"
$partsDetailGroup.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#AEB8C3")
$partsDetailGroup.FontSize=13
$partsDetailStack.Children.Add($partsDetailGroup)|Out-Null

$partsDetailStock=New-Object System.Windows.Controls.TextBlock
$partsDetailStock.Text="Total stock: -"
$partsDetailStock.FontSize=14
$partsDetailStock.FontWeight="SemiBold"
$partsDetailStock.Margin="0,12,0,0"
$partsDetailStack.Children.Add($partsDetailStock)|Out-Null

$partsDetailLocations=New-Object System.Windows.Controls.TextBlock
$partsDetailLocations.Text="Player: -   Storage: -   Trunk: -   Repair M: -"
$partsDetailLocations.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#BFC7D1")
$partsDetailLocations.FontSize=13
$partsDetailLocations.TextWrapping="Wrap"
$partsDetailLocations.Margin="0,5,0,0"
$partsDetailStack.Children.Add($partsDetailLocations)|Out-Null

$partsDetailCondition=New-Object System.Windows.Controls.TextBlock
$partsDetailCondition.Text="100%: -   Repair: -"
$partsDetailCondition.FontSize=13
$partsDetailCondition.Margin="0,10,0,0"
$partsDetailStack.Children.Add($partsDetailCondition)|Out-Null

$partsDetailStatusBorder=New-Object System.Windows.Controls.Border
$partsDetailStatusBorder.Background=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#18251D")
$partsDetailStatusBorder.BorderBrush=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#315F3A")
$partsDetailStatusBorder.BorderThickness="1"
$partsDetailStatusBorder.CornerRadius="6"
$partsDetailStatusBorder.Padding="9,6"
$partsDetailStatusBorder.Margin="0,14,0,0"
$partsDetailStatus=New-Object System.Windows.Controls.TextBlock
$partsDetailStatus.Text="Select a part to inspect stock"
$partsDetailStatus.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#67D56A")
$partsDetailStatus.FontWeight="Bold"
$partsDetailStatus.FontSize=12
$partsDetailStatus.TextWrapping="Wrap"
$partsDetailStatusBorder.Child=$partsDetailStatus
$partsDetailStack.Children.Add($partsDetailStatusBorder)|Out-Null

$partsDetailHint=New-Object System.Windows.Controls.TextBlock
$partsDetailHint.Text="Live stock is combined from player inventory, storage, car trunks and repair machines. Trunk quantities are included in Total; trunk condition is not currently classified."
$partsDetailHint.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#7F8C99")
$partsDetailHint.FontSize=11
$partsDetailHint.TextWrapping="Wrap"
$partsDetailHint.Margin="0,14,0,0"
$partsDetailStack.Children.Add($partsDetailHint)|Out-Null

# v0.43.10.2 - contained large Selected Part preview.
# Uses the same proven direct BitmapImage route as the working row icons,
# but keeps the artwork inside a fixed preview box so it can never overflow.
$partsDetailPreviewBorder=New-Object System.Windows.Controls.Border
$partsDetailPreviewBorder.Height=205
$partsDetailPreviewBorder.Margin="0,14,0,0"
$partsDetailPreviewBorder.Padding="10"
$partsDetailPreviewBorder.Background=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#11161D")
$partsDetailPreviewBorder.BorderBrush=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#343C47")
$partsDetailPreviewBorder.BorderThickness="1"
$partsDetailPreviewBorder.CornerRadius="6"
$partsDetailPreviewBorder.Visibility="Collapsed"

$partsDetailPreviewImage=New-Object System.Windows.Controls.Image
$partsDetailPreviewImage.MaxWidth=235
$partsDetailPreviewImage.MaxHeight=180
$partsDetailPreviewImage.Stretch=[System.Windows.Media.Stretch]::Uniform
$partsDetailPreviewImage.HorizontalAlignment=[System.Windows.HorizontalAlignment]::Center
$partsDetailPreviewImage.VerticalAlignment=[System.Windows.VerticalAlignment]::Center
$partsDetailPreviewImage.SnapsToDevicePixels=$true
$partsDetailPreviewBorder.Child=$partsDetailPreviewImage
$partsDetailStack.Children.Add($partsDetailPreviewBorder)|Out-Null

$partsDetailBorder.Child=$partsDetailStack
$partsBody.Children.Add($partsDetailBorder)|Out-Null
$partsRoot.Children.Add($partsBody)|Out-Null

function Update-PartsDetail($item){
 if($null -eq $item){return}
 $partsDetailName.Text=[string]$item.Name
 $partsDetailGroup.Text=if(([string]$item.Group) -eq "Customisation" -and -not [string]::IsNullOrWhiteSpace([string]$item.CustomGroup)){"Category: Customisation - $([string]$item.CustomGroup)"}else{"Category: $([string]$item.Group)"}
 $partsDetailStock.Text="Total stock: $([int]$item.Qty)"
 $partsDetailLocations.Text="Player: $([int]$item.Player)   Storage: $([int]$item.Storage)   Trunk: $([int]$item.Trunk)   Repair M: $([int]$item.RepairMachine)"
 $partsDetailCondition.Text="100%: $([int]$item.Full)   Repair: $([int]$item.Repair)"

 # Large preview uses the exact same icon chosen for the visible row.
 try{
  $partsDetailPreviewImage.Source=$null
  $partsDetailPreviewBorder.Visibility="Collapsed"
  $previewPath=[string]$item.IconPath
  if(-not [string]::IsNullOrWhiteSpace($previewPath) -and (Test-Path -LiteralPath $previewPath)){
   $previewBmp=New-CompanionBitmapImageFromAbsolutePath $previewPath
   if($null -ne $previewBmp){
    $partsDetailPreviewImage.Source=$previewBmp
    $partsDetailPreviewBorder.Visibility="Visible"
   }
  }
 }catch{
  $partsDetailPreviewImage.Source=$null
  $partsDetailPreviewBorder.Visibility="Collapsed"
 }

 if([int]$item.Qty -lt 2){
  $partsDetailStatus.Text="⚠ LOW STOCK - only $([int]$item.Qty) available"
  $partsDetailStatus.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#F0B84B")
  $partsDetailStatusBorder.Background=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#302817")
  $partsDetailStatusBorder.BorderBrush=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#7A6422")
 }elseif([int]$item.Repair -gt 0){
  $partsDetailStatus.Text="$([int]$item.Repair) item(s) need repair"
  $partsDetailStatus.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#F28B82")
  $partsDetailStatusBorder.Background=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#301C1C")
  $partsDetailStatusBorder.BorderBrush=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#713737")
 }else{
  $partsDetailStatus.Text="✓ STOCK OK"
  $partsDetailStatus.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#67D56A")
  $partsDetailStatusBorder.Background=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#18251D")
  $partsDetailStatusBorder.BorderBrush=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#315F3A")
 }
}

function New-PartsHeaderGrid([bool]$isCustom=$false){
 $g=New-Object System.Windows.Controls.Grid
 $g.Margin='4,2,4,0'
 $widths=if($isCustom){@(28,185,52,58,52,64,48)}else{@(28,145,52,58,52,64,48,50,48)}
 $labels=if($isCustom){@('', 'Item','Player','Storage','Trunk','Repair M','Total')}else{@('', 'Item','Player','Storage','Trunk','Repair M','100%','Repair','Total')}
 for($i=0;$i -lt $widths.Count;$i++){
  $cd=New-Object System.Windows.Controls.ColumnDefinition
  $cd.Width=New-Object System.Windows.GridLength([double]$widths[$i])
  [void]$g.ColumnDefinitions.Add($cd)
  $tb=New-Object System.Windows.Controls.TextBlock
  $tb.Text=$labels[$i];$tb.FontWeight='SemiBold';$tb.Foreground='#BFC7D1';$tb.FontSize=11;$tb.Margin='3,2,3,4';$tb.VerticalAlignment='Center'
  [System.Windows.Controls.Grid]::SetColumn($tb,$i);[void]$g.Children.Add($tb)
 }
 return $g
}

function New-PartsVisualRow($item,[bool]$isCustom=$false){
 $li=New-Object System.Windows.Controls.ListViewItem
 $li.Tag=$item
 $li.HorizontalContentAlignment='Stretch'
 $li.Padding='0';$li.Margin='0'
 $g=New-Object System.Windows.Controls.Grid
 $g.Margin='0'
 $widths=if($isCustom){@(28,185,52,58,52,64,48)}else{@(28,145,52,58,52,64,48,50,48)}
 foreach($w in $widths){$cd=New-Object System.Windows.Controls.ColumnDefinition;$cd.Width=New-Object System.Windows.GridLength([double]$w);[void]$g.ColumnDefinitions.Add($cd)}

 # IMPORTANT: create the Image control directly here. No GridView/DataTemplate/
 # PSObject image binding is involved. This uses the same proven BitmapImage
 # loader as the working navigation and category icons.
 $img=New-Object System.Windows.Controls.Image
 $img.Width=20;$img.Height=20;$img.Stretch='Uniform';$img.HorizontalAlignment='Center';$img.VerticalAlignment='Center';$img.Margin='3'
 try{
  $iconPath=[string]$item.IconPath
  if(-not [string]::IsNullOrWhiteSpace($iconPath) -and (Test-Path -LiteralPath $iconPath)){
   $img.Source=New-CompanionBitmapImageFromAbsolutePath $iconPath
  }
 }catch{}
 [System.Windows.Controls.Grid]::SetColumn($img,0);[void]$g.Children.Add($img)

 $vals=if($isCustom){@([string]$item.Name,[string]$item.Player,[string]$item.Storage,[string]$item.Trunk,[string]$item.RepairMachine,[string]$item.Qty)}else{@([string]$item.Name,[string]$item.Player,[string]$item.Storage,[string]$item.Trunk,[string]$item.RepairMachine,[string]$item.Full,[string]$item.Repair,[string]$item.Qty)}
 for($i=0;$i -lt $vals.Count;$i++){
  $tb=New-Object System.Windows.Controls.TextBlock
  $tb.Text=$vals[$i];$tb.VerticalAlignment='Center';$tb.Margin='4,4,3,4';$tb.TextTrimming='CharacterEllipsis'
  if($i -eq 0){$tb.Foreground='#F3F5F7'}else{$tb.Foreground='#D6DCE3';$tb.HorizontalAlignment='Center'}
  [System.Windows.Controls.Grid]::SetColumn($tb,$i+1);[void]$g.Children.Add($tb)
 }
 $li.Content=$g
 return $li
}

function Add-PartsVisualItem($list,$item,[bool]$isCustom=$false){
 [void]$list.Items.Add((New-PartsVisualRow $item $isCustom))
}

function Add-PartsSubTab([string]$header,[string]$key){
 $tab=New-Object System.Windows.Controls.TabItem
 $tab.Header=$header
 $dock=New-Object System.Windows.Controls.DockPanel
 $dock.LastChildFill=$true
 $headerGrid=New-PartsHeaderGrid $false
 [System.Windows.Controls.DockPanel]::SetDock($headerGrid,'Top');[void]$dock.Children.Add($headerGrid)
 $list=New-Object System.Windows.Controls.ListView
 $list.Margin='4,0,4,4';$list.FontSize=13;$list.HorizontalContentAlignment='Stretch'
 $list.Add_SelectionChanged({param($sender,$e) if($null -ne $sender.SelectedItem){$row=$sender.SelectedItem.Tag;if($null -ne $row){Update-PartsDetail $row}}})
 [void]$dock.Children.Add($list)
 $tab.Content=$dock
 [void]$partsTabs.Items.Add($tab)
 $lists[$key]=$list
 return $tab
}

$partsAllTab=Add-PartsSubTab "ALL" "PartsAll"
$partsEngineTab=Add-PartsSubTab "ENGINE" "Engine"
$partsBrakesTab=Add-PartsSubTab "BRAKES" "Brakes"
$partsSuspensionTab=Add-PartsSubTab "SUSPENSION" "Suspension"
$partsExhaustTab=Add-PartsSubTab "EXHAUST" "Exhaust"
$partsSmallTab=Add-PartsSubTab "FUSES + OTHER PARTS" "SmallParts"

# Customisation stock stays inside Parts.  Mirror the game tuning-garage
# top-level organisation with four sub-tabs rather than one flat Group column.
$partsCustomTab=New-Object System.Windows.Controls.TabItem
$partsCustomTab.Header="CUSTOM"

function New-CustomisationStockList {
 $dock=New-Object System.Windows.Controls.DockPanel
 $dock.LastChildFill=$true
 $headerGrid=New-PartsHeaderGrid $true
 [System.Windows.Controls.DockPanel]::SetDock($headerGrid,'Top');[void]$dock.Children.Add($headerGrid)
 $list=New-Object System.Windows.Controls.ListView
 $list.Margin='4,0,4,4';$list.FontSize=13;$list.HorizontalContentAlignment='Stretch'
 $list.Add_SelectionChanged({param($sender,$e) if($null -ne $sender.SelectedItem){$row=$sender.SelectedItem.Tag;if($null -ne $row){Update-PartsDetail $row}}})
 [void]$dock.Children.Add($list)
 return @($dock,$list)
}

function New-CustomisationSubHeader([string]$text,[string]$iconRelative){
 $sp=New-Object System.Windows.Controls.StackPanel
 $sp.Orientation='Horizontal'
 $sp.VerticalAlignment='Center'
 $img=New-Object System.Windows.Controls.Image
 $img.Width=20;$img.Height=20;$img.Margin='0,0,7,0';$img.Stretch='Uniform'
 try{$img.Source=New-CompanionBitmapImage $iconRelative}catch{}
 [void]$sp.Children.Add($img)
 $tb=New-Object System.Windows.Controls.TextBlock
 $tb.Text=$text;$tb.FontWeight='Bold';$tb.VerticalAlignment='Center'
 [void]$sp.Children.Add($tb)
 return $sp
}

$customTabs=New-Object System.Windows.Controls.TabControl
$customTabs.Margin='4'
$customTabs.Background=[System.Windows.Media.Brushes]::Transparent
$customTabs.BorderThickness='0'

$customExteriorTab=New-Object System.Windows.Controls.TabItem
$customExteriorTab.Header=New-CustomisationSubHeader 'EXTERIOR' 'Icons/Parts/Customization/exterior.png'
$customExteriorBuilt=New-CustomisationStockList
$customExteriorTab.Content=$customExteriorBuilt[0]
$customExteriorList=$customExteriorBuilt[1]
[void]$customTabs.Items.Add($customExteriorTab)

$customInteriorTab=New-Object System.Windows.Controls.TabItem
$customInteriorTab.Header=New-CustomisationSubHeader 'INTERIOR' 'Icons/Parts/Customization/interior.png'
$customInteriorBuilt=New-CustomisationStockList
$customInteriorTab.Content=$customInteriorBuilt[0]
$customInteriorList=$customInteriorBuilt[1]
[void]$customTabs.Items.Add($customInteriorTab)

$customPaintTab=New-Object System.Windows.Controls.TabItem
$customPaintTab.Header=New-CustomisationSubHeader 'PAINT SHOP' 'Icons/Parts/Customization/paint_shop.png'
$customPaintBuilt=New-CustomisationStockList
$customPaintTab.Content=$customPaintBuilt[0]
$customPaintList=$customPaintBuilt[1]
[void]$customTabs.Items.Add($customPaintTab)

$customSpecialTab=New-Object System.Windows.Controls.TabItem
$customSpecialTab.Header=New-CustomisationSubHeader 'SPECIAL UPGRADES' 'Icons/Parts/Customization/special_upgrades.png'
$customSpecialBuilt=New-CustomisationStockList
$customSpecialTab.Content=$customSpecialBuilt[0]
$customSpecialList=$customSpecialBuilt[1]
[void]$customTabs.Items.Add($customSpecialTab)

$partsCustomTab.Content=$customTabs
[void]$partsTabs.Items.Add($partsCustomTab)
$lists["CustomisationExterior"]=$customExteriorList
$lists["CustomisationInterior"]=$customInteriorList
$lists["CustomisationPaint"]=$customPaintList
$lists["CustomisationSpecial"]=$customSpecialList
$partsTab.Content=$partsRoot
[void]$tabs.Items.Add($partsTab)

# ------------------------------------------------------------
# REPAIR MACHINE TAB
# ------------------------------------------------------------
$repairTab=New-Object System.Windows.Controls.TabItem
$repairTab.Header="REPAIR MACHINE"
$repairTab.Tag="RepairMachine"

$repairRoot=New-Object System.Windows.Controls.DockPanel

$repairStatus=New-Object System.Windows.Controls.TextBlock
$repairStatus.Text="Waiting for repair machines..."
$repairStatus.Margin="8"
$repairStatus.FontWeight="SemiBold"
$repairStatus.FontSize=13
[System.Windows.Controls.DockPanel]::SetDock($repairStatus,"Top")
$repairRoot.Children.Add($repairStatus)|Out-Null

$repairList=New-Object System.Windows.Controls.ListView
$repairList.Margin="8"
$repairList.FontSize=13
$repairView=New-Object System.Windows.Controls.GridView
$repairList.View=$repairView

$rc1=New-Object System.Windows.Controls.GridViewColumn
$rc1.Header="Item";$rc1.Width=185
$rc1.DisplayMemberBinding=New-Object System.Windows.Data.Binding("Name")
[void]$repairView.Columns.Add($rc1)

$rc2=New-Object System.Windows.Controls.GridViewColumn
$rc2.Header="Machine 1";$rc2.Width=75
$rc2.DisplayMemberBinding=New-Object System.Windows.Data.Binding("Machine1")
[void]$repairView.Columns.Add($rc2)

$rc3=New-Object System.Windows.Controls.GridViewColumn
$rc3.Header="Machine 2";$rc3.Width=75
$rc3.DisplayMemberBinding=New-Object System.Windows.Data.Binding("Machine2")
[void]$repairView.Columns.Add($rc3)

$rc4=New-Object System.Windows.Controls.GridViewColumn
$rc4.Header="Total";$rc4.Width=55
$rc4.DisplayMemberBinding=New-Object System.Windows.Data.Binding("Qty")
[void]$repairView.Columns.Add($rc4)

$rc5=New-Object System.Windows.Controls.GridViewColumn
$rc5.Header="100%";$rc5.Width=55
$rc5.DisplayMemberBinding=New-Object System.Windows.Data.Binding("Full")
[void]$repairView.Columns.Add($rc5)

$rc6=New-Object System.Windows.Controls.GridViewColumn
$rc6.Header="Repair";$rc6.Width=55
$rc6.DisplayMemberBinding=New-Object System.Windows.Data.Binding("Repair")
[void]$repairView.Columns.Add($rc6)

$repairRoot.Children.Add($repairList)|Out-Null
$repairTab.Content=$repairRoot
[void]$partsTabs.Items.Add($repairTab)

# ------------------------------------------------------------
# CARS OWNED TAB - GROUPED + TRUNKS
# ------------------------------------------------------------
$carsTab=New-Object System.Windows.Controls.TabItem
$carsTab.Header="CARS"
$carsTab.Tag="CarsOwned"

$carsGrid=New-Object System.Windows.Controls.Grid
$carsGrid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height="Auto"}))
$carsGrid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height="2*"}))
$carsGrid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height="Auto"}))
$carsGrid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height="Auto"}))
$carsGrid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height="*"}))

$carsStatus=New-Object System.Windows.Controls.TextBlock
$carsStatus.Text="Waiting for owned cars..."
$carsStatus.Margin="8"
$carsStatus.FontWeight="SemiBold"
[System.Windows.Controls.Grid]::SetRow($carsStatus,0)
$carsGrid.Children.Add($carsStatus)|Out-Null

$carsList=New-Object System.Windows.Controls.ListView
$carsList.Margin="8,0,8,5"
$carsView=New-Object System.Windows.Controls.GridView
$carsList.View=$carsView
[System.Windows.Controls.Grid]::SetRow($carsList,1)

$cc1=New-Object System.Windows.Controls.GridViewColumn
$cc1.Header="Car";$cc1.Width=190
[xml]$carCellXaml=@"
<DataTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">
 <StackPanel Orientation="Horizontal">
  <Border Width="68" Height="42" Margin="2,1,10,1" Background="#101820" BorderBrush="#31404D" BorderThickness="1" CornerRadius="2" VerticalAlignment="Center" ClipToBounds="True">
   <Border.Style>
    <Style TargetType="{x:Type Border}">
     <Setter Property="Visibility" Value="Visible"/>
     <Style.Triggers>
      <DataTrigger Binding="{Binding IsHeader}" Value="True"><Setter Property="Visibility" Value="Collapsed"/></DataTrigger>
      <DataTrigger Binding="{Binding HasCarIcon}" Value="False"><Setter Property="Visibility" Value="Collapsed"/></DataTrigger>
     </Style.Triggers>
    </Style>
   </Border.Style>
   <Image Tag="RuntimeCarThumb" Width="64" Height="38" HorizontalAlignment="Center" VerticalAlignment="Center" Stretch="UniformToFill" SnapsToDevicePixels="True"/>
  </Border>
  <TextBlock Text="{Binding Model}" VerticalAlignment="Center"/>
 </StackPanel>
</DataTemplate>
"@
$carCellReader=New-Object System.Xml.XmlNodeReader $carCellXaml
$cc1.CellTemplate=[Windows.Markup.XamlReader]::Load($carCellReader)
[void]$carsView.Columns.Add($cc1)

$ccBody=New-Object System.Windows.Controls.GridViewColumn
$ccBody.Header="Body Type";$ccBody.Width=105
$ccBody.DisplayMemberBinding=New-Object System.Windows.Data.Binding("BodyType")
[void]$carsView.Columns.Add($ccBody)

$ccColour=New-Object System.Windows.Controls.GridViewColumn
$ccColour.Header="Colour";$ccColour.Width=88
[xml]$colourTemplateXaml=@"
<DataTemplate xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">
 <StackPanel Orientation="Horizontal">
  <Border Width="13" Height="13" CornerRadius="2" Margin="0,1,5,0"
          BorderBrush="#707070" BorderThickness="1" Background="{Binding ColorHex}"/>
  <TextBlock Text="{Binding ColourLabel}" VerticalAlignment="Center"/>
 </StackPanel>
</DataTemplate>
"@
$colourTemplateReader=New-Object System.Xml.XmlNodeReader $colourTemplateXaml
$ccColour.CellTemplate=[Windows.Markup.XamlReader]::Load($colourTemplateReader)
[void]$carsView.Columns.Add($ccColour)

$cc2=New-Object System.Windows.Controls.GridViewColumn
$cc2.Header="Year";$cc2.Width=48
$cc2.DisplayMemberBinding=New-Object System.Windows.Data.Binding("Year")
[void]$carsView.Columns.Add($cc2)

$cc3=New-Object System.Windows.Controls.GridViewColumn
$cc3.Header="Mileage";$cc3.Width=82
$cc3.DisplayMemberBinding=New-Object System.Windows.Data.Binding("MileageText")
[void]$carsView.Columns.Add($cc3)

$ccCond=New-Object System.Windows.Controls.GridViewColumn
$ccCond.Header="Condition";$ccCond.Width=70
$ccCond.DisplayMemberBinding=New-Object System.Windows.Data.Binding("ConditionText")
[void]$carsView.Columns.Add($ccCond)

$ccBought=New-Object System.Windows.Controls.GridViewColumn
$ccBought.Header="Bought For";$ccBought.Width=92
$ccBought.DisplayMemberBinding=New-Object System.Windows.Data.Binding("BoughtForText")
[void]$carsView.Columns.Add($ccBought)

$ccLocation=New-Object System.Windows.Controls.GridViewColumn
$ccLocation.Header="Location";$ccLocation.Width=125
$ccLocation.DisplayMemberBinding=New-Object System.Windows.Data.Binding("Location")
[void]$carsView.Columns.Add($ccLocation)

$ccDistance=New-Object System.Windows.Controls.GridViewColumn
$ccDistance.Header="Distance";$ccDistance.Width=85
$ccDistance.DisplayMemberBinding=New-Object System.Windows.Data.Binding("Distance")
[void]$carsView.Columns.Add($ccDistance)

$cc4=New-Object System.Windows.Controls.GridViewColumn
$cc4.Header="Trunk";$cc4.Width=48
$cc4.DisplayMemberBinding=New-Object System.Windows.Data.Binding("TrunkTotal")
[void]$carsView.Columns.Add($cc4)

$cc5=New-Object System.Windows.Controls.GridViewColumn
$cc5.Header="Status";$cc5.Width=70
$cc5.DisplayMemberBinding=New-Object System.Windows.Data.Binding("SaleStatus")
[void]$carsView.Columns.Add($cc5)

$carsGrid.Children.Add($carsList)|Out-Null

$carDetail=New-Object System.Windows.Controls.TextBlock
$carDetail.Text="Select a car to see safe live vehicle details and trunk contents."
$carDetail.Margin="8,5,8,8"
$carDetail.FontWeight="SemiBold"
$carDetail.TextWrapping="Wrap"
$carDetail.FontSize=12
$carDetail.Visibility="Collapsed"
[System.Windows.Controls.Grid]::SetRow($carDetail,2)
$carsGrid.Children.Add($carDetail)|Out-Null

$trunkList=New-Object System.Windows.Controls.ListView
$trunkList.Margin="0"
$trunkList.MaxHeight=150
$trunkView=New-Object System.Windows.Controls.GridView
$trunkList.View=$trunkView
[System.Windows.Controls.Grid]::SetRow($trunkList,4)

$tc1=New-Object System.Windows.Controls.GridViewColumn
$tc1.Header="Trunk Item";$tc1.Width=180
$tc1.DisplayMemberBinding=New-Object System.Windows.Data.Binding("Name")
[void]$trunkView.Columns.Add($tc1)

$tc2=New-Object System.Windows.Controls.GridViewColumn
$tc2.Header="Qty";$tc2.Width=45
$tc2.DisplayMemberBinding=New-Object System.Windows.Data.Binding("Qty")
[void]$trunkView.Columns.Add($tc2)

$tc3=New-Object System.Windows.Controls.GridViewColumn
$tc3.Header="Condition";$tc3.Width=72
$tc3.DisplayMemberBinding=New-Object System.Windows.Data.Binding("Condition")
[void]$trunkView.Columns.Add($tc3)

$carsBottomGrid=New-Object System.Windows.Controls.Grid
$carsBottomGrid.Margin="8,0,8,8"
$carsBottomGrid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width="0.8*"}))
$carsBottomGrid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width="1.2*"}))
[System.Windows.Controls.Grid]::SetRow($carsBottomGrid,4)

$selectedBox=New-Object System.Windows.Controls.GroupBox
$selectedBox.Header="SELECTED VEHICLE"
$selectedBox.Margin="0,0,6,0"

$selectedScroll=New-Object System.Windows.Controls.ScrollViewer
$selectedScroll.VerticalScrollBarVisibility="Auto"

$selectedInfoText=New-Object System.Windows.Controls.TextBlock
$selectedInfoText.Text="Select a car to see its details."
$selectedInfoText.Margin="8"
$selectedInfoText.TextWrapping="Wrap"
$selectedInfoText.FontSize=13
$selectedInfoText.FontFamily="Consolas"

$selectedPanel=New-Object System.Windows.Controls.StackPanel

# v0.43.8.6 - selected vehicle game thumbnail. Uses the same direct Image/BitmapImage
# path that is proven stable for Parts and Inventory icons.
$selectedCarImageBorder=New-Object System.Windows.Controls.Border
$selectedCarImageBorder.Margin="8,8,8,2"
$selectedCarImageBorder.Padding="6"
$selectedCarImageBorder.Background="#11161D"
$selectedCarImageBorder.BorderBrush="#343C47"
$selectedCarImageBorder.BorderThickness="1"
$selectedCarImageBorder.CornerRadius="5"
$selectedCarImageBorder.Visibility="Collapsed"
$selectedCarImage=New-Object System.Windows.Controls.Image
$selectedCarImage.Height=190
$selectedCarImage.Stretch="Uniform"
$selectedCarImage.HorizontalAlignment="Center"
$selectedCarImage.VerticalAlignment="Center"
$selectedCarImageBorder.Child=$selectedCarImage
[void]$selectedPanel.Children.Add($selectedCarImageBorder)

[void]$selectedPanel.Children.Add($selectedInfoText)
$personalCarCheck=New-Object System.Windows.Controls.CheckBox
$personalCarCheck.Content="PERSONAL CAR - keep out of sales workflow"
$personalCarCheck.Margin="8,6,8,4"
$personalCarCheck.FontWeight="SemiBold"
[void]$selectedPanel.Children.Add($personalCarCheck)
$personalCarHint=New-Object System.Windows.Controls.TextBlock
$personalCarHint.Text="Saved for this game save. Untick to return the car to its normal workflow."
$personalCarHint.Margin="8,0,8,8"
$personalCarHint.Foreground="#9EA9B5"
$personalCarHint.TextWrapping="Wrap"
[void]$selectedPanel.Children.Add($personalCarHint)
$selectedScroll.Content=$selectedPanel
$selectedBox.Content=$selectedScroll
[System.Windows.Controls.Grid]::SetColumn($selectedBox,0)
[void]$carsBottomGrid.Children.Add($selectedBox)

$readyBox=New-Object System.Windows.Controls.GroupBox
$readyBox.Header="READY CHECK - 95% TARGET"
$readyBox.Margin="6,0,0,0"

# Stage 2: split the Ready Check area into checklist + needs-attention columns.
$readyPanel=New-Object System.Windows.Controls.Grid
$readyPanel.Margin="6"
$readyPanel.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height="Auto"}))
$readyPanel.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height="*"}))

$readySummary=New-Object System.Windows.Controls.TextBlock
$readySummary.Text="Select a waiting car to see its checklist."
$readySummary.FontWeight="SemiBold"
$readySummary.FontSize=13
$readySummary.TextWrapping="Wrap"
$readySummary.Margin="0,0,0,6"
[System.Windows.Controls.Grid]::SetRow($readySummary,0)
[void]$readyPanel.Children.Add($readySummary)

$readyColumns=New-Object System.Windows.Controls.Grid
$readyColumns.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width="3*"}))
$readyColumns.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width="2*"}))
[System.Windows.Controls.Grid]::SetRow($readyColumns,1)
[void]$readyPanel.Children.Add($readyColumns)

$readyChecklistScroll=New-Object System.Windows.Controls.ScrollViewer
$readyChecklistScroll.VerticalScrollBarVisibility="Auto"
$readyChecklistScroll.HorizontalScrollBarVisibility="Disabled"
$readyChecklistScroll.Margin="0,0,8,0"
$readyChecklist=New-Object System.Windows.Controls.TextBlock
$readyChecklist.TextWrapping="Wrap"
$readyChecklist.FontFamily="Consolas"
$readyChecklist.FontSize=13
$readyChecklistScroll.Content=$readyChecklist
[System.Windows.Controls.Grid]::SetColumn($readyChecklistScroll,0)
[void]$readyColumns.Children.Add($readyChecklistScroll)

$attentionBorder=New-Object System.Windows.Controls.Border
$attentionBorder.BorderBrush="#B57B12"
$attentionBorder.BorderThickness="1,0,0,0"
$attentionBorder.Padding="12,0,4,0"
[System.Windows.Controls.Grid]::SetColumn($attentionBorder,1)
[void]$readyColumns.Children.Add($attentionBorder)

$attentionPanel=New-Object System.Windows.Controls.StackPanel
$attentionHeader=New-Object System.Windows.Controls.TextBlock
$attentionHeader.Text="NEEDS ATTENTION"
$attentionHeader.FontWeight="Bold"
$attentionHeader.FontSize=13
$attentionHeader.Foreground="#F4B321"
$attentionHeader.Margin="0,0,0,7"
[void]$attentionPanel.Children.Add($attentionHeader)

$attentionScroll=New-Object System.Windows.Controls.ScrollViewer
$attentionScroll.VerticalScrollBarVisibility="Auto"
$attentionScroll.HorizontalScrollBarVisibility="Disabled"
$needsAttention=New-Object System.Windows.Controls.TextBlock
$needsAttention.TextWrapping="Wrap"
$needsAttention.FontFamily="Consolas"
$needsAttention.FontSize=13
$needsAttention.FontWeight="SemiBold"
$attentionScroll.Content=$needsAttention
[void]$attentionPanel.Children.Add($attentionScroll)
$attentionBorder.Child=$attentionPanel

$readyBox.Content=$readyPanel
[System.Windows.Controls.Grid]::SetColumn($readyBox,1)
[void]$carsBottomGrid.Children.Add($readyBox)
[void]$carsGrid.Children.Add($carsBottomGrid)
$carsSubTabs=New-Object System.Windows.Controls.TabControl
$carsSubTabs.Margin="4";$carsSubTabs.Background="#171C24"

$carsForSaleTab=New-Object System.Windows.Controls.TabItem
$carsForSaleTab.Header="FOR SALE"

$carsForSaleRoot=New-Object System.Windows.Controls.Grid
$carsForSaleRoot.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height="Auto"}))
$carsForSaleRoot.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height="*"}))

$carsForSaleStatus=New-Object System.Windows.Controls.TextBlock
$carsForSaleStatus.Margin="8"
$carsForSaleStatus.FontWeight="SemiBold"
$carsForSaleStatus.Text="Waiting for advertised cars..."
[System.Windows.Controls.Grid]::SetRow($carsForSaleStatus,0)
[void]$carsForSaleRoot.Children.Add($carsForSaleStatus)

$carsForSaleList=New-Object System.Windows.Controls.ListView
$carsForSaleList.Margin="8,0,8,8"
$carsForSaleView=New-Object System.Windows.Controls.GridView
$carsForSaleList.View=$carsForSaleView
[System.Windows.Controls.Grid]::SetRow($carsForSaleList,1)

foreach($sp in @(
 @("Car","Model",150),
 @("Body Type","BodyType",105),
 @("Colour","ColourLabel",90),
 @("Year","Year",52),
 @("Mileage","MileageText",82),
 @("Condition","ConditionText",72),
 @("Bought For","BoughtForText",92),
 @("Location","Location",125),
 @("Distance","Distance",85),
 @("Trunk","TrunkTotal",52),
 @("Listed At","ListingPriceText",95)
)){
 $col=New-Object System.Windows.Controls.GridViewColumn
 $col.Header=$sp[0];$col.Width=$sp[2]
 $col.DisplayMemberBinding=New-Object System.Windows.Data.Binding($sp[1])
 [void]$carsForSaleView.Columns.Add($col)
}

[void]$carsForSaleRoot.Children.Add($carsForSaleList)
$carsForSaleTab.Content=$carsForSaleRoot
[void]$carsSubTabs.Items.Add($carsForSaleTab)

$carsReadyTab=New-Object System.Windows.Controls.TabItem
$carsReadyTab.Header="READY FOR SALE"

$carsReadyRoot=New-Object System.Windows.Controls.Grid
$carsReadyRoot.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height="Auto"}))
$carsReadyRoot.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height="*"}))

$carsReadyStatus=New-Object System.Windows.Controls.TextBlock
$carsReadyStatus.Margin="8"
$carsReadyStatus.FontWeight="SemiBold"
$carsReadyStatus.Text="Ready for sale: waiting for vehicle condition data..."
[System.Windows.Controls.Grid]::SetRow($carsReadyStatus,0)
[void]$carsReadyRoot.Children.Add($carsReadyStatus)

$carsReadyList=New-Object System.Windows.Controls.ListView
$carsReadyList.Margin="8,0,8,8"
$carsReadyView=New-Object System.Windows.Controls.GridView
$carsReadyList.View=$carsReadyView
[System.Windows.Controls.Grid]::SetRow($carsReadyList,1)

foreach($sp in @(
 @("Car","Model",150),
 @("Body Type","BodyType",105),
 @("Colour","ColourLabel",95),
 @("Year","Year",52),
 @("Mileage","MileageText",82),
 @("Condition","ConditionText",76),
 @("Bought For","BoughtForText",92),
 @("Location","Location",125),
 @("Distance","Distance",85),
 @("Trunk","TrunkTotal",52)
)){
 $col=New-Object System.Windows.Controls.GridViewColumn
 $col.Header=$sp[0];$col.Width=$sp[2]
 $col.DisplayMemberBinding=New-Object System.Windows.Data.Binding($sp[1])
 [void]$carsReadyView.Columns.Add($col)
}

[void]$carsReadyRoot.Children.Add($carsReadyList)
$carsReadyTab.Content=$carsReadyRoot
[void]$carsSubTabs.Items.Add($carsReadyTab)

$carsWaitingTab=New-Object System.Windows.Controls.TabItem
$carsWaitingTab.Header="WAITING"
$carsWaitingTab.Content=$carsGrid
[void]$carsSubTabs.Items.Add($carsWaitingTab)

$carsWrecksTab=New-Object System.Windows.Controls.TabItem
$carsWrecksTab.Header="WRECKS"
$carsWrecksRoot=New-Object System.Windows.Controls.Grid
$carsWrecksRoot.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height="Auto"}))
$carsWrecksRoot.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height="*"}))
$carsWrecksStatus=New-Object System.Windows.Controls.TextBlock
$carsWrecksStatus.Margin="8";$carsWrecksStatus.FontWeight="SemiBold";$carsWrecksStatus.Text="Wrecks: waiting for saved wreck state..."
[System.Windows.Controls.Grid]::SetRow($carsWrecksStatus,0);[void]$carsWrecksRoot.Children.Add($carsWrecksStatus)
$carsWrecksList=New-Object System.Windows.Controls.ListView
$carsWrecksList.Margin="8,0,8,8";$carsWrecksView=New-Object System.Windows.Controls.GridView;$carsWrecksList.View=$carsWrecksView
[System.Windows.Controls.Grid]::SetRow($carsWrecksList,1)
foreach($sp in @(@("Car","Model",190),@("Body Type","BodyType",105),@("Colour","ColourLabel",95),@("Year","Year",52),@("Mileage","MileageText",82),@("Condition","ConditionText",76),@("Location","Location",125),
 @("Distance","Distance",85),@("Trunk","TrunkTotal",52))){
 $col=New-Object System.Windows.Controls.GridViewColumn;$col.Header=$sp[0];$col.Width=$sp[2];$col.DisplayMemberBinding=New-Object System.Windows.Data.Binding($sp[1]);[void]$carsWrecksView.Columns.Add($col)
}
[void]$carsWrecksRoot.Children.Add($carsWrecksList);$carsWrecksTab.Content=$carsWrecksRoot;[void]$carsSubTabs.Items.Add($carsWrecksTab)

$carsPersonalTab=New-Object System.Windows.Controls.TabItem
$carsPersonalTab.Header="PERSONAL CARS"
$carsPersonalRoot=New-Object System.Windows.Controls.Grid
$carsPersonalRoot.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height="Auto"}))
$carsPersonalRoot.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height="*"}))
$carsPersonalStatus=New-Object System.Windows.Controls.TextBlock
$carsPersonalStatus.Margin="8";$carsPersonalStatus.FontWeight="SemiBold";$carsPersonalStatus.Text="Personal Cars: none marked yet."
[System.Windows.Controls.Grid]::SetRow($carsPersonalStatus,0);[void]$carsPersonalRoot.Children.Add($carsPersonalStatus)
$carsPersonalList=New-Object System.Windows.Controls.ListView
$carsPersonalList.Margin="8,0,8,8";$carsPersonalView=New-Object System.Windows.Controls.GridView;$carsPersonalList.View=$carsPersonalView
[System.Windows.Controls.Grid]::SetRow($carsPersonalList,1)
foreach($sp in @(@("Car","Model",190),@("Body Type","BodyType",105),@("Colour","ColourLabel",95),@("Year","Year",52),@("Mileage","MileageText",82),@("Condition","ConditionText",76),@("Location","Location",125),
 @("Distance","Distance",85),@("Trunk","TrunkTotal",52))){
 $col=New-Object System.Windows.Controls.GridViewColumn;$col.Header=$sp[0];$col.Width=$sp[2];$col.DisplayMemberBinding=New-Object System.Windows.Data.Binding($sp[1]);[void]$carsPersonalView.Columns.Add($col)
}
[void]$carsPersonalRoot.Children.Add($carsPersonalList);$carsPersonalTab.Content=$carsPersonalRoot;[void]$carsSubTabs.Items.Add($carsPersonalTab)


# v0.43.10.2: cross-location MODIFIED view. Cars stay in their normal tabs too.
$carsModifiedTab=New-Object System.Windows.Controls.TabItem
$carsModifiedTab.Header="MODIFIED"
$carsModifiedRoot=New-Object System.Windows.Controls.Grid
$carsModifiedRoot.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height="Auto"}))
$carsModifiedRoot.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height="*"}))
$carsModifiedStatus=New-Object System.Windows.Controls.TextBlock
$carsModifiedStatus.Margin="8";$carsModifiedStatus.FontWeight="SemiBold";$carsModifiedStatus.Text="Modified Cars: waiting for fitted-part scan..."
[System.Windows.Controls.Grid]::SetRow($carsModifiedStatus,0);[void]$carsModifiedRoot.Children.Add($carsModifiedStatus)
$carsModifiedList=New-Object System.Windows.Controls.ListView
$carsModifiedList.Margin="8,0,8,8";$carsModifiedView=New-Object System.Windows.Controls.GridView;$carsModifiedList.View=$carsModifiedView
[System.Windows.Controls.Grid]::SetRow($carsModifiedList,1)
foreach($sp in @(@("Car","Model",165),@("Body Type","BodyType",90),@("Year","Year",52),@("Location","Location",110),@("Sport","SportCount",55),@("Racing","RacingCount",58),@("Custom","CustomCount",58),@("Fitted upgrades","ModificationSummary",430))){
 $col=New-Object System.Windows.Controls.GridViewColumn;$col.Header=$sp[0];$col.Width=$sp[2];$col.DisplayMemberBinding=New-Object System.Windows.Data.Binding($sp[1]);[void]$carsModifiedView.Columns.Add($col)
}
[void]$carsModifiedRoot.Children.Add($carsModifiedList);$carsModifiedTab.Content=$carsModifiedRoot;[void]$carsSubTabs.Items.Add($carsModifiedTab)

# Put the same compact game car icon beside the model in every Cars list.
foreach($view in @($carsForSaleView,$carsReadyView,$carsWrecksView,$carsPersonalView,$carsModifiedView)){
 try{$r=New-Object System.Xml.XmlNodeReader $carCellXaml;$view.Columns[0].DisplayMemberBinding=$null;$view.Columns[0].CellTemplate=[Windows.Markup.XamlReader]::Load($r)}catch{}
}

# v0.44.0.70 - direct Cars row thumbnail hydration.
# Data binding can see HasCarIcon but has repeatedly failed to paint Image.Source for
# runtime PNGs.  Assign Source directly to the realized Image controls instead.
function Find-RuntimeCarThumbImage($root){
 if($null -eq $root){return $null}
 try{
  if($root -is [System.Windows.Controls.Image] -and [string]$root.Tag -eq 'RuntimeCarThumb'){return $root}
  $count=[System.Windows.Media.VisualTreeHelper]::GetChildrenCount($root)
  for($i=0;$i -lt $count;$i++){
   $child=[System.Windows.Media.VisualTreeHelper]::GetChild($root,$i)
   $found=Find-RuntimeCarThumbImage $child
   if($null -ne $found){return $found}
  }
 }catch{}
 return $null
}
function Hydrate-CarListThumbnails($lv){
 if($null -eq $lv){return}
 try{
  [System.Windows.Controls.VirtualizingStackPanel]::SetIsVirtualizing($lv,$false)
  $lv.UpdateLayout()
  for($i=0;$i -lt $lv.Items.Count;$i++){
   $item=$lv.Items[$i]
   if($null -eq $item -or [bool]$item.IsHeader){continue}
   $container=$lv.ItemContainerGenerator.ContainerFromIndex($i)
   if($null -eq $container){continue}
   $container.ApplyTemplate();$container.UpdateLayout()
   $img=Find-RuntimeCarThumbImage $container
   if($null -eq $img){continue}
   $path=[string]$item.CarIconPath
   if(-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path -LiteralPath $path)){
    $img.Source=New-RuntimeCarThumbnail $path
   }else{
    $img.Source=$null
   }
  }
 }catch{}
}
function Hydrate-CurrentCarsList{
 try{
  switch([int]$carsSubTabs.SelectedIndex){
   0 {Hydrate-CarListThumbnails $carsForSaleList}
   1 {Hydrate-CarListThumbnails $carsReadyList}
   2 {Hydrate-CarListThumbnails $carsList}
   3 {Hydrate-CarListThumbnails $carsWrecksList}
   4 {Hydrate-CarListThumbnails $carsPersonalList}
   5 {Hydrate-CarListThumbnails $carsModifiedList}
  }
 }catch{}
}
$carsSubTabs.Add_SelectionChanged({
 try{$carsSubTabs.UpdateLayout();Hydrate-CurrentCarsList}catch{}
})

# Keep the selected car visibly highlighted even when the details popout has focus.
[xml]$carSelectionStyleX=@"
<Style xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
       xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
       TargetType="{x:Type ListViewItem}">
 <Setter Property="HorizontalContentAlignment" Value="Stretch"/>
 <Style.Triggers>
  <Trigger Property="IsSelected" Value="True">
   <Setter Property="Background" Value="#7A5209"/>
   <Setter Property="Foreground" Value="White"/>
  </Trigger>
 </Style.Triggers>
</Style>
"@
$carStyleReader=New-Object System.Xml.XmlNodeReader $carSelectionStyleX
$carSelectionStyle=[Windows.Markup.XamlReader]::Load($carStyleReader)
$carsList.ItemContainerStyle=$carSelectionStyle
$carsForSaleList.ItemContainerStyle=$carSelectionStyle
$carsReadyList.ItemContainerStyle=$carSelectionStyle
$carsWrecksList.ItemContainerStyle=$carSelectionStyle
$carsPersonalList.ItemContainerStyle=$carSelectionStyle

# Cars page readability: slightly larger list text without changing the layout.
foreach($lv in @($carsList,$carsForSaleList,$carsReadyList,$carsWrecksList,$carsPersonalList,$carsModifiedList)){
 try{$lv.FontSize=12.5;$lv.FontFamily="Segoe UI"}catch{}
}
foreach($st in @($carsStatus,$carsForSaleStatus,$carsReadyStatus,$carsWrecksStatus,$carsPersonalStatus,$carsModifiedStatus,$carsRefreshStatus)){
 try{$st.FontSize=12.5} catch{}
}

try{[void]$carsGrid.Children.Remove($carsBottomGrid)}catch{}
$carsBottomGrid.Margin="4,2,4,4"
$carsTopPanel=New-Object System.Windows.Controls.Grid
$carsTopPanel.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height="Auto"}))
$carsTopPanel.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height="*"}))

$carsRefreshBar=New-Object System.Windows.Controls.DockPanel
$carsRefreshBar.Margin="6,4,6,3"

$carsRefreshButton=New-Object System.Windows.Controls.Button
$carsRefreshButton.Padding="10,5"
$carsRefreshButton.Margin="0,0,10,0"
$carsRefreshButton.FontWeight="Bold"

# Prefer the real in-game scanner icon from the MasterAssets library when present.
$scannerAsset=Get-CompanionAssetPath "Icons/Cars/Scanner_128.png"
# Public release: no developer Desktop/MasterAssets fallback. Runtime/local Companion assets only.
if(Test-Path -LiteralPath $scannerAsset){
 try{
  $scanPanel=New-Object System.Windows.Controls.StackPanel
  $scanPanel.Orientation="Horizontal"
  $scanPanel.VerticalAlignment="Center"
  $scanImage=New-Object System.Windows.Controls.Image
  $scanBitmap=New-Object System.Windows.Media.Imaging.BitmapImage
  $scanBitmap.BeginInit();$scanBitmap.CacheOption=[System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
  $scanBitmap.UriSource=New-Object System.Uri($scannerAsset,[System.UriKind]::Absolute)
  $scanBitmap.EndInit();$scanBitmap.Freeze()
  $scanImage.Source=$scanBitmap;$scanImage.Width=22;$scanImage.Height=22;$scanImage.Margin="0,0,7,0"
  $scanText=New-Object System.Windows.Controls.TextBlock
  $scanText.Text="SCAN CARS";$scanText.VerticalAlignment="Center";$scanText.FontWeight="Bold"
  [void]$scanPanel.Children.Add($scanImage);[void]$scanPanel.Children.Add($scanText)
  $carsRefreshButton.Content=$scanPanel
 }catch{$carsRefreshButton.Content="SCAN CARS"}
}else{$carsRefreshButton.Content="SCAN CARS"}
[System.Windows.Controls.DockPanel]::SetDock($carsRefreshButton,"Left")
[void]$carsRefreshBar.Children.Add($carsRefreshButton)

$carsRefreshStatus=New-Object System.Windows.Controls.TextBlock
$carsRefreshStatus.Text="Cars: cached startup data + automatic refresh"
$carsRefreshStatus.VerticalAlignment="Center"
$carsRefreshStatus.Foreground="#BFC7D1"
[void]$carsRefreshBar.Children.Add($carsRefreshStatus)

[System.Windows.Controls.Grid]::SetRow($carsRefreshBar,0)
[System.Windows.Controls.Grid]::SetRow($carsSubTabs,1)
[void]$carsTopPanel.Children.Add($carsRefreshBar)
[void]$carsTopPanel.Children.Add($carsSubTabs)

$carsTabRoot=New-Object System.Windows.Controls.Grid
$carsTabRoot.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height="1.08*"}))
$carsTabRoot.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition -Property @{Height="0.92*"}))
[System.Windows.Controls.Grid]::SetRow($carsTopPanel,0)
[System.Windows.Controls.Grid]::SetRow($carsBottomGrid,1)
[void]$carsTabRoot.Children.Add($carsTopPanel)
[void]$carsTabRoot.Children.Add($carsBottomGrid)
$carsTab.Content=$carsTabRoot
[void]$tabs.Items.Add($carsTab)

# ------------------------------------------------------------
# FUTURE MAIN PAGES - shell placeholders only
# ------------------------------------------------------------
function New-ComingSoonPage([string]$title,[string]$subtitle){
 $root=New-Object System.Windows.Controls.Grid
 $root.Background="#111820"
 $card=New-Object System.Windows.Controls.Border
 $card.Width=620;$card.MaxWidth=720;$card.Padding="44";$card.CornerRadius="14"
 $card.Background="#171F28";$card.BorderBrush="#34404C";$card.BorderThickness="1"
 $card.HorizontalAlignment="Center";$card.VerticalAlignment="Center"
 $sp=New-Object System.Windows.Controls.StackPanel
 $h=New-Object System.Windows.Controls.TextBlock
 $h.Text=$title;$h.FontSize=30;$h.FontWeight="Bold";$h.Foreground="#FFF8EB";$h.HorizontalAlignment="Center"
 $coming=New-Object System.Windows.Controls.TextBlock
 $coming.Text="COMING SOON";$coming.FontSize=20;$coming.FontWeight="Bold";$coming.Foreground="#E39A2D";$coming.HorizontalAlignment="Center";$coming.Margin="0,12,0,0"
 $desc=New-Object System.Windows.Controls.TextBlock
 $desc.Text=$subtitle;$desc.FontSize=13;$desc.Foreground="#AEB8C3";$desc.TextWrapping="Wrap";$desc.TextAlignment="Center";$desc.Margin="0,16,0,0"
 [void]$sp.Children.Add($h);[void]$sp.Children.Add($coming);[void]$sp.Children.Add($desc)
 $card.Child=$sp;[void]$root.Children.Add($card);return $root
}


function New-ContractsLayoutPage{
 $scroll=New-Object System.Windows.Controls.ScrollViewer
 $scroll.VerticalScrollBarVisibility="Auto"
 $scroll.HorizontalScrollBarVisibility="Disabled"

 $root=New-Object System.Windows.Controls.StackPanel
 $root.Margin="10"
 $scroll.Content=$root

 # Page header
 $head=New-Object System.Windows.Controls.Grid
 $head.Margin="0,0,0,10"
 [void]$head.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition))
 [void]$head.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width="Auto"}))

 $headLeft=New-Object System.Windows.Controls.StackPanel
 $title=New-Object System.Windows.Controls.TextBlock
 $title.Text="CONTRACTS";$title.Foreground="#FFF3E3";$title.FontWeight="Bold";$title.FontSize=22
 [void]$headLeft.Children.Add($title)
 $script:contractsRefreshStatus=New-Object System.Windows.Controls.TextBlock
 $script:contractsRefreshStatus.Text="Live contract intelligence";$script:contractsRefreshStatus.Foreground="#8FA0AD";$script:contractsRefreshStatus.FontSize=11;$script:contractsRefreshStatus.Margin="0,2,0,0"
 [void]$headLeft.Children.Add($script:contractsRefreshStatus)
 [System.Windows.Controls.Grid]::SetColumn($headLeft,0);[void]$head.Children.Add($headLeft)

 $script:contractsRefreshButton=New-Object System.Windows.Controls.Button
 $script:contractsRefreshButton.Content="REFRESH";$script:contractsRefreshButton.Padding="14,6";$script:contractsRefreshButton.MinWidth=90
 $script:contractsRefreshButton.Background="#315B85";$script:contractsRefreshButton.BorderBrush="#76B9F5";$script:contractsRefreshButton.Foreground="#FFF8EB";$script:contractsRefreshButton.FontWeight="Bold"
 [System.Windows.Controls.Grid]::SetColumn($script:contractsRefreshButton,1);[void]$head.Children.Add($script:contractsRefreshButton)
 [void]$root.Children.Add($head)

 # Legacy summary variables stay available to refresh/dashboard code.
 $script:contractsSummaryB2B=$null
 $script:contractsSummaryCars=$null
 $script:contractsSummaryPawn=$null
 $script:contractsSummaryDealer=$null

 # ----------------------------------------------------------------
 # B2B + DEALER
 # ----------------------------------------------------------------
 $contractsGrid=New-Object System.Windows.Controls.Grid
 $contractsGrid.Margin="0,0,0,10"
 [void]$contractsGrid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition))
 [void]$contractsGrid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition))

 # B2B CARD
 $b2b=New-Object System.Windows.Controls.Border
 $b2b.Background="#1B222B";$b2b.BorderBrush="#C88A21";$b2b.BorderThickness="1";$b2b.CornerRadius="8";$b2b.Padding="0";$b2b.Margin="0,0,5,0"
 $b2bSp=New-Object System.Windows.Controls.StackPanel

 $b2bAccent=New-Object System.Windows.Controls.Border
 $b2bAccent.Height=4;$b2bAccent.Background="#C88A21";$b2bAccent.CornerRadius="8,8,0,0"
 [void]$b2bSp.Children.Add($b2bAccent)

 $b2bBody=New-Object System.Windows.Controls.StackPanel;$b2bBody.Margin="10,8,10,10"
 $b2bTop=New-Object System.Windows.Controls.Grid
 [void]$b2bTop.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width="Auto"}))
 [void]$b2bTop.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition))
 [void]$b2bTop.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width="Auto"}))

 $b2bIcon=New-Object System.Windows.Controls.Image
 $b2bIcon.Width=26;$b2bIcon.Height=26;$b2bIcon.Stretch="Uniform";$b2bIcon.Margin="0,0,8,0"
 try{$b2bIcon.Source=New-CompanionBitmapImage "Icons/Navigation/contracts.png"}catch{}
 [System.Windows.Controls.Grid]::SetColumn($b2bIcon,0);[void]$b2bTop.Children.Add($b2bIcon)

 $script:contractsB2BName=New-Object System.Windows.Controls.TextBlock
 $script:contractsB2BName.Text="B2B CONTRACT";$script:contractsB2BName.FontWeight="Bold";$script:contractsB2BName.FontSize=17;$script:contractsB2BName.Foreground="#FFF3E3";$script:contractsB2BName.VerticalAlignment="Center"
 [System.Windows.Controls.Grid]::SetColumn($script:contractsB2BName,1);[void]$b2bTop.Children.Add($script:contractsB2BName)

 $script:contractsB2BState=New-Object System.Windows.Controls.TextBlock
 $script:contractsB2BState.Text="WAITING";$script:contractsB2BState.FontSize=11;$script:contractsB2BState.FontWeight="Bold";$script:contractsB2BState.Foreground="#E39A2D";$script:contractsB2BState.Padding="7,3";$script:contractsB2BState.VerticalAlignment="Center"
 [System.Windows.Controls.Grid]::SetColumn($script:contractsB2BState,2);[void]$b2bTop.Children.Add($script:contractsB2BState)
 [void]$b2bBody.Children.Add($b2bTop)

 $b2bStatsBorder=New-Object System.Windows.Controls.Border
 $b2bStatsBorder.Background="#121820";$b2bStatsBorder.CornerRadius="5";$b2bStatsBorder.Padding="7,5";$b2bStatsBorder.Margin="0,8,0,7"
 $b2bStats=New-Object System.Windows.Controls.StackPanel;$b2bStats.Orientation="Horizontal"
 foreach($spec in @(@("CARS ","contractsB2BCars"),@("   RESPRAYS ","contractsB2BResprays"),@("   REPAIRS ","contractsB2BRepairs"),@("   MISSING ","contractsB2BMissing"))){
  $lab=New-Object System.Windows.Controls.TextBlock;$lab.Text=$spec[0];$lab.Foreground="#72808D";$lab.FontSize=10;$lab.FontWeight="Bold"
  $val=New-Object System.Windows.Controls.TextBlock;$val.Text="-";$val.Foreground="#E8EDF2";$val.FontSize=11;$val.FontWeight="Bold"
  Set-Variable -Name $spec[1] -Value $val -Scope Script
  [void]$b2bStats.Children.Add($lab);[void]$b2bStats.Children.Add($val)
 }
 $b2bStatsBorder.Child=$b2bStats;[void]$b2bBody.Children.Add($b2bStatsBorder)

 $script:contractsB2BConditions=New-Object System.Windows.Controls.TextBlock
 $script:contractsB2BConditions.Text="Requirements: -";$script:contractsB2BConditions.Foreground="#9EABB7";$script:contractsB2BConditions.FontSize=11;$script:contractsB2BConditions.TextWrapping="Wrap";$script:contractsB2BConditions.Margin="0,0,0,5"
 [void]$b2bBody.Children.Add($script:contractsB2BConditions)

 $script:contractsB2BDetails=New-Object System.Windows.Controls.TextBlock
 $script:contractsB2BDetails.Text="Waiting for B2B requirements...";$script:contractsB2BDetails.Foreground="#E2E8EE";$script:contractsB2BDetails.FontSize=12;$script:contractsB2BDetails.TextWrapping="Wrap";$script:contractsB2BDetails.LineHeight=17
 [void]$b2bBody.Children.Add($script:contractsB2BDetails)
 [void]$b2bSp.Children.Add($b2bBody);$b2b.Child=$b2bSp
 [System.Windows.Controls.Grid]::SetColumn($b2b,0);[void]$contractsGrid.Children.Add($b2b)

 # DEALER CARD
 $dealerContract=New-Object System.Windows.Controls.Border
 $dealerContract.Background="#1B222B";$dealerContract.BorderBrush="#315B85";$dealerContract.BorderThickness="1";$dealerContract.CornerRadius="8";$dealerContract.Padding="0";$dealerContract.Margin="5,0,0,0"
 $dealerSp=New-Object System.Windows.Controls.StackPanel
 $dealerAccent=New-Object System.Windows.Controls.Border;$dealerAccent.Height=4;$dealerAccent.Background="#315B85";$dealerAccent.CornerRadius="8,8,0,0"
 [void]$dealerSp.Children.Add($dealerAccent)

 $dealerBody=New-Object System.Windows.Controls.StackPanel;$dealerBody.Margin="10,8,10,10"
 $dealerTop=New-Object System.Windows.Controls.Grid
 [void]$dealerTop.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width="Auto"}))
 [void]$dealerTop.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition))
 [void]$dealerTop.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width="Auto"}))

 $dealerIcon=New-Object System.Windows.Controls.Image
 $dealerIcon.Width=30;$dealerIcon.Height=26;$dealerIcon.Stretch="Uniform";$dealerIcon.Margin="0,0,8,0"
 try{$dealerIcon.Source=New-CompanionBitmapImage "GameUI/Contracts/Branding/UI_DealerContracts_Logo.png"}catch{}
 [System.Windows.Controls.Grid]::SetColumn($dealerIcon,0);[void]$dealerTop.Children.Add($dealerIcon)

 $script:contractsDealerContractName=New-Object System.Windows.Controls.TextBlock
 $script:contractsDealerContractName.Text="DEALER CONTRACT";$script:contractsDealerContractName.FontWeight="Bold";$script:contractsDealerContractName.FontSize=17;$script:contractsDealerContractName.Foreground="#FFF3E3";$script:contractsDealerContractName.VerticalAlignment="Center"
 [System.Windows.Controls.Grid]::SetColumn($script:contractsDealerContractName,1);[void]$dealerTop.Children.Add($script:contractsDealerContractName)

 $script:contractsDealerContractState=New-Object System.Windows.Controls.TextBlock
 $script:contractsDealerContractState.Text="WAITING";$script:contractsDealerContractState.FontSize=11;$script:contractsDealerContractState.FontWeight="Bold";$script:contractsDealerContractState.Foreground="#76B9F5";$script:contractsDealerContractState.Padding="7,3";$script:contractsDealerContractState.VerticalAlignment="Center"
 [System.Windows.Controls.Grid]::SetColumn($script:contractsDealerContractState,2);[void]$dealerTop.Children.Add($script:contractsDealerContractState)
 [void]$dealerBody.Children.Add($dealerTop)

 $dealerStatsBorder=New-Object System.Windows.Controls.Border
 $dealerStatsBorder.Background="#121820";$dealerStatsBorder.CornerRadius="5";$dealerStatsBorder.Padding="7,5";$dealerStatsBorder.Margin="0,8,0,7"
 $dealerStats=New-Object System.Windows.Controls.StackPanel;$dealerStats.Orientation="Horizontal"
 foreach($spec in @(@("CARS ","contractsDealerContractCars"),@("   RESPRAYS ","contractsDealerContractResprays"),@("   REPAIRS ","contractsDealerContractRepairs"),@("   MISSING ","contractsDealerContractMissing"))){
  $lab=New-Object System.Windows.Controls.TextBlock;$lab.Text=$spec[0];$lab.Foreground="#72808D";$lab.FontSize=10;$lab.FontWeight="Bold"
  $val=New-Object System.Windows.Controls.TextBlock;$val.Text="-";$val.Foreground="#E8EDF2";$val.FontSize=11;$val.FontWeight="Bold"
  Set-Variable -Name $spec[1] -Value $val -Scope Script
  [void]$dealerStats.Children.Add($lab);[void]$dealerStats.Children.Add($val)
 }
 $dealerStatsBorder.Child=$dealerStats;[void]$dealerBody.Children.Add($dealerStatsBorder)

 $script:contractsDealerContractConditions=New-Object System.Windows.Controls.TextBlock
 $script:contractsDealerContractConditions.Text="Requirements: -";$script:contractsDealerContractConditions.Foreground="#9EABB7";$script:contractsDealerContractConditions.FontSize=11;$script:contractsDealerContractConditions.TextWrapping="Wrap";$script:contractsDealerContractConditions.Margin="0,0,0,5"
 [void]$dealerBody.Children.Add($script:contractsDealerContractConditions)

 $script:contractsDealerContractDetails=New-Object System.Windows.Controls.TextBlock
 $script:contractsDealerContractDetails.Text="Waiting for Dealer requirements...";$script:contractsDealerContractDetails.Foreground="#E2E8EE";$script:contractsDealerContractDetails.FontSize=12;$script:contractsDealerContractDetails.TextWrapping="Wrap";$script:contractsDealerContractDetails.LineHeight=17
 [void]$dealerBody.Children.Add($script:contractsDealerContractDetails)
 [void]$dealerSp.Children.Add($dealerBody);$dealerContract.Child=$dealerSp
 [System.Windows.Controls.Grid]::SetColumn($dealerContract,1);[void]$contractsGrid.Children.Add($dealerContract)

 [void]$root.Children.Add($contractsGrid)

 # ----------------------------------------------------------------
 # TONY'S PAWN SHOP - full-width feature card
 # ----------------------------------------------------------------
 $pawnCard=New-Object System.Windows.Controls.Border
 $pawnCard.Background="#1A2420";$pawnCard.BorderBrush="#3D7650";$pawnCard.BorderThickness="1";$pawnCard.CornerRadius="8";$pawnCard.Padding="0";$pawnCard.Margin="0,0,0,10"
 $pawnSp=New-Object System.Windows.Controls.StackPanel
 $pawnAccent=New-Object System.Windows.Controls.Border;$pawnAccent.Height=4;$pawnAccent.Background="#4A8C5E";$pawnAccent.CornerRadius="8,8,0,0"
 [void]$pawnSp.Children.Add($pawnAccent)

 $pawnBody=New-Object System.Windows.Controls.StackPanel;$pawnBody.Margin="10,8,10,10"
 $pawnHead=New-Object System.Windows.Controls.Grid
 [void]$pawnHead.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width="Auto"}))
 [void]$pawnHead.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition))

 $pawnIcon=New-Object System.Windows.Controls.Image
 $pawnIcon.Width=30;$pawnIcon.Height=30;$pawnIcon.Stretch="Uniform";$pawnIcon.Margin="0,0,9,0"
 try{$pawnIcon.Source=New-CompanionBitmapImage "GameUI/Map/Icons/MAP_ico_PawnShop.png"}catch{}
 [System.Windows.Controls.Grid]::SetColumn($pawnIcon,0);[void]$pawnHead.Children.Add($pawnIcon)

 $pawnHeadText=New-Object System.Windows.Controls.StackPanel
 $pawnTitle=New-Object System.Windows.Controls.TextBlock;$pawnTitle.Text="TONY'S PAWN SHOP";$pawnTitle.Foreground="#FFF3E3";$pawnTitle.FontWeight="Bold";$pawnTitle.FontSize=16
 $pawnSub=New-Object System.Windows.Controls.TextBlock;$pawnSub.Text="Current requests • Tony Rep rewards • stock matching";$pawnSub.Foreground="#8FA99A";$pawnSub.FontSize=10;$pawnSub.Margin="0,1,0,0"
 [void]$pawnHeadText.Children.Add($pawnTitle);[void]$pawnHeadText.Children.Add($pawnSub)
 $script:contractsTonyRep=New-Object System.Windows.Controls.TextBlock
 $script:contractsTonyRep.Text="TONY REP  -";$script:contractsTonyRep.Foreground="#9AD8AA";$script:contractsTonyRep.FontSize=11;$script:contractsTonyRep.FontWeight="SemiBold";$script:contractsTonyRep.Margin="0,3,0,0"
 [void]$pawnHeadText.Children.Add($script:contractsTonyRep)
 $script:contractsDailyDeal=New-Object System.Windows.Controls.TextBlock
 $script:contractsDailyDeal.Text="DEAL OF THE DAY: No deal available";$script:contractsDailyDeal.Foreground="#F2C760";$script:contractsDailyDeal.FontSize=11;$script:contractsDailyDeal.Margin="0,2,0,0"
 [void]$pawnHeadText.Children.Add($script:contractsDailyDeal)
 [System.Windows.Controls.Grid]::SetColumn($pawnHeadText,1);[void]$pawnHead.Children.Add($pawnHeadText)
 [void]$pawnBody.Children.Add($pawnHead)

 $pawnContent=New-Object System.Windows.Controls.Border
 $pawnContent.Background="#111915";$pawnContent.BorderBrush="#2F4F3A";$pawnContent.BorderThickness="1";$pawnContent.CornerRadius="6";$pawnContent.Padding="8";$pawnContent.Margin="0,6,0,0"
 $script:contractsPawnText=New-Object System.Windows.Controls.TextBlock
 $script:contractsPawnText.Text="Waiting for Pawn Shop requests...";$script:contractsPawnText.Foreground="#E2E8EE";$script:contractsPawnText.FontSize=11;$script:contractsPawnText.TextWrapping="Wrap";$script:contractsPawnText.LineHeight=15
 $pawnContent.Child=$script:contractsPawnText
 [void]$pawnBody.Children.Add($pawnContent)
 [void]$pawnSp.Children.Add($pawnBody);$pawnCard.Child=$pawnSp
 [void]$root.Children.Add($pawnCard)

 # ----------------------------------------------------------------
 # CUSTOMER ORDERS + MISSIONS
 # ----------------------------------------------------------------
 $lower=New-Object System.Windows.Controls.Grid
 [void]$lower.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition))
 [void]$lower.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition))

 $customerCard=New-Object System.Windows.Controls.Border
 $customerCard.Background="#1B222B";$customerCard.BorderBrush="#315B85";$customerCard.BorderThickness="1";$customerCard.CornerRadius="8";$customerCard.Padding="9";$customerCard.Margin="0,0,5,0"
 $customerSp=New-Object System.Windows.Controls.StackPanel
 $customerHead=New-Object System.Windows.Controls.StackPanel;$customerHead.Orientation="Horizontal"
 $mailIcon=New-Object System.Windows.Controls.Image;$mailIcon.Width=25;$mailIcon.Height=25;$mailIcon.Stretch="Uniform";$mailIcon.Margin="0,0,8,0"
 try{$mailIcon.Source=New-CompanionBitmapImage "GameUI/Map/Icons/MAP_ico_Mail.png"}catch{}
 [void]$customerHead.Children.Add($mailIcon)
 $dealerTitle=New-Object System.Windows.Controls.TextBlock;$dealerTitle.Text="CUSTOMER ORDERS";$dealerTitle.Foreground="#FFF3E3";$dealerTitle.FontWeight="Bold";$dealerTitle.FontSize=15;$dealerTitle.VerticalAlignment="Center"
 [void]$customerHead.Children.Add($dealerTitle);[void]$customerSp.Children.Add($customerHead)

 $customerInner=New-Object System.Windows.Controls.Border;$customerInner.Background="#121820";$customerInner.CornerRadius="5";$customerInner.Padding="8";$customerInner.Margin="0,7,0,0"
 $script:contractsDealerText=New-Object System.Windows.Controls.TextBlock
 $script:contractsDealerText.Text="No active customer vehicle order."; $script:contractsDealerText.Foreground="#E2E8EE";$script:contractsDealerText.FontSize=12;$script:contractsDealerText.TextWrapping="Wrap";$script:contractsDealerText.LineHeight=17
 $customerInner.Child=$script:contractsDealerText;[void]$customerSp.Children.Add($customerInner)
 $customerCard.Child=$customerSp
 [System.Windows.Controls.Grid]::SetColumn($customerCard,0);[void]$lower.Children.Add($customerCard)

 $missionCard=New-Object System.Windows.Controls.Border
 $missionCard.Background="#1B222B";$missionCard.BorderBrush="#5A4B78";$missionCard.BorderThickness="1";$missionCard.CornerRadius="8";$missionCard.Padding="9";$missionCard.Margin="5,0,0,0"
 $missionSp=New-Object System.Windows.Controls.StackPanel
 $missionHead=New-Object System.Windows.Controls.StackPanel;$missionHead.Orientation="Horizontal"
 $questIcon=New-Object System.Windows.Controls.Image;$questIcon.Width=25;$questIcon.Height=25;$questIcon.Stretch="Uniform";$questIcon.Margin="0,0,8,0"
 try{$questIcon.Source=New-CompanionBitmapImage "GameUI/Map/Icons/MAP_ico_Quest.png"}catch{}
 [void]$missionHead.Children.Add($questIcon)
 $missionTitle=New-Object System.Windows.Controls.TextBlock;$missionTitle.Text="MISSIONS / TASKS";$missionTitle.Foreground="#FFF3E3";$missionTitle.FontWeight="Bold";$missionTitle.FontSize=15;$missionTitle.VerticalAlignment="Center"
 [void]$missionHead.Children.Add($missionTitle);[void]$missionSp.Children.Add($missionHead)

 $missionInner=New-Object System.Windows.Controls.Border;$missionInner.Background="#15131B";$missionInner.CornerRadius="5";$missionInner.Padding="8";$missionInner.Margin="0,7,0,0"
 $script:contractsMissionText=New-Object System.Windows.Controls.TextBlock
 $script:contractsMissionText.Text="Waiting for active missions...";$script:contractsMissionText.Foreground="#E2E8EE";$script:contractsMissionText.FontSize=12;$script:contractsMissionText.TextWrapping="Wrap";$script:contractsMissionText.LineHeight=17
 $missionInner.Child=$script:contractsMissionText;[void]$missionSp.Children.Add($missionInner)
 $missionCard.Child=$missionSp
 [System.Windows.Controls.Grid]::SetColumn($missionCard,1);[void]$lower.Children.Add($missionCard)

 # Compact Contracts activity row: Tony on the left, Customer Orders + Missions stacked on the right.
 [void]$root.Children.Remove($pawnCard)
 [void]$root.Children.Remove($lower)
 [void]$lower.Children.Remove($customerCard)
 [void]$lower.Children.Remove($missionCard)

 $activityGrid=New-Object System.Windows.Controls.Grid
 $activityGrid.Margin="0,0,0,0"
 $activityGrid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width="1.35*"}))|Out-Null
 $activityGrid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width="1*"}))|Out-Null

 $pawnCard.Margin="0,0,6,0"
 [System.Windows.Controls.Grid]::SetColumn($pawnCard,0)
 [void]$activityGrid.Children.Add($pawnCard)

 $activityRight=New-Object System.Windows.Controls.StackPanel
 $customerCard.Margin="6,0,0,6"
 $missionCard.Margin="6,0,0,0"
 [void]$activityRight.Children.Add($customerCard)
 [void]$activityRight.Children.Add($missionCard)
 [System.Windows.Controls.Grid]::SetColumn($activityRight,1)
 [void]$activityGrid.Children.Add($activityRight)

 [void]$root.Children.Add($activityGrid)
 return $scroll
}

$employeesTab=New-Object System.Windows.Controls.TabItem;$employeesTab.Tag="Employees";$employeesTab.Header="EMPLOYEES";$employeesTab.Content=New-ComingSoonPage "EMPLOYEES" "Employee cards, roles, shifts and PAID / NOT PAID status will live here.";[void]$tabs.Items.Add($employeesTab)
$contractsTab=New-Object System.Windows.Controls.TabItem;$contractsTab.Tag="Contracts";$contractsTab.Header="CONTRACTS";$contractsTab.Content=New-ContractsLayoutPage;[void]$tabs.Items.Add($contractsTab)

function Find-ContractNamedControl($parent,[string]$name){
 if($null -eq $parent){return $null}
 if(($parent -is [System.Windows.FrameworkElement]) -and $parent.Name -eq $name){return $parent}
 if($parent -is [System.Windows.Controls.Panel]){
  foreach($c in $parent.Children){$r=Find-ContractNamedControl $c $name;if($r){return $r}}
 }elseif($parent -is [System.Windows.Controls.ContentControl]){
  $r=Find-ContractNamedControl $parent.Content $name;if($r){return $r}
 }elseif($parent -is [System.Windows.Controls.ScrollViewer]){
  $r=Find-ContractNamedControl $parent.Content $name;if($r){return $r}
 }
 return $null
}
$script:contractsSummaryB2B=Find-ContractNamedControl $contractsTab.Content "ContractsSummaryB2B"
$script:contractsSummaryCars=Find-ContractNamedControl $contractsTab.Content "ContractsSummaryCars"
$script:contractsSummaryPawn=Find-ContractNamedControl $contractsTab.Content "ContractsSummaryPawn"
$script:contractsSummaryDealer=Find-ContractNamedControl $contractsTab.Content "ContractsSummaryDealer"
if($dashboardContractsLink){$dashboardContractsLink.Add_Click({$tabs.SelectedItem=$contractsTab})}
if($script:contractsRefreshButton){$script:contractsRefreshButton.Add_Click({
 if(Request-ReaderRefresh "contracts"){
  $script:contractsRefreshStatus.Text="Refresh requested - waiting for reader..."
 }
})}


$automatedPlatformTab=New-Object System.Windows.Controls.TabItem;$automatedPlatformTab.Tag="AutomatedPlatform";$automatedPlatformTab.Header="AUTOMATION";$automatedPlatformTab.Content=New-ComingSoonPage "AUTOMATION" "COMING SOON";[void]$tabs.Items.Add($automatedPlatformTab)
$racingTab=New-Object System.Windows.Controls.TabItem;$racingTab.Tag="Racing";$racingTab.Header="RACING";$racingTab.Content=New-ComingSoonPage "RACING" "COMING SOON";[void]$tabs.Items.Add($racingTab)
$autoFleetTab=New-Object System.Windows.Controls.TabItem;$autoFleetTab.Tag="AutoFleet";$autoFleetTab.Header="AUTOFLEET + DEALERSHIPS";$autoFleetTab.Content=New-ComingSoonPage "AUTOFLEET + DEALERSHIPS" "COMING SOON";[void]$tabs.Items.Add($autoFleetTab)
function New-SettingsSection([string]$title,[string]$subtitle){
 $border=New-Object System.Windows.Controls.Border
 $border.Background="#20262F";$border.BorderBrush="#3B4552";$border.BorderThickness="1";$border.CornerRadius="8";$border.Padding="14";$border.Margin="0,0,0,12"
 $sp=New-Object System.Windows.Controls.StackPanel
 $h=New-Object System.Windows.Controls.TextBlock;$h.Text=$title;$h.Foreground="#FFF3E3";$h.FontWeight="Bold";$h.FontSize=18
 [void]$sp.Children.Add($h)
 if(-not [string]::IsNullOrWhiteSpace($subtitle)){
  $d=New-Object System.Windows.Controls.TextBlock;$d.Text=$subtitle;$d.Foreground="#9CA8B5";$d.FontSize=12;$d.TextWrapping="Wrap";$d.Margin="0,4,0,12"
  [void]$sp.Children.Add($d)
 }
 $border.Child=$sp
 return @($border,$sp)
}
function New-RefreshCombo([string]$settingKey){
 $combo=New-Object System.Windows.Controls.ComboBox
 $combo.Width=170;$combo.Height=30;$combo.HorizontalAlignment="Left";$combo.Tag=$settingKey
 foreach($entry in @(
  @("Off / Manual",0),@("Every 10 seconds",10),@("Every 30 seconds",30),@("Every 1 minute",60),@("Every 3 minutes",180),@("Every 5 minutes",300)
 )){
  $item=New-Object System.Windows.Controls.ComboBoxItem
  $item.Content=$entry[0];$item.Tag=[int]$entry[1]
  [void]$combo.Items.Add($item)
  if([int]$script:refreshSettings[$settingKey] -eq [int]$entry[1]){$combo.SelectedItem=$item}
 }
 if($null -eq $combo.SelectedItem){$combo.SelectedIndex=0}
 return $combo
}
function New-RefreshSettingRow([string]$label,[string]$description,[string]$settingKey,[string]$requestTarget){
 $grid=New-Object System.Windows.Controls.Grid;$grid.Margin="0,4,0,10"
 [void]$grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width="2.0*"}))
 [void]$grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width="1.2*"}))
 [void]$grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{Width="Auto"}))
 $left=New-Object System.Windows.Controls.StackPanel
 $name=New-Object System.Windows.Controls.TextBlock;$name.Text=$label;$name.FontWeight="SemiBold";$name.Foreground="#FFF3E3";$name.FontSize=14
 $desc=New-Object System.Windows.Controls.TextBlock;$desc.Text=$description;$desc.Foreground="#8FA0AD";$desc.FontSize=11;$desc.TextWrapping="Wrap";$desc.Margin="0,2,12,0"
 [void]$left.Children.Add($name);[void]$left.Children.Add($desc)
 [System.Windows.Controls.Grid]::SetColumn($left,0);[void]$grid.Children.Add($left)
 $combo=New-RefreshCombo $settingKey
 $combo.Margin="4,0,12,0";[System.Windows.Controls.Grid]::SetColumn($combo,1);[void]$grid.Children.Add($combo)
 $button=$null
 if(-not [string]::IsNullOrWhiteSpace($requestTarget)){
  $button=New-Object System.Windows.Controls.Button;$button.Content="REFRESH NOW";$button.Padding="12,6";$button.MinWidth=108;$button.Tag=$requestTarget
  $button.Background="#315B85";$button.BorderBrush="#76B9F5";$button.Foreground="#FFF8EB";$button.FontWeight="Bold"
  [System.Windows.Controls.Grid]::SetColumn($button,2);[void]$grid.Children.Add($button)
 }
 return @($grid,$combo,$button)
}

$settingsRoot=New-Object System.Windows.Controls.ScrollViewer;$settingsRoot.VerticalScrollBarVisibility="Auto"
$settingsPanel=New-Object System.Windows.Controls.StackPanel;$settingsPanel.Margin="12";$settingsRoot.Content=$settingsPanel
$settingsHeading=New-Object System.Windows.Controls.TextBlock;$settingsHeading.Text="SETTINGS";$settingsHeading.Foreground="#FFF3E3";$settingsHeading.FontWeight="Bold";$settingsHeading.FontSize=22;$settingsHeading.Margin="0,0,0,10";[void]$settingsPanel.Children.Add($settingsHeading)

$refreshSection=New-SettingsSection "REFRESH SETTINGS" "Choose how often the Companion updates. Off / Manual stops that automatic reader while keeping cached data on screen."
[void]$settingsPanel.Children.Add($refreshSection[0]);$refreshStack=$refreshSection[1]
$rowDashboard=New-RefreshSettingRow "Business / Dashboard" "Money and business summary reader." "dashboard_seconds" "dashboard";[void]$refreshStack.Children.Add($rowDashboard[0]);$settingsDashboardCombo=$rowDashboard[1];$settingsDashboardRefresh=$rowDashboard[2]
$rowContracts=New-RefreshSettingRow "Contracts" "B2B, Dealer Orders, Pawn Shop and Missions. Also controls how often car/inventory matching is recalculated." "contracts_seconds" "contracts";[void]$refreshStack.Children.Add($rowContracts[0]);$settingsContractsCombo=$rowContracts[1];$settingsContractsRefresh=$rowContracts[2]
$rowInventory=New-RefreshSettingRow "Inventory + Parts" "Player inventory used by both Inventory and Parts pages." "inventory_seconds" "inventory";[void]$refreshStack.Children.Add($rowInventory[0]);$settingsInventoryCombo=$rowInventory[1];$settingsInventoryRefresh=$rowInventory[2]
$rowStorage=New-RefreshSettingRow "Storage + Repair Machines" "Storage containers and repair-machine contents." "storage_seconds" "storage";[void]$refreshStack.Children.Add($rowStorage[0]);$settingsStorageCombo=$rowStorage[1];$settingsStorageRefresh=$rowStorage[2]
$rowCars=New-RefreshSettingRow "Cars" "Automatic lightweight Cars refresh. The full SCAN CARS button stays on the Cars page." "cars_seconds" "";[void]$refreshStack.Children.Add($rowCars[0]);$settingsCarsCombo=$rowCars[1]
$settingsSaved=New-Object System.Windows.Controls.TextBlock;$settingsSaved.Text="Changes are saved automatically.";$settingsSaved.Foreground="#67D56A";$settingsSaved.FontSize=11;$settingsSaved.Margin="0,2,0,0";[void]$refreshStack.Children.Add($settingsSaved)

$diagSection=New-SettingsSection "DIAGNOSTICS / DEBUG" "Debug tools are optional and disabled by default. They do not change gameplay."
[void]$settingsPanel.Children.Add($diagSection[0]);$diagStack=$diagSection[1]
$settingsDebugCheck=New-Object System.Windows.Controls.CheckBox;$settingsDebugCheck.Content="Enable Companion debug logging";$settingsDebugCheck.IsChecked=[bool]$script:refreshSettings["debug_enabled"];$settingsDebugCheck.Foreground="#FFF3E3";$settingsDebugCheck.Margin="0,0,0,10";[void]$diagStack.Children.Add($settingsDebugCheck)
$settingsDiagnosticsCheck=New-Object System.Windows.Controls.CheckBox;$settingsDiagnosticsCheck.Content="Enable Diagnostics";$settingsDiagnosticsCheck.IsChecked=[bool]$script:refreshSettings["diagnostics_enabled"];$settingsDiagnosticsCheck.Foreground="#FFF3E3";$settingsDiagnosticsCheck.Margin="0,0,0,10";[void]$diagStack.Children.Add($settingsDiagnosticsCheck)
$diagStatus=New-Object System.Windows.Controls.TextBlock;$diagStatus.Text=("Diagnostics folder: {0}" -f $diagnosticsRoot);$diagStatus.Foreground="#8FA0AD";$diagStatus.FontSize=11;$diagStatus.TextWrapping="Wrap";$diagStatus.Margin="0,0,0,10";[void]$diagStack.Children.Add($diagStatus)
$diagButtons=New-Object System.Windows.Controls.StackPanel;$diagButtons.Orientation="Horizontal"
$settingsOpenFolder=New-Object System.Windows.Controls.Button;$settingsOpenFolder.Content="OPEN DIAGNOSTICS FOLDER";$settingsOpenFolder.Padding="12,6";$settingsOpenFolder.Margin="0,0,8,0";$settingsOpenFolder.Background="#315B85";$settingsOpenFolder.BorderBrush="#76B9F5";$settingsOpenFolder.Foreground="#FFF8EB";$settingsOpenFolder.FontWeight="Bold";[void]$diagButtons.Children.Add($settingsOpenFolder)
$settingsCreateDiag=New-Object System.Windows.Controls.Button;$settingsCreateDiag.Content="REFRESH DIAGNOSTICS";$settingsCreateDiag.Padding="12,6";$settingsCreateDiag.Background="#59636F";$settingsCreateDiag.BorderBrush="#8FA0AD";$settingsCreateDiag.Foreground="#FFF8EB";$settingsCreateDiag.FontWeight="Bold";[void]$diagButtons.Children.Add($settingsCreateDiag)
[void]$diagStack.Children.Add($diagButtons)
$settingsDiagResult=New-Object System.Windows.Controls.TextBlock;$settingsDiagResult.Text="";$settingsDiagResult.Foreground="#67D56A";$settingsDiagResult.FontSize=11;$settingsDiagResult.Margin="0,8,0,0";[void]$diagStack.Children.Add($settingsDiagResult)

$settingsTab=New-Object System.Windows.Controls.TabItem;$settingsTab.Tag="Settings";$settingsTab.Header="SETTINGS";$settingsTab.Content=$settingsRoot;[void]$tabs.Items.Add($settingsTab)

# Sidebar navigation controls the hidden main TabControl headers.
function Select-MainPage([string]$tag){
 for($i=0;$i -lt $tabs.Items.Count;$i++){
  $t=$tabs.Items[$i]
  if($null -ne $t.Tag -and ([string]$t.Tag) -eq $tag){$tabs.SelectedIndex=$i;break}
 }
}
$navDashboard.Add_Click({Select-MainPage "Dashboard"})
$navInventory.Add_Click({Select-MainPage "InventoryRoot"})
$navParts.Add_Click({Select-MainPage "Parts"})
$navCars.Add_Click({Select-MainPage "CarsOwned"})
$navEmployees.Add_Click({Select-MainPage "Employees"})
$navContracts.Add_Click({Select-MainPage "Contracts"})
$navAutomatedPlatform.Add_Click({Select-MainPage "AutomatedPlatform"})
$navRacing.Add_Click({Select-MainPage "Racing"})
$navAutoFleet.Add_Click({Select-MainPage "AutoFleet"})
$navSettings.Add_Click({Select-MainPage "Settings"})

if($null -ne $dashboardRefreshSettingsLink){$dashboardRefreshSettingsLink.Add_Click({Select-MainPage "Settings"})}

function Save-RefreshSettingsFromUi{
 if($script:refreshUiInitializing){return}
 try{
  foreach($pair in @(
   @($settingsDashboardCombo,"dashboard_seconds"),@($settingsContractsCombo,"contracts_seconds"),@($settingsInventoryCombo,"inventory_seconds"),@($settingsStorageCombo,"storage_seconds"),@($settingsCarsCombo,"cars_seconds")
  )){
   $combo=$pair[0];$key=[string]$pair[1]
   if($null -ne $combo.SelectedItem){$script:refreshSettings[$key]=[int]$combo.SelectedItem.Tag}
  }
  $script:refreshSettings["debug_enabled"]=[bool]$settingsDebugCheck.IsChecked
  $script:refreshSettings["diagnostics_enabled"]=[bool]$settingsDiagnosticsCheck.IsChecked
  if([bool]$script:refreshSettings["diagnostics_enabled"]){Set-Content -LiteralPath $diagnosticsFlagPath -Value "enabled" -Encoding ASCII}else{Remove-Item -LiteralPath $diagnosticsFlagPath -Force -ErrorAction SilentlyContinue}
  Save-RefreshSettings
  Write-CompanionDebug "Refresh settings saved."
  $settingsSaved.Text=("Settings saved at {0}" -f (Get-Date -Format "HH:mm:ss"))
 }catch{}
}
foreach($c in @($settingsDashboardCombo,$settingsContractsCombo,$settingsInventoryCombo,$settingsStorageCombo,$settingsCarsCombo)){$c.Add_SelectionChanged({Save-RefreshSettingsFromUi})}
$settingsDebugCheck.Add_Click({Save-RefreshSettingsFromUi})
$settingsDiagnosticsCheck.Add_Click({Save-RefreshSettingsFromUi})
$settingsDashboardRefresh.Add_Click({if(Request-ReaderRefresh "dashboard"){$settingsSaved.Text="Dashboard refresh requested..."}})
$settingsContractsRefresh.Add_Click({if(Request-ReaderRefresh "contracts"){$settingsSaved.Text="Contracts refresh requested..."}})
$settingsInventoryRefresh.Add_Click({if(Request-ReaderRefresh "inventory"){$settingsSaved.Text="Inventory + Parts refresh requested..."}})
$settingsStorageRefresh.Add_Click({if(Request-ReaderRefresh "storage"){$settingsSaved.Text="Storage + Repair refresh requested..."}})
$settingsOpenFolder.Add_Click({try{Start-Process explorer.exe -ArgumentList ('"'+$diagnosticsRoot+'"')}catch{}})
$settingsCreateDiag.Add_Click({
 try{
  $lines=New-Object System.Collections.Generic.List[string]
  [void]$lines.Add("Car Dealer Companion Diagnostic Report")
  [void]$lines.Add("Version: v0.45.0.0")
  [void]$lines.Add(("Created: {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss")))
  [void]$lines.Add(("Save profile: {0}" -f $saveProfile))
  [void]$lines.Add("")
  [void]$lines.Add("Refresh settings:")
  foreach($k in @("dashboard_seconds","inventory_seconds","storage_seconds","cars_seconds","debug_enabled","diagnostics_enabled")){[void]$lines.Add(("  {0}={1}" -f $k,$script:refreshSettings[$k]))}
  [void]$lines.Add("")
  [void]$lines.Add("Data files:")
  foreach($path in @($json,$storageJson,$repairJson,$businessJson,$carsJson,$carsDistanceJson)){
   if(Test-Path -LiteralPath $path){$fi=Get-Item -LiteralPath $path;[void]$lines.Add(("  {0} | {1} bytes | {2}" -f $fi.Name,$fi.Length,$fi.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")))}else{[void]$lines.Add(("  {0} | missing" -f [IO.Path]::GetFileName($path)))}
  }
  $diagOut=Join-Path $diagnosticsRoot "companion_diagnostic.txt"
  $lines | Set-Content -LiteralPath $diagOut -Encoding UTF8
  Write-IconDiagnostic
  $settingsDiagResult.Text="Diagnostics refreshed in the Companion Diagnostics folder."
 }catch{$settingsDiagResult.Text="Could not create diagnostic report."}
})

$script:MainNavButtons=@{
 "Dashboard"=$navDashboard;"InventoryRoot"=$navInventory;"Parts"=$navParts;"CarsOwned"=$navCars;
 "Employees"=$navEmployees;"Contracts"=$navContracts;"AutomatedPlatform"=$navAutomatedPlatform;"AutoFleet"=$navAutoFleet;"Settings"=$navSettings
}
function Update-MainNavSelection{
 $selectedTag=""
 try{if($null -ne $tabs.SelectedItem.Tag){$selectedTag=[string]$tabs.SelectedItem.Tag}}catch{}
 foreach($key in $script:MainNavButtons.Keys){
  $btn=$script:MainNavButtons[$key]
  if($key -eq $selectedTag){$btn.Background="#6A4611";$btn.BorderBrush="#D69022"}
  else{$btn.Background="#18212B";$btn.BorderBrush="#33404D"}
 }
}
$tabs.Add_SelectionChanged({Update-MainNavSelection})
Update-MainNavSelection

# ------------------------------------------------------------
# GAME-STYLE VISUAL SHELL (presentation only)
# ------------------------------------------------------------
# Data readers, Cars classification, selection, cache and refresh logic remain
# untouched.  This section only replaces tab headers and presentation colours.
function New-GameNavHeader([string]$symbol,[string]$label,[string]$colour){
 $panel=New-Object System.Windows.Controls.StackPanel
 $panel.Orientation="Vertical";$panel.HorizontalAlignment="Center";$panel.Margin="3,2,3,3"
 $tile=New-Object System.Windows.Controls.Border
 $tile.Width=48;$tile.Height=48;$tile.CornerRadius="10";$tile.Background=$colour
 $tile.BorderBrush="#0B0E12";$tile.BorderThickness="3";$tile.Padding="3"
 $glyph=New-Object System.Windows.Controls.TextBlock
 $glyph.Text=$symbol;$glyph.FontFamily="Segoe MDL2 Assets";$glyph.FontSize=24;$glyph.FontWeight="Normal"
 $glyph.Foreground="White";$glyph.HorizontalAlignment="Center";$glyph.VerticalAlignment="Center"
 $tile.Child=$glyph
 $txt=New-Object System.Windows.Controls.TextBlock
 $txt.Text=$label;$txt.FontFamily="Lato, Segoe UI";$txt.FontSize=12;$txt.FontWeight="Bold"
 $txt.Foreground="#F3EBDD";$txt.HorizontalAlignment="Center";$txt.Margin="0,3,0,0"
 [void]$panel.Children.Add($tile);[void]$panel.Children.Add($txt)
 return $panel
}

# Reusable presentation API for every future main tab. New feature tabs should
# use this helper so they inherit the same launcher tile, typography and shell.
$script:GameNavPalette=@("#D34843","#6A963B","#2E4EB2","#8B3CB3","#D56A27","#315B85","#B87824")
function Set-GameMainTabHeader($tab,[string]$symbol,[string]$label,[string]$colour){
 if($null -eq $tab){return}
 if([string]::IsNullOrWhiteSpace($colour)){
  $colour=$script:GameNavPalette[[Math]::Abs($tabs.Items.Count % $script:GameNavPalette.Count)]
 }
 $tab.Header=New-GameNavHeader $symbol $label $colour
}
function New-GameMainTab([string]$label,[string]$tag,[string]$symbol,[string]$colour){
 $tab=New-Object System.Windows.Controls.TabItem
 $tab.Tag=$tag
 Set-GameMainTabHeader $tab $symbol $label $colour
 return $tab
}

$mainNav=@(
 @($tabs.Items[0],([string][char]0xE80F),"DASHBOARD","#D34843"),
 @($tabs.Items[1],([string][char]0xE7B8),"INVENTORY","#6A963B"),
 @($partsTab,([string][char]0xE713),"PARTS","#2E4EB2"),
 @($carsTab,([string][char]0xE804),"CARS","#D56A27")
)
foreach($n in $mainNav){
 try{$n[0].Header=New-GameNavHeader $n[1] $n[2] $n[3]}catch{}
}

function New-GameSubHeader([string]$text,[string]$colour){
 $b=New-Object System.Windows.Controls.Border
 $b.Background=$colour;$b.CornerRadius="7";$b.Padding="10,5";$b.Margin="1"
 $t=New-Object System.Windows.Controls.TextBlock
 $t.Text=$text;$t.Foreground="White";$t.FontSize=11;$t.FontWeight="Bold"
 $b.Child=$t;return $b
}

# Inventory tabs use the same coloured button treatment as Cars/Parts and
# prefer genuine game inventory assets from MasterAssets when available.
function Get-InventoryCategoryIcon([string]$category){
 try{
  $pack=@{"ALL"="Icons/Inventory/all.png";"VALUABLES"="GameUI/Inventory/Loot/UI_icn_Collectibles.png";"ELECTRONICS"="GameUI/Inventory/Loot/UI_icn_ElektronicDevices.png";"TOOLS"="GameUI/Inventory/Loot/UI_icn_Tools.png";"MEDIA"="GameUI/Inventory/Loot/UI_icn_CDxDVD.png";"FURNITURE"="GameUI/Inventory/Furniture/UI_Modern_Chair_ico.png";"CONSUMABLES"="Icons/Inventory/consumables.png";"CONTAINERS"="GameUI/Inventory/Loot/UI_icn_Lootbox.png";"OTHER"="Icons/Inventory/other.png"}
  if($pack.ContainsKey($category)){$pp=Get-CompanionAssetPath $pack[$category];if($pp){return $pp}}
  $master=Join-Path $base "_NoBundledMasterAssets"
  $folder=$null
  switch($category){
   "ALL" {$folder=Join-Path $master "Navigation"}
   "VALUABLES" {$folder=Join-Path $master "Inventory\Valuables"}
   "FURNITURE" {$folder=Join-Path $master "Inventory\Furniture"}
   "CONSUMABLES" {$folder=Join-Path $master "Inventory\Consumables"}
   "CONTAINERS" {$folder=Join-Path $master "Inventory\Misc"}
   "OTHER" {$folder=Join-Path $master "Inventory\Misc"}
  }
  if($folder -and (Test-Path -LiteralPath $folder)){
   if($category -eq "ALL"){
    $preferred=Join-Path $folder "UI_Inventory_icn.png"
    if(Test-Path -LiteralPath $preferred){return $preferred}
   }
   $f=Get-ChildItem -LiteralPath $folder -File -Filter *.png -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -First 1
   if($f){return $f.FullName}
  }
 }catch{}
 return $null
}
function New-InventoryCategoryHeader([string]$text,[string]$colour,[string]$category){
 $b=New-Object System.Windows.Controls.Border
 $b.Background=$colour;$b.CornerRadius="7";$b.Padding="10,5";$b.Margin="1"
 $sp=New-Object System.Windows.Controls.StackPanel
 $sp.Orientation="Horizontal";$sp.VerticalAlignment="Center"
 $iconPath=Get-InventoryCategoryIcon $category
 if($iconPath){
  try{
   $img=New-Object System.Windows.Controls.Image
   $bmp=New-Object System.Windows.Media.Imaging.BitmapImage
   $bmp.BeginInit();$bmp.CacheOption=[System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
   $bmp.UriSource=New-Object System.Uri($iconPath,[System.UriKind]::Absolute)
   $bmp.EndInit();$bmp.Freeze()
   $img.Source=$bmp;$img.Width=18;$img.Height=18;$img.Margin="0,0,7,0";$img.Stretch="Uniform"
   [void]$sp.Children.Add($img)
  }catch{}
 }
 $t=New-Object System.Windows.Controls.TextBlock
 $t.Text=$text;$t.Foreground="White";$t.FontSize=11;$t.FontWeight="Bold";$t.VerticalAlignment="Center"
 [void]$sp.Children.Add($t);$b.Child=$sp;return $b
}

# Parts tabs use the same game-style coloured button treatment as Cars.
# When the MasterAssets library is present, each button also uses a real game part icon.
function Get-PartsCategoryIcon([string]$category){
 try{
  $pack=@{"ALL"="Icons/Parts/all.png";"ENGINE"="Icons/Parts/all.png";"BRAKES"="Icons/Parts/all.png";"SUSPENSION"="Icons/Parts/all.png";"EXHAUST"="Icons/Parts/exhaust.png";"FUSES"="Icons/Parts/all.png";"REPAIR"="Icons/Parts/repair.png"}
  if($pack.ContainsKey($category)){$pp=Get-CompanionAssetPath $pack[$category];if($pp){return $pp}}
  $master=Join-Path $base "_NoBundledMasterAssets"
  $folder=$null
  switch($category){
   "ALL" {$folder=Join-Path $master "Navigation"}
   "ENGINE" {$folder=Join-Path $master "Parts\Engine"}
   "BRAKES" {$folder=Join-Path $master "Parts\Brakes"}
   "SUSPENSION" {$folder=Join-Path $master "Parts\Suspension"}
   "EXHAUST" {$folder=Join-Path $master "Parts\Exhaust"}
   "FUSES" {$folder=Join-Path $master "Parts\Fuses"}
   "REPAIR" {$folder=Join-Path $master "Parts\Repair"}
  }
  if($folder -and (Test-Path -LiteralPath $folder)){
   if($category -eq "ALL"){
    $preferred=Join-Path $folder "UI_Inventory_icn.png"
    if(Test-Path -LiteralPath $preferred){return $preferred}
   }
   $f=Get-ChildItem -LiteralPath $folder -File -Filter *.png -ErrorAction SilentlyContinue | Sort-Object Name | Select-Object -First 1
   if($f){return $f.FullName}
  }
 }catch{}
 return $null
}
function New-PartsCategoryHeader([string]$text,[string]$colour,[string]$category){
 $b=New-Object System.Windows.Controls.Border
 $b.Background=$colour;$b.CornerRadius="7";$b.Padding="10,5";$b.Margin="1"
 $sp=New-Object System.Windows.Controls.StackPanel
 $sp.Orientation="Horizontal";$sp.VerticalAlignment="Center"
 $iconPath=Get-PartsCategoryIcon $category
 if($iconPath){
  try{
   $img=New-Object System.Windows.Controls.Image
   $bmp=New-Object System.Windows.Media.Imaging.BitmapImage
   $bmp.BeginInit();$bmp.CacheOption=[System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
   $bmp.UriSource=New-Object System.Uri($iconPath,[System.UriKind]::Absolute)
   $bmp.EndInit();$bmp.Freeze()
   $img.Source=$bmp;$img.Width=18;$img.Height=18;$img.Margin="0,0,7,0";$img.Stretch="Uniform"
   [void]$sp.Children.Add($img)
  }catch{}
 }
 $t=New-Object System.Windows.Controls.TextBlock
 $t.Text=$text;$t.Foreground="White";$t.FontSize=11;$t.FontWeight="Bold";$t.VerticalAlignment="Center"
 [void]$sp.Children.Add($t)
 $b.Child=$sp;return $b
}
try{$inventoryAllTab.Header=New-InventoryCategoryHeader "ALL" "#496B2E" "ALL"}catch{}
try{$inventoryValuablesTab.Header=New-InventoryCategoryHeader "VALUABLES + SAFES" "#9B772C" "VALUABLES"}catch{}
try{$inventoryElectronicsTab.Header=New-InventoryCategoryHeader "ELECTRONICS" "#315B85" "ELECTRONICS"}catch{}
try{$inventoryToolsTab.Header=New-InventoryCategoryHeader "TOOLS" "#6D6540" "TOOLS"}catch{}
try{$inventoryMediaTab.Header=New-InventoryCategoryHeader "MEDIA" "#704B78" "MEDIA"}catch{}
try{$inventoryFurnitureTab.Header=New-InventoryCategoryHeader "FURNITURE" "#76513D" "FURNITURE"}catch{}
try{$inventoryConsumablesTab.Header=New-InventoryCategoryHeader "CONSUMABLES" "#8B3C57" "CONSUMABLES"}catch{}
try{$inventoryContainersTab.Header=New-InventoryCategoryHeader "CONTAINERS" "#315B85" "CONTAINERS"}catch{}
try{$inventoryOtherTab.Header=New-InventoryCategoryHeader "OTHER" "#59636F" "OTHER"}catch{}
try{$partsAllTab.Header=New-PartsCategoryHeader "ALL" "#496B2E" "ALL"}catch{}
try{$partsEngineTab.Header=New-PartsCategoryHeader "ENGINE" "#A95B2D" "ENGINE"}catch{}
try{$partsBrakesTab.Header=New-PartsCategoryHeader "BRAKES" "#A93E39" "BRAKES"}catch{}
try{$partsSuspensionTab.Header=New-PartsCategoryHeader "SUSPENSION" "#315B85" "SUSPENSION"}catch{}
try{$partsExhaustTab.Header=New-PartsCategoryHeader "EXHAUST" "#59636F" "EXHAUST"}catch{}
try{$partsSmallTab.Header=New-PartsCategoryHeader "FUSES + OTHER" "#9B772C" "FUSES"}catch{}
try{$repairTab.Header=New-PartsCategoryHeader "REPAIR MACHINE" "#8B3C57" "REPAIR"}catch{}
try{$carsForSaleTab.Header=New-GameSubHeader "FOR SALE" "#A93E39"}catch{}
try{$carsReadyTab.Header=New-GameSubHeader "READY FOR SALE" "#5D8E39"}catch{}
try{$carsWaitingTab.Header=New-GameSubHeader "WAITING" "#B87824"}catch{}
try{$carsWrecksTab.Header=New-GameSubHeader "WRECKS" "#5A6572"}catch{}
try{$carsPersonalTab.Header=New-GameSubHeader "PERSONAL CARS" "#315B85"}catch{}
try{$carsModifiedTab.Header=New-GameSubHeader "MODIFIED" "#8B5A9B"}catch{}

# Cars prototype surface: game-dark cards with warm readable text.
try{$carsTabRoot.Background="#171C24"}catch{}
try{$carsTopPanel.Background="#171C24"}catch{}
try{$carsBottomGrid.Background="#171C24"}catch{}
try{$carsRefreshStatus.Foreground="#BFC7D1"}catch{}
try{$carsRefreshButton.Background="#D56A27";$carsRefreshButton.BorderBrush="#F29A58"}catch{}

function Format-CarPercent($value){
 if($null -eq $value){return "-"}
 try{
  $n=[double]$value
  if($n -ge 0 -and $n -le 1.000001){
   return ("{0:P0}" -f $n)
  }
  return ("{0:N1}%" -f $n)
 }catch{
  return "-"
 }
}

function Get-CarConditionPercent($value){
 if($null -eq $value){return $null}
 try{
  $n=[double]$value
  if($n -lt 0){return $null}
  if($n -le 1.000001){return ($n*100.0)}
  return $n
 }catch{
  return $null
 }
}

function Format-CarMoney($value){
 try{
  $n=[double]$value
  if($n -le 0){return "-"}
  return ('$' + ("{0:N0}" -f $n))
 }catch{
  return "-"
 }
}
function Format-CarBoughtLabel($value,[bool]$wreckWhenZero){
 try{
  $n=[double]$value
  if($n -le 0){
   if($wreckWhenZero){return "Wreck"}
   return "-"
  }
  return (Format-CarMoney $n)
 }catch{
  if($wreckWhenZero){return "Wreck"}
  return "-"
 }
}

function Test-CarIsWreck($car){
 try{
  if($null -eq $car){return $false}

  try{if([bool]$car.isForSale){return $false}}catch{}

  # A former wreck keeps its original $0 acquisition price forever.
  # Once repaired, current condition takes priority over that historical value.
  try{
   $pct=Get-CarConditionPercent $car.mechanicalCondition
   if($null -ne $pct -and $pct -ge 95.0){return $false}
  }catch{}

  # Prefer the game's current active wreck flag.
  try{if([bool]$car.isAbandonedWreck){return $true}}catch{}

  # Fallback for newly collected wrecks where the live flag can be unreliable.
  try{
   $paid=[double]$car.buyingPlayerPrice
   if($paid -le 0){return $true}
  }catch{}

  return $false
 }catch{
  return $false
 }
}

function Format-CarMileage($value){
 try{return ("{0:N2}" -f [double]$value)}catch{return "-"}
}
function Get-CarDistanceMap{
 $map=@{}
 try{
  if(Test-Path -LiteralPath $carsDistanceJson){
   $d=(Get-Content -LiteralPath $carsDistanceJson -Raw -ErrorAction SilentlyContinue)|ConvertFrom-Json
   if($null -ne $d -and $d.officeResolved -and $null -ne $d.distances){
    foreach($p in $d.distances.PSObject.Properties){
     try{$map[[string]$p.Name]=[double]$p.Value}catch{}
    }
   }
  }
 }catch{}
 return $map
}

function Get-CarDistanceText($map,[string]$carId){
 try{
  if($null -ne $map -and -not [string]::IsNullOrWhiteSpace($carId) -and $map.ContainsKey($carId)){
   # Match the game display: whole metres from office.
   return ("{0:N0} m" -f [double]$map[$carId])
  }
 }catch{}
 return "-"
}

function Get-CarLocationText($car){
 try{
  if([bool]$car.inUndergroundGarage){return "Underground Garage"}
  if(-not [string]::IsNullOrWhiteSpace([string]$car.location)){return [string]$car.location}
 }catch{}
 return "-"
}



function Format-CarText($value){
 $s=[string]$value
 if([string]::IsNullOrWhiteSpace($s)){return "-"}
 return $s
}

function Format-Gearbox($value){
 $s=[string]$value
 switch($s){
  "0" { return "Manual" }
  "1" { return "Automatic" }
  default {
   if([string]::IsNullOrWhiteSpace($s)){return "-"}
   return $s
  }
 }
}

function Format-Fuel($value){
 $s=[string]$value
 switch($s){
  "0" { return "Gasoline" }
  default {
   if([string]::IsNullOrWhiteSpace($s)){return "-"}
   return $s
  }
 }
}

function Format-Colour($value){
 $s=[string]$value
 if([string]::IsNullOrWhiteSpace($s)){return "-"}

 # First discovery sweep exposes this as E_VehiclePaintColor, but the generated
 # enum labels are NewEnumerator0..20 rather than human colour names.
 # Therefore do not invent a colour-name mapping. Show the stable colour id
 # until we have a proven game label for each id.
 if($s -match '^\d+$'){
  return ("Colour ID " + $s)
 }

 return $s
}


function Get-CarColourHex($r,$g,$b){
 try{
  if($null -eq $r -or $null -eq $g -or $null -eq $b){return "#A0A0A0"}
  $rr=[Math]::Max(0,[Math]::Min(255,[Math]::Round(([double]$r)*255)))
  $gg=[Math]::Max(0,[Math]::Min(255,[Math]::Round(([double]$g)*255)))
  $bb=[Math]::Max(0,[Math]::Min(255,[Math]::Round(([double]$b)*255)))
  return ("#{0:X2}{1:X2}{2:X2}" -f $rr,$gg,$bb)
 }catch{
  return "#A0A0A0"
 }
}

function Get-CarColourLabel($enumValue,$r,$g,$b){
 # v0.37.1.0: exact E_VehiclePaintColor mapping from the updated game PAK.
 # UE4SS normally exposes the compact runtime ordinal (0..19), but also accept
 # the generated NewEnumerator labels if a wrapper returns those instead.
 $runtimeMap=@{
  0="Black";1="Silver";2="Red";3="Blue";4="Purple";5="NavyBlue";
  6="White";7="Gray";8="Gold";9="Green";10="Brown";11="Orange";
  12="Yellow";13="Graphite";14="Light-Blue";15="Light-Green";
  16="SUPER-SILVER";17="SUPER-GOLD";18="SUPER-DIAMOND";19="Custom"
 }
 $generatedMap=@{
  0="Black";1="Silver";2="Red";3="Blue";4="Purple";5="NavyBlue";
  7="White";8="Gray";9="Gold";10="Green";11="Brown";12="Orange";
  13="Yellow";14="Graphite";15="Light-Blue";16="Light-Green";
  17="SUPER-SILVER";18="SUPER-GOLD";19="SUPER-DIAMOND";20="Custom"
 }

 $s=[string]$enumValue
 if([string]::IsNullOrWhiteSpace($s)){return "-"}

 $n=0
 if([int]::TryParse($s,[ref]$n)){
  if($runtimeMap.ContainsKey($n)){return $runtimeMap[$n]}
 }
 if($s -match 'NewEnumerator(\d+)'){
  $g=[int]$Matches[1]
  if($generatedMap.ContainsKey($g)){return $generatedMap[$g]}
 }

 return $s
}

function Get-PartValue($details,[string]$key){
 if($null -eq $details -or $null -eq $details.parts){return $null}
 try{
  $p=$details.parts.PSObject.Properties[$key]
  if($null -eq $p){return $null}
  return $p.Value
 }catch{return $null}
}

function Get-PartPercent($details,[string]$key){
 $p=Get-PartValue $details $key
 if($null -eq $p -or $null -eq $p.durability){return $null}
 try{return [double]$p.durability}catch{return $null}
}

function New-ConditionRow([string]$label,$value){
 $dock=New-Object System.Windows.Controls.DockPanel
 $dock.Margin="0,1,0,1"

 $name=New-Object System.Windows.Controls.TextBlock
 $name.Text=$label
 $name.Width=145
 $name.VerticalAlignment="Center"
 [void]$dock.Children.Add($name)

 $pct=New-Object System.Windows.Controls.TextBlock
 $pct.Width=42
 $pct.TextAlignment="Right"
 $pct.VerticalAlignment="Center"
 [System.Windows.Controls.DockPanel]::SetDock($pct,"Right")

 $bar=New-Object System.Windows.Controls.ProgressBar
 $bar.Width=115
 $bar.Height=14
 $bar.Minimum=0
 $bar.Maximum=100
 $bar.Margin="6,0,0,0"

 if($null -eq $value){
  $bar.Value=0
  $pct.Text="-"
  $bar.IsEnabled=$false
 }else{
  $n=[double]$value
  if($n -le 1.000001){$n=$n*100}
  $n=[Math]::Max(0,[Math]::Min(100,$n))
  $bar.Value=$n
  $pct.Text=("{0:N0}%" -f $n)
 }

 [void]$dock.Children.Add($bar)
 [void]$dock.Children.Add($pct)
 return $dock
}

function New-SectionTitle([string]$text){
 $t=New-Object System.Windows.Controls.TextBlock
 $t.Text=$text
 $t.FontWeight="Bold"
 $t.FontSize=13
 $t.Margin="0,8,0,3"
 return $t
}

function Get-CarDetailsCachePath([string]$carId){
 if([string]::IsNullOrWhiteSpace($carId)){return $null}
 $safe=($carId -replace '[^A-Za-z0-9_.-]','_')
 return (Join-Path $carDetailsCacheDir ($safe + ".json"))
}

function Save-CarDetailsCache($details){
 try{
  if($null -eq $details){return}
  $id=[string]$details.carId
  if([string]::IsNullOrWhiteSpace($id)){return}
  $p=Get-CarDetailsCachePath $id
  if($null -eq $p){return}
  $details | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $p -Encoding UTF8
 }catch{}
}

function Load-SelectedCarDetails([string]$carId){
 # First preference: the reader's current live selected-car file.
 if(Test-Path $carDetailsJson){
  try{
   $d=(Get-Content $carDetailsJson -Raw)|ConvertFrom-Json
   if($d.connected -and ([string]$d.carId) -eq $carId){
    Save-CarDetailsCache $d
    return $d
   }
  }catch{}
 }

 # Fallback: persistent per-car cache. This is why previously loaded cars
 # can reopen immediately without waiting for the reader again.
 $cache=Get-CarDetailsCachePath $carId
 if($null -ne $cache -and (Test-Path $cache)){
  try{
   $d=(Get-Content $cache -Raw)|ConvertFrom-Json
   if($d.connected -and ([string]$d.carId) -eq $carId){return $d}
  }catch{}
 }

 return $null
}

function Add-CarReadinessProperties($o,$car){
 $names=@(
  @("MechanicalCondition","mechanicalCondition"),
  @("ScoreBrakes","scoreBrakes"),@("ScoreSuspension","scoreSuspension"),
  @("ScoreExhaust","scoreExhaust"),@("ScoreClutch","scoreClutch"),
  @("ScoreEngine","scoreEngine"),@("ScoreRadiator","scoreRadiator"),
  @("ScoreElectrical","scoreElectrical"),@("ReadinessFuses","readinessFuses"),
  @("ReadinessBattery","readinessBattery"),@("ReadinessWindshield","readinessWindshield"),
  @("ReadinessTire1","readinessTire1"),@("ReadinessTire2","readinessTire2"),
  @("ReadinessTire3","readinessTire3"),@("ReadinessTire4","readinessTire4"),
  @("ReadinessTireOpt","readinessTireOpt")
 )
 foreach($pair in $names){
  $v=$null
  try{if($null -ne $car.($pair[1])){$v=[double]$car.($pair[1])}}catch{}
  Add-Member -InputObject $o -MemberType NoteProperty -Name $pair[0] -Value $v
 }
 Add-Member -InputObject $o -MemberType NoteProperty -Name ReadinessExhaustHoles -Value $(try{[int]$car.readinessExhaustHoles}catch{0})
 Add-Member -InputObject $o -MemberType NoteProperty -Name ReadinessPhotos -Value $(try{[int]$car.readinessPhotos}catch{0})
 Add-Member -InputObject $o -MemberType NoteProperty -Name ReadinessPhotosMax -Value $(try{[int]$car.readinessPhotosMax}catch{7})
 Add-Member -InputObject $o -MemberType NoteProperty -Name ReadinessPlateClean -Value ([bool]$car.readinessPlateClean)
 Add-Member -InputObject $o -MemberType NoteProperty -Name ReadinessPhotoStudio -Value ([bool]$car.readinessPhotoStudio)
 Add-Member -InputObject $o -MemberType NoteProperty -Name FuelPercent -Value $(try{if($null -ne $car.fuelPercent){[double]$car.fuelPercent}else{$null}}catch{$null}) -Force

 # Visual-condition values are needed on every Cars tab, including PERSONAL CARS.
 # Previously CurrentDirtValue/CurrentRustValue were only added by one row builder,
 # so Wash and Bodywork became "?" on tabs whose rows did not carry those fields.
 Add-Member -InputObject $o -MemberType NoteProperty -Name CurrentDirtValue -Value $(try{[double]$car.currentDirtValue}catch{$null}) -Force
 Add-Member -InputObject $o -MemberType NoteProperty -Name CurrentRustValue -Value $(try{[double]$car.currentRustValue}catch{$null}) -Force
 Add-Member -InputObject $o -MemberType NoteProperty -Name CurWashValue -Value $(try{[double]$car.curWashValue}catch{$null}) -Force
 Add-Member -InputObject $o -MemberType NoteProperty -Name CurPolishValue -Value $(try{[double]$car.curPolishValue}catch{$null}) -Force
}

function Format-CheckPercent($value,[double]$target=95){
 if($null -eq $value){return "[?]  -"}
 try{
  $n=[double]$value
  if($n -le 1.000001){$n=$n*100}
  $mark=if($n -ge $target){"[OK]"}else{"[ ] "}
  return ("{0} {1,3:N0}%" -f $mark,$n)
 }catch{return "[?]  -"}
}

function Get-PolishReadinessValue($value){
 # CurPolishValue is a shader/game-state value whose complete state is 0.5.
 # Convert its 0..0.5 range to the game's displayed 0..100% readiness scale.
 try{
  $n=[double]$value
  if($n -lt 0){$n=0}
  $n=$n*2.0
  if($n -gt 1){$n=1}
  return $n
 }catch{return $null}
}

function Update-ReadyChecklist($selected){
 if($null -eq $readySummary -or $null -eq $readyChecklist){return}
 if($null -eq $selected -or [bool]$selected.IsHeader){
  $readySummary.Text="Select a waiting car to see its checklist."
  $readyChecklist.Text=""
  $needsAttention.Text=""
  return
 }
 $pct=Get-CarConditionPercent $selected.MechanicalCondition
 $condText=if($null -eq $pct){"-"}else{"{0:N0}%" -f $pct}
 $readySummary.Text=("{0} | Car condition: {1}" -f $selected.Model,$condText)
 $lines=New-Object System.Collections.Generic.List[string]
 $attention=New-Object System.Collections.Generic.List[string]
 foreach($entry in @(
  @("Brakes",$selected.ScoreBrakes),@("Suspension",$selected.ScoreSuspension),
  @("Engine",$selected.ScoreEngine),@("Clutch",$selected.ScoreClutch),
  @("Exhaust",$selected.ScoreExhaust),@("Radiator",$selected.ScoreRadiator),
  @("Fuses",$selected.ReadinessFuses),@("Battery",$selected.ReadinessBattery),
  @("Windshield",$selected.ReadinessWindshield)
 )){
  $line=("{0,-12} {1}" -f $entry[0],(Format-CheckPercent $entry[1] 95))
  [void]$lines.Add($line)
  $v=$null;try{$v=Get-CarConditionPercent $entry[1]}catch{}
  if($null -ne $v -and $v -lt 95){[void]$attention.Add(("{0} {1:N0}%" -f $entry[0],$v))}
 }
 $holes=[int]$selected.ReadinessExhaustHoles
 $holeMark=if($holes -eq 0){"[OK]"}else{"[ ] "}
 [void]$lines.Add(("{0,-12} {1} {2}" -f "Exhaust holes",$holeMark,$holes))
 if($holes -gt 0){[void]$attention.Add(("Exhaust holes: {0}" -f $holes))}

 $pressures=@($selected.ReadinessTire1,$selected.ReadinessTire2,$selected.ReadinessTire3,$selected.ReadinessTire4)
 $valid=@($pressures | Where-Object {$null -ne $_}).Count
 $tireText="[?] incomplete"
 if($valid -eq 4 -and $null -ne $selected.ReadinessTireOpt){
  $opt=[double]$selected.ReadinessTireOpt
  $bad=@()
  for($i=0;$i -lt 4;$i++){if([Math]::Abs(([double]$pressures[$i])-$opt) -gt 0.05){$bad+=($i+1)}}
  if($bad.Count -eq 0){$tireText=("[OK] all {0:N2}" -f $opt)}
  else{$tireText=("[ ]  target {0:N2}" -f $opt);[void]$attention.Add(("Tyres need pressure: " + ($bad -join ",")))}
 }elseif($valid -eq 4){$tireText="[OK] pressures read"}
 [void]$lines.Add(("{0,-12} {1}" -f "Tyres",$tireText))

 $fuelText="[?]  -"
 if($null -ne $selected.FuelPercent){
  try{
   $fp=[double]$selected.FuelPercent
   if($fp -lt 0){$fp=0}
   if($fp -gt 100){$fp=100}
   $fuelText=("{0:N0}%" -f $fp)
  }catch{}
 }
 [void]$lines.Add(("{0,-12} {1}" -f "Fuel",$fuelText))

 # Match the game's Car Details visual condition values.
 # CurrentDirtValue is the displayed Washed completion (0..1).
 # CurPolishValue reaches 0.5 at 100%, so normalize it to 0..1.
 # CurrentRustValue is the displayed Bodywork completion (0..1).
 $washValue=$selected.CurrentDirtValue
 $polishValue=Get-PolishReadinessValue $selected.CurPolishValue
 $bodyworkValue=$selected.CurrentRustValue

 $wash=Get-CarConditionPercent $washValue
 $polish=Get-CarConditionPercent $polishValue
 $bodywork=Get-CarConditionPercent $bodyworkValue

 [void]$lines.Add(("{0,-12} {1}" -f "Wash",(Format-CheckPercent $washValue 95)))
 [void]$lines.Add(("{0,-12} {1}" -f "Polish",(Format-CheckPercent $polishValue 95)))
 [void]$lines.Add(("{0,-12} {1}" -f "Bodywork",(Format-CheckPercent $bodyworkValue 95)))

 if($null -ne $wash -and $wash -lt 95){[void]$attention.Add(("Wash {0:N0}%" -f $wash))}
 if($null -ne $polish -and $polish -lt 95){[void]$attention.Add(("Polish {0:N0}%" -f $polish))}
 if($null -ne $bodywork -and $bodywork -lt 95){[void]$attention.Add(("Bodywork {0:N0}%" -f $bodywork))}

 $photoMark=if([int]$selected.ReadinessPhotos -ge [int]$selected.ReadinessPhotosMax -and [int]$selected.ReadinessPhotosMax -gt 0){"[OK]"}else{"[ ] "}
 [void]$lines.Add(("{0,-12} {1} {2}/{3}" -f "Photos",$photoMark,[int]$selected.ReadinessPhotos,[int]$selected.ReadinessPhotosMax))
 $plateMark=if([bool]$selected.ReadinessPlateClean){"[OK]"}else{"[ ] "}
 [void]$lines.Add(("{0,-12} {1}" -f "Plate clean",$plateMark))

 $readyChecklist.Text=($lines -join "`n")
 if($attention.Count -gt 0){
  $needsAttention.Foreground="#F4B321"
  $attentionLines=New-Object System.Collections.Generic.List[string]
  foreach($issue in $attention){[void]$attentionLines.Add(("- {0}" -f $issue))}
  $needsAttention.Text=($attentionLines -join "`n")
 }else{
  $needsAttention.Foreground="#64D96B"
  $needsAttention.Text="[OK] READY`nNo tracked issues."
 }
}

function Update-CarSelectionFromItem($selected){
 if($null -eq $trunkList){return}

 $trunkList.Items.Clear()

 if($null -eq $selected -or [bool]$selected.IsHeader){
  $carDetail.Text="Select a car to see its details and ready check."
  $selectedInfoText.Text="Select a car to see its details."
  try{$selectedCarImage.Source=$null;$selectedCarImageBorder.Visibility="Collapsed"}catch{}
  $script:selectedCarForPersonal=$null
  $script:updatingPersonalCheck=$true
  $personalCarCheck.IsChecked=$false
  $personalCarCheck.IsEnabled=$false
  $script:updatingPersonalCheck=$false
  Update-ReadyChecklist $null
  return
 }

 $script:selectedCarId=[string]$selected.CarId
 $script:selectedCarForPersonal=$selected

 # Load exactly one lightweight game thumbnail for this model.
 try{
  $carImagePath=Get-RuntimeCarPhotoPath ([string]$selected.Model) $selected.color
  if(-not [string]::IsNullOrWhiteSpace($carImagePath)){
   $carBmp=New-RuntimeCarBitmap $carImagePath
   if($null -ne $carBmp){$selectedCarImage.Source=$carBmp;$selectedCarImageBorder.Visibility="Visible"}else{$selectedCarImage.Source=$null;$selectedCarImageBorder.Visibility="Collapsed"}
  }else{$selectedCarImage.Source=$null;$selectedCarImageBorder.Visibility="Collapsed"}
 }catch{$selectedCarImage.Source=$null;$selectedCarImageBorder.Visibility="Collapsed"}

 $script:updatingPersonalCheck=$true
 $personalCarCheck.IsEnabled=$true
 $personalCarCheck.IsChecked=(Test-PersonalCar ([string]$selected.CarId))
 $script:updatingPersonalCheck=$false
$detail=("{0} | {1} | {2:N0} miles | Colour: {3} | Trunk: {4}" -f `
    $selected.Model,$selected.Year,[double]$selected.Mileage,([string]$selected.ColourLabel),[int]$selected.TrunkTotal)

 $carDetail.Text=$detail

 $trunkSummary=if([int]$selected.TrunkTotal -gt 0){("{0} items" -f [int]$selected.TrunkTotal)}else{"Empty"}
 $selectedLocation=if([string]::IsNullOrWhiteSpace([string]$selected.Location)){"-"}else{[string]$selected.Location}
 $selectedBody=if([string]::IsNullOrWhiteSpace([string]$selected.BodyType)){"-"}else{[string]$selected.BodyType}
 $wreckState=if([bool]$selected.IsAbandonedWreck){"Abandoned Wreck"}elseif([bool]$selected.IsWreckForSell){"Wreck For Sell"}elseif([bool]$selected.WasWreck){"Recovered / Was Wreck"}else{"No"}
 $saleLine=""
 try{if($selected.PSObject.Properties.Name -contains "ListingPriceText" -and -not [string]::IsNullOrWhiteSpace([string]$selected.ListingPriceText)){$saleLine=("`nFor Sale At: {0}" -f [string]$selected.ListingPriceText)}}catch{}
 $selectedDistance="-"
 try{if($selected.PSObject.Properties.Name -contains "Distance"){$selectedDistance=[string]$selected.Distance}}catch{}
 $fittedMechanical=Get-FittedMechanicalSummary $selected
 $fittedLine=if([string]::IsNullOrWhiteSpace($fittedMechanical)){""}else{("`nUPGRADED FITTED PARTS: {0}" -f $fittedMechanical)}
 $selectedInfoText.Text=(
  "Car: {0}`nBody Type: {1}`nYear: {2}`nMileage: {3:N2}`nColour: {4}`nCondition: {5}{14}`nBought For: {6}{7}`nLocation: {8}`nDistance from Office: {9}`nTrunk: {10}`nGearbox: {11}`nFuel: {12}`nWreck State: {13}" -f `
  $selected.Model,$selectedBody,$selected.Year,[double]$selected.Mileage,([string]$selected.ColourLabel),([string]$selected.ConditionText),`
  (Format-CarBoughtLabel $selected.BuyingPlayerPrice ([bool]$selected.IsAbandonedWreck)),$saleLine,$selectedLocation,$selectedDistance,$trunkSummary,(Format-Gearbox $selected.GearboxType),(Format-Fuel $selected.FuelType),$wreckState,$fittedLine)

 Update-ReadyChecklist $selected

 foreach($t in @($selected.TrunkItems)){
  $o=New-Object PSObject
  Add-Member -InputObject $o -MemberType NoteProperty -Name Name -Value ([string]$t.name)
  Add-Member -InputObject $o -MemberType NoteProperty -Name Qty -Value ([int]$t.qty)

  $dur=[double]$t.durability
  if($dur -ge 0 -and $dur -le 1){
   $condition=("{0:P0}" -f $dur)
  }elseif($dur -gt 1){
   $condition=("{0:N0}%" -f $dur)
  }else{
   $condition="-"
  }
  Add-Member -InputObject $o -MemberType NoteProperty -Name Condition -Value $condition
  [void]$trunkList.Items.Add($o)
 }

 if($trunkList.Items.Count -eq 0){
  $empty=New-Object PSObject
  Add-Member -InputObject $empty -MemberType NoteProperty -Name Name -Value "Empty"
  Add-Member -InputObject $empty -MemberType NoteProperty -Name Qty -Value 0
  Add-Member -InputObject $empty -MemberType NoteProperty -Name Condition -Value "-"
  [void]$trunkList.Items.Add($empty)
 }
}

function Update-CarSelection{
 Update-CarSelectionFromItem $carsList.SelectedItem
}

$carsRefreshButton.Add_Click({
 try{
  # Keep a permanent, low-overhead fitted-parts diagnostic for manual scans.
  # Creating it here makes the diagnostic visible immediately when SCAN CARS is pressed,
  # even before the UE4SS reader consumes the request on its next live-read tick.
  $fittedDiag=Join-Path $diagnosticsRoot "fitted_parts_diagnostic.txt"
  if([bool]$script:refreshSettings["diagnostics_enabled"]){ @(
   "CAR DEALER COMPANION - FITTED PARTS DIAGNOSTIC",
   ("Requested: "+(Get-Date -Format "yyyy-MM-dd HH:mm:ss")),
   "Status: SCAN CARS request created; waiting for UE4SS fitted-part reader...",
   ""
  ) | Set-Content -LiteralPath $fittedDiag -Encoding ASCII }

  Set-Content -LiteralPath $carsRefreshRequest -Value ("manual "+(Get-Date -Format "yyyy-MM-dd HH:mm:ss")) -Encoding ASCII
  $carsRefreshStatus.Text="Cars refresh requested - diagnostic created..."
  $carsRefreshButton.IsEnabled=$false

  $reenable=New-Object System.Windows.Threading.DispatcherTimer
  $reenable.Interval=[TimeSpan]::FromSeconds(12)
  $reenable.Add_Tick({
   try{$carsRefreshButton.IsEnabled=$true}catch{}
   try{$reenable.Stop()}catch{}
  })
  $reenable.Start()
 }catch{
  $carsRefreshStatus.Text="Could not request Cars refresh."
  $carsRefreshButton.IsEnabled=$true
 }
})

$personalCarCheck.Add_Click({
 if($script:updatingPersonalCheck){return}
 if($null -eq $script:selectedCarForPersonal){return}
 $carId=[string]$script:selectedCarForPersonal.CarId
 $k=Get-PersonalCarKey $carId
 if($k -eq ""){return}
 $sw=[System.Diagnostics.Stopwatch]::StartNew()
 Write-OverlayPerformance ("personal-toggle BEGIN carId={0} checked={1}" -f $carId,[bool]$personalCarCheck.IsChecked)
 if([bool]$personalCarCheck.IsChecked){$script:personalCars[$k]=$true}
 elseif($script:personalCars.ContainsKey($k)){$script:personalCars.Remove($k)}
 $saveSw=[System.Diagnostics.Stopwatch]::StartNew();Save-PersonalCars;$saveSw.Stop()
 Write-OverlayPerformance ("personal-toggle save={0}ms carId={1}" -f $saveSw.ElapsedMilliseconds,$carId)
 $script:forceCarsUiRebuild=$true
 $refreshSw=[System.Diagnostics.Stopwatch]::StartNew();Refresh-UI;$refreshSw.Stop()
 $sw.Stop()
 Write-OverlayPerformance ("personal-toggle END total={0}ms refresh={1}ms carId={2}" -f $sw.ElapsedMilliseconds,$refreshSw.ElapsedMilliseconds,$carId)
})

$carsList.Add_SelectionChanged({
 if($null -ne $carsList.SelectedItem){Update-CarSelectionFromItem $carsList.SelectedItem}
})
$carsForSaleList.Add_SelectionChanged({
 if($null -ne $carsForSaleList.SelectedItem -and -not [bool]$carsForSaleList.SelectedItem.IsHeader){Update-CarSelectionFromItem $carsForSaleList.SelectedItem}
})
$carsReadyList.Add_SelectionChanged({
 if($null -ne $carsReadyList.SelectedItem -and -not [bool]$carsReadyList.SelectedItem.IsHeader){Update-CarSelectionFromItem $carsReadyList.SelectedItem}
})
$carsWrecksList.Add_SelectionChanged({
 if($null -ne $carsWrecksList.SelectedItem -and -not [bool]$carsWrecksList.SelectedItem.IsHeader){Update-CarSelectionFromItem $carsWrecksList.SelectedItem}
})
$carsPersonalList.Add_SelectionChanged({
 if($null -ne $carsPersonalList.SelectedItem -and -not [bool]$carsPersonalList.SelectedItem.IsHeader){Update-CarSelectionFromItem $carsPersonalList.SelectedItem}
})
$carsModifiedList.Add_SelectionChanged({
 if($null -ne $carsModifiedList.SelectedItem -and -not [bool]$carsModifiedList.SelectedItem.IsHeader){Update-CarSelectionFromItem $carsModifiedList.SelectedItem}
})

function Get-CustomisationGroup([string]$name){
 if([string]::IsNullOrWhiteSpace($name)){return ""}
 $n=$name.ToLowerInvariant()
 # Mirror the tuning garage's own top-level organisation.
 if($n -match 'hood|front bumper|rear bumper|spoiler|headlight|mirror gadget|side skirt|wheel|rim'){return "Exterior"}
 if($n -match 'steering wheel|upholstery'){return "Interior"}
 if($n -match 'paint|carbon finish|matte finish|metallic finish|pearl finish'){return "Paint Shop"}
 if($n -match 'horn|neon|nitro'){return "Special Upgrades"}
 return ""
}

function Get-CustomisationIconPath([string]$customGroup){
 try{
  switch($customGroup){
   "Exterior" {return (Get-CompanionAssetPath "Icons/Parts/Customization/exterior.png")}
   "Interior" {return (Get-CompanionAssetPath "Icons/Parts/Customization/interior.png")}
   "Paint Shop" {return (Get-CompanionAssetPath "Icons/Parts/Customization/paint_shop.png")}
   "Special Upgrades" {return (Get-CompanionAssetPath "Icons/Parts/Customization/special_upgrades.png")}
  }
 }catch{}
 return $null
}

function Get-PartsRowIconPath([string]$group,[string]$name,[string]$customGroup=""){
 try{
  $probe=([string]$name).ToLowerInvariant()
  $itemRoot="Icons/Parts/Items/"

  # Genuine per-item mechanical icons. Sport brake rows use a prepared
  # composite: genuine brake artwork plus the genuine Sport tier badge.
  # v0.44.0.72.12.1.10: the Sport-specific textures were never added to the
  # runtime export list, so this always resolved to nothing. Fall back to
  # the base (non-Sport) icon when the Sport variant isn't available yet -
  # same safety-net pattern already used below for the Sport suspension pin.
  if($probe -match 'brake disc'){
   if($probe -match '\bsport\b'){
    $sp=Get-RuntimeIconPath ($itemRoot+"UI_BrakeDisc_Sport_ico.png")
    if($sp){return $sp}
   }
   return (Get-CompanionAssetPath ($itemRoot+"UI_BrakeDisc_ico.png"))
  }
  if($probe -match 'brake (caliper|clip)'){
   if($probe -match '\bsport\b'){
    $sp=Get-RuntimeIconPath ($itemRoot+"UI_BrakeClips_Sport_ico.png")
    if($sp){return $sp}
   }
   return (Get-CompanionAssetPath ($itemRoot+"UI_BrakeClips_ico.png"))
  }
  if($probe -match 'clutch'){return (Get-CompanionAssetPath ($itemRoot+"UI_clutch_ico.png"))}
  if($probe -match 'battery'){return (Get-CompanionAssetPath ($itemRoot+"UI_battery_ico.png"))}
  if($probe -match 'radiator'){return (Get-CompanionAssetPath ($itemRoot+"UI_radiator_ico.png"))}
  if($probe -match 'engine'){return (Get-CompanionAssetPath ($itemRoot+"UI_engine_ico.png"))}
  if($probe -match 'front.*(absorber|shock)'){return (Get-CompanionAssetPath ($itemRoot+"UI_FrontAbsorber_ico.png"))}
  if($probe -match 'rear.*(absorber|shock)'){return (Get-CompanionAssetPath ($itemRoot+"UI_RearAbsorber_ico.png"))}
  if($probe -match 'suspension(?: arm)? pin'){
   if($probe -match '\bsport\b'){
    $sp=Get-RuntimeIconPath ($itemRoot+"DLC_UI_SuspensionPin_sport_ico.png")
    if($sp){return $sp}
   }
   return (Get-CompanionAssetPath ($itemRoot+"UI_SuspensionPin_ico.png"))
  }
  if($probe -match 'exhaust repair tape'){
   $p=Get-CompanionAssetPath ($itemRoot+"UI_icn_Tape.png")
   if($p){return $p}
   return (Get-CompanionAssetPath "GameUI/Automation/Workers/DIAL_PartsRepairAuto_icn.png")
  }
  if($probe -match 'plate repair kit'){
   $p=Get-CompanionAssetPath ($itemRoot+"NewCarPlates01ICON.png")
   if($p){return $p}
   return (Get-CompanionAssetPath "GameUI/Automation/Workers/DIAL_PartsRepairAuto_icn.png")
  }
  if($probe -match 'cataly'){return (Get-CompanionAssetPath ($itemRoot+"UI_CatalycticConverter_ico.png"))}
  if($probe -match 'manifold|mainfold'){return (Get-CompanionAssetPath ($itemRoot+"UI_mainfold_ico.png"))}
  if($probe -match 'muffler'){return (Get-CompanionAssetPath ($itemRoot+"UI_muffler_ico.png"))}
  if($probe -match 'resonator'){return (Get-CompanionAssetPath ($itemRoot+"UI_resonator_ico.png"))}
  if($probe -match 'tail ?pipe'){return (Get-CompanionAssetPath ($itemRoot+"UI_tailpipe_ico.png"))}
  if($probe -match 'windshield glue'){return (Get-CompanionAssetPath ($itemRoot+"UI_WindshieldGlue_icn.png"))}
  if($probe -match 'windshield'){return (Get-CompanionAssetPath ($itemRoot+"UI_Windshield_icn.png"))}
  if($probe -match 'wheel|rim'){return (Get-CompanionAssetPath ($itemRoot+"UI_Wheel_icn.png"))}

  # Fuse rows: use the genuine per-amperage game artwork directly.
  # Runtime fuse exports are deliberately NOT allowed to override these yet:
  # the exporter created files successfully, but those cached renders proved
  # visually blank in-game. This keeps Parts stable while preserving runtime
  # export diagnostics for later investigation.
  if($group -eq "Fuses" -or $probe -match 'fuse'){
   $m=[regex]::Match($probe,'(?<![0-9])(60|50|40|30|25|20|15|10|5)\s*a(?![0-9])',[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
   if($m.Success){
    $amp=[int]$m.Groups[1].Value
    $f=Get-RuntimeIconPath ($itemRoot+("fuse{0}a.png" -f $amp))
    if($f){return $f}
   }
   $f=Get-CompanionAssetPath "Icons/Parts/all.png";if($f){return $f}
  }

  if($group -eq "Customisation"){
   if($probe -match 'front bumper'){
    $bumper=(Get-CompanionAssetPath "Icons/Parts/Customization/front_bumper.png")
    if($bumper){return $bumper}
   }
   $c=Get-CustomisationIconPath $customGroup
   if($c){return $c}
  }

  # Fallback category icons keep every row visually useful even when the game
  # has no approved individual UI icon in the curated asset library yet.
  switch($group){
   "Engine" {return (Get-CompanionAssetPath "Icons/Parts/all.png")}
   "Brakes" {return (Get-CompanionAssetPath "Icons/Parts/all.png")}
   "Suspension" {return (Get-CompanionAssetPath "Icons/Parts/all.png")}
   "Fuses" {return (Get-CompanionAssetPath "Icons/Parts/all.png")}
   "Other Parts" {return (Get-CompanionAssetPath "Icons/Parts/all.png")}
  }
 }catch{}
 return $null
}

function Format-FittedPartName([string]$key,[string]$partId){
 $probe=((([string]$key)+" "+([string]$partId))).Trim()
 if([string]::IsNullOrWhiteSpace($probe)){return ""}

 $tier=""
 if($probe -match '(?i)racing|race'){$tier="Racing"}
 elseif($probe -match '(?i)sports?|sport'){$tier="Sport"}

 # Prefer the product id for mechanical families. Slot keys often include
 # Front/Rear/L/R placement and can produce unreadable repeated text.
 $base=[string]$partId
 if([string]::IsNullOrWhiteSpace($base)){$base=[string]$key}
 $base=$base -replace "^BlueprintGeneratedClass'",""
 $base=$base -replace "^BP_Product_CarPart_",""
 $base=$base -replace "^BP_Product_",""
 $base=$base -replace "_C'?$",""
 $base=($base -replace '(?i)Sports?|Racing|Race','').Trim('_ ')

 $compact=($base -replace '[^A-Za-z0-9]','')
 switch -Regex ($compact){
  '^BrakeDisc$' {$name='Brake Disc';break}
  '^BrakeClips?$' {$name='Brake Calipers';break}
  '^FrontShockAbsorber$' {$name='Front Shock Absorber';break}
  '^RearShockAbsorber$' {$name='Rear Shock Absorber';break}
  '^SuspensionArmPin$' {$name='Suspension Arm Pin';break}
  '^ExhaustCatalyticConverter$' {$name='Catalytic Converter';break}
  '^ExhaustMainfold$' {$name='Exhaust Manifold';break}
  '^ExhaustManifold$' {$name='Exhaust Manifold';break}
  '^ExhaustMuffler$' {$name='Muffler';break}
  '^ExhaustResonator$' {$name='Resonator';break}
  '^ExhaustTailPipe$' {$name='Tail Pipe';break}
  '^Battery$' {$name='Battery';break}
  '^Intercooler$' {$name='Radiator';break}
  '^Radiator$' {$name='Radiator';break}
  '^Clutch$' {$name='Clutch';break}
  '^Engine$' {$name='Engine';break}
  default {
   $name=$base -replace '_',' '
   $name=$name -replace '([a-z0-9])([A-Z])','$1 $2'
   $name=($name -replace '\s+',' ').Trim()
  }
 }
 if([string]::IsNullOrWhiteSpace($name)){$name='Upgrade'}
 if($tier){return ("{0} {1}" -f $tier,$name).Trim()}
 return $name
}

function Get-FittedMechanicalSummary($item){
 try{
  if($null -eq $item -or $null -eq $item.InstalledParts){return ""}

  # Only upgraded mechanical parts belong in the car-detail summary. Standard
  # parts remain represented by the existing Ready Check percentages.
  $counts=@{}
  foreach($p in @($item.InstalledParts)){
   if($null -eq $p){continue}
   $partId=[string]$p.partId
   if([string]::IsNullOrWhiteSpace($partId)){continue}

   $tier=""
   if($partId -match '(?i)Race|Racing'){$tier="Racing"}
   elseif($partId -match '(?i)Sport'){$tier="Sport"}
   else{continue}

   $baseId=($partId -replace '(?i)Sport','' -replace '(?i)Racing','' -replace '(?i)Race','').Trim()
   $name=$baseId -replace '_',' '
   $name=$name -replace '([a-z0-9])([A-Z])','$1 $2'
   $name=($name -replace '\s+',' ').Trim()

   # Match the friendly names already used by the Parts page.
   switch -Regex ($baseId){
    '^BrakeDisc$' {$name='Brake Disc';break}
    '^BrakeClips$' {$name='Brake Calipers';break}
    '^FrontShockAbsorber$' {$name='Front Shock Absorber';break}
    '^RearShockAbsorber$' {$name='Rear Shock Absorber';break}
    '^SuspensionArmPin$' {$name='Suspension Arm Pin';break}
    '^ExhaustCatalyticConverter$' {$name='Catalytic Converter';break}
    '^ExhaustMainfold$' {$name='Exhaust Manifold';break}
    '^ExhaustMuffler$' {$name='Muffler';break}
    '^ExhaustResonator$' {$name='Resonator';break}
    '^ExhaustTailPipe$' {$name='Tail Pipe';break}
   }

   $label=("{0} {1}" -f $tier,$name).Trim()
   if($counts.ContainsKey($label)){$counts[$label]++}else{$counts[$label]=1}
  }

  if($counts.Count -eq 0){return ""}
  $labels=@()
  foreach($label in @($counts.Keys | Sort-Object)){
   $count=[int]$counts[$label]
   if($count -gt 1){$labels+=("{0} x{1}" -f $label,$count)}else{$labels+=$label}
  }
  return ($labels -join ", ")
 }catch{return ""}
}


function Get-CarModificationInfo($item){
 $sport=0;$racing=0;$custom=0;$labelCounts=@{}
 try{
  foreach($p in @($item.installedParts)){
   if($null -eq $p){continue}
   $partId=[string]$p.partId;$key=[string]$p.key
   $probe=(($key+" "+$partId)).Trim()
   if([string]::IsNullOrWhiteSpace($probe)){continue}
   $friendly=Format-FittedPartName $key $partId
   $isMod=$false
   if($probe -match '(?i)racing|race'){$racing++;$isMod=$true}
   elseif($probe -match '(?i)sports?|sport'){$sport++;$isMod=$true}
   else{
    $cg=Get-CustomisationGroup $probe
    if([string]::IsNullOrWhiteSpace($cg)){$cg=Get-CustomisationGroup $friendly}
    if(-not [string]::IsNullOrWhiteSpace($cg)){$custom++;$isMod=$true}
   }
   if($isMod){
    $label=if([string]::IsNullOrWhiteSpace($friendly)){$probe}else{$friendly}
    if($labelCounts.ContainsKey($label)){$labelCounts[$label]++}else{$labelCounts[$label]=1}
   }
  }
 }catch{}
 $labels=@()
 foreach($label in @($labelCounts.Keys | Sort-Object)){
  $count=[int]$labelCounts[$label]
  if($count -gt 1){$labels+=("{0} x{1}" -f $label,$count)}else{$labels+=$label}
 }
 $badges=@();if($sport -gt 0){$badges+=("SPORT {0}" -f $sport)};if($racing -gt 0){$badges+=("RACING {0}" -f $racing)};if($custom -gt 0){$badges+=("CUSTOM {0}" -f $custom)}
 [pscustomobject]@{Sport=$sport;Racing=$racing;Custom=$custom;Total=($sport+$racing+$custom);Badges=($badges -join '  |  ');Summary=($labels -join ', ')}
}

function Group-For([string]$name,[string]$type){
 if($null -eq $name){$name=""}
 if($null -eq $type){$type=""}
 $n=$name.ToLowerInvariant()
 $t=$type.ToLowerInvariant()

 # DLC TUNING / CUSTOMISATION - keep this stock under Parts, but separate
 # from mechanical categories. The names follow the game's tuning catalogue.
 $customGroup=Get-CustomisationGroup $name
 if(-not [string]::IsNullOrWhiteSpace($customGroup)){return "Customisation"}

 # FUSES
 if($n -match "fuse|relay"){return "Fuses"}

 # ENGINE / DRIVETRAIN / COOLING / SERVICE PARTS
 if($n -match "engine|piston|crank|crankshaft|cam|camshaft|timing|clutch|flywheel|gearbox|transmission|intercooler|radiator|turbo|supercharger|alternator|starter|oil filter|air filter|fuel filter|spark plug|glow plug|water pump|fuel pump|oil pump|belt|serpentine|tensioner|pulley|injector|carburetor|throttle|intake|cylinder|head gasket|valve|rocker|connecting rod|bearing|ecu|engine control"){return "Engine"}

 # BRAKES
 if($n -match "brake|caliper|disc|rotor|pad|drum|master cylinder|brake hose|brake line"){return "Brakes"}

 # SUSPENSION / STEERING
 if($n -match "shock|suspension|spring|control arm|arm pin|tie rod|strut|stabilizer|sway bar|ball joint|steering rack|steering rod|knuckle|hub bearing|wheel bearing"){return "Suspension"}

 # EXHAUST
 if($n -match "exhaust|catalytic|catalyst|muffler|silencer|downpipe|exhaust manifold|resonator|tailpipe"){return "Exhaust"}

 # CLEAR NON-CAR INVENTORY
 # Safes can arrive with a generic display name but a Safe/Storage/Container
 # type. Classify these before the broad car-part fallback so they are never
 # counted by the reader and then hidden from the Inventory lists.
 if($n -match "candy|cigarette|safe|container|storage box|crate|trophy|lockpick|snack|drink|food|chocolate|soda|cola|water bottle|cash box"){return "Others"}
 if($t -match "safe|strongbox|vault|valuable|treasure|container|storage|consumable|lock|decorable|other"){return "Others"}

 # OTHER CAR PARTS:
 # batteries, glass/windscreens, wheels/tyres, lights, mirrors, doors,
 # bonnet/hood, boot/trunk, bumpers, fenders, panels, seats, interior etc.
 if($n -match "battery|windshield|windscreen|window|glass|wheel|tyre|tire|rim|mirror|headlight|tail light|taillight|lamp|bulb|door|hood|bonnet|boot lid|trunk lid|bumper|fender|wing|quarter panel|panel|grille|grill|seat|steering wheel|dashboard|dash|wiper|washer|license plate|number plate|plate kit|repair kit|horn|airbag|fuel tank|fuel cap|door handle"){return "Other Parts"}

 if($t -match "car part|component"){return "Other Parts"}

 return "Others"
}

function Inventory-Group-For([string]$name,[string]$type){
 if($null -eq $name){$name=""}
 if($null -eq $type){$type=""}
 $n=$name.ToLowerInvariant()
 $t=$type.ToLowerInvariant()

 # Safes, valuables and task/loot objects players commonly need to check quickly.
 if($n -match "safe|jewel|jewelry|jewellery|gold|silver|diamond|valuable|watch|necklace|bracelet|ring|cash box|cashbox|money box|antique|painting|artwork|trophy|collectible|collectable"){
  return "Valuables"
 }
 if($t -match "safe|strongbox|vault|valuable|treasure"){return "Valuables"}

 # Electronics and communications loot.
 if($n -match "ephon|ephon|ephone|flip-phone|flip phone|smartphone|cellphone|mobile phone|walkie|cb radio|electronic device"){return "Electronics"}
 if($t -match "electronic|phone|radio"){return "Electronics"}

 # Tools and lockpicking equipment.
 if($n -match "lockpick|screwdriver|impact drill|\bdrill\b|\btool\b"){return "Tools"}
 if($t -match "tool|lockpick"){return "Tools"}

 # Music and physical media.
 if($n -match "guitar|musical|vinyl|record|\bcd\b|dvd"){return "Media"}
 if($t -match "music|media|vinyl|record"){return "Media"}

 # Furniture/decor becomes increasingly useful later in the game.
 if($n -match "sofa|couch|chair|armchair|stool|table|desk|cabinet|cupboard|wardrobe|dresser|drawer|bookcase|bookshelf|shelf|bed|nightstand|night stand|lamp|rug|carpet|vase|plant|furniture|ottoman|bench|tv stand|television stand|coffee table|dining table"){
  return "Furniture"
 }
 if($t -match "furniture|decor|decorable"){return "Furniture"}

 # Food/drink/smoking and other consumables.
 if($n -match "candy|cigarette|snack|drink|food|chocolate|soda|cola|water bottle|coffee|energy drink|juice|beer|can of|bottle of"){
  return "Consumables"
 }
 if($t -match "consumable|food|drink"){return "Consumables"}

 # General containers that are not car storage/components.
 if($n -match "container|storage box|crate|box|case|basket|bin|bag|sack|chest"){
  return "Containers"
 }
 if($t -match "container|storage"){return "Containers"}

 return "Other"
}

$script:seen=$false;$script:gone=$null
function Game-Running{
 return $null -ne (Get-Process -ErrorAction SilentlyContinue | Where-Object {$_.ProcessName -like "CarDealerSimulator*" -or $_.ProcessName -like "CarDealerSim*"} | Select-Object -First 1)
}
function Normalize-Key([string]$name){
 if($null -eq $name){return ""}
 return (($name.ToLowerInvariant()) -replace '[^a-z0-9]','')
}

function Format-BusinessMoney($value){
 if($null -eq $value){return "-"}
 try{return ('$' + ('{0:N0}' -f [double]$value))}catch{return "-"}
}


function Normalize-ContractToken([string]$s){
 if([string]::IsNullOrWhiteSpace($s)){return ""}
 return (($s.ToLowerInvariant()) -replace '[^a-z0-9]','')
}

function Get-ContractInventoryMap{
 $map=@{}
 foreach($path in @($json,$storageJson)){
  if(-not $path -or -not (Test-Path -LiteralPath $path)){continue}
  try{
   $d=(Get-Content -LiteralPath $path -Raw)|ConvertFrom-Json
   foreach($i in @($d.items)){
    $name=[string]$i.name
    if([string]::IsNullOrWhiteSpace($name)){$name=[string]$i.itemId}
    if([string]::IsNullOrWhiteSpace($name)){$name=[string]$i.id}
    $key=Normalize-ContractToken $name
    if(-not $key){continue}
    $qty=0
    foreach($p in @("qty","quantity","count","total")){
     if($i.PSObject.Properties.Name -contains $p){try{$qty=[int]$i.$p}catch{};break}
    }
    if($map.ContainsKey($key)){$map[$key]+=$qty}else{$map[$key]=$qty}
   }
  }catch{}
 }
 foreach($car in @(Get-ContractCars)){
  foreach($t in @($car.trunk)){
   if($null -eq $t){continue}
   $name=""
   foreach($p in @("name","itemName","itemId","id","partId")){
    if($t.PSObject.Properties.Name -contains $p -and -not [string]::IsNullOrWhiteSpace([string]$t.$p)){
     $name=[string]$t.$p;break
    }
   }
   $key=Normalize-ContractToken $name
   if(-not $key){continue}
   $qty=1
   foreach($p in @("qty","quantity","count")){
    if($t.PSObject.Properties.Name -contains $p){try{$qty=[int]$t.$p}catch{};break}
   }
   if($map.ContainsKey($key)){$map[$key]+=$qty}else{$map[$key]=$qty}
  }
 }
 return $map
}

function Get-ContractCars{
 if(-not (Test-Path $carsJson)){return @()}
 try{
  $d=(Get-Content $carsJson -Raw)|ConvertFrom-Json
  if($d.connected){return @($d.cars | Where-Object {-not $_.isUtility})}
 }catch{}
 return @()
}

function Get-TaskRequirement([string]$text){
 $o=[ordered]@{Model="";Color="";MinMechanical=$null;PerfectVisual=$false;Customization=@()}
 if([string]::IsNullOrWhiteSpace($text)){return [pscustomobject]$o}
 if($text -match '(?im)^\s*Model:\s*(.+?)\s*$'){$o.Model=$Matches[1].Trim()}
 if($text -match '(?im)^\s*Color:\s*(.+?)\s*$'){$o.Color=$Matches[1].Trim()}
 if($text -match '(?im)Technical Condition:.*?min\.\s*(\d+(?:\.\d+)?)%'){$o.MinMechanical=([double]$Matches[1])/100.0}
 if($text -match '(?i)Perfect visual condition'){$o.PerfectVisual=$true}
 if($text -match '(?im)^\s*Customi[sz]ation(?:s)?:\s*(.+?)\s*$'){
  $o.Customization=@($Matches[1] -split '[,;|]' | ForEach-Object {$_.Trim()} | Where-Object {$_})
 }
 return [pscustomobject]$o
}

function Test-CarModelMatch($car,[string]$model){
 $want=Normalize-ContractToken $model
 $have=Normalize-ContractToken ([string]$car.model)
 if(-not $want -or -not $have){return $false}
 return ($have -eq $want -or $have.EndsWith($want) -or $want.EndsWith($have))
}

function Test-EnumLikeMatch([string]$a,[string]$b){
 $aa=Normalize-ContractToken $a;$bb=Normalize-ContractToken $b
 if(-not $aa -or -not $bb){return $false}
 return ($aa -eq $bb -or $aa.EndsWith($bb) -or $bb.EndsWith($aa))
}


function Get-VehiclePaintColorName($value){
 $raw=[string]$value
 if([string]::IsNullOrWhiteSpace($raw)){return ""}

 $names=@(
  "Black","Silver","Red","Blue","Purple","NavyBlue","White","Gray","Gold","Green",
  "Brown","Orange","Yellow","Graphite","Light-Blue","Light-Green",
  "SUPER-SILVER","SUPER-GOLD","SUPER-DIAMOND","Custom"
 )

 $n=0
 if([int]::TryParse($raw,[ref]$n)){
  if($n -ge 0 -and $n -lt $names.Count){return $names[$n]}
 }

 if($raw -match 'NewEnumerator(\d+)'){
  $enumKey=[int]$Matches[1]
  $enumNameMap=@{
   0="Black";1="Silver";2="Red";3="Blue";4="Purple";5="NavyBlue";
   7="White";8="Gray";9="Gold";10="Green";11="Brown";12="Orange";
   13="Yellow";14="Graphite";15="Light-Blue";16="Light-Green";
   17="SUPER-SILVER";18="SUPER-GOLD";19="SUPER-DIAMOND";20="Custom"
  }
  if($enumNameMap.ContainsKey($enumKey)){return [string]$enumNameMap[$enumKey]}
 }

 return $raw
}

function Get-DealerOrderAssessment($event,$cars,$inventoryMap){
 $taskText=(@($event.tasks | ForEach-Object {[string]$_.taskText}) -join "`n")
 $req=Get-TaskRequirement $taskText
 $result=[ordered]@{
  Model=$req.Model;Color=$req.Color;Status="MISSING";StatusText="No matching car";Car=$null
  NeedsRepair=$false;NeedsRespray=$false;NeedsVisual=$false;NeedBuy=@()
 }

 $candidates=@($cars | Where-Object {Test-CarModelMatch $_ $req.Model})
 if($candidates.Count -gt 0){
  $scored=@()
  foreach($c in $candidates){
   $repair=$false;$respray=$false;$visual=$false
   if($null -ne $req.MinMechanical -and $null -ne $c.mechanicalCondition){
    $repair=([double]$c.mechanicalCondition -lt [double]$req.MinMechanical)
   }
   if(-not [string]::IsNullOrWhiteSpace($req.Color)){
    $respray= -not (Test-EnumLikeMatch (Get-VehiclePaintColorName $c.color) (Get-VehiclePaintColorName $req.Color))
   }
   if($req.PerfectVisual){
    $rust=0.0;$dirt=0.0
    try{$rust=[double]$c.currentRustValue}catch{}
    try{$dirt=[double]$c.currentDirtValue}catch{}
    $visual=($rust -gt 0.01 -or $dirt -gt 0.01)
   }
   $score=0;if($repair){$score+=4};if($respray){$score+=2};if($visual){$score+=1}
   $scored += [pscustomobject]@{Car=$c;Repair=$repair;Respray=$respray;Visual=$visual;Score=$score}
  }
  $best=$scored | Sort-Object Score | Select-Object -First 1
  $result.Car=$best.Car;$result.NeedsRepair=$best.Repair;$result.NeedsRespray=$best.Respray;$result.NeedsVisual=$best.Visual

  $actions=New-Object System.Collections.Generic.List[string]
  if($best.Repair){[void]$actions.Add("needs repair")}
  if($best.Respray){[void]$actions.Add(("needs respray to {0}" -f $req.Color))}
  if($best.Visual){[void]$actions.Add("needs visual work")}
  if($actions.Count -eq 0){$result.Status="READY";$result.StatusText="Have car - ready"}
  else{$result.Status="PREP";$result.StatusText=("Have car - " + ($actions -join ", "))}
 }

 foreach($part in @($req.Customization)){
  $key=Normalize-ContractToken $part;$have=0
  foreach($ik in @($inventoryMap.Keys)){
   if($ik -eq $key -or $ik.Contains($key) -or $key.Contains($ik)){$have=[int]$inventoryMap[$ik];break}
  }
  if($have -le 0){$result.NeedBuy += $part}
 }
 if($result.NeedBuy.Count -gt 0){
  if($result.Status -eq "READY"){$result.Status="PREP"}
  $result.StatusText += (" | need to buy: " + ($result.NeedBuy -join ", "))
 }
 return [pscustomobject]$result
}

$script:PawnModelNames=@{0="Striker";1="Vanguard";2="600C";3="Thunder";4="Boulder";5="Canyon";6="Andante";7="Largo";8="Allegretto";9="Pulse";10="Journey";11="P3";12="P4";13="Truck";14="280G";15="Gale";16="Cortega";17="Voyager";18="P2";19="Ignis";20="Ridge";21="ThunderX";22="Truck+";23="Outrider";24="800C";25="700R";26="Trail";27="Transporter";28="Ascend";29="Ventus";30="AscendL";31="Highrunner";32="Summit";33="Nova";34="Highland";35="Rapid";36="Horizon";37="Tempest";38="Ravager";39="350S";40="Vesper"}
$script:PawnBrandNames=@{0="Apex Motors";1="UMX";2="Off Rider";3="Phantom";4="Harmonia Vehicles";5="NGD";6="Zen Motors";7="Cargo Wise";8="Tow";9="Cavallaro";10="Ardena";11="Aurora";12="Car"}

function Get-PawnModelName($value){
 $n=0
 if([int]::TryParse(([string]$value),[ref]$n)){if($script:PawnModelNames.ContainsKey($n)){return [string]$script:PawnModelNames[$n]}}
 return [string]$value
}

function Get-PawnBrandName($value){
 $n=0
 if([int]::TryParse(([string]$value),[ref]$n)){if($script:PawnBrandNames.ContainsKey($n)){return [string]$script:PawnBrandNames[$n]}}
 return [string]$value
}

function Test-PawnBrand($car,[string]$brandRaw){
 if([string]::IsNullOrWhiteSpace($brandRaw)){return $true}
 $brand=Normalize-ContractToken (Get-PawnBrandName $brandRaw)
 $model=Normalize-ContractToken ([string]$car.model)
 if(-not $brand -or -not $model){return $false}
 return $model.StartsWith($brand)
}

function Get-ContractCarLocation($car){
 if($null -eq $car){return ""}
 $loc=""
 try{$loc=([string]$car.location).Trim()}catch{}
 if([string]::IsNullOrWhiteSpace($loc)){try{$loc=([string]$car.locationSource).Trim()}catch{}}
 if([string]::IsNullOrWhiteSpace($loc)){return ""}
 # For-sale cars are easy to find on the forecourt/showroom. Keep the useful
 # For Sale flag, but remove the reader's unhelpful "area unknown" wording.
 if($loc -match '(?i)^For Sale(?:\s*-\s*area unknown)?$'){return "For Sale"}
 return $loc
}

function Get-ContractLocationSuffix($car){
 $loc=Get-ContractCarLocation $car
 if([string]::IsNullOrWhiteSpace($loc)){return ""}
 if($loc -eq "For Sale"){return " | For Sale"}
 return (" | Location: " + $loc)
}
function Get-PawnRequestAssessment($p,$cars,$inventoryMap){
 $lines=New-Object System.Collections.Generic.List[string]
 $status='CHECK'
 $type=0
 try{$type=[int]$p.typeRaw}catch{}

 if($type -eq 1){
  foreach($c in @($p.conditions)){
   if([string]::IsNullOrWhiteSpace([string]$c.itemId)){continue}
   $want=0;try{$want=[int]$c.requiredQuantity}catch{}
   $key=Normalize-ContractToken ([string]$c.itemId)
   $have=0;$found=$false
   foreach($ik in @($inventoryMap.Keys)){if($ik -eq $key -or $ik.Contains($key) -or $key.Contains($ik)){$have=[int]$inventoryMap[$ik];$found=$true;break}}
   if($found){if($have -ge $want){$status='READY';[void]$lines.Add(("{0}: {1}/{2} owned - READY" -f $c.itemId,$have,$want))}else{$status='MISSING';[void]$lines.Add(("{0}: {1}/{2} owned" -f $c.itemId,$have,$want))}}
   else{$status='CHECK';[void]$lines.Add(("{0}: inventory source cannot verify this item" -f $c.itemId))}
  }
  return [pscustomobject]@{Status=$status;Lines=$lines}
 }

 $modelRaw='';$brandRaw='';$colorRaw='';$rustRaw='';$minTech=$null;$minYear=$null;$maxYear=$null;$needGoodTires=$false
 foreach($c in @($p.conditions)){
  $cid=[string]$c.conditionId;$cls=[string]$c.className
  if(($cid -eq 'Model' -or $cls -match 'CarQC_Model_C') -and -not [string]::IsNullOrWhiteSpace([string]$c.modelRaw)){$modelRaw=[string]$c.modelRaw}
  if(-not [string]::IsNullOrWhiteSpace([string]$c.brandRaw)){$brandRaw=[string]$c.brandRaw}
  if(-not [string]::IsNullOrWhiteSpace([string]$c.colorRaw)){$colorRaw=[string]$c.colorRaw}
  if(-not [string]::IsNullOrWhiteSpace([string]$c.rustStateRaw)){$rustRaw=[string]$c.rustStateRaw}
  if($null -ne $c.minTechnicalCondition -and [string]$c.minTechnicalCondition -ne ''){try{$minTech=[double]$c.minTechnicalCondition}catch{}}
  if($cid -eq 'ProductionYear' -or $cls -match 'CarQC_ProductionYearRange_C'){if($null -ne $c.minProductionYear -and [string]$c.minProductionYear -ne ''){try{$minYear=[int]$c.minProductionYear}catch{}};if($null -ne $c.maxProductionYear -and [string]$c.maxProductionYear -ne ''){try{$maxYear=[int]$c.maxProductionYear}catch{}}}
  if($cid -eq 'TirePressures' -or $cls -match 'CarQC_TirePressures_C'){$needGoodTires=$true}
 }

 if($modelRaw){[void]$lines.Add(("Model: {0}" -f (Get-PawnModelName $modelRaw)))}
 if($brandRaw){[void]$lines.Add(("Brand: {0}" -f (Get-PawnBrandName $brandRaw)))}
 if($colorRaw){[void]$lines.Add(("Colour: {0}" -f (Get-VehiclePaintColorName $colorRaw)))}
 if($rustRaw){[void]$lines.Add("Rusty")}
 if($null -ne $minYear -and $null -ne $maxYear){[void]$lines.Add(("Production Year: {0}-{1}" -f $minYear,$maxYear))}
 if($needGoodTires){[void]$lines.Add("Good Tire Pressure")}
 if($null -ne $minTech){[void]$lines.Add(("Condition: {0:N0}%+" -f ($minTech*100)))}

 $matches=@()
 foreach($car in @($cars)){
  $ok=$true
  if($modelRaw){try{$ok=$ok -and ([int]$car.modelId -eq [int]$modelRaw)}catch{$ok=$false}}
  if($brandRaw){$ok=$ok -and (Test-PawnBrand $car $brandRaw)}
  if($colorRaw){$ok=$ok -and (Test-EnumLikeMatch (Get-VehiclePaintColorName $car.color) (Get-VehiclePaintColorName $colorRaw))}
  if($null -ne $minYear){try{$ok=$ok -and ([int]$car.year -ge $minYear)}catch{$ok=$false}}
  if($null -ne $maxYear){try{$ok=$ok -and ([int]$car.year -le $maxYear)}catch{$ok=$false}}
  if($ok){$matches += $car}
 }

 if($matches.Count -eq 0){
  $partial=$null;if($brandRaw){$partial=@($cars | Where-Object { Test-PawnBrand $_ $brandRaw } | Select-Object -First 1)[0]}
  if($null -ne $partial){[void]$lines.Add(("Brand: {0} - HAVE" -f (Get-PawnBrandName $brandRaw)));if($null -ne $minYear -and $null -ne $maxYear){[void]$lines.Add(("Year: {0} / Required {1}-{2} - MISSING" -f $partial.year,$minYear,$maxYear))};if($needGoodTires){[void]$lines.Add("Good Tire Pressure - CHECK")};[void]$lines.Add(("Owned car: {0}{1}" -f $partial.model,(Get-ContractLocationSuffix $partial)))}else{[void]$lines.Add('Owned car match: none')}
  return [pscustomobject]@{Status='MISSING';Lines=$lines}
 }
 $best=$matches | Select-Object -First 1
 $mech='-';try{$mech=("{0:N0}%" -f ([double]$best.mechanicalCondition*100))}catch{}
 $carLoc=Get-ContractCarLocation $best
 [void]$lines.Add(("Owned car match: {0} | {1} | Mechanical {2}{3}" -f $best.model,(Get-VehiclePaintColorName $best.color),$mech,(Get-ContractLocationSuffix $best)))
 if($null -ne $minTech -and [double]$best.mechanicalCondition -lt $minTech){$status='PREP'}elseif($rustRaw){$status='CHECK'}else{$status='READY'}
 return [pscustomobject]@{Status=$status;Lines=$lines}
}

function Get-B2BAssessment($b2b,$cars){
 $reqs=@($b2b.requirements);$used=@{}
 $matched=0;$resprays=0;$repairs=0;$missing=0
 # Plain PowerShell array: avoids the Windows PowerShell 5.1 generic-list
 # binder failure ("Argument types do not match") during PSCustomObject return.
 $slots=@()

 for($ri=0;$ri -lt $reqs.Count;$ri++){
  $r=$reqs[$ri];$candidates=@()
  for($ci=0;$ci -lt $cars.Count;$ci++){
   if($used.ContainsKey($ci)){continue}
   $c=$cars[$ci];$bodyOk=$false
   if(-not [string]::IsNullOrWhiteSpace([string]$r.bodyType)){$bodyOk=Test-EnumLikeMatch ([string]$c.bodyType) ([string]$r.bodyType)}
   if(-not $bodyOk -and -not [string]::IsNullOrWhiteSpace([string]$r.vehicleTypeRaw)){$bodyOk=Test-EnumLikeMatch ([string]$c.bodyTypeId) ([string]$r.vehicleTypeRaw)}
   $brandOk=$true
   if([bool]$r.requiresBrand -and -not [string]::IsNullOrWhiteSpace([string]$r.requiredBrandRaw)){$brandOk=Test-PawnBrand $c ([string]$r.requiredBrandRaw)}
   if($bodyOk -and $brandOk){$candidates += [pscustomobject]@{Index=$ci;Car=$c}}
  }

  $bits=New-Object System.Collections.Generic.List[string]
  if(-not [string]::IsNullOrWhiteSpace([string]$r.bodyType)){[void]$bits.Add([string]$r.bodyType)}
  elseif(-not [string]::IsNullOrWhiteSpace([string]$r.vehicleTypeRaw)){[void]$bits.Add(("Type {0}" -f $r.vehicleTypeRaw))}
  if([bool]$r.requiresBrand -and -not [string]::IsNullOrWhiteSpace([string]$r.requiredBrandRaw)){[void]$bits.Add((Get-PawnBrandName $r.requiredBrandRaw))}
  if(-not [string]::IsNullOrWhiteSpace([string]$r.requiredColorRaw)){[void]$bits.Add((Get-VehiclePaintColorName $r.requiredColorRaw))}
  if($bits.Count -eq 0){[void]$bits.Add("Vehicle")}
  $label=($bits -join " | ")

  if($candidates.Count -eq 0){
   $missing++
   $slots += [pscustomobject]@{Index=($ri+1);Label=$label;Status="MISSING";Detail="Need to buy / obtain";Car=$null}
   continue
  }

  $scored=@()
  foreach($x in $candidates){
   $c=$x.Car;$needsRespray=$false;$needsRepair=$false
   if(-not [string]::IsNullOrWhiteSpace([string]$r.requiredColorRaw)){$needsRespray= -not (Test-EnumLikeMatch (Get-VehiclePaintColorName $c.color) (Get-VehiclePaintColorName $r.requiredColorRaw))}
   $minMech=$null
   try{$minMech=[double]$r.minMechCondition}catch{}
   if($null -eq $minMech -or $minMech -le 0){try{$minMech=[double]$b2b.minMechCondition}catch{}}
   if($null -ne $minMech -and $minMech -gt 0 -and $null -ne $c.mechanicalCondition){$needsRepair=([double]$c.mechanicalCondition -lt $minMech)}
   $score=0;if($needsRepair){$score+=2};if($needsRespray){$score+=1}
   $scored += [pscustomobject]@{Index=$x.Index;Car=$c;Repair=$needsRepair;Respray=$needsRespray;Score=$score}
  }

  $best=$scored | Sort-Object Score | Select-Object -First 1
  $used[$best.Index]=$true;$matched++
  if($best.Respray){$resprays++};if($best.Repair){$repairs++}

  $actions=New-Object System.Collections.Generic.List[string]
  if($best.Repair){[void]$actions.Add("repair")}
  if($best.Respray){[void]$actions.Add(("respray to {0}" -f (Get-VehiclePaintColorName $r.requiredColorRaw)))}

  $slotLocation=Get-ContractCarLocation $best.Car
  if($actions.Count -eq 0){
   $slots += [pscustomobject]@{Index=($ri+1);Label=$label;Status="READY";Detail=("Have - ready" + (Get-ContractLocationSuffix $best.Car));Car=$best.Car}
  }else{
   $slots += [pscustomobject]@{Index=($ri+1);Label=$label;Status="PREP";Detail=("Have - needs " + ($actions -join " + ") + (Get-ContractLocationSuffix $best.Car));Car=$best.Car}
  }
 }

 $status="READY"
 if($missing -gt 0){$status="MISSING"}elseif($resprays -gt 0 -or $repairs -gt 0){$status="PREP"}

 return [pscustomobject]@{
  Required=$reqs.Count;Matched=$matched;Resprays=$resprays;Repairs=$repairs;Missing=$missing;Status=$status;Slots=$slots
 }
}

function Get-WholesaleRequirementLines($contractData){
 $lines=New-Object System.Collections.Generic.List[string]
 $slot=0
 foreach($r in @($contractData.requirements)){
  $slot++
  $bits=New-Object System.Collections.Generic.List[string]
  if(-not [string]::IsNullOrWhiteSpace([string]$r.bodyType)){[void]$bits.Add([string]$r.bodyType)}
  elseif(-not [string]::IsNullOrWhiteSpace([string]$r.vehicleTypeRaw)){[void]$bits.Add(("Type {0}" -f $r.vehicleTypeRaw))}
  if([bool]$r.requiresBrand -and -not [string]::IsNullOrWhiteSpace([string]$r.requiredBrandRaw)){[void]$bits.Add((Get-PawnBrandName $r.requiredBrandRaw))}
  if(-not [string]::IsNullOrWhiteSpace([string]$r.requiredColorRaw)){[void]$bits.Add((Get-VehiclePaintColorName $r.requiredColorRaw))}
  if($bits.Count -eq 0){[void]$bits.Add("Vehicle")}
  [void]$lines.Add(("#{0}: {1}" -f $slot,($bits -join " | ")))
 }
 return @($lines)
}

function Set-WholesaleSlotDisplay($textBlock,$assessment){
 if($null -eq $textBlock){return}
 $textBlock.Inlines.Clear()

 $head=New-Object System.Windows.Documents.Run
 $head.Text=("Cars: {0}/{1} available`n" -f $assessment.Matched,$assessment.Required)
 $head.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#AEB8C3")
 [void]$textBlock.Inlines.Add($head)

 if($assessment.Resprays -gt 0 -or $assessment.Repairs -gt 0 -or $assessment.Missing -gt 0){
  $sum=New-Object System.Windows.Documents.Run
  $parts=New-Object System.Collections.Generic.List[string]
  if($assessment.Resprays -gt 0){[void]$parts.Add(("{0} respray" -f $assessment.Resprays))}
  if($assessment.Repairs -gt 0){[void]$parts.Add(("{0} repair" -f $assessment.Repairs))}
  if($assessment.Missing -gt 0){[void]$parts.Add(("{0} missing" -f $assessment.Missing))}
  $sum.Text=(($parts -join "  •  ")+"`n`n")
  $sum.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#9EABB7")
  [void]$textBlock.Inlines.Add($sum)
 }else{
  $blank=New-Object System.Windows.Documents.Run;$blank.Text="`n";[void]$textBlock.Inlines.Add($blank)
 }

 $title=New-Object System.Windows.Documents.Run
 $title.Text="Requested cars:`n"
 $title.FontWeight="Bold"
 $title.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFF3E3")
 [void]$textBlock.Inlines.Add($title)

 foreach($slot in @($assessment.Slots)){
  $brush="#E2E8EE";$mark="•"
  if($slot.Status -eq "READY"){$brush="#67D56A";$mark="●"}
  elseif($slot.Status -eq "PREP"){$brush="#E39A2D";$mark="●"}
  elseif($slot.Status -eq "MISSING"){$brush="#F06A5F";$mark="●"}

  $run=New-Object System.Windows.Documents.Run
  $run.Text=("{0} #{1}: {2}  —  {3}`n" -f $mark,$slot.Index,$slot.Label,$slot.Detail)
  $run.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString($brush)
  if($slot.Status -eq "READY"){$run.FontWeight="SemiBold"}
  [void]$textBlock.Inlines.Add($run)
 }
}

function Format-ContractRemaining($seconds){
 try{$s=[int][math]::Max(0,[math]::Floor([double]$seconds))}catch{return $null}
 $days=[int][math]::Floor($s/86400);$s=$s%86400
 $hours=[int][math]::Floor($s/3600);$s=$s%3600
 $mins=[int][math]::Floor($s/60)
 if($days -gt 0){return ("{0}d {1:D2}h {2:D2}m left" -f $days,$hours,$mins)}
 if($hours -gt 0){return ("{0}h {1:D2}m left" -f $hours,$mins)}
 return ("{0}m left" -f $mins)
}

function Format-PawnRefreshCountdown($seconds){
 try{$s=[int][math]::Max(0,[math]::Floor([double]$seconds))}catch{return "Waiting for game refresh time"}
 $days=[int][math]::Floor($s/86400);$s=$s%86400
 $hours=[int][math]::Floor($s/3600);$s=$s%3600
 $mins=[int][math]::Floor($s/60)
 if($days -gt 0){return ("{0}d {1:D2}h {2:D2}m" -f $days,$hours,$mins)}
 if($hours -gt 0){return ("{0}h {1:D2}m" -f $hours,$mins)}
 return ("{0}m" -f $mins)
}

function Get-PawnStatusName($raw){
 $s=([string]$raw).Trim().ToLowerInvariant()
 if($s -eq "0" -or $s -match "unaccepted"){return "UNACCEPTED"}
 if($s -eq "1" -or ($s -match "active" -and $s -notmatch "inactive")){return "ACTIVE"}
 if($s -eq "2" -or $s -match "completed"){return "COMPLETED"}
 if($s -eq "3" -or $s -match "failed"){return "FAILED"}
 return ([string]$raw).ToUpperInvariant()
}

function Refresh-ContractsPage{
 if($null -eq $script:contractsB2BName){return}

 $contractSecs=[int]$script:refreshSettings["contracts_seconds"]
 $cadence=if($contractSecs -le 0){"Manual only"}elseif($contractSecs -lt 60){("Every {0} seconds" -f $contractSecs)}elseif(($contractSecs % 60) -eq 0){("Every {0} minute(s)" -f [int]($contractSecs/60))}else{("Every {0} seconds" -f $contractSecs)}
 if($script:contractsRefreshStatus){
  if(Test-Path $contractsJson){
   $last=(Get-Item -LiteralPath $contractsJson -ErrorAction SilentlyContinue).LastWriteTime
   if($last){$script:contractsRefreshStatus.Text=("Refresh: {0}  •  Last data: {1}" -f $cadence,$last.ToString("HH:mm:ss"))}
   else{$script:contractsRefreshStatus.Text=("Refresh: {0}  •  Waiting for live data" -f $cadence)}
  }else{
   $script:contractsRefreshStatus.Text=("Refresh: {0}  •  No contracts data yet" -f $cadence)
  }
 }

 $script:contractsB2BName.Text="No active B2B contract"
 $script:contractsB2BState.Text="NONE"
 $script:contractsB2BCars.Text="-";$script:contractsB2BResprays.Text="-";$script:contractsB2BRepairs.Text="-";$script:contractsB2BMissing.Text="-"
 $script:contractsB2BConditions.Text="Requirements: -"
 $script:contractsB2BDetails.Text="No active B2B vehicle requirements detected."
 $script:contractsDealerContractName.Text="No active Dealer Contract"
 $script:contractsDealerContractState.Text="NONE"
 $script:contractsDealerContractCars.Text="-";$script:contractsDealerContractResprays.Text="-";$script:contractsDealerContractRepairs.Text="-";$script:contractsDealerContractMissing.Text="-"
 $script:contractsDealerContractConditions.Text="Requirements: -"
 $script:contractsDealerContractDetails.Text="No active Dealer Contract vehicle requirements detected."
 $script:contractsPawnText.Text="No Pawn Shop requests detected."
 $script:contractsDealerText.Text="No active customer/email vehicle orders detected."
 $script:contractsMissionText.Text="No other active missions detected."
 if($script:contractsSummaryB2B){$script:contractsSummaryB2B.Text="NONE"}
 if($script:contractsSummaryCars){$script:contractsSummaryCars.Text="-"}
 if($script:contractsSummaryPawn){$script:contractsSummaryPawn.Text="0"}
 if($script:contractsSummaryDealer){$script:contractsSummaryDealer.Text="0"}
 if($dashContractsSummary){$dashContractsSummary.Text="No active contracts detected."}

 if(-not (Test-Path $contractsJson)){return}
 try{$cd=(Get-Content $contractsJson -Raw)|ConvertFrom-Json}catch{return}
 if(-not $cd.connected){return}

 $cars=@(Get-ContractCars);$inventoryMap=Get-ContractInventoryMap

 $tonyUiRep=$null
 try{
  if($null -ne $cd.tonyReputation){$tonyUiRep=[double]$cd.tonyReputation}
  elseif(Test-Path $businessJson){
   $bd=(Get-Content $businessJson -Raw)|ConvertFrom-Json
   if($bd.connected -and $null -ne $bd.tonyReputation){$tonyUiRep=[double]$bd.tonyReputation}
  }
 }catch{}
 if($script:contractsTonyRep){
  if($null -ne $tonyUiRep){$script:contractsTonyRep.Text=("TONY REP  {0:N0}" -f $tonyUiRep)}
  else{$script:contractsTonyRep.Text="TONY REP  -"}
 }
 if($dashTonyRep){
  if($null -ne $tonyUiRep){$dashTonyRep.Text=("Tony Rep: {0:N0}" -f $tonyUiRep)}
  else{$dashTonyRep.Text="Tony Rep: -"}
 }
 if($script:contractsDailyDeal){
  if($null -ne $cd.dailyDeal -and [bool]$cd.dailyDeal.detected){$script:contractsDailyDeal.Text="DEAL OF THE DAY: AVAILABLE"}
  else{$script:contractsDailyDeal.Text="DEAL OF THE DAY: No deal available"}
 }
 if($dashTonyDeal){
  if($null -ne $cd.dailyDeal -and [bool]$cd.dailyDeal.detected){$dashTonyDeal.Text="Deal of the Day: AVAILABLE"}
  else{$dashTonyDeal.Text="Deal of the Day: No deal available"}
 }
 if($dashTonyRequests){
  $reqs=@($cd.pawnRequests)
  $rdy=0;$miss=0;$prep=0
  foreach($rp in $reqs){
   $gs=Get-PawnStatusName $rp.statusRaw
   if($gs -ne "COMPLETED" -and $gs -ne "FAILED"){
    $ra=Get-PawnRequestAssessment $rp $cars $inventoryMap
    if($ra.Status -eq "READY"){$rdy++}elseif($ra.Status -eq "PREP" -or $ra.Status -eq "CHECK"){$prep++}else{$miss++}
   }
  }
  $dashTonyRequests.Text=("Requests: {0} current  •  Ready {1}  •  Missing {2}" -f $reqs.Count,$rdy,$miss)
 }

 $readyCount=0;$prepCount=0;$missingCount=0
 $dashBits=New-Object System.Collections.Generic.List[string]

 if($null -ne $cd.b2b -and @($cd.b2b.requirements).Count -gt 0){
  $b2bRaw=([string]$cd.b2b.statusRaw).Trim()
  if($false -and $b2bRaw -eq "0"){
   # Runtime-proven B2B state: raw 0 while the game shows FULFILLED / waiting for refresh.
   # Do not show the completed contract's old vehicle requirements.
   $script:contractsB2BName.Text="B2B CONTRACT"
   $script:contractsB2BState.Text="FULFILLED"
   $script:contractsB2BCars.Text="-";$script:contractsB2BResprays.Text="-";$script:contractsB2BRepairs.Text="-";$script:contractsB2BMissing.Text="-"
   $script:contractsB2BConditions.Text="New contract pending"
   $script:contractsB2BDetails.Text="Contract fulfilled. Waiting for the next B2B contract."
   if($script:contractsSummaryB2B){$script:contractsSummaryB2B.Text="FULFILLED"}
   if($script:contractsSummaryCars){$script:contractsSummaryCars.Text="-"}
   [void]$dashBits.Add("B2B fulfilled - new contract pending")
  }else{
   # Raw states other than the observed fulfilled state are intentionally not guessed.
   $a=Get-B2BAssessment $cd.b2b $cars
   $script:contractsB2BName.Text="Current B2B Contract";$script:contractsB2BState.Text=$a.Status
   $script:contractsB2BCars.Text=("{0}/{1}" -f $a.Matched,$a.Required)
   $script:contractsB2BResprays.Text=[string]$a.Resprays;$script:contractsB2BRepairs.Text=[string]$a.Repairs;$script:contractsB2BMissing.Text=[string]$a.Missing
   $mech="-";$body="-"
   try{if([double]$cd.b2b.minMechCondition -gt 0){$mech=("{0:N0}%" -f ([double]$cd.b2b.minMechCondition*100))}}catch{}
   try{if([double]$cd.b2b.minBodyCondition -gt 0){$body=("{0:N0}%" -f ([double]$cd.b2b.minBodyCondition*100))}}catch{}
   $conditionBits=New-Object System.Collections.Generic.List[string]
   [void]$conditionBits.Add(("Mechanical: {0}" -f $mech))
   [void]$conditionBits.Add(("Visual / Body: {0}" -f $body))
   [void]$conditionBits.Add(("DLC requirement: {0}" -f ([bool]$cd.b2b.requiresDLCPart)))
   $script:contractsB2BConditions.Text=($conditionBits -join "     ")
   Set-WholesaleSlotDisplay $script:contractsB2BDetails $a
   if($script:contractsSummaryB2B){$script:contractsSummaryB2B.Text=$a.Status}
   if($script:contractsSummaryCars){$script:contractsSummaryCars.Text=("{0}/{1}" -f $a.Matched,$a.Required)}
   [void]$dashBits.Add(("B2B {0}/{1} cars" -f $a.Matched,$a.Required))
   if($a.Resprays -gt 0){[void]$dashBits.Add(("{0} respray(s)" -f $a.Resprays))}
   if($a.Repairs -gt 0){[void]$dashBits.Add(("{0} repair(s)" -f $a.Repairs))}
   if($a.Status -eq "READY"){$readyCount++}elseif($a.Status -eq "PREP"){$prepCount++}else{$missingCount++}
  }
 }

 if($null -ne $cd.dealerContract -and @($cd.dealerContract.requirements).Count -gt 0){
  $da=Get-B2BAssessment $cd.dealerContract $cars
  $dealerRaw=([string]$cd.dealerContract.statusRaw).Trim()
  $dealerState=if($dealerRaw -eq "3"){"ACTIVE"}else{$da.Status}
  $script:contractsDealerContractName.Text="Current Dealer Contract";$script:contractsDealerContractState.Text=$dealerState
  $script:contractsDealerContractCars.Text=("{0}/{1}" -f $da.Matched,$da.Required)
  $script:contractsDealerContractResprays.Text=[string]$da.Resprays
  $script:contractsDealerContractRepairs.Text=[string]$da.Repairs
  $script:contractsDealerContractMissing.Text=[string]$da.Missing
  $dMech="-";$dBody="-"
  try{if([double]$cd.dealerContract.minMechCondition -gt 0){$dMech=("{0:N0}%" -f ([double]$cd.dealerContract.minMechCondition*100))}}catch{}
  try{if([double]$cd.dealerContract.minBodyCondition -gt 0){$dBody=("{0:N0}%" -f ([double]$cd.dealerContract.minBodyCondition*100))}}catch{}
  $dConditionBits=New-Object System.Collections.Generic.List[string]
  [void]$dConditionBits.Add(("Mechanical: {0}" -f $dMech))
  [void]$dConditionBits.Add(("Visual / Body: {0}" -f $dBody))
  [void]$dConditionBits.Add(("DLC requirement: {0}" -f ([bool]$cd.dealerContract.requiresDLCPart)))
  $script:contractsDealerContractConditions.Text=($dConditionBits -join "     ")
  Set-WholesaleSlotDisplay $script:contractsDealerContractDetails $da
  [void]$dashBits.Add(("Dealer {0} - {1}/{2} cars" -f $dealerState,$da.Matched,$da.Required))
  if($da.Resprays -gt 0){[void]$dashBits.Add(("Dealer: {0} respray(s)" -f $da.Resprays))}
  if($da.Repairs -gt 0){[void]$dashBits.Add(("Dealer: {0} repair(s)" -f $da.Repairs))}
  if($da.Status -eq "READY"){$readyCount++}elseif($da.Status -eq "PREP"){$prepCount++}else{$missingCount++}
 }

 $pawnBlocks=@()
 foreach($p in @($cd.pawnRequests)){
  $name=if([string]::IsNullOrWhiteSpace([string]$p.requestName)){"Pawn request"}else{[string]$p.requestName}
  $gameStatus=Get-PawnStatusName $p.statusRaw
  $blockLines=New-Object System.Collections.Generic.List[string]
  if($gameStatus -eq "COMPLETED" -or $gameStatus -eq "FAILED"){
   [void]$blockLines.Add(("{0}  [{1}]" -f $name,$gameStatus))
   if($null -ne $p.secondsUntilRefresh){[void]$blockLines.Add(("  New request in: {0}" -f (Format-PawnRefreshCountdown $p.secondsUntilRefresh)))}else{[void]$blockLines.Add("  Waiting for next Pawn Shop refresh")}
   $pawnBlocks += [pscustomobject]@{Text=($blockLines -join "`n");Status=$gameStatus}
   continue
  }
  $pa=Get-PawnRequestAssessment $p $cars $inventoryMap
  [void]$blockLines.Add(("{0}  [{1}]" -f $name,$pa.Status))
  foreach($x in @($pa.Lines)){[void]$blockLines.Add(("  " + [string]$x))}
  if(-not [string]::IsNullOrWhiteSpace([string]$p.rewardMoney)){[void]$blockLines.Add(("  Reward: {0}   Tony Rep +{1}" -f $p.rewardMoney,$p.rewardReputation))}
  $pawnBlocks += [pscustomobject]@{Text=($blockLines -join "`n");Status=$pa.Status}
  if($pa.Status -eq "READY"){$readyCount++}elseif($pa.Status -eq "PREP" -or $pa.Status -eq "CHECK"){$prepCount++}else{$missingCount++}
 }
 if($pawnBlocks.Count -gt 0){
  $script:contractsPawnText.Inlines.Clear()
  for($pi=0;$pi -lt $pawnBlocks.Count;$pi++){
   $pb=$pawnBlocks[$pi]
   $run=New-Object System.Windows.Documents.Run;$run.Text=[string]$pb.Text
   if([string]$pb.Status -eq "READY"){$run.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#A8FFB0");$run.Background=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#173A20");$run.FontWeight="SemiBold"}
   elseif([string]$pb.Status -eq "MISSING"){$run.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#F4D7D4")}
   else{$run.Foreground=[System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFF3E3")}
   [void]$script:contractsPawnText.Inlines.Add($run)
   if($pi -lt ($pawnBlocks.Count-1)){$gap=New-Object System.Windows.Documents.Run;$gap.Text="`n`n";[void]$script:contractsPawnText.Inlines.Add($gap)}
  }
 }
 if($script:contractsSummaryPawn){$script:contractsSummaryPawn.Text=[string]@($cd.pawnRequests).Count}

 $dealerLines=New-Object System.Collections.Generic.List[string]
 $missionLines=New-Object System.Collections.Generic.List[string]
 $dealerCount=0
 foreach($e in @($cd.events)){
  $allTaskText=(@($e.tasks | ForEach-Object {[string]$_.taskText}) -join "`n")
  $isDealer=([string]$e.eventId -match 'VehicleOrder' -or [string]$e.displayName -match 'Deliver Ordered Vehicle' -or $allTaskText -match 'Deliver car in the following state')
  if($isDealer){
   $dealerCount++;$a=Get-DealerOrderAssessment $e $cars $inventoryMap
   $title=if([string]::IsNullOrWhiteSpace([string]$e.displayName)){"Customer vehicle order"}else{[string]$e.displayName}
   [void]$dealerLines.Add($title)
   if(-not [string]::IsNullOrWhiteSpace($a.Model)){[void]$dealerLines.Add(("  Required: {0}" -f $a.Model))}
   [void]$dealerLines.Add(("  {0}" -f $a.StatusText))
   if($null -ne $a.Car){
    $cond="-";try{$cond=("{0:N0}%" -f ([double]$a.Car.mechanicalCondition*100))}catch{}
    [void]$dealerLines.Add(("  Your car: {0} | Mechanical {1}{2}" -f $a.Car.model,$cond,(Get-ContractLocationSuffix $a.Car)))
   }
   if($a.Status -eq "READY"){$readyCount++}elseif($a.Status -eq "PREP"){$prepCount++}else{$missingCount++}
   [void]$dashBits.Add(("Customer Order: {0}" -f $a.StatusText))
  }else{
   $name=if([string]::IsNullOrWhiteSpace([string]$e.displayName)){[string]$e.eventId}else{[string]$e.displayName}
   if(-not [string]::IsNullOrWhiteSpace($name)){
    [void]$missionLines.Add($name)
    foreach($t in @($e.tasks)){
     if(-not [string]::IsNullOrWhiteSpace([string]$t.taskText)){[void]$missionLines.Add(("  " + ([string]$t.taskText -replace "`r?`n"," | ")))}
    }
   }
  }
 }
 if($dealerLines.Count -gt 0){$script:contractsDealerText.Text=($dealerLines -join "`n")}else{$script:contractsDealerText.Text="No active customer vehicle order."}
 if($missionLines.Count -gt 0){$script:contractsMissionText.Text=($missionLines -join "`n")}else{$script:contractsMissionText.Text="No active missions or tasks."}
 if($script:contractsSummaryDealer){$script:contractsSummaryDealer.Text=[string]$dealerCount}

 if($dashContractsSummary){
  $head=("Ready {0}  •  Preparation {1}  •  Missing/Buy {2}" -f $readyCount,$prepCount,$missingCount)
  if($dashBits.Count -gt 0){$dashContractsSummary.Text=$head+"`n"+($dashBits -join "  •  ")}else{$dashContractsSummary.Text=$head}
 }
}

function Refresh-BusinessDashboard{
 if($null -eq $businessMoney){return}

 if(-not (Test-Path $businessJson)){
  $businessMoney.Text="Money: -"
  $businessLevel.Text="Level: -"
  $businessXP.Text="XP: -"
  $businessReputation.Text="Reputation: -"
  if($null -ne $businessTonyRep){$businessTonyRep.Text="Tony Rep: -"}
  if($null -ne $businessGameDay){$businessGameDay.Text="Game Day: -"}
  if($null -ne $headerReputation){$headerReputation.Text="REPUTATION  -"}
  if($null -ne $headerGameClock){$headerGameClock.Text="DAY -  •  --:--"}
  $businessGameTime.Text="Game Time: -"
  if($null -ne $headerMoney){$headerMoney.Text="MONEY  -"}
  if($null -ne $headerXP){$headerXP.Text="XP  -"}
  return
 }

 try{
  $b=(Get-Content $businessJson -Raw)|ConvertFrom-Json
  if(-not $b.connected){return}

  if($null -ne $b.money){
   $businessMoney.Text=("Money: {0}" -f (Format-BusinessMoney $b.money))
   if($null -ne $headerMoney){$headerMoney.Text=("MONEY  {0}" -f (Format-BusinessMoney $b.money))}
  }else{
   $businessMoney.Text="Money: -"
   if($null -ne $headerMoney){$headerMoney.Text="MONEY  -"}
  }

  if($null -ne $b.reputationLevel){
   $businessLevel.Text=("Level: {0}" -f [int]$b.reputationLevel)
   if($null -ne $headerReputation){$headerReputation.Text=("REPUTATION  LV {0}" -f [int]$b.reputationLevel)}
  }else{
   $businessLevel.Text="Level: -"
   if($null -ne $headerReputation){$headerReputation.Text="REPUTATION  -"}
  }

  if($null -ne $b.reputationExperience){
   $businessXP.Text=("XP: {0:N0}" -f [double]$b.reputationExperience)
   if($null -ne $headerXP){$headerXP.Text=("XP  {0:N0}" -f [double]$b.reputationExperience)}
  }else{
   $businessXP.Text="XP: -"
   if($null -ne $headerXP){$headerXP.Text="XP  -"}
  }

  if($null -ne $b.reputationProgressPercent -and $null -ne $b.needExperienceToNext){
   $nextLevelText=""
   if($null -ne $b.reputationLevel){$nextLevelText=(" to Level {0}" -f ([int]$b.reputationLevel + 1))}
   $businessReputation.Text=("Progress: {0:N1}%  •  {1:N0} XP{2}" -f [double]$b.reputationProgressPercent,[double]$b.needExperienceToNext,$nextLevelText)
  }elseif($null -ne $b.reputationLevel){
   $businessReputation.Text=("Reputation Level: {0}" -f [int]$b.reputationLevel)
  }else{
   $businessReputation.Text="Reputation: -"
  }

  if($null -ne $businessTonyRep){
   if($null -ne $b.tonyReputation){$businessTonyRep.Text=("Tony Rep: {0:N0}" -f [double]$b.tonyReputation)}
   else{$businessTonyRep.Text="Tony Rep: -"}
  }

  if($null -ne $businessGameDay){
   if($null -ne $b.gameDay){$businessGameDay.Text=("Game Day: {0}" -f [int]$b.gameDay)}
   else{$businessGameDay.Text="Game Day: -"}
  }

  if($null -ne $b.gameTime -and -not [string]::IsNullOrWhiteSpace([string]$b.gameTime)){
   $businessGameTime.Text=("Game Time: {0}" -f [string]$b.gameTime)
  }else{
   $businessGameTime.Text="Game Time: -"
  }

  if($null -ne $headerGameClock){
   $dayText="-";$timeText="--:--"
   if($null -ne $b.gameDay){$dayText=[string][int]$b.gameDay}
   if($null -ne $b.gameTime -and -not [string]::IsNullOrWhiteSpace([string]$b.gameTime)){$timeText=[string]$b.gameTime}
   $headerGameClock.Text=("DAY {0}  •  {1}" -f $dayText,$timeText)
  }
 }catch{
  $businessMoney.Text="Money: -"
  $businessLevel.Text="Level: -"
  $businessXP.Text="XP: -"
  $businessReputation.Text="Reputation: -"
  if($null -ne $businessTonyRep){$businessTonyRep.Text="Tony Rep: -"}
  if($null -ne $businessGameDay){$businessGameDay.Text="Game Day: -"}
  if($null -ne $headerReputation){$headerReputation.Text="REPUTATION  -"}
  if($null -ne $headerGameClock){$headerGameClock.Text="DAY -  •  --:--"}
  $businessGameTime.Text="Game Time: -"
  if($null -ne $headerMoney){$headerMoney.Text="MONEY  -"}
  if($null -ne $headerXP){$headerXP.Text="XP  -"}
 }
}

function Update-DashboardVehicleCards{
 try{
  if($null -ne $dashWorkflow -and $null -ne $vehicleTotal){
   $m=[regex]::Match([string]$vehicleTotal.Text,'(\d+)')
   if($m.Success){$dashWorkflow.Text=$m.Groups[1].Value}
  }
  if($null -ne $dashReady -and $null -ne $vehicleReady){
   $m=[regex]::Match([string]$vehicleReady.Text,'(\d+)')
   if($m.Success){$dashReady.Text=$m.Groups[1].Value}
  }
 }catch{}
}

function Format-RefreshInterval([int]$seconds){
 if($seconds -le 0){return "Manual"}
 if($seconds -lt 60){return ("{0}s" -f $seconds)}
 if(($seconds % 60) -eq 0){return ("{0} min" -f [int]($seconds/60))}
 return ("{0}s" -f $seconds)
}

function Update-CarsRefreshStatus{
 if($null -eq $carsRefreshStatus){return}
 try{
  if(Test-Path $carsJson){
   $t=(Get-Item -LiteralPath $carsJson).LastWriteTime
   if($carsRefreshButton.IsEnabled){
    $mode=Format-RefreshInterval ([int]$script:refreshSettings["cars_seconds"])
    if([int]$script:refreshSettings["cars_seconds"] -le 0){$carsRefreshStatus.Text=("Last Cars refresh: {0} | Auto: Off" -f $t.ToString("HH:mm:ss"))}
    else{$carsRefreshStatus.Text=("Last Cars refresh: {0} | Auto every {1}" -f $t.ToString("HH:mm:ss"),$mode)}
   }
  }elseif($carsRefreshButton.IsEnabled){
   $mode=Format-RefreshInterval ([int]$script:refreshSettings["cars_seconds"])
   if([int]$script:refreshSettings["cars_seconds"] -le 0){$carsRefreshStatus.Text="Cars: waiting for manual scan | Auto: Off"}
   else{$carsRefreshStatus.Text=("Cars: waiting for first refresh | Auto every {0}" -f $mode)}
  }
 }catch{}
}

$script:lastUiDataStamp=""
$script:lastRuntimeCarPhotoStamp=""
function Get-RuntimeCarPhotoStamp{
 try{
  if(Test-Path -LiteralPath $script:runtimeCarPhotoRoot){
   $photos=@(Get-ChildItem -LiteralPath $script:runtimeCarPhotoRoot -File -Filter "*.png" -ErrorAction SilentlyContinue)
   $last=0
   if($photos.Count -gt 0){$last=($photos | Measure-Object -Property LastWriteTimeUtc -Maximum).Maximum.Ticks}
   return ("{0}:{1}" -f $photos.Count,$last)
  }
 }catch{}
 return "missing"
}
function Get-UiDataStamp{
 $parts=New-Object System.Collections.Generic.List[string]
 foreach($path in @($json,$storageJson,$repairJson,$carsJson,$businessJson,$contractsJson)){
  try{
   if(Test-Path -LiteralPath $path){
    $fi=Get-Item -LiteralPath $path -ErrorAction Stop
    [void]$parts.Add(("{0}:{1}:{2}" -f $fi.Name,$fi.LastWriteTimeUtc.Ticks,$fi.Length))
   }else{
    [void]$parts.Add(("{0}:missing" -f [IO.Path]::GetFileName($path)))
   }
  }catch{}
 }
 try{
  if(Test-Path -LiteralPath $script:runtimeCarPhotoRoot){
   $photos=@(Get-ChildItem -LiteralPath $script:runtimeCarPhotoRoot -File -Filter "*.png" -ErrorAction SilentlyContinue)
   $last=0
   if($photos.Count -gt 0){$last=($photos | Measure-Object -Property LastWriteTimeUtc -Maximum).Maximum.Ticks}
   [void]$parts.Add(("RuntimeCarPhotos:{0}:{1}" -f $photos.Count,$last))
  }else{[void]$parts.Add("RuntimeCarPhotos:missing")}
 }catch{}
 return ($parts -join "|")
}

function Refresh-UI{
 Update-CarsRefreshStatus
 # Preserve last known-good live data per save for instant startup next time.
 Save-StartupCacheFile $json "inventory.json"
 Save-StartupCacheFile $storageJson "storage.json"
 Save-StartupCacheFile $repairJson "repair_machine.json"
 Save-StartupCacheFile $carsJson "cars_owned.json"
 Save-StartupCacheFile $businessJson "business.json"
  Save-StartupCacheFile $contractsJson "contracts.json"

 Refresh-BusinessDashboard
 Refresh-ContractsPage
 $player=@{}
 $storage=@{}
 $trunk=@{}
 $names=@{}
 $types=@{}

 if(Test-Path $json){
  try{
   $d=(Get-Content $json -Raw)|ConvertFrom-Json
   if($d.connected){
    foreach($i in @($d.items)){
     $key=Normalize-Key ([string]$i.name)
     $player[$key]=$i
     $names[$key]=[string]$i.name
     $types[$key]=[string]$i.type
    }
   }
  }catch{}
 }

 $storageConnected=$false
 $storageContainers=0
 if(Test-Path $storageJson){
  try{
   $s=(Get-Content $storageJson -Raw)|ConvertFrom-Json
   if($s.connected){
    $storageConnected=$true
    $storageContainers=[int]$s.containerCount
    foreach($i in @($s.items)){
     $key=Normalize-Key ([string]$i.name)
     $storage[$key]=$i
     if(-not $names.ContainsKey($key)){$names[$key]=[string]$i.name}
     if(-not $types.ContainsKey($key)){$types[$key]=[string]$i.type}
    }
   }
  }catch{}
 }

 # v0.43.8.5: cars_owned.json already contains the monitored owned-car
 # trunk rows. Merge those quantities by item name for Parts stock without
 # adding another UE object scan. Trunk durability is intentionally unknown
 # in the conservative reader, so trunk stock affects Total only, not 100% / Repair.
 if(Test-Path $carsJson){
  try{
   $cj=(Get-Content $carsJson -Raw)|ConvertFrom-Json
   if($cj.connected){
    foreach($car in @($cj.cars)){
     foreach($ti in @($car.trunk)){
      $tname=[string]$ti.name
      if([string]::IsNullOrWhiteSpace($tname) -or $tname -eq "Unknown Item"){continue}
      $key=Normalize-Key $tname
      if([string]::IsNullOrWhiteSpace($key)){continue}
      $tq=1
      try{$tq=[int]$ti.qty}catch{}
      if($tq -le 0){$tq=1}
      if($trunk.ContainsKey($key)){$trunk[$key]=[int]$trunk[$key]+$tq}else{$trunk[$key]=$tq}
      if(-not $names.ContainsKey($key)){$names[$key]=$tname}
      if(-not $types.ContainsKey($key)){$types[$key]=""}
     }
    }
   }
  }catch{}
 }

 foreach($l in $lists.Values){$l.Items.Clear()}
 $low.Items.Clear()
 if($null -ne $groupSummary){$groupSummary.Items.Clear()}

 foreach($ck in @("CustomisationExterior","CustomisationInterior","CustomisationPaint","CustomisationSpecial")){if($lists.ContainsKey($ck)){$lists[$ck].Items.Clear()}}
 $groupCounts=@{"Engine"=0;"Brakes"=0;"Suspension"=0;"Fuses"=0;"Exhaust"=0;"Other Parts"=0;"Customisation"=0;"Others"=0}
 $partsUnique=0
 $partsLowCount=0
 $partsReadyTotal=0
 $partsRepairTotal=0
 $inventoryCounts=@{"Valuables"=0;"Electronics"=0;"Tools"=0;"Media"=0;"Furniture"=0;"Consumables"=0;"Containers"=0;"Other"=0}
 $inventoryPlayerTotal=0;$inventoryStorageTotal=0;$inventoryTrunkTotal=0
 $playerTotal=0
 $storageTotal=0
 $trunkPartsTotal=0
 $repairMachineTotal=0
 $readyTotal=0
 $repairTotal=0
 $differentOwned=0

 $repairInv=@{}
 $repairNames=@{}
 $repairTypes=@{}
 $repairM1=@{}
 $repairM2=@{}
 $repairConnected=$false
 $repairContainers=0

 if(Test-Path $repairJson){
  try{
   $rj=(Get-Content $repairJson -Raw)|ConvertFrom-Json
   if($rj.connected){
    $repairConnected=$true
    $repairContainers=[int]$rj.containerCount
    foreach($ri in @($rj.items)){
     $key=(([string]$ri.name).ToLowerInvariant()+"||"+([string]$ri.type).ToLowerInvariant())
     $repairInv[$key]=$ri
     $repairNames[$key]=[string]$ri.name
     $repairTypes[$key]=[string]$ri.type
     $repairM1[$key]=[int]$ri.machine1
     $repairM2[$key]=[int]$ri.machine2
    }
   }
  }catch{}
 }

 $allKeys=New-Object System.Collections.Generic.HashSet[string]
 foreach($k in $player.Keys){[void]$allKeys.Add([string]$k)}
 foreach($k in $storage.Keys){[void]$allKeys.Add([string]$k)}
 foreach($k in $trunk.Keys){[void]$allKeys.Add([string]$k)}
 foreach($k in $repairInv.Keys){[void]$allKeys.Add([string]$k)}

 $rows=@()

 foreach($key in $allKeys){
  $name=[string]$names[$key]
  if([string]::IsNullOrWhiteSpace($name) -and $repairNames.ContainsKey($key)){$name=[string]$repairNames[$key]}
  if([string]::IsNullOrWhiteSpace($name)){continue}

  $pq=0;$sq=0;$tq=0;$rq=0;$m1=0;$m2=0;$full=0;$repair=0

  if($player.ContainsKey($key)){
   $i=$player[$key]
   $pq=[int]$i.qty
   $full+=[int]$i.full
   $repair+=[int]$i.repair
  }

  if($storage.ContainsKey($key)){
   $i=$storage[$key]
   $sq=[int]$i.qty
   $full+=[int]$i.full
   $repair+=[int]$i.repair
  }

  if($repairInv.ContainsKey($key)){
   $i=$repairInv[$key]
   $rq=[int]$i.qty
   $m1=[int]$i.machine1
   $m2=[int]$i.machine2
   $full+=[int]$i.full
   $repair+=[int]$i.repair
  }

  $group=Group-For $name ([string]$types[$key])
  # v0.44.0.57: trunk stock is a location for BOTH Parts and non-car Inventory.
  # cars_owned.json is already the proven live trunk source, so no new UE scan is added.
  if($trunk.ContainsKey($key)){$tq=[int]$trunk[$key]}

  $qty=$pq+$sq+$tq+$rq
  if($qty -le 0){continue}
  if($group -ne "Others"){$partsUnique++;$partsReadyTotal+=$full;$partsRepairTotal+=$repair}

  $o=New-Object PSObject
  Add-Member -InputObject $o -MemberType NoteProperty -Name Name -Value $name
  Add-Member -InputObject $o -MemberType NoteProperty -Name Player -Value $pq
  Add-Member -InputObject $o -MemberType NoteProperty -Name Storage -Value $sq
  Add-Member -InputObject $o -MemberType NoteProperty -Name Trunk -Value $tq
  Add-Member -InputObject $o -MemberType NoteProperty -Name RepairMachine -Value $rq
  Add-Member -InputObject $o -MemberType NoteProperty -Name Machine1 -Value $m1
  Add-Member -InputObject $o -MemberType NoteProperty -Name Machine2 -Value $m2
  Add-Member -InputObject $o -MemberType NoteProperty -Name Full -Value $full
  Add-Member -InputObject $o -MemberType NoteProperty -Name Repair -Value $repair
  Add-Member -InputObject $o -MemberType NoteProperty -Name Qty -Value $qty
  Add-Member -InputObject $o -MemberType NoteProperty -Name Group -Value $group
  $customGroup=if($group -eq "Customisation"){Get-CustomisationGroup $name}else{""}
  Add-Member -InputObject $o -MemberType NoteProperty -Name CustomGroup -Value $customGroup
  $rowIconPath=Get-PartsRowIconPath $group $name $customGroup
  Add-Member -InputObject $o -MemberType NoteProperty -Name IconPath -Value $rowIconPath
  $rowIconImage=$null
  $rowIconUri=$null
  if($rowIconPath){try{$rowIconImage=New-CompanionBitmapImageFromAbsolutePath $rowIconPath;$rowIconUri=New-Object System.Uri($rowIconPath,[System.UriKind]::Absolute)}catch{}}
  Add-Member -InputObject $o -MemberType NoteProperty -Name IconImage -Value $rowIconImage
  Add-Member -InputObject $o -MemberType NoteProperty -Name IconUri -Value $rowIconUri
  $inventoryGroup=""
  if($group -eq "Others"){
   $inventoryGroup=Inventory-Group-For $name ([string]$types[$key])
   Add-Member -InputObject $o -MemberType NoteProperty -Name InventoryGroup -Value $inventoryGroup
   if($inventoryCounts.ContainsKey($inventoryGroup)){$inventoryCounts[$inventoryGroup]+=$qty}
   $inventoryPlayerTotal+=$pq;$inventoryStorageTotal+=$sq;$inventoryTrunkTotal+=$tq
  }else{
   Add-Member -InputObject $o -MemberType NoteProperty -Name InventoryGroup -Value ""
  }
  $rows+=$o

  $differentOwned++
  $playerTotal+=$pq
  $storageTotal+=$sq
  $trunkPartsTotal+=$tq
  $repairMachineTotal+=$rq
  $readyTotal+=$full
  $repairTotal+=$repair
  if($groupCounts.ContainsKey($group)){$groupCounts[$group]+=$qty}
 }

 foreach($o in @($rows | Sort-Object Name)){
  if(([string]$o.Group) -eq "Others"){
   Add-InventoryVisualItem $lists["InventoryAll"] $o
   switch([string]$o.InventoryGroup){
    "Valuables" {Add-InventoryVisualItem $lists["InventoryValuables"] $o}
    "Electronics" {Add-InventoryVisualItem $lists["InventoryElectronics"] $o}
    "Tools" {Add-InventoryVisualItem $lists["InventoryTools"] $o}
    "Media" {Add-InventoryVisualItem $lists["InventoryMedia"] $o}
    "Furniture" {Add-InventoryVisualItem $lists["InventoryFurniture"] $o}
    "Consumables" {Add-InventoryVisualItem $lists["InventoryConsumables"] $o}
    "Containers" {Add-InventoryVisualItem $lists["InventoryContainers"] $o}
    default {Add-InventoryVisualItem $lists["InventoryOther"] $o}
   }
  }else{
   Add-PartsVisualItem $lists["PartsAll"] $o $false
   switch([string]$o.Group){
    "Engine" {Add-PartsVisualItem $lists["Engine"] $o $false}
    "Brakes" {Add-PartsVisualItem $lists["Brakes"] $o $false}
    "Suspension" {Add-PartsVisualItem $lists["Suspension"] $o $false}
    "Exhaust" {Add-PartsVisualItem $lists["Exhaust"] $o $false}
    "Fuses" {Add-PartsVisualItem $lists["SmallParts"] $o $false}
    "Other Parts" {Add-PartsVisualItem $lists["SmallParts"] $o $false}
    "Customisation" {
      switch([string]$o.CustomGroup){
       "Exterior" {Add-PartsVisualItem $lists["CustomisationExterior"] $o $true}
       "Interior" {Add-PartsVisualItem $lists["CustomisationInterior"] $o $true}
       "Paint Shop" {Add-PartsVisualItem $lists["CustomisationPaint"] $o $true}
       "Special Upgrades" {Add-PartsVisualItem $lists["CustomisationSpecial"] $o $true}
      }
    }
   }
  }

  # Low Stock is for CAR PARTS only.
  # "Below 2" means exactly 1 currently available.
  if(([string]$o.Group -ne "Others") -and ([int]$o.Qty -lt 2)){
   [void]$low.Items.Add(("{0} - {1} total" -f $o.Name,$o.Qty))
   $partsLowCount++
  }
 }

 if($null -ne $groupSummary){
  foreach($g in @("Engine","Brakes","Suspension","Exhaust")){
   [void]$groupSummary.Items.Add(("{0}: {1}" -f $g,$groupCounts[$g]))
  }
  [void]$groupSummary.Items.Add(("Fuses + Other Parts: {0}" -f ($groupCounts["Fuses"]+$groupCounts["Other Parts"])))
  [void]$groupSummary.Items.Add(("Customisation: {0}" -f $groupCounts["Customisation"]))
  [void]$groupSummary.Items.Add(("Inventory - Valuables + Safes: {0}" -f $inventoryCounts["Valuables"]))
  [void]$groupSummary.Items.Add(("Inventory - Furniture: {0}" -f $inventoryCounts["Furniture"]))
  [void]$groupSummary.Items.Add(("Inventory - Consumables: {0}" -f $inventoryCounts["Consumables"]))
  [void]$groupSummary.Items.Add(("Inventory - Containers: {0}" -f $inventoryCounts["Containers"]))
  [void]$groupSummary.Items.Add(("Inventory - Other: {0}" -f $inventoryCounts["Other"]))
 }

 if($null -ne $inventorySummaryTotal){
  $inventoryTotalQty=$inventoryCounts["Valuables"]+$inventoryCounts["Electronics"]+$inventoryCounts["Tools"]+$inventoryCounts["Media"]+$inventoryCounts["Furniture"]+$inventoryCounts["Consumables"]+$inventoryCounts["Containers"]+$inventoryCounts["Other"]
  $inventorySummaryTotal.Text="$inventoryTotalQty"
  $inventorySummaryUnique.Text="$($lists["InventoryAll"].Items.Count)"
  $inventorySummaryPlayer.Text="$inventoryPlayerTotal"
  $inventorySummaryStorage.Text="$inventoryStorageTotal"
  $inventorySummaryTrunk.Text="$inventoryTrunkTotal"
  try{$inventoryAllTab.Header=New-InventoryCategoryHeader ("ALL ({0})" -f $lists["InventoryAll"].Items.Count) "#496B2E" "ALL"}catch{}
  try{$inventoryValuablesTab.Header=New-InventoryCategoryHeader ("VALUABLES + SAFES ({0})" -f $lists["InventoryValuables"].Items.Count) "#9B772C" "VALUABLES"}catch{}
  try{$inventoryElectronicsTab.Header=New-InventoryCategoryHeader ("ELECTRONICS ({0})" -f $lists["InventoryElectronics"].Items.Count) "#315B85" "ELECTRONICS"}catch{}
  try{$inventoryToolsTab.Header=New-InventoryCategoryHeader ("TOOLS ({0})" -f $lists["InventoryTools"].Items.Count) "#6D6540" "TOOLS"}catch{}
  try{$inventoryMediaTab.Header=New-InventoryCategoryHeader ("MEDIA ({0})" -f $lists["InventoryMedia"].Items.Count) "#704B78" "MEDIA"}catch{}
  try{$inventoryFurnitureTab.Header=New-InventoryCategoryHeader ("FURNITURE ({0})" -f $lists["InventoryFurniture"].Items.Count) "#76513D" "FURNITURE"}catch{}
  try{$inventoryConsumablesTab.Header=New-InventoryCategoryHeader ("CONSUMABLES ({0})" -f $lists["InventoryConsumables"].Items.Count) "#8B3C57" "CONSUMABLES"}catch{}
  try{$inventoryContainersTab.Header=New-InventoryCategoryHeader ("CONTAINERS ({0})" -f $lists["InventoryContainers"].Items.Count) "#315B85" "CONTAINERS"}catch{}
  try{$inventoryOtherTab.Header=New-InventoryCategoryHeader ("OTHER ({0})" -f $lists["InventoryOther"].Items.Count) "#59636F" "OTHER"}catch{}
 }

 if($null -ne $partsSummaryTotal){
  $partsTotalQty=$groupCounts["Engine"]+$groupCounts["Brakes"]+$groupCounts["Suspension"]+$groupCounts["Exhaust"]+$groupCounts["Fuses"]+$groupCounts["Other Parts"]+$groupCounts["Customisation"]
  $partsSummaryTotal.Text="$partsTotalQty"
  $partsSummaryReady.Text="$partsReadyTotal"
  $partsSummaryRepair.Text="$partsRepairTotal"
  $partsSummaryLow.Text="$partsLowCount"
  try{$partsAllTab.Header=New-PartsCategoryHeader ("ALL ({0})" -f $partsUnique) "#496B2E" "ALL"}catch{}
  try{$partsEngineTab.Header=New-PartsCategoryHeader ("ENGINE ({0})" -f $lists["Engine"].Items.Count) "#A95B2D" "ENGINE"}catch{}
  try{$partsBrakesTab.Header=New-PartsCategoryHeader ("BRAKES ({0})" -f $lists["Brakes"].Items.Count) "#A93E39" "BRAKES"}catch{}
  try{$partsSuspensionTab.Header=New-PartsCategoryHeader ("SUSPENSION ({0})" -f $lists["Suspension"].Items.Count) "#315B85" "SUSPENSION"}catch{}
  try{$partsExhaustTab.Header=New-PartsCategoryHeader ("EXHAUST ({0})" -f $lists["Exhaust"].Items.Count) "#59636F" "EXHAUST"}catch{}
  try{$partsSmallTab.Header=New-PartsCategoryHeader ("FUSES + OTHER ({0})" -f $lists["SmallParts"].Items.Count) "#9B772C" "FUSES"}catch{}
  try{$partsCustomTab.Header=New-PartsCategoryHeader ("CUSTOM ({0})" -f $groupCounts["Customisation"]) "#B16A21" "CUSTOM"}catch{}
 }

 if($null -ne $dashInventory){$dashInventory.Text="$($lists["InventoryAll"].Items.Count)"}
 if($null -ne $dashRepair){$dashRepair.Text="$partsRepairTotal"}

 if($low.Items.Count -eq 0){[void]$low.Items.Add("No car parts below 2 in stock.")}

 $unique.Text="Different items owned: $differentOwned"
 $total.Text="Player: $playerTotal   Storage: $storageTotal   Trunk Parts: $trunkPartsTotal   Repair Machines: $repairMachineTotal   Total: $($playerTotal+$storageTotal+$trunkPartsTotal+$repairMachineTotal)"
 $count.Text="$($playerTotal+$storageTotal+$trunkPartsTotal+$repairMachineTotal) total - $readyTotal ready - $repairTotal repair"

 if($storageConnected){
  $status.Text="Live player + storage + car trunks + repair machines ("+$repairContainers+" repair machines) - "+(Get-Date -Format "HH:mm:ss")
 }else{
  $status.Text="Waiting for safe live data after save load..."
 }

 Update-DashboardVehicleCards

 # Repair machine tab
 if($null -ne $repairList){
  $repairList.Items.Clear()
  if(Test-Path $repairJson){
   try{
    $r=(Get-Content $repairJson -Raw)|ConvertFrom-Json
    if($r.connected){
     foreach($i in @($r.items)){
      $o=New-Object PSObject
      Add-Member -InputObject $o -MemberType NoteProperty -Name Name -Value ([string]$i.name)
      Add-Member -InputObject $o -MemberType NoteProperty -Name Machine1 -Value ([int]$i.machine1)
      Add-Member -InputObject $o -MemberType NoteProperty -Name Machine2 -Value ([int]$i.machine2)
      Add-Member -InputObject $o -MemberType NoteProperty -Name Qty -Value ([int]$i.qty)
      Add-Member -InputObject $o -MemberType NoteProperty -Name Full -Value ([int]$i.full)
      Add-Member -InputObject $o -MemberType NoteProperty -Name Repair -Value ([int]$i.repair)
      [void]$repairList.Items.Add($o)
     }
     $m1Total=0;$m2Total=0
     if(@($r.machines).Count -ge 1){$m1Total=[int]$r.machines[0].total}
     if(@($r.machines).Count -ge 2){$m2Total=[int]$r.machines[1].total}
     $repairStatus.Text=("Repair machines: {0} | Machine 1: {1} | Machine 2: {2} | Total: {3}" -f [int]$r.containerCount,$m1Total,$m2Total,[int]$r.total)
    }else{
     $repairStatus.Text="Repair machines not found."
    }
   }catch{
    $repairStatus.Text="Repair machine data error."
   }
  }else{
   $repairStatus.Text="Waiting for repair machines..."
  }
  try{$repairTab.Header=New-PartsCategoryHeader ("REPAIR MACHINE ({0})" -f $repairList.Items.Count) "#8B3C57" "REPAIR"}catch{}
 }

 # Cars owned / For Sale tabs
 if($null -ne $carsList){
  $selectedId=[string]$script:selectedCarId
  foreach($selList in @($carsList,$carsForSaleList,$carsReadyList,$carsWrecksList,$carsPersonalList,$carsModifiedList)){
   if($selectedId -eq "" -and $null -ne $selList -and $null -ne $selList.SelectedItem -and -not [bool]$selList.SelectedItem.IsHeader){
    $selectedId=[string]$selList.SelectedItem.CarId
   }
  }
  if(Test-Path $carsJson){
   $carsStamp=""
   try{$carsStamp=[string](Get-Item -LiteralPath $carsJson).LastWriteTimeUtc.Ticks}catch{}
   if($script:forceCarsUiRebuild -or $carsStamp -ne $script:lastCarsJsonStamp){

    # Only clear/rebuild the five Cars tables when cars.json really changed.
    $carsList.Items.Clear()
    if($null -ne $carsForSaleList){$carsForSaleList.Items.Clear()}
    if($null -ne $carsReadyList){$carsReadyList.Items.Clear()}
    if($null -ne $carsWrecksList){$carsWrecksList.Items.Clear()}
    if($null -ne $carsPersonalList){$carsPersonalList.Items.Clear()}
    if($null -ne $carsModifiedList){$carsModifiedList.Items.Clear()}

   try{
    $c=(Get-Content $carsJson -Raw)|ConvertFrom-Json
    $carDistanceMap=Get-CarDistanceMap

    if($c.connected){
     $allCars=@($c.cars)
     $uniqueCars=@{}
     $anonymousCars=@()
     foreach($c in @($allCars)){
      $cid=[string]$c.carId
      if(-not [string]::IsNullOrWhiteSpace($cid)){
       if(-not $uniqueCars.ContainsKey($cid)){$uniqueCars[$cid]=$c}
      }else{
       $anonymousCars+=,$c
      }
     }
     $allCars=@($uniqueCars.Values)+@($anonymousCars)

     $utilityCars=@($allCars | Where-Object {
      $mn=([string]$_.model).ToLowerInvariant()
      ([bool]$_.isUtility) -or $mn -eq "transporter" -or $mn -eq "e_max transporter" -or $mn.Contains("e_max transporter") -or $mn.Contains("tow truck")
     })
     $nonUtilityCars=@($allCars | Where-Object {
      $mn=([string]$_.model).ToLowerInvariant()
      -not (([bool]$_.isUtility) -or $mn -eq "transporter" -or $mn -eq "e_max transporter" -or $mn.Contains("e_max transporter") -or $mn.Contains("tow truck"))
     })
     $personalCars=@($nonUtilityCars | Where-Object {Test-PersonalCar ([string]$_.carId)})
     $workflowCars=@($nonUtilityCars | Where-Object {-not (Test-PersonalCar ([string]$_.carId))})
     $forSaleCars=@($workflowCars | Where-Object { $s=$false;try{$s=[bool]$_.isForSale}catch{}; $s -or ([string]$_.saleStatus -eq "For Sale") })
     # Wrecks are current-state only. $0 acquisition is retained only as a fallback
     # for unrepaired newly collected wrecks; repaired former wrecks must leave this tab.
     $wreckCars=@($workflowCars | Where-Object { Test-CarIsWreck $_ })
     $normalCars=@($workflowCars | Where-Object { $s=$false;try{$s=[bool]$_.isForSale}catch{}; (-not $s) -and (-not (Test-CarIsWreck $_)) })
     $readyCars=@($normalCars | Where-Object { $pct=Get-CarConditionPercent $_.mechanicalCondition; $null -ne $pct -and $pct -ge 95.0 })
     $readyIds=@{};foreach($rc in @($readyCars)){if($null -ne $rc.carId){$readyIds[[string]$rc.carId]=$true}}
     $waitingCars=@($normalCars | Where-Object {-not $readyIds.ContainsKey([string]$_.carId)})
     $vehicleInfoOnlyCars=@($workflowCars | Where-Object {[bool]$_.isVehicleInfoOnly})

     # Keep the Cars tabs informative while preserving the existing five-tab workflow.
     try{$carsForSaleTab.Header=New-GameSubHeader ("FOR SALE ({0})" -f $forSaleCars.Count) "#A93E39"}catch{}
     try{$carsReadyTab.Header=New-GameSubHeader ("READY FOR SALE ({0})" -f $readyCars.Count) "#5D8E39"}catch{}
     try{$carsWaitingTab.Header=New-GameSubHeader ("WAITING ({0})" -f $waitingCars.Count) "#B87824"}catch{}
     try{$carsWrecksTab.Header=New-GameSubHeader ("WRECKS ({0})" -f $wreckCars.Count) "#5A6572"}catch{}
     try{$carsPersonalTab.Header=New-GameSubHeader ("PERSONAL CARS ({0})" -f $personalCars.Count) "#315B85"}catch{}
     $modifiedCars=@($allCars | Where-Object {(Get-CarModificationInfo $_).Total -gt 0})
     try{$carsModifiedTab.Header=New-GameSubHeader ("MODIFIED ({0})" -f $modifiedCars.Count) "#8B5A9B"}catch{}

     if($null -ne $vehicleTotal){$vehicleTotal.Text=("Workflow Cars: {0}" -f $workflowCars.Count)}
     if($null -ne $vehicleOnSale){$vehicleOnSale.Text=("Cars On Sale: {0}" -f $forSaleCars.Count)}
     if($null -ne $vehicleReady){$vehicleReady.Text=("Cars Ready For Sale: {0}" -f $readyCars.Count)}
     if($null -ne $vehicleWaiting){$vehicleWaiting.Text=("Waiting: {0} | Wrecks: {1}" -f $waitingCars.Count,$wreckCars.Count)}
     if($null -ne $vehicleUtility){
      if($utilityCars.Count -gt 0){
       $utilityNames=@($utilityCars | ForEach-Object {[string]$_.model}) -join ", "
       $vehicleUtility.Text=("Utility Vehicles: {0} - {1}" -f $utilityCars.Count,$utilityNames)
      }else{$vehicleUtility.Text="Utility Vehicles: 0"}
     }
     if($null -ne $vehiclePersonal){
      if($personalCars.Count -gt 0){
       $personalNames=@($personalCars | ForEach-Object {[string]$_.model}) -join ", "
       $vehiclePersonal.Text=("Personal Cars: {0} - {1}" -f $personalCars.Count,$personalNames)
      }else{$vehiclePersonal.Text="Personal Cars: 0"}
     }

     if($null -ne $vehicleGhost){
      if($vehicleInfoOnlyCars.Count -gt 0){
       $ghostNames=@($vehicleInfoOnlyCars | ForEach-Object {[string]$_.model}) -join ", "
       $vehicleGhost.Text=("VehicleInfo-only records: {0} - {1}" -f $vehicleInfoOnlyCars.Count,$ghostNames)
      }else{$vehicleGhost.Text="VehicleInfo-only records: 0"}
     }
     $groups=@($waitingCars | Group-Object bodyType | Sort-Object Name)

     foreach($group in $groups){
      $header=New-Object PSObject
      Add-Member -InputObject $header -MemberType NoteProperty -Name IsHeader -Value $true
      Add-Member -InputObject $header -MemberType NoteProperty -Name Model -Value ("--- {0} ({1}) ---" -f $group.Name,$group.Count)
      Add-Member -InputObject $header -MemberType NoteProperty -Name ColorHex -Value "#F7F7F7"
      Add-Member -InputObject $header -MemberType NoteProperty -Name ColourLabel -Value ""
      Add-Member -InputObject $header -MemberType NoteProperty -Name Year -Value ""
      Add-Member -InputObject $header -MemberType NoteProperty -Name Mileage -Value ""
      Add-Member -InputObject $header -MemberType NoteProperty -Name ConditionText -Value ""
      Add-Member -InputObject $header -MemberType NoteProperty -Name TrunkTotal -Value ""
      Add-Member -InputObject $header -MemberType NoteProperty -Name SaleStatus -Value ""
      [void]$carsList.Items.Add($header)

      foreach($car in @($group.Group | Sort-Object model,year)){
       $o=New-Object PSObject
       Add-Member -InputObject $o -MemberType NoteProperty -Name IsHeader -Value $false
       Add-Member -InputObject $o -MemberType NoteProperty -Name BodyType -Value ([string]$car.bodyType)
       Add-Member -InputObject $o -MemberType NoteProperty -Name BodyTypeId -Value ([string]$car.bodyTypeId)
       Add-Member -InputObject $o -MemberType NoteProperty -Name Model -Value ([string]$car.model)
       Add-Member -InputObject $o -MemberType NoteProperty -Name Year -Value ([int]$car.year)
       Add-Member -InputObject $o -MemberType NoteProperty -Name Mileage -Value ([double]$car.mileage)
       Add-Member -InputObject $o -MemberType NoteProperty -Name MileageText -Value (Format-CarMileage $car.mileage)
       Add-Member -InputObject $o -MemberType NoteProperty -Name CarId -Value ([string]$car.carId)
       Add-Member -InputObject $o -MemberType NoteProperty -Name BoughtForText -Value (Format-CarBoughtLabel $car.buyingPlayerPrice $false)
       Add-Member -InputObject $o -MemberType NoteProperty -Name Location -Value (Get-CarLocationText $car)
       Add-Member -InputObject $o -MemberType NoteProperty -Name Distance -Value (Get-CarDistanceText $carDistanceMap ([string]$car.carId))
       Add-Member -InputObject $o -MemberType NoteProperty -Name BuyingPrice -Value ([double]$car.buyingPrice)
       Add-Member -InputObject $o -MemberType NoteProperty -Name SellingPrice -Value ([double]$car.sellingPrice)
       Add-Member -InputObject $o -MemberType NoteProperty -Name TrunkTotal -Value ([int]$car.trunkTotal)
       Add-Member -InputObject $o -MemberType NoteProperty -Name SaleStatus -Value ([string]$car.saleStatus)
       Add-Member -InputObject $o -MemberType NoteProperty -Name IsForSale -Value ([bool]$car.isForSale)
       Add-Member -InputObject $o -MemberType NoteProperty -Name ListingPrice -Value ([double]$car.listingPrice)
       Add-Member -InputObject $o -MemberType NoteProperty -Name ListingDaysLeft -Value ([double]$car.listingDaysLeft)
       Add-Member -InputObject $o -MemberType NoteProperty -Name TrunkItems -Value @($car.trunk)
       Add-Member -InputObject $o -MemberType NoteProperty -Name InstalledParts -Value @($car.installedParts)
       Add-Member -InputObject $o -MemberType NoteProperty -Name BuyingPlayerPrice -Value ([double]$car.buyingPlayerPrice)
       Add-Member -InputObject $o -MemberType NoteProperty -Name BuyingMarketPrice -Value ([double]$car.buyingMarketPrice)
       Add-Member -InputObject $o -MemberType NoteProperty -Name SellingPlayerPrice -Value ([double]$car.sellingPlayerPrice)
       Add-Member -InputObject $o -MemberType NoteProperty -Name CurrentDirtValue -Value ([double]$car.currentDirtValue)
       Add-Member -InputObject $o -MemberType NoteProperty -Name CurrentRustValue -Value ([double]$car.currentRustValue)
       Add-Member -InputObject $o -MemberType NoteProperty -Name CurWashValue -Value ([double]$car.curWashValue)
       Add-Member -InputObject $o -MemberType NoteProperty -Name CurPolishValue -Value ([double]$car.curPolishValue)
       Add-Member -InputObject $o -MemberType NoteProperty -Name VehicleScoreCache -Value ([double]$car.vehicleScoreCache)
       Add-Member -InputObject $o -MemberType NoteProperty -Name ConditionText -Value (Format-CarPercent $car.mechanicalCondition)
       Add-CarReadinessProperties $o $car
       Add-Member -InputObject $o -MemberType NoteProperty -Name BuyingCarPartsScore -Value ([double]$car.buyingCarPartsScore)
       Add-Member -InputObject $o -MemberType NoteProperty -Name GearboxType -Value ([string]$car.gearboxType)
       Add-Member -InputObject $o -MemberType NoteProperty -Name FuelType -Value ([string]$car.fuelType)
       Add-Member -InputObject $o -MemberType NoteProperty -Name IsAbandonedWreck -Value ([bool](Test-CarIsWreck $car))
       Add-Member -InputObject $o -MemberType NoteProperty -Name IsWreckForSell -Value ([bool]$car.isWreckForSell)
       Add-Member -InputObject $o -MemberType NoteProperty -Name WasWreck -Value ([bool]$car.wasWreck)
       Add-Member -InputObject $o -MemberType NoteProperty -Name Color -Value ([string]$car.color)
       $hex=Get-CarColourHex $car.colorR $car.colorG $car.colorB
       Add-Member -InputObject $o -MemberType NoteProperty -Name ColorHex -Value $hex
       $colourLabel=Get-CarColourLabel $car.color $car.colorR $car.colorG $car.colorB
       Add-Member -InputObject $o -MemberType NoteProperty -Name ColourLabel -Value $colourLabel

       Add-Member -InputObject $o -MemberType NoteProperty -Name Color -Value ([string]$car.color) -Force

       Add-CarIconProperty $o
       [void]$carsList.Items.Add($o)

       if($selectedId -ne "" -and ([string]$o.CarId) -eq $selectedId){
        $carsList.SelectedItem=$o
       }
      }
     }

     # WRECKS use saved wreck state OR the confirmed $0 acquisition rule.
     foreach($g in @($wreckCars | Group-Object bodyType | Sort-Object Name)){
      $h=New-Object PSObject;Add-Member -InputObject $h -MemberType NoteProperty -Name IsHeader -Value $true;Add-Member -InputObject $h -MemberType NoteProperty -Name Model -Value ("--- {0} ({1}) ---" -f $g.Name,$g.Count);[void]$carsWrecksList.Items.Add($h)
      foreach($car in @($g.Group | Sort-Object model,year)){
       $o=New-Object PSObject
       Add-Member -InputObject $o -MemberType NoteProperty -Name IsHeader -Value $false
       Add-Member -InputObject $o -MemberType NoteProperty -Name Model -Value ([string]$car.model)
       Add-Member -InputObject $o -MemberType NoteProperty -Name BodyType -Value ([string]$car.bodyType)
       Add-Member -InputObject $o -MemberType NoteProperty -Name Year -Value ([int]$car.year)
       Add-Member -InputObject $o -MemberType NoteProperty -Name Mileage -Value ([double]$car.mileage)
       Add-Member -InputObject $o -MemberType NoteProperty -Name MileageText -Value (Format-CarMileage $car.mileage)
       Add-Member -InputObject $o -MemberType NoteProperty -Name CarId -Value ([string]$car.carId)
       Add-Member -InputObject $o -MemberType NoteProperty -Name Location -Value (Get-CarLocationText $car)
       Add-Member -InputObject $o -MemberType NoteProperty -Name Distance -Value (Get-CarDistanceText $carDistanceMap ([string]$car.carId))
       Add-Member -InputObject $o -MemberType NoteProperty -Name TrunkTotal -Value ([int]$car.trunkTotal)
       Add-Member -InputObject $o -MemberType NoteProperty -Name TrunkItems -Value @($car.trunk)
       Add-Member -InputObject $o -MemberType NoteProperty -Name InstalledParts -Value @($car.installedParts)
       Add-Member -InputObject $o -MemberType NoteProperty -Name BuyingPlayerPrice -Value ([double]$car.buyingPlayerPrice)
       Add-Member -InputObject $o -MemberType NoteProperty -Name GearboxType -Value ([string]$car.gearboxType)
       Add-Member -InputObject $o -MemberType NoteProperty -Name FuelType -Value ([string]$car.fuelType)
       Add-Member -InputObject $o -MemberType NoteProperty -Name IsAbandonedWreck -Value ([bool](Test-CarIsWreck $car))
       Add-Member -InputObject $o -MemberType NoteProperty -Name IsWreckForSell -Value ([bool]$car.isWreckForSell)
       Add-Member -InputObject $o -MemberType NoteProperty -Name WasWreck -Value ([bool]$car.wasWreck)
       $hex=Get-CarColourHex $car.colorR $car.colorG $car.colorB
       Add-Member -InputObject $o -MemberType NoteProperty -Name ColorHex -Value $hex
       $colourLabel=Get-CarColourLabel $car.color $car.colorR $car.colorG $car.colorB
       Add-Member -InputObject $o -MemberType NoteProperty -Name ColourLabel -Value $colourLabel
       Add-Member -InputObject $o -MemberType NoteProperty -Name VehicleScoreCache -Value ([double]$car.vehicleScoreCache)
       Add-Member -InputObject $o -MemberType NoteProperty -Name ConditionText -Value (Format-CarPercent $car.mechanicalCondition)
       Add-CarReadinessProperties $o $car
       Add-Member -InputObject $o -MemberType NoteProperty -Name Color -Value ([string]$car.color) -Force
       Add-CarIconProperty $o
       [void]$carsWrecksList.Items.Add($o)
       if($selectedId -ne "" -and ([string]$o.CarId) -eq $selectedId){$carsWrecksList.SelectedItem=$o}
      }
     }
     if($null -ne $carsWrecksStatus){$carsWrecksStatus.Text=("Wrecks: {0}" -f $wreckCars.Count)}

     # PERSONAL CARS use the same selected details and ready checklist.
     foreach($g in @($personalCars | Group-Object bodyType | Sort-Object Name)){
      $h=New-Object PSObject;Add-Member -InputObject $h -MemberType NoteProperty -Name IsHeader -Value $true;Add-Member -InputObject $h -MemberType NoteProperty -Name Model -Value ("--- {0} ({1}) ---" -f $g.Name,$g.Count);[void]$carsPersonalList.Items.Add($h)
      foreach($car in @($g.Group | Sort-Object model,year)){
       $o=New-Object PSObject
       Add-Member -InputObject $o -MemberType NoteProperty -Name IsHeader -Value $false
       Add-Member -InputObject $o -MemberType NoteProperty -Name Model -Value ([string]$car.model)
       Add-Member -InputObject $o -MemberType NoteProperty -Name BodyType -Value ([string]$car.bodyType)
       Add-Member -InputObject $o -MemberType NoteProperty -Name Year -Value ([int]$car.year)
       Add-Member -InputObject $o -MemberType NoteProperty -Name Mileage -Value ([double]$car.mileage)
       Add-Member -InputObject $o -MemberType NoteProperty -Name MileageText -Value (Format-CarMileage $car.mileage)
       Add-Member -InputObject $o -MemberType NoteProperty -Name CarId -Value ([string]$car.carId)
       Add-Member -InputObject $o -MemberType NoteProperty -Name Location -Value (Get-CarLocationText $car)
       Add-Member -InputObject $o -MemberType NoteProperty -Name Distance -Value (Get-CarDistanceText $carDistanceMap ([string]$car.carId))
       Add-Member -InputObject $o -MemberType NoteProperty -Name TrunkTotal -Value ([int]$car.trunkTotal)
       Add-Member -InputObject $o -MemberType NoteProperty -Name TrunkItems -Value @($car.trunk)
       Add-Member -InputObject $o -MemberType NoteProperty -Name InstalledParts -Value @($car.installedParts)
       Add-Member -InputObject $o -MemberType NoteProperty -Name BuyingPlayerPrice -Value ([double]$car.buyingPlayerPrice)
       Add-Member -InputObject $o -MemberType NoteProperty -Name GearboxType -Value ([string]$car.gearboxType)
       Add-Member -InputObject $o -MemberType NoteProperty -Name FuelType -Value ([string]$car.fuelType)
       Add-Member -InputObject $o -MemberType NoteProperty -Name IsAbandonedWreck -Value ([bool](Test-CarIsWreck $car))
       Add-Member -InputObject $o -MemberType NoteProperty -Name IsWreckForSell -Value ([bool]$car.isWreckForSell)
       Add-Member -InputObject $o -MemberType NoteProperty -Name WasWreck -Value ([bool]$car.wasWreck)
       $hex=Get-CarColourHex $car.colorR $car.colorG $car.colorB
       Add-Member -InputObject $o -MemberType NoteProperty -Name ColorHex -Value $hex
       $colourLabel=Get-CarColourLabel $car.color $car.colorR $car.colorG $car.colorB
       Add-Member -InputObject $o -MemberType NoteProperty -Name ColourLabel -Value $colourLabel
       Add-Member -InputObject $o -MemberType NoteProperty -Name VehicleScoreCache -Value ([double]$car.vehicleScoreCache)
       Add-Member -InputObject $o -MemberType NoteProperty -Name ConditionText -Value (Format-CarPercent $car.mechanicalCondition)
       Add-CarReadinessProperties $o $car
       Add-Member -InputObject $o -MemberType NoteProperty -Name Color -Value ([string]$car.color) -Force
       Add-CarIconProperty $o
       [void]$carsPersonalList.Items.Add($o)
       if($selectedId -ne "" -and ([string]$o.CarId) -eq $selectedId){$carsPersonalList.SelectedItem=$o}
      }
     }
     if($null -ne $carsPersonalStatus){$carsPersonalStatus.Text=("Personal Cars: {0} | Untick PERSONAL CAR below to return it to the normal pool." -f $personalCars.Count)}


     # MODIFIED is an additional cross-location view. It does not remove a car
     # from WAITING / FOR SALE / WRECKS / PERSONAL. A car disappears naturally
     # when it is no longer present in the live owned-car data after sale.
     foreach($car in @($modifiedCars | Sort-Object model,year)){
      $mi=Get-CarModificationInfo $car
      $o=New-Object PSObject
      Add-Member -InputObject $o -MemberType NoteProperty -Name IsHeader -Value $false
      foreach($pair in @(
       @('Model',[string]$car.model),@('BodyType',[string]$car.bodyType),@('BodyTypeId',[string]$car.bodyTypeId),@('Year',[int]$car.year),
       @('Mileage',[double]$car.mileage),@('MileageText',(Format-CarMileage $car.mileage)),@('CarId',[string]$car.carId),
       @('Location',(Get-CarLocationText $car)),@('Distance',(Get-CarDistanceText $carDistanceMap ([string]$car.carId))),
       @('TrunkTotal',[int]$car.trunkTotal),@('TrunkItems',@($car.trunk)),@('InstalledParts',@($car.installedParts)),
       @('BuyingPlayerPrice',[double]$car.buyingPlayerPrice),@('BuyingMarketPrice',[double]$car.buyingMarketPrice),@('SellingPlayerPrice',[double]$car.sellingPlayerPrice),
       @('GearboxType',[string]$car.gearboxType),@('FuelType',[string]$car.fuelType),@('IsAbandonedWreck',[bool](Test-CarIsWreck $car)),
       @('IsWreckForSell',[bool]$car.isWreckForSell),@('WasWreck',[bool]$car.wasWreck),@('VehicleScoreCache',[double]$car.vehicleScoreCache),
       @('ConditionText',(Format-CarPercent $car.mechanicalCondition)),@('ModificationBadges',[string]$mi.Badges),@('SportCount',[int]$mi.Sport),@('RacingCount',[int]$mi.Racing),@('CustomCount',[int]$mi.Custom),@('ModificationSummary',[string]$mi.Summary)
      )){Add-Member -InputObject $o -MemberType NoteProperty -Name $pair[0] -Value $pair[1]}
      Add-CarReadinessProperties $o $car
      Add-Member -InputObject $o -MemberType NoteProperty -Name Color -Value ([string]$car.color) -Force
      Add-CarIconProperty $o
      [void]$carsModifiedList.Items.Add($o)
      if($selectedId -ne "" -and ([string]$o.CarId) -eq $selectedId){$carsModifiedList.SelectedItem=$o}
     }
     if($null -ne $carsModifiedStatus){
      $sportCars=@($modifiedCars | Where-Object {(Get-CarModificationInfo $_).Sport -gt 0}).Count
      $raceCars=@($modifiedCars | Where-Object {(Get-CarModificationInfo $_).Racing -gt 0}).Count
      $customCars=@($modifiedCars | Where-Object {(Get-CarModificationInfo $_).Custom -gt 0}).Count
      $carsModifiedStatus.Text=("Modified Cars: {0} | Sport: {1} | Racing: {2} | Custom: {3} | Cars remain in their normal tabs." -f $modifiedCars.Count,$sportCars,$raceCars,$customCars)
     }

# FOR SALE grouped by Body Type.
     foreach($saleGroup in @($forSaleCars | Group-Object bodyType | Sort-Object Name)){
      $header=New-Object PSObject
      Add-Member -InputObject $header -MemberType NoteProperty -Name IsHeader -Value $true
      Add-Member -InputObject $header -MemberType NoteProperty -Name Model -Value ("--- {0} ({1}) ---" -f $saleGroup.Name,$saleGroup.Count)
      [void]$carsForSaleList.Items.Add($header)
      foreach($car in @($saleGroup.Group | Sort-Object model,year)){
      $o=New-Object PSObject
      Add-Member -InputObject $o -MemberType NoteProperty -Name IsHeader -Value $false
      Add-Member -InputObject $o -MemberType NoteProperty -Name Model -Value ([string]$car.model)
      Add-Member -InputObject $o -MemberType NoteProperty -Name Year -Value ([int]$car.year)
      Add-Member -InputObject $o -MemberType NoteProperty -Name Mileage -Value ([double]$car.mileage)
      Add-Member -InputObject $o -MemberType NoteProperty -Name MileageText -Value (Format-CarMileage $car.mileage)
      Add-Member -InputObject $o -MemberType NoteProperty -Name CarId -Value ([string]$car.carId)
      Add-Member -InputObject $o -MemberType NoteProperty -Name BoughtForText -Value (Format-CarBoughtLabel $car.buyingPlayerPrice $false)
      Add-Member -InputObject $o -MemberType NoteProperty -Name Location -Value (Get-CarLocationText $car)
       Add-Member -InputObject $o -MemberType NoteProperty -Name Distance -Value (Get-CarDistanceText $carDistanceMap ([string]$car.carId))
      Add-Member -InputObject $o -MemberType NoteProperty -Name BodyType -Value ([string]$car.bodyType)
      Add-Member -InputObject $o -MemberType NoteProperty -Name TrunkTotal -Value ([int]$car.trunkTotal)
      Add-Member -InputObject $o -MemberType NoteProperty -Name TrunkItems -Value @($car.trunk)
      Add-Member -InputObject $o -MemberType NoteProperty -Name InstalledParts -Value @($car.installedParts)
      Add-Member -InputObject $o -MemberType NoteProperty -Name BuyingPrice -Value ([double]$car.buyingPrice)
      Add-Member -InputObject $o -MemberType NoteProperty -Name SellingPrice -Value ([double]$car.sellingPrice)
      Add-Member -InputObject $o -MemberType NoteProperty -Name BuyingPlayerPrice -Value ([double]$car.buyingPlayerPrice)
      Add-Member -InputObject $o -MemberType NoteProperty -Name BuyingMarketPrice -Value ([double]$car.buyingMarketPrice)
      Add-Member -InputObject $o -MemberType NoteProperty -Name SellingPlayerPrice -Value ([double]$car.sellingPlayerPrice)
      Add-Member -InputObject $o -MemberType NoteProperty -Name GearboxType -Value ([string]$car.gearboxType)
      Add-Member -InputObject $o -MemberType NoteProperty -Name FuelType -Value ([string]$car.fuelType)
       Add-Member -InputObject $o -MemberType NoteProperty -Name IsAbandonedWreck -Value ([bool](Test-CarIsWreck $car))
       Add-Member -InputObject $o -MemberType NoteProperty -Name IsWreckForSell -Value ([bool]$car.isWreckForSell)
       Add-Member -InputObject $o -MemberType NoteProperty -Name WasWreck -Value ([bool]$car.wasWreck)
      $hex=Get-CarColourHex $car.colorR $car.colorG $car.colorB
      Add-Member -InputObject $o -MemberType NoteProperty -Name ColorHex -Value $hex
      $colourLabel=Get-CarColourLabel $car.color $car.colorR $car.colorG $car.colorB
      Add-Member -InputObject $o -MemberType NoteProperty -Name ColourLabel -Value $colourLabel
      Add-Member -InputObject $o -MemberType NoteProperty -Name VehicleScoreCache -Value ([double]$car.vehicleScoreCache)
      Add-Member -InputObject $o -MemberType NoteProperty -Name ConditionText -Value (Format-CarPercent $car.mechanicalCondition)
       Add-CarReadinessProperties $o $car
      $lp="-"
      if($null -ne $car.listingPrice){try{$lp=Format-CarMoney ([double]$car.listingPrice)}catch{}}
      Add-Member -InputObject $o -MemberType NoteProperty -Name ListingPriceText -Value $lp
      Add-Member -InputObject $o -MemberType NoteProperty -Name Color -Value ([string]$car.color) -Force
      Add-CarIconProperty $o
       [void]$carsForSaleList.Items.Add($o)
      if($selectedId -ne "" -and ([string]$o.CarId) -eq $selectedId){
       $carsForSaleList.SelectedItem=$o
      }
     }
     }

     # READY FOR SALE grouped by Body Type.
     foreach($readyGroup in @($readyCars | Group-Object bodyType | Sort-Object Name)){
      $header=New-Object PSObject
      Add-Member -InputObject $header -MemberType NoteProperty -Name IsHeader -Value $true
      Add-Member -InputObject $header -MemberType NoteProperty -Name Model -Value ("--- {0} ({1}) ---" -f $readyGroup.Name,$readyGroup.Count)
      [void]$carsReadyList.Items.Add($header)
      foreach($car in @($readyGroup.Group | Sort-Object model,year)){
      $o=New-Object PSObject
      Add-Member -InputObject $o -MemberType NoteProperty -Name IsHeader -Value $false
      Add-Member -InputObject $o -MemberType NoteProperty -Name Model -Value ([string]$car.model)
      Add-Member -InputObject $o -MemberType NoteProperty -Name Year -Value ([int]$car.year)
      Add-Member -InputObject $o -MemberType NoteProperty -Name Mileage -Value ([double]$car.mileage)
      Add-Member -InputObject $o -MemberType NoteProperty -Name MileageText -Value (Format-CarMileage $car.mileage)
      Add-Member -InputObject $o -MemberType NoteProperty -Name CarId -Value ([string]$car.carId)
      Add-Member -InputObject $o -MemberType NoteProperty -Name BoughtForText -Value (Format-CarBoughtLabel $car.buyingPlayerPrice $false)
      Add-Member -InputObject $o -MemberType NoteProperty -Name Location -Value (Get-CarLocationText $car)
       Add-Member -InputObject $o -MemberType NoteProperty -Name Distance -Value (Get-CarDistanceText $carDistanceMap ([string]$car.carId))
      Add-Member -InputObject $o -MemberType NoteProperty -Name BodyType -Value ([string]$car.bodyType)
      Add-Member -InputObject $o -MemberType NoteProperty -Name TrunkTotal -Value ([int]$car.trunkTotal)
      Add-Member -InputObject $o -MemberType NoteProperty -Name TrunkItems -Value @($car.trunk)
      Add-Member -InputObject $o -MemberType NoteProperty -Name InstalledParts -Value @($car.installedParts)
      Add-Member -InputObject $o -MemberType NoteProperty -Name BuyingPrice -Value ([double]$car.buyingPrice)
      Add-Member -InputObject $o -MemberType NoteProperty -Name SellingPrice -Value ([double]$car.sellingPrice)
      Add-Member -InputObject $o -MemberType NoteProperty -Name BuyingPlayerPrice -Value ([double]$car.buyingPlayerPrice)
      Add-Member -InputObject $o -MemberType NoteProperty -Name BuyingMarketPrice -Value ([double]$car.buyingMarketPrice)
      Add-Member -InputObject $o -MemberType NoteProperty -Name SellingPlayerPrice -Value ([double]$car.sellingPlayerPrice)
      Add-Member -InputObject $o -MemberType NoteProperty -Name GearboxType -Value ([string]$car.gearboxType)
      Add-Member -InputObject $o -MemberType NoteProperty -Name FuelType -Value ([string]$car.fuelType)
       Add-Member -InputObject $o -MemberType NoteProperty -Name IsAbandonedWreck -Value ([bool](Test-CarIsWreck $car))
       Add-Member -InputObject $o -MemberType NoteProperty -Name IsWreckForSell -Value ([bool]$car.isWreckForSell)
       Add-Member -InputObject $o -MemberType NoteProperty -Name WasWreck -Value ([bool]$car.wasWreck)
      Add-Member -InputObject $o -MemberType NoteProperty -Name VehicleScoreCache -Value ([double]$car.vehicleScoreCache)
      Add-Member -InputObject $o -MemberType NoteProperty -Name ConditionText -Value (Format-CarPercent $car.mechanicalCondition)
       Add-CarReadinessProperties $o $car
      $hex=Get-CarColourHex $car.colorR $car.colorG $car.colorB
      Add-Member -InputObject $o -MemberType NoteProperty -Name ColorHex -Value $hex
      $colourLabel=Get-CarColourLabel $car.color $car.colorR $car.colorG $car.colorB
      Add-Member -InputObject $o -MemberType NoteProperty -Name ColourLabel -Value $colourLabel
      Add-Member -InputObject $o -MemberType NoteProperty -Name Color -Value ([string]$car.color) -Force
      Add-CarIconProperty $o
       [void]$carsReadyList.Items.Add($o)
      if($selectedId -ne "" -and ([string]$o.CarId) -eq $selectedId){
       $carsReadyList.SelectedItem=$o
      }
     }
     }
     if($null -ne $carsReadyStatus){
      $carsReadyStatus.Text=("Ready for sale (95%+): {0} | Click a car for details below" -f $readyCars.Count)
     }

     if($null -ne $carsForSaleStatus){
      $carsForSaleStatus.Text=("Currently advertised: {0} | Click a car for details below" -f $forSaleCars.Count)
     }

     $mapped=@($allCars | Where-Object {$_.bodyType -notlike "Body Type *" -and $_.bodyType -ne "Unknown Type"}).Count
     $waitingGarage=@($waitingCars | Where-Object {[bool]$_.inUndergroundGarage}).Count
      $waitingLive=@($waitingCars | Where-Object {[bool]$_.hasLiveVehicle}).Count
      $waitingInfoOnly=@($waitingCars | Where-Object {[bool]$_.isVehicleInfoOnly}).Count
      $carsStatus.Text=("Waiting: {0} | Below 95% and already collected/managed" -f $waitingCars.Count)

     if($selectedId -eq ""){
      Update-CarSelection
     }
     try{$carsSubTabs.UpdateLayout();Hydrate-CurrentCarsList}catch{}
    }else{
     $carsStatus.Text="Owned car data unavailable."
    }

    # The rebuild completed successfully; now remember this cars.json version.
    $script:lastCarsJsonStamp=$carsStamp
    $script:forceCarsUiRebuild=$false
   }catch{
    # Leave forceCarsUiRebuild true so a temporary parse/read failure is retried.
    $script:forceCarsUiRebuild=$true
    $carsStatus.Text=("Owned car data error: " + $_.Exception.Message)
   }
   }
  }else{
   $carsStatus.Text="Waiting for owned cars..."
  }
 }


}


$wa=[System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$panelWidth=[Math]::Min(1400,[Math]::Max(1000,$wa.Width-40))
$panelHeight=[Math]::Min(850,[Math]::Max(650,$wa.Height-80))
$w.WindowStyle="SingleBorderWindow"
$w.ResizeMode="CanResizeWithGrip"
$w.ShowInTaskbar=$true
$w.Topmost=$true
$w.Width=$panelWidth
$w.Height=$panelHeight
$w.Left=$wa.Left+[Math]::Max(12,[Math]::Round(($wa.Width-$panelWidth)/2))
$w.Top=$wa.Top+[Math]::Max(12,[Math]::Round(($wa.Height-$panelHeight)/2))
$w.Title="Car Dealer Companion ($script:OverlayBuildVersion)"

$script:isVisible=$true
$script:hwnd=[IntPtr]::Zero
function Focus-Companion{
 if(-not $script:isVisible){return}
 try{
  if($w.WindowState -eq "Minimized"){$w.WindowState="Normal"}
  $w.Topmost=$true
  [void]$w.Activate()
  if($script:hwnd -ne [IntPtr]::Zero){
   [void][CDIHotKey]::BringWindowToTop($script:hwnd)
   [void][CDIHotKey]::SetForegroundWindow($script:hwnd)
  }
  [void]$w.Focus()
 }catch{}
}
function Show-Companion{
 $script:isVisible=$true
 Refresh-UI
 $script:lastUiDataStamp=Get-UiDataStamp
$script:lastRuntimeCarPhotoStamp=Get-RuntimeCarPhotoStamp
 [void]$w.Show()
 $w.WindowState="Normal"
 Focus-Companion
}
function Hide-Companion{
 $script:isVisible=$false
 [void]$w.Hide()
}
function Toggle-Companion{
 if(-not $script:isVisible){Show-Companion;return}
 # If the Companion is visible but the game currently owns focus/cursor,
 # F1 restores Companion focus in one press instead of hiding it when the game owns focus.
 if($script:hwnd -ne [IntPtr]::Zero){
  $fg=[CDIHotKey]::GetForegroundWindow()
  if($fg -ne $script:hwnd){Focus-Companion;return}
 }
 Hide-Companion
}

$timer=New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval=[TimeSpan]::FromSeconds(1)
$timer.Add_Tick({
 if($script:isVisible){
  Update-CarsRefreshStatus
  $photoStamp=Get-RuntimeCarPhotoStamp
  if($photoStamp -ne $script:lastRuntimeCarPhotoStamp){
   $script:lastRuntimeCarPhotoStamp=$photoStamp
   $script:forceCarsUiRebuild=$true
   # v0.44.0.70: a newly generated runtime photo must repaint Cars immediately.
   # This is especially important for Custom paint cars, whose stock-colour
   # fallback PNG can arrive after the car data itself has stopped changing.
   Refresh-UI
  }
  $stamp=Get-UiDataStamp
  if($stamp -ne $script:lastUiDataStamp){
   $script:lastUiDataStamp=$stamp
   Refresh-UI
  }
 }
})
$timer.Start()

$HOTKEY=9021
$VK=0x70
$script:source=$null
$w.Add_SourceInitialized({
 $h=New-Object System.Windows.Interop.WindowInteropHelper($w)
 $hwnd=$h.Handle
 $script:hwnd=$hwnd
 [void][CDIHotKey]::RegisterHotKey($hwnd,$HOTKEY,0,$VK)
 $script:source=[System.Windows.Interop.HwndSource]::FromHwnd($hwnd)
 [void]$script:source.AddHook({
  param($a,$m,$wp,$lp,[ref]$handled)
  if($m -eq 0x0312 -and $wp.ToInt32() -eq $HOTKEY){
   Toggle-Companion
   $handled.Value=$true
  }
  return [IntPtr]::Zero
 })
})
$w.Add_Closing({
 param($s,$e)
 $e.Cancel=$true
 Hide-Companion
})
$w.Add_Closed({
 try{Remove-Item $pidPath -Force}catch{}
})
Refresh-UI
$script:lastUiDataStamp=Get-UiDataStamp
$script:lastRuntimeCarPhotoStamp=Get-RuntimeCarPhotoStamp
[void]$w.Show()
[void]$w.Activate()
[void][System.Windows.Threading.Dispatcher]::Run()

# ------------------------------------------------------------
# v0.43.3.0 EMBEDDED GAME ICONS
# ------------------------------------------------------------
function New-NavIconContent([string]$label,[string]$asset,[double]$iconSize=24){
 try{
  $panel=New-Object System.Windows.Controls.StackPanel
  $panel.Orientation=[System.Windows.Controls.Orientation]::Horizontal
  $panel.VerticalAlignment=[System.Windows.VerticalAlignment]::Center
  $bmp=New-CompanionBitmapImage $asset
  if($bmp){
   $img=New-Object System.Windows.Controls.Image
   $img.Source=$bmp;$img.Width=$iconSize;$img.Height=$iconSize;$img.Stretch='Uniform';$img.Margin='0,0,10,0'
   [void]$panel.Children.Add($img)
  }
  $txt=New-Object System.Windows.Controls.TextBlock
  $txt.Text=$label;$txt.Foreground='#F3F5F7';$txt.FontSize=14;$txt.FontWeight='SemiBold';$txt.VerticalAlignment='Center'
  [void]$panel.Children.Add($txt)
  return $panel
 }catch{return $label}
}
try{$navDashboard.Content=New-NavIconContent 'DASHBOARD' 'Icons/Navigation/dashboard.png'}catch{}
try{$navInventory.Content=New-NavIconContent 'INVENTORY' 'Icons/Navigation/inventory.png'}catch{}
try{$navParts.Content=New-NavIconContent 'PARTS' 'Icons/Navigation/parts.png'}catch{}
try{$navCars.Content=New-NavIconContent 'CARS' 'Icons/Navigation/cars.png'}catch{}
try{$navEmployees.Content=New-NavIconContent 'EMPLOYEES' 'Icons/Navigation/employees.png'}catch{}
try{$navContracts.Content=New-NavIconContent 'CONTRACTS' 'Icons/Navigation/contracts.png'}catch{}
try{$navAutomatedPlatform.Content=New-NavIconContent 'AUTOMATION' 'Icons/Navigation/settings.png'}catch{}
try{$navRacing.Content=New-NavIconContent 'RACING' 'Icons/Navigation/cars.png'}catch{}
try{$navAutoFleet.Content=New-NavIconContent 'AUTOFLEET + DEALERSHIPS' 'Icons/Navigation/cars.png'}catch{}
try{$navSettings.Content=New-NavIconContent 'SETTINGS' 'Icons/Navigation/settings.png'}catch{}
