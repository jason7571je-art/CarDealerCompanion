local MOD="CarDealerInventoryReader v0.45.0.0 RELEASE"
local base=(os.getenv("LOCALAPPDATA") or ".").."\\CarDealerInventoryOverlay"
local jsonPath=base.."\\inventory.json"
local storageJsonPath=base.."\\storage.json"
local repairJsonPath=base.."\\repair_machine.json"
local carsJsonPath=base.."\\cars_owned.json"
local diagnosticsRoot=(os.getenv("LOCALAPPDATA") or ".").."\\CarDealerInventoryOverlay\\Diagnostics"
os.execute('if not exist "'..diagnosticsRoot..'" mkdir "'..diagnosticsRoot..'" >nul 2>nul')
local fittedPartsDiagnosticPath=diagnosticsRoot.."\\fitted_parts_diagnostic.txt"
local diagnosticsEnabledPath=base.."\\diagnostics_enabled.flag"
local function diagnostics_enabled() local f=io.open(diagnosticsEnabledPath,"r"); if f then f:close(); return true end; return false end
local distanceDiagnosticPath=base.."\\distance_diagnostic.json"
local playerSpawnDiagnosticPath=base.."\\player_spawn_diagnostic.json"
local carsDistancePath=base.."\\cars_distance.json"
local businessJsonPath=base.."\\business.json"
local contractsJsonPath=base.."\\contracts.json"
local carsRefreshRequestPath=base.."\\cars_refresh_request.txt"

-- ============================================================
-- v0.44.0.72 RUNTIME ICONS - game-owned UI textures loaded from installed game
-- One-hit conversion. Independent of Cars and Contracts data logic.
-- ============================================================
do
local runtimeIconCacheRoot=base.."\\RuntimeIcons"
local runtimeIconReadyPath=base.."\\runtime_icons_v04400721212110.ready"
local runtimeIconDiagnosticPath=diagnosticsRoot.."\\runtime_icons.txt"
os.execute('if not exist "'..runtimeIconCacheRoot..'" mkdir "'..runtimeIconCacheRoot..'" >nul 2>nul')
local RUNTIME_ICONS={
 {rel="Icons/Navigation/dashboard.png",asset="/Game/CarDealerSim/Art/UI/cardealerlogo.cardealerlogo",w=804,h=512},
 {rel="Icons/Navigation/inventory.png",asset="/Game/CarDealerSim/UI/Assets/Icon/UI_Inventory_icn.UI_Inventory_icn",w=256,h=256},
 {rel="Icons/Navigation/parts.png",asset="/Game/CarDealerSim/Objects/Shop/ShopUI/Auto-partIcon.Auto-partIcon",w=128,h=128},
 {rel="Icons/Navigation/cars.png",asset="/Game/CarDealerSim/UI/Minimap/Legend/Icons/MAP_ico_PlayerCar.MAP_ico_PlayerCar",w=64,h=64},
 {rel="Icons/Navigation/employees.png",asset="/Game/CarDealerSim/Mechanics/Workers/UI/Textures/DIAL_Automation_icn.DIAL_Automation_icn",w=256,h=256},
 {rel="Icons/Navigation/contracts.png",asset="/Game/CarDealerSim/Mechanics/SideEvents/Wholesaler/UI_DealerContracts_icn.UI_DealerContracts_icn",w=256,h=256},
 {rel="Icons/Navigation/map.png",asset="/Game/CarDealerSim/UI/Minimap/Legend/Icons/GPS_icon.GPS_icon",w=64,h=64},
 {rel="Icons/Navigation/progression.png",asset="/Game/CarDealerSim/Inventory/Items/ItemsTextures/PS_Upgrade_icn.PS_Upgrade_icn",w=160,h=160},
 {rel="Icons/Inventory/all.png",asset="/Game/CarDealerSim/UI/Assets/Icon/UI_Inventory_icn.UI_Inventory_icn",w=256,h=256},
 {rel="Icons/Inventory/consumables.png",asset="/Game/CarDealerSim/Inventory/Items/ItemsTextures/candy_icon.candy_icon",w=128,h=128},
 {rel="Icons/Inventory/other.png",asset="/Game/CarDealerSim/Objects/Shop/ShopUI/Other_128.Other_128",w=128,h=128},
 {rel="Icons/Navigation/settings.png",asset="/Game/CarDealerSim/Mechanics/ShoppingList/UI/Textures/gear-solid.gear-solid",w=256,h=256},
 {rel="GameUI/Automation/Workers/DIAL_PartsRepairAuto_icn.png",asset="/Game/CarDealerSim/Mechanics/Workers/UI/Textures/DIAL_PartsRepairAuto_icn.DIAL_PartsRepairAuto_icn",w=256,h=256},
 {rel="Icons/Parts/Items/UI_icn_Tape.png",asset="/Game/CarDealerSim/Inventory/Items/ItemsTextures/New/UI_icn_Tape.UI_icn_Tape",w=256,h=256},
 {rel="Icons/Parts/Items/NewCarPlates01ICON.png",asset="/Game/CarDealerSim/Inventory/Items/ItemsTextures/NewCarPlates01ICON.NewCarPlates01ICON",w=256,h=256},
 {rel="Icons/Cars/Scanner_128.png",asset="/Game/CarDealerSim/UI/RadialMenu/Icons/Scanner_128.Scanner_128",w=128,h=128},
 {rel="GameUI/Inventory/Furniture/UI_Modern_Chair_ico.png",asset="/Game/CarDealerSim/DLC01/2D/DecorableIcons/UI_Modern_Chair_ico.UI_Modern_Chair_ico",w=256,h=256},
 {rel="GameUI/Inventory/Furniture/UI_Modern_DecorationA_ico.png",asset="/Game/CarDealerSim/DLC01/2D/DecorableIcons/UI_Modern_DecorationA_ico.UI_Modern_DecorationA_ico",w=256,h=256},
 {rel="GameUI/Inventory/Furniture/UI_Modern_Lamp_ico.png",asset="/Game/CarDealerSim/DLC01/2D/DecorableIcons/UI_Modern_Lamp_ico.UI_Modern_Lamp_ico",w=256,h=256},
 {rel="GameUI/Inventory/Furniture/UI_Modern_Phone_ico.png",asset="/Game/CarDealerSim/DLC01/2D/DecorableIcons/UI_Modern_Phone_ico.UI_Modern_Phone_ico",w=256,h=256},
 {rel="GameUI/Inventory/Furniture/UI_Modern_PictureA_ico.png",asset="/Game/CarDealerSim/DLC01/2D/DecorableIcons/UI_Modern_PictureA_ico.UI_Modern_PictureA_ico",w=256,h=256},
 {rel="GameUI/Inventory/Furniture/UI_Modern_Table_ico.png",asset="/Game/CarDealerSim/DLC01/2D/DecorableIcons/UI_Modern_Table_ico.UI_Modern_Table_ico",w=256,h=256},
 {rel="GameUI/Inventory/Furniture/UI_Modern_TrashCan_ico.png",asset="/Game/CarDealerSim/DLC01/2D/DecorableIcons/UI_Modern_TrashCan_ico.UI_Modern_TrashCan_ico",w=256,h=256},
 {rel="GameUI/Contracts/Branding/UI_DealerContracts_Logo.png",asset="/Game/CarDealerSim/Mechanics/SideEvents/Wholesaler/UI_DealerContracts_Logo.UI_DealerContracts_Logo",w=256,h=128},
 {rel="GameUI/Map/Icons/MAP_ico_PawnShop.png",asset="/Game/CarDealerSim/UI/Minimap/Legend/Icons/MAP_ico_PawnShop.MAP_ico_PawnShop",w=64,h=64},
 {rel="GameUI/Map/Icons/MAP_ico_Mail.png",asset="/Game/CarDealerSim/UI/Minimap/Legend/Icons/MAP_ico_Mail.MAP_ico_Mail",w=64,h=64},
 {rel="GameUI/Map/Icons/MAP_ico_Quest.png",asset="/Game/CarDealerSim/UI/Minimap/Legend/Icons/MAP_ico_Quest.MAP_ico_Quest",w=64,h=64},
 {rel="GameUI/Inventory/Loot/UI_icn_CBRadio.png",asset="/Game/CarDealerSim/LockPicking/Icons/UI_icn_CBRadio.UI_icn_CBRadio",w=256,h=256},
 {rel="GameUI/Inventory/Loot/UI_icn_CDxDVD.png",asset="/Game/CarDealerSim/LockPicking/Icons/UI_icn_CDxDVD.UI_icn_CDxDVD",w=256,h=256},
 {rel="GameUI/Inventory/Loot/UI_icn_Collectibles.png",asset="/Game/CarDealerSim/LockPicking/Icons/UI_icn_Collectibles.UI_icn_Collectibles",w=256,h=256},
 {rel="GameUI/Inventory/Loot/UI_icn_ElektronicDevices.png",asset="/Game/CarDealerSim/LockPicking/Icons/UI_icn_ElektronicDevices.UI_icn_ElektronicDevices",w=256,h=256},
 {rel="GameUI/Inventory/Loot/UI_icn_Gold.png",asset="/Game/CarDealerSim/LockPicking/Icons/UI_icn_Gold.UI_icn_Gold",w=256,h=256},
 {rel="GameUI/Inventory/Loot/UI_icn_Jewelery.png",asset="/Game/CarDealerSim/LockPicking/Icons/UI_icn_Jewelery.UI_icn_Jewelery",w=256,h=256},
 {rel="GameUI/Inventory/Loot/UI_icn_LockPicker.png",asset="/Game/CarDealerSim/LockPicking/Icons/UI_icn_LockPicker.UI_icn_LockPicker",w=256,h=256},
 {rel="GameUI/Inventory/Loot/UI_icn_Lootbox.png",asset="/Game/CarDealerSim/LockPicking/Icons/UI_icn_Lootbox.UI_icn_Lootbox",w=256,h=256},
 {rel="GameUI/Inventory/Loot/UI_icn_MusicalEquipment.png",asset="/Game/CarDealerSim/LockPicking/Icons/UI_icn_MusicalEquipment.UI_icn_MusicalEquipment",w=256,h=256},
 {rel="GameUI/Inventory/Loot/UI_icn_Safe.png",asset="/Game/CarDealerSim/LockPicking/Icons/UI_icn_Safe.UI_icn_Safe",w=256,h=256},
 {rel="GameUI/Inventory/Loot/UI_icn_Tools.png",asset="/Game/CarDealerSim/LockPicking/Icons/UI_icn_Tools.UI_icn_Tools",w=256,h=256},
 {rel="GameUI/Inventory/Loot/UI_icn_Vinyl.png",asset="/Game/CarDealerSim/LockPicking/Icons/UI_icn_Vinyl.UI_icn_Vinyl",w=256,h=256},
 {rel="GameUI/Inventory/Loot/UI_icn_Wallet.png",asset="/Game/CarDealerSim/LockPicking/Icons/UI_icn_Wallet.UI_icn_Wallet",w=256,h=256},
 {rel="GameUI/Inventory/Consumables/Cigarette-icon.png",asset="/Game/CarDealerSim/Inventory/Items/ItemsTextures/Cigarette-icon.Cigarette-icon",w=128,h=128},
 {rel="GameUI/Inventory/Consumables/candy_icon.png",asset="/Game/CarDealerSim/Inventory/Items/ItemsTextures/candy_icon.candy_icon",w=128,h=128},
 {rel="Icons/Parts/all.png",asset="/Game/CarDealerSim/Objects/Shop/ShopUI/Auto-partIcon.Auto-partIcon",w=128,h=128},
 {rel="Icons/Parts/engine.png",asset="/Game/CarDealerSim/Core/Vehicle/UI/ico_IndicatorLight_CheckEnginee.ico_IndicatorLight_CheckEnginee",w=128,h=128},
 {rel="Icons/Parts/brakes.png",asset="/Game/CarDealerSim/Core/Vehicle/UI/ico_IndicatorLight_BrakeWarning.ico_IndicatorLight_BrakeWarning",w=128,h=128},
 {rel="Icons/Parts/suspension.png",asset="/Game/CarDealerSim/Core/Vehicle/UI/ico_IndicatorLight_Suspensions.ico_IndicatorLight_Suspensions",w=128,h=128},
 {rel="Icons/Parts/repair.png",asset="/Game/CarDealerSim/Mechanics/Workers/UI/Textures/DIAL_PartsRepairAuto_icn.DIAL_PartsRepairAuto_icn",w=254,h=256},
 {rel="Icons/Parts/exhaust.png",asset="/Game/CarDealerSim/Inventory/Items/ItemsTextures/Exhaust_Mainfold.Exhaust_Mainfold",w=256,h=256},
 {rel="Icons/Parts/Items/UI_BrakeDisc_ico.png",asset="/Game/CarDealerSim/Inventory/Items/ItemsTextures/New/UI_BrakeDisc_ico.UI_BrakeDisc_ico",w=256,h=256},
 {rel="Icons/Parts/Items/UI_BrakeClips_ico.png",asset="/Game/CarDealerSim/Inventory/Items/ItemsTextures/New/UI_BrakeClips_ico.UI_BrakeClips_ico",w=256,h=256},
 {rel="Icons/Parts/Items/UI_clutch_ico.png",asset="/Game/CarDealerSim/Inventory/Items/ItemsTextures/New/UI_clutch_ico.UI_clutch_ico",w=256,h=256},
 {rel="Icons/Parts/Items/UI_battery_ico.png",asset="/Game/CarDealerSim/Inventory/Items/ItemsTextures/New/UI_battery_ico.UI_battery_ico",w=256,h=256},
 {rel="Icons/Parts/Items/UI_radiator_ico.png",asset="/Game/CarDealerSim/Inventory/Items/ItemsTextures/New/UI_radiator_ico.UI_radiator_ico",w=256,h=256},
 {rel="Icons/Parts/Items/UI_engine_ico.png",asset="/Game/CarDealerSim/Inventory/Items/ItemsTextures/New/UI_engine_ico.UI_engine_ico",w=256,h=256},
 {rel="Icons/Parts/Items/UI_FrontAbsorber_ico.png",asset="/Game/CarDealerSim/Inventory/Items/ItemsTextures/New/UI_FrontAbsorber_ico.UI_FrontAbsorber_ico",w=256,h=256},
 {rel="Icons/Parts/Items/UI_RearAbsorber_ico.png",asset="/Game/CarDealerSim/Inventory/Items/ItemsTextures/New/UI_RearAbsorber_ico.UI_RearAbsorber_ico",w=256,h=256},
 {rel="Icons/Parts/Items/UI_SuspensionPin_ico.png",asset="/Game/CarDealerSim/Inventory/Items/ItemsTextures/New/UI_SuspensionPin_ico.UI_SuspensionPin_ico",w=256,h=256},
 {rel="Icons/Parts/Items/DLC_UI_SuspensionPin_sport_ico.png",asset="/Game/CarDealerSim/DLC01/2D/UI/ProductIcons/DLC_UI_SuspensionPin_sport_ico.DLC_UI_SuspensionPin_sport_ico",w=256,h=256},
 {rel="Icons/Parts/Items/UI_CatalycticConverter_ico.png",asset="/Game/CarDealerSim/Inventory/Items/ItemsTextures/New/UI_CatalycticConverter_ico.UI_CatalycticConverter_ico",w=256,h=256},
 {rel="Icons/Parts/Items/UI_mainfold_ico.png",asset="/Game/CarDealerSim/Inventory/Items/ItemsTextures/New/UI_mainfold_ico.UI_mainfold_ico",w=256,h=256},
 {rel="Icons/Parts/Items/UI_muffler_ico.png",asset="/Game/CarDealerSim/Inventory/Items/ItemsTextures/New/UI_muffler_ico.UI_muffler_ico",w=256,h=256},
 {rel="Icons/Parts/Items/UI_resonator_ico.png",asset="/Game/CarDealerSim/Inventory/Items/ItemsTextures/New/UI_resonator_ico.UI_resonator_ico",w=256,h=256},
 {rel="Icons/Parts/Items/UI_tailpipe_ico.png",asset="/Game/CarDealerSim/Inventory/Items/ItemsTextures/New/UI_tailpipe_ico.UI_tailpipe_ico",w=256,h=256},
 {rel="Icons/Parts/Items/UI_WindshieldGlue_icn.png",asset="/Game/CarDealerSim/Inventory/Items/ItemsTextures/Windshield/UI_WindshieldGlue_icn.UI_WindshieldGlue_icn",w=128,h=128},
 {rel="Icons/Parts/Items/UI_Windshield_icn.png",asset="/Game/CarDealerSim/Inventory/Items/ItemsTextures/Windshield/UI_Windshield_icn.UI_Windshield_icn",w=128,h=128},
 {rel="Icons/Parts/Items/UI_Wheel_icn.png",asset="/Game/CarDealerSim/DLC01/2D/UI/CustomPanel/Assets/UI_Wheel_icn.UI_Wheel_icn",w=512,h=512},
 {rel="Icons/Parts/Items/fuse5a.png",assets={"/Game/CarDealerSim/Inventory/Items/ItemsTextures/New/UI_smallfuse5_ico.UI_smallfuse5_ico","/Game/CarDealerSim/Inventory/Items/ItemsTextures/UI_smallfuse5_ico.UI_smallfuse5_ico","/Game/CarDealerSim/Art/RepairView/FuseBox/UI_smallfuse5_ico.UI_smallfuse5_ico","/Game/CarDealerSim/Art/RepairView/FuseBox/FuseBlades/UI_smallfuse5_ico.UI_smallfuse5_ico"},w=256,h=256},
 {rel="Icons/Parts/Items/fuse10a.png",assets={"/Game/CarDealerSim/Inventory/Items/ItemsTextures/New/UI_smallfuse10_ico.UI_smallfuse10_ico","/Game/CarDealerSim/Inventory/Items/ItemsTextures/UI_smallfuse10_ico.UI_smallfuse10_ico","/Game/CarDealerSim/Art/RepairView/FuseBox/UI_smallfuse10_ico.UI_smallfuse10_ico","/Game/CarDealerSim/Art/RepairView/FuseBox/FuseBlades/UI_smallfuse10_ico.UI_smallfuse10_ico"},w=256,h=256},
 {rel="Icons/Parts/Items/fuse15a.png",assets={"/Game/CarDealerSim/Inventory/Items/ItemsTextures/New/UI_smallfuse15_ico.UI_smallfuse15_ico","/Game/CarDealerSim/Inventory/Items/ItemsTextures/UI_smallfuse15_ico.UI_smallfuse15_ico","/Game/CarDealerSim/Art/RepairView/FuseBox/UI_smallfuse15_ico.UI_smallfuse15_ico","/Game/CarDealerSim/Art/RepairView/FuseBox/FuseBlades/UI_smallfuse15_ico.UI_smallfuse15_ico"},w=256,h=256},
 {rel="Icons/Parts/Items/fuse20a.png",assets={"/Game/CarDealerSim/Inventory/Items/ItemsTextures/New/UI_smallfuse20_ico.UI_smallfuse20_ico","/Game/CarDealerSim/Inventory/Items/ItemsTextures/UI_smallfuse20_ico.UI_smallfuse20_ico","/Game/CarDealerSim/Art/RepairView/FuseBox/UI_smallfuse20_ico.UI_smallfuse20_ico","/Game/CarDealerSim/Art/RepairView/FuseBox/FuseBlades/UI_smallfuse20_ico.UI_smallfuse20_ico"},w=256,h=256},
 {rel="Icons/Parts/Items/fuse25a.png",assets={"/Game/CarDealerSim/Inventory/Items/ItemsTextures/New/UI_smallfuse25_ico.UI_smallfuse25_ico","/Game/CarDealerSim/Inventory/Items/ItemsTextures/UI_smallfuse25_ico.UI_smallfuse25_ico","/Game/CarDealerSim/Art/RepairView/FuseBox/UI_smallfuse25_ico.UI_smallfuse25_ico","/Game/CarDealerSim/Art/RepairView/FuseBox/FuseBlades/UI_smallfuse25_ico.UI_smallfuse25_ico"},w=256,h=256},
 {rel="Icons/Parts/Items/fuse30a.png",assets={"/Game/CarDealerSim/Inventory/Items/ItemsTextures/New/UI_maxifuse30_ico.UI_maxifuse30_ico","/Game/CarDealerSim/Inventory/Items/ItemsTextures/UI_maxifuse30_ico.UI_maxifuse30_ico","/Game/CarDealerSim/Art/RepairView/FuseBox/UI_maxifuse30_ico.UI_maxifuse30_ico","/Game/CarDealerSim/Art/RepairView/FuseBox/FuseBlades/UI_maxifuse30_ico.UI_maxifuse30_ico"},w=256,h=256},
 {rel="Icons/Parts/Items/fuse40a.png",assets={"/Game/CarDealerSim/Inventory/Items/ItemsTextures/New/UI_maxifuse40_ico.UI_maxifuse40_ico","/Game/CarDealerSim/Inventory/Items/ItemsTextures/UI_maxifuse40_ico.UI_maxifuse40_ico","/Game/CarDealerSim/Art/RepairView/FuseBox/UI_maxifuse40_ico.UI_maxifuse40_ico","/Game/CarDealerSim/Art/RepairView/FuseBox/FuseBlades/UI_maxifuse40_ico.UI_maxifuse40_ico"},w=256,h=256},
 {rel="Icons/Parts/Items/fuse50a.png",assets={"/Game/CarDealerSim/Inventory/Items/ItemsTextures/New/UI_maxifuse50_ico.UI_maxifuse50_ico","/Game/CarDealerSim/Inventory/Items/ItemsTextures/UI_maxifuse50_ico.UI_maxifuse50_ico","/Game/CarDealerSim/Art/RepairView/FuseBox/UI_maxifuse50_ico.UI_maxifuse50_ico","/Game/CarDealerSim/Art/RepairView/FuseBox/FuseBlades/UI_maxifuse50_ico.UI_maxifuse50_ico"},w=256,h=256},
 {rel="Icons/Parts/Items/fuse60a.png",assets={"/Game/CarDealerSim/Inventory/Items/ItemsTextures/New/UI_maxifuse60_ico.UI_maxifuse60_ico","/Game/CarDealerSim/Inventory/Items/ItemsTextures/UI_maxifuse60_ico.UI_maxifuse60_ico","/Game/CarDealerSim/Art/RepairView/FuseBox/UI_maxifuse60_ico.UI_maxifuse60_ico","/Game/CarDealerSim/Art/RepairView/FuseBox/FuseBlades/UI_maxifuse60_ico.UI_maxifuse60_ico"},w=256,h=256},
}
local runtimeIconBatchPending=false
local runtimeIconBatchFinished=false
local runtimeIconRetryCount=0
local RUNTIME_ICON_MAX_RETRIES=8
local RUNTIME_ICON_CHUNK_SIZE=6
local RUNTIME_ICON_CHUNK_DELAY_MS=250
local function runtime_icon_name(rel) return tostring(rel or ""):gsub("[^%w_-]","_") end
local function runtime_icon_diag(line)
 local f=io.open(runtimeIconDiagnosticPath,"a")
 if f then f:write(os.date("%Y-%m-%d %H:%M:%S").."  "..tostring(line or "").."\n");f:close() end
end
-- v0.44.0.72.12.1.2: a file "existing" is not the same as a file having data.
-- ExportTexture2D/ExportRenderTarget can both create a 0-byte file without
-- erroring, and the old exists()/success checks only opened the handle -
-- this is what silently broke every single Icons/Parts/* icon. Everything
-- below now checks actual byte size.
local function runtime_icon_file_size(path)
 local f=io.open(path,"rb")
 if not f then return -1 end
 local size=f:seek("end")
 f:close()
 return size or -1
end
local function runtime_icon_exists(rel)
 return runtime_icon_file_size(runtimeIconCacheRoot.."\\"..runtime_icon_name(rel)..".png")>0
end
-- v0.44.0.72.12.1.10: LoadAsset can return a non-nil Lua object for a
-- package that exists but isn't actually resident in memory yet - the
-- object looks present but the underlying UObject pointer is invalid,
-- and using it (e.g. in K2_DrawTexture) throws "UObject instance is
-- nullptr" instead of failing cleanly. Checking :IsValid() catches this
-- before it ever reaches the draw call. If the wrapper has no IsValid
-- method at all, assume it's fine (matches the old behaviour) rather
-- than rejecting every asset on a UE4SS version that doesn't expose it.
local function is_valid_uobject(obj)
 local ok,result=pcall(function() return obj:IsValid() end)
 if not ok then return true end
 return result and true or false
end
local function runtime_icon_export(world,library,req)
 local texture=nil
 local chosenAsset=nil
 if req.assets then
  for _,candidate in ipairs(req.assets) do
   local okLoad,loaded=pcall(function() return LoadAsset(candidate) end)
   if okLoad and loaded and is_valid_uobject(loaded) then texture=loaded;chosenAsset=candidate;break end
  end
 else
  local okLoad,loaded=pcall(function() return LoadAsset(req.asset) end)
  if okLoad and loaded and is_valid_uobject(loaded) then texture=loaded;chosenAsset=req.asset end
 end
 if not texture then return false,"LoadAsset failed or returned an invalid/not-yet-resident object" end
 -- Prefer Unreal's direct Texture2D export for small UI/part textures.
 -- Some UI textures produced a valid but fully transparent image when drawn
 -- through a render target. Direct export avoids that conversion path.
 local directName=runtime_icon_name(req.rel)
 local directOk=pcall(function()
  library:ExportTexture2D(world,texture,runtimeIconCacheRoot,directName)
 end)
 if directOk then
  local directPng=runtimeIconCacheRoot.."\\"..directName..".png"
  local directRaw=runtimeIconCacheRoot.."\\"..directName
  if runtime_icon_file_size(directPng)>0 then
   return true,(chosenAsset or req.asset).." [direct]"
  end
  if runtime_icon_file_size(directRaw)>0 then
   os.remove(directPng)
   if os.rename(directRaw,directPng) then
    return true,(chosenAsset or req.asset).." [direct]"
   end
  end
  -- Direct export produced nothing usable - clean up so an empty/partial
  -- file can't later be mistaken for a completed export, then fall through
  -- to the render-target path below.
  os.remove(directPng)
  os.remove(directRaw)
 end
 local rt=library:CreateRenderTarget2D(world,req.w or 256,req.h or 256,3,{R=0.0,G=0.0,B=0.0,A=0.0},false,false)
 if not rt then return false,"render target failed" end
 local canvasOut,sizeOut,contextOut={},{},{}
 library:BeginDrawCanvasToRenderTarget(world,rt,canvasOut,sizeOut,contextOut)
 local canvas=canvasOut.Canvas
 if not canvas or not sizeOut.RenderTarget then return false,"canvas/context unavailable" end
 local okDraw,errDraw=pcall(function()
  canvas:K2_DrawTexture(texture,{X=0.0,Y=0.0},{X=tonumber(req.w or 256),Y=tonumber(req.h or 256)},{X=0.0,Y=0.0},{X=1.0,Y=1.0},{R=1.0,G=1.0,B=1.0,A=1.0},0,0.0,{X=0.0,Y=0.0})
 end)
 if not okDraw then return false,"draw failed: "..tostring(errDraw) end
 library:EndDrawCanvasToRenderTarget(world,sizeOut)
 local name=runtime_icon_name(req.rel)
 library:ExportRenderTarget(world,rt,runtimeIconCacheRoot,name)
 local raw=runtimeIconCacheRoot.."\\"..name
 local png=raw..".png"
 if runtime_icon_file_size(raw)>0 then
  os.remove(png)
  local renamed,renameErr=os.rename(raw,png)
  if not renamed then return false,"rename failed: "..tostring(renameErr) end
 end
 if runtime_icon_file_size(png)>0 then
  return true,chosenAsset
 end
 os.remove(png)
 os.remove(raw)
 return false,"export produced an empty file"
end
local function queue_runtime_icons_once()
 if runtimeIconBatchPending or runtimeIconBatchFinished then return end
 local ready=io.open(runtimeIconReadyPath,"rb")
 if ready then ready:close();runtimeIconBatchFinished=true;return end
 local world=FindFirstOf("BP_GameMode_C") or FindFirstOf("BP_CDSGameInstance_C")
 local system=StaticFindObject("/Script/Engine.Default__KismetSystemLibrary")
 local library=StaticFindObject("/Script/Engine.Default__KismetRenderingLibrary")
 if not world or not system or not library then return end
 runtimeIconBatchPending=true
 local offOk=pcall(function() system:ExecuteConsoleCommand(world,"r.TextureStreaming 0",nil) end)
 if not offOk then runtimeIconBatchPending=false;return end
 ExecuteWithDelay(2000,function()
  ExecuteInGameThread(function()
   local probe={rel="Icons/Parts/Items/UI_engine_ico.png",asset="/Game/CarDealerSim/Inventory/Items/ItemsTextures/New/UI_engine_ico.UI_engine_ico",w=256,h=256}
   local probeOk,probeErr=runtime_icon_export(world,library,probe)
   if not probeOk then
    runtime_icon_diag("WAIT: render path not ready yet: "..tostring(probeErr))
    pcall(function() system:ExecuteConsoleCommand(world,"r.TextureStreaming 1",nil) end)
    runtimeIconBatchPending=false
    return
   end
   -- Clean up any broken (0-byte) cache files from a previous run - real
   -- files are left alone so a successful icon never gets redone.
   for _,req in ipairs(RUNTIME_ICONS) do
    local target=runtimeIconCacheRoot.."\\"..runtime_icon_name(req.rel)..".png"
    if runtime_icon_file_size(target)<=0 then os.remove(target) end
   end

   -- v0.44.0.72.12.1.2: export in small chunks spread across several
   -- game-thread ticks instead of all 73 textures in one synchronous
   -- callback. Running the full batch in a single frame was the other half
   -- of the Icons/Parts bug (later entries in the loop came out blank) and
   -- it also produced a visible stutter every time this ran.
   local generated,existing,failed=0,0,0
   runtime_icon_diag("Runtime icon one-hit export started: "..tostring(#RUNTIME_ICONS).." mapping(s), chunk size "..tostring(RUNTIME_ICON_CHUNK_SIZE)..".")
   local index=1
   local function run_chunk()
    local processedInChunk=0
    while index<=#RUNTIME_ICONS and processedInChunk<RUNTIME_ICON_CHUNK_SIZE do
     local req=RUNTIME_ICONS[index]
     if runtime_icon_exists(req.rel) then
      existing=existing+1
     else
      local ok,detail=runtime_icon_export(world,library,req)
      if ok then generated=generated+1;runtime_icon_diag("OK  "..req.rel.." <- "..tostring(detail or req.asset))
      else failed=failed+1;runtime_icon_diag("FAIL "..req.rel.." | "..tostring(detail)) end
     end
     index=index+1
     processedInChunk=processedInChunk+1
    end
    if index<=#RUNTIME_ICONS then
     ExecuteWithDelay(RUNTIME_ICON_CHUNK_DELAY_MS,function()
      ExecuteInGameThread(run_chunk)
     end)
    else
     pcall(function() system:ExecuteConsoleCommand(world,"r.TextureStreaming 1",nil) end)
     runtime_icon_diag("COMPLETE generated="..tostring(generated).." existing="..tostring(existing).." failed="..tostring(failed)..". Streaming restored.")
     runtimeIconBatchPending=false
     if failed>0 and runtimeIconRetryCount<RUNTIME_ICON_MAX_RETRIES then
      -- v0.44.0.72.12.1.10: some assets load a non-nil-but-invalid object on
      -- the first attempt (not yet resident in memory) and self-heal once
      -- the game itself references that content. Don't write the ready
      -- marker or stop trying while failures remain - the outer 5-second
      -- LoopAsync will call this again automatically, retrying only the
      -- entries that don't already have a real cached file, up to a capped
      -- number of attempts so a genuinely broken asset doesn't retry forever.
      runtimeIconRetryCount=runtimeIconRetryCount+1
      runtime_icon_diag("RETRY scheduled ("..tostring(runtimeIconRetryCount).."/"..tostring(RUNTIME_ICON_MAX_RETRIES).."): "..tostring(failed).." icon(s) still failing.")
     else
      if failed>0 then
       runtime_icon_diag("GIVING UP after "..tostring(runtimeIconRetryCount).." retries with "..tostring(failed).." icon(s) still failing. Marking one-hit complete anyway.")
      end
      local marker=io.open(runtimeIconReadyPath,"w")
      if marker then marker:write("v0.44.0.72.12.1.10 generated="..tostring(generated).." existing="..tostring(existing).." failed="..tostring(failed).."\n");marker:close() end
      runtimeIconBatchFinished=true
     end
    end
   end
   run_chunk()
  end)
 end)
end

-- Try every five seconds until the game has a usable render canvas. Once the
-- versioned ready marker exists this loop becomes a no-op on future launches.
LoopAsync(5000,function()
 if runtimeIconBatchFinished then return true end
 ExecuteInGameThread(function() pcall(queue_runtime_icons_once) end)
 return false
end)
end -- isolated runtime-icon scope; avoids Lua 200-local main-chunk limit


-- ============================================================
-- v0.44.0.70 RUNTIME CAR PHOTOS - game-owned photos loaded from installed game
-- ============================================================
local carPhotoCacheRoot=base.."\\RuntimeCarPhotos"
os.execute('if not exist "'..carPhotoCacheRoot..'" mkdir "'..carPhotoCacheRoot..'" >nul 2>nul')
local RUNTIME_CAR_PHOTOS={
 ["280G"]={
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/280G/280G_Black.280G_Black",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/280G/280G_Red_0.280G_Red_0",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/280G/280G_Blue.280G_Blue",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/280G/280G_Silver.280G_Silver",
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/280G/280G_White_0.280G_White_0",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/280G/280G_Purple.280G_Purple",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/280G/280G_NavyBlue.280G_NavyBlue",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/280G/280G_Gray.280G_Gray",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/280G/280G_Gold.280G_Gold",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/280G/280G_Green.280G_Green",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/280G/280G_Brown.280G_Brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/280G/280G_Orange.280G_Orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/280G/280G_Yellow_0.280G_Yellow_0",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/280G/280G_Graphite.280G_Graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/280G/280G_Light-Blue.280G_Light-Blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/280G/280G_Light-Green.280G_Light-Green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/280G/cavallaro-280g-silver.cavallaro-280g-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/280G/cavallaro-280g-gold.cavallaro-280g-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/280G/cavallaro-280g-diamond.cavallaro-280g-diamond",
 },
 ["350s"]={
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/350s/350s_White.350s_White",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/350s/350S_Red/350S_Red_0.350S_Red_0",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/350s/350s_Gold.350s_Gold",
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/350s/350s_Black.350s_Black",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/350s/350S_Silver/350S_Silver_0.350S_Silver_0",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/350s/350s_Blue.350s_Blue",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/350s/350s_Purple.350s_Purple",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/350s/350s_NavyBlue.350s_NavyBlue",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/350s/350s_Gray.350s_Gray",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/350s/350s_Green.350s_Green",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/350s/350s_Brown.350s_Brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/350s/350s_Orange.350s_Orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/350s/350S_Yellow/350S_Yellow_0.350S_Yellow_0",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/350s/350s_Graphite.350s_Graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/350s/350s_LightBlue.350s_LightBlue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/350s/350s_LightGreen.350s_LightGreen",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/350s/350s_SuperSilver.350s_SuperSilver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/350s/350s_SuperGold.350s_SuperGold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/350s/350s_SuperDiamond.350s_SuperDiamond",
 },
 ["600C"]={
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/600C/600C_White_0.600C_White_0",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/600C/600C_Red_0.600C_Red_0",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/600C/600C_Gold_0.600C_Gold_0",
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/600C/600c_Black.600c_Black",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/600C/600c_silver.600c_silver",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/600C/600c_Blue.600c_Blue",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/600C/600c_Purple.600c_Purple",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/600C/600c_NavyBlue.600c_NavyBlue",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/600C/600c_Gray.600c_Gray",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/600C/600c_Green.600c_Green",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/600C/600c_Brown.600c_Brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/600C/600c_orange.600c_orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/600C/600c_yellow.600c_yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/600C/600c_Graphite.600c_Graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/600C/600c_Light-Blue.600c_Light-Blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/600C/600c_Light-Green.600c_Light-Green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/600C/umx-600c-silver.umx-600c-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/600C/umx-600c-gold.umx-600c-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/600C/umx-600c-diamond.umx-600c-diamond",
 },
 ["700R"]={
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/700R/700R_White/700R_White_0.700R_White_0",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/700R/red.red",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/700R/700R_Gold/700R_Gold_0.700R_Gold_0",
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/700R/700R_Black/700R_Black_0.700R_Black_0",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/700R/700R_Silver/700R_Silver_0.700R_Silver_0",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/700R/700R_Blue/700R_Blue_0.700R_Blue_0",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/700R/purple.purple",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/700R/light-blue.light-blue",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/700R/gray.gray",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/700R/700R_Green/700R_Green_0.700R_Green_0",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/700R/brown.brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/700R/orange.orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/700R/yellow.yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/700R/graphite.graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/700R/light-blue.light-blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/700R/light-green.light-green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/700R/umx-700r-silver.umx-700r-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/700R/umx-700r-gold.umx-700r-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/700R/umx-700r-diamond.umx-700r-diamond",
 },
 ["800C"]={
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/800C/800C_White_0.800C_White_0",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/800C/800C_Red_0.800C_Red_0",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/800C/800C_Gold_0.800C_Gold_0",
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/800C/800C_Black_0.800C_Black_0",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/800C/silver.silver",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/800C/blue.blue",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/800C/purple.purple",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/800C/navyblue.navyblue",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/800C/gray.gray",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/800C/green.green",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/800C/brown.brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/800C/orange.orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/800C/yellow.yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/800C/graphite.graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/800C/light-blue.light-blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/800C/light-green.light-green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/800C/umx-800c-silver.umx-800c-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/800C/umx-800c-gold.umx-800c-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/800C/umx-800c-diamond.umx-800c-diamond",
 },
 ["Allegretto"]={
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Allegretto/Allegretto_Brown_0.Allegretto_Brown_0",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Allegretto/Allegretto_Red_0.Allegretto_Red_0",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Allegretto/Allegretto_Green_0.Allegretto_Green_0",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Allegretto/Allegretto_Silver_0.Allegretto_Silver_0",
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Allegretto/Allegretto_Black.Allegretto_Black",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Allegretto/Allegretto_Blue.Allegretto_Blue",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Allegretto/Allegretto_Purple.Allegretto_Purple",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Allegretto/Allegretto_NavyBlue.Allegretto_NavyBlue",
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Allegretto/Allegretto_White.Allegretto_White",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Allegretto/Allegretto_Grey.Allegretto_Grey",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Allegretto/Allegretto_Gold.Allegretto_Gold",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Allegretto/Allegretto_Orange.Allegretto_Orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Allegretto/Allegretto_Yellow.Allegretto_Yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Allegretto/Allegretto_Graphite.Allegretto_Graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Allegretto/Allegretto_Light-Blue.Allegretto_Light-Blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Allegretto/Allegretto_Light-Green.Allegretto_Light-Green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Allegretto/harmonia-allegretto-silver.harmonia-allegretto-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Allegretto/harmonia-allegretto-gold.harmonia-allegretto-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Allegretto/harmonia-allegretto-diamond.harmonia-allegretto-diamond",
 },
 ["Andante"]={
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Andante/Andante_Black_0.Andante_Black_0",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Andante/Andante_NavyBlue_0.Andante_NavyBlue_0",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Andante/Andante_Silver_0.Andante_Silver_0",
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Andante/Andante_White_0.Andante_White_0",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Andante/Andante_Silver_0.Andante_Silver_0",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Andante/Andante_Red.Andante_Red",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Andante/Andante_Blue.Andante_Blue",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Andante/Andante_Purple.Andante_Purple",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Andante/Andante_Gold.Andante_Gold",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Andante/Andante_Green.Andante_Green",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Andante/Andante_Brown.Andante_Brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Andante/Andante_Orange.Andante_Orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Andante/Andante_Yellow.Andante_Yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Andante/Andante_Graphite.Andante_Graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Andante/Andante_Light-Blue.Andante_Light-Blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Andante/Andante_Light-Green.Andante_Light-Green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Andante/harmonia-andante-silver.harmonia-andante-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Andante/harmonia-andante-gold.harmonia-andante-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Andante/harmonia-andante-diamond.harmonia-andante-diamond",
 },
 ["Ascend"]={
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ascend/white.white",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ascend/red.red",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ascend/gold.gold",
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ascend/Ascend_Black_0.Ascend_Black_0",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ascend/Ascend_Silver_0.Ascend_Silver_0",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ascend/blue.blue",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ascend/purple.purple",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ascend/Ascend_NavyBlue_0.Ascend_NavyBlue_0",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ascend/gray.gray",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ascend/green.green",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ascend/brown.brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ascend/orange.orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ascend/yellow.yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ascend/Ascend_Graphite_0.Ascend_Graphite_0",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ascend/light-blue.light-blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ascend/light-green.light-green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ascend/ascend-special-silver.ascend-special-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ascend/ascend-special-gold.ascend-special-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ascend/ascend-special-diamond.ascend-special-diamond",
 },
 ["AscendL"]={
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/AscendL/AscendL_White_0.AscendL_White_0",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/AscendL/AscendL_Red_0.AscendL_Red_0",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/AscendL/gold.gold",
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/AscendL/black.black",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/AscendL/silver.silver",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/AscendL/blue.blue",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/AscendL/purple.purple",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/AscendL/navyblue.navyblue",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/AscendL/gray.gray",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/AscendL/AscendL_Green_0.AscendL_Green_0",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/AscendL/brown.brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/AscendL/orange.orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/AscendL/yellow.yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/AscendL/AscendL_Graphite_0.AscendL_Graphite_0",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/AscendL/lightblue.lightblue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/AscendL/lightgreen.lightgreen",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/AscendL/specialsilver.specialsilver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/AscendL/specialgold.specialgold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/AscendL/specialdiamond.specialdiamond",
 },
 ["Aurora"]={
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Aurora/white.White",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Aurora/red.Red",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Aurora/gold.Gold",
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Aurora/Outrider_Black_0.Outrider_Black_0",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Aurora/silver.Silver",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Aurora/blue.blue",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Aurora/purple.purple",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Aurora/Outrider_NavyBlue_0.Outrider_NavyBlue_0",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Aurora/Outrider_Gray_0.Outrider_Gray_0",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Aurora/green.green",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Aurora/brown.brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Aurora/orange.orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Aurora/Outrider_Yellow_0.Outrider_Yellow_0",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Aurora/graphite.graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Aurora/light-blue.light-blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Aurora/light-green.light-green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Aurora/aurora-outrider-silver.aurora-outrider-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Aurora/aurora-outrider-gold.aurora-outrider-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Aurora/aurora-outrider-diamond.aurora-outrider-diamond",
 },
 ["Boulder"]={
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Boulder/Boulder_Green_0.Boulder_Green_0",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Boulder/Boulder_Gray_0.Boulder_Gray_0",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Boulder/Boulder_Brown_0.Boulder_Brown_0",
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Boulder/Boulder_Black.Boulder_Black",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Boulder/Boulder_Silver.Boulder_Silver",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Boulder/Boulder_Red.Boulder_Red",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Boulder/Boulder_Blue.Boulder_Blue",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Boulder/Boulder_Purple.Boulder_Purple",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Boulder/Boulder_NavyBlue.Boulder_NavyBlue",
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Boulder/Boulder_White.Boulder_White",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Boulder/Boulder_Gold.Boulder_Gold",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Boulder/Boulder_Orange.Boulder_Orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Boulder/Boulder_Yellow.Boulder_Yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Boulder/Boulder_Graphite.Boulder_Graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Boulder/Boulder_Light-Blue.Boulder_Light-Blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Boulder/Boulder_Light-Green.Boulder_Light-Green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Boulder/offrider-boulder-silver.offrider-boulder-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Boulder/offrider-boulder-gold.offrider-boulder-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Boulder/offrider-boulder-diamond.offrider-boulder-diamond",
 },
 ["Canyon"]={
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Canyon/Canyon_Black_0.Canyon_Black_0",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Canyon/Canyon_Red_0.Canyon_Red_0",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Canyon/Canyon_Blue_0.Canyon_Blue_0",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Canyon/Canyon_Silver.Canyon_Silver",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Canyon/Canyon_Purple.Canyon_Purple",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Canyon/Canyon_NavyBlue.Canyon_NavyBlue",
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Canyon/Canyon_White.Canyon_White",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Canyon/Canyon_Gray.Canyon_Gray",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Canyon/Canyon_Gold.Canyon_Gold",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Canyon/Canyon_Green.Canyon_Green",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Canyon/Canyon_Brown.Canyon_Brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Canyon/Canyon_Orange.Canyon_Orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Canyon/Canyon_Yellow.Canyon_Yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Canyon/Canyon_Graphite.Canyon_Graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Canyon/Canyon_Light-Blue.Canyon_Light-Blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Canyon/Canyon_Light-Green.Canyon_Light-Green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Canyon/offrider-canyon-silver.offrider-canyon-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Canyon/offrider-canyon-gold.offrider-canyon-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Canyon/offrider-canyon-diamond.offrider-canyon-diamond",
 },
 ["Cortega"]={
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Cortega/Cortega_Black_0.Cortega_Black_0",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Cortega/Cortega_Red.Cortega_Red",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Cortega/Cortega_Blue.Cortega_Blue",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Cortega/Cortega_Silver_0.Cortega_Silver_0",
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Cortega/Cortega_White_0.Cortega_White_0",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Cortega/Cortega_Purple.Cortega_Purple",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Cortega/Cortega_NavyBlue_0.Cortega_NavyBlue_0",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Cortega/Cortega_Gray_0.Cortega_Gray_0",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Cortega/Cortega_Gold.Cortega_Gold",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Cortega/Cortega_Green.Cortega_Green",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Cortega/Cortega_Brown.Cortega_Brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Cortega/Cortega_Orange.Cortega_Orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Cortega/Cortega_Yellow.Cortega_Yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Cortega/Cortega_Graphite.Cortega_Graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Cortega/Cortega_Light-Blue.Cortega_Light-Blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Cortega/Cortega_Light-Green.Cortega_Light-Green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Cortega/phantom-cortega-silver.phantom-cortega-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Cortega/phantom-cortega-gold.phantom-cortega-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Cortega/phantom-cortega-diamond.phantom-cortega-diamond",
 },
 ["Elevate"]={
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Elevate/white.white",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Elevate/Elevate_Red_0.Elevate_Red_0",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Elevate/gold.gold",
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Elevate/Elevate_Black_0.Elevate_Black_0",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Elevate/Elevate_Silver_0.Elevate_Silver_0",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Elevate/blue.blue",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Elevate/purple.purple",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Elevate/Elevate_NavyBlue_0.Elevate_NavyBlue_0",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Elevate/gray.gray",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Elevate/green.green",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Elevate/brown.brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Elevate/orange.orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Elevate/yellow.yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Elevate/graphite.graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Elevate/light-blue.light-blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Elevate/light-green.light-green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Elevate/special-silver.special-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Elevate/special-gold.special-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Elevate/special-diamond.special-diamond",
 },
 ["Gale"]={
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Gale/Gale_Black.Gale_Black",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Gale/Gale_Red.Gale_Red",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Gale/Gale_Blue.Gale_Blue",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Gale/Gale_Silver_0.Gale_Silver_0",
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Gale/Gale_White.Gale_White",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Gale/Gale_Purple.Gale_Purple",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Gale/Gale_NavyBlue.Gale_NavyBlue",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Gale/Gale_Gray.Gale_Gray",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Gale/Gale_Gold.Gale_Gold",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Gale/Gale_Green.Gale_Green",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Gale/Gale_Brown_0.Gale_Brown_0",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Gale/Gale_Orange_0.Gale_Orange_0",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Gale/Gale_Yellow.Gale_Yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Gale/Gale_Graphite.Gale_Graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Gale/Gale_Light-Blue.Gale_Light-Blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Gale/Gale_Light-Green.Gale_Light-Green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Gale/phantom-gale-silver.phantom-gale-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Gale/phantom-gale-gold.phantom-gale-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Gale/phantom-gale-diamond.phantom-gale-diamond",
 },
 ["Highland"]={
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highland/white.white",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highland/Highland_Red_0.Highland_Red_0",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highland/gold.gold",
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highland/Highland_Black_0.Highland_Black_0",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highland/silver.silver",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highland/blue.blue",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highland/purple.purple",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highland/Highland_NavyBlue_0.Highland_NavyBlue_0",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highland/gray.gray",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highland/green.green",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highland/brown.brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highland/oragne.oragne",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highland/yellow.yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highland/Highland_Graphite_0.Highland_Graphite_0",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highland/light-blue.light-blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highland/light-green.light-green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highland/special-silver.special-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highland/special-gold.special-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highland/special-diamond.special-diamond",
 },
 ["Highrunner"]={
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highrunner/white.white",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highrunner/red.red",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highrunner/Highrunner_Gold_0.Highrunner_Gold_0",
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highrunner/Highrunner_Black_0.Highrunner_Black_0",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highrunner/Highrunner_Silver_0.Highrunner_Silver_0",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highrunner/blue.blue",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highrunner/purple.purple",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highrunner/navyblue.navyblue",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highrunner/gray.gray",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highrunner/green.green",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highrunner/brown.brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highrunner/orange.orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highrunner/tellow.tellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highrunner/graphite.graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highrunner/Highrunner_Light-Blue_0.Highrunner_Light-Blue_0",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highrunner/light-green.light-green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highrunner/special-silver.special-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highrunner/special-gold.special-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Highrunner/special-diamond.special-diamond",
 },
 ["Horizon"]={
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Horizon/Horizon_White_0.Horizon_White_0",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Horizon/Horizon_Red_0.Horizon_Red_0",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Horizon/Horizon_Gold.Horizon_Gold",
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Horizon/Horizon_Black.Horizon_Black",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Horizon/Horizon_Silver.Horizon_Silver",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Horizon/Horizon_Blue_0.Horizon_Blue_0",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Horizon/Horizon_Purple.Horizon_Purple",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Horizon/Horizon_NavyBlue.Horizon_NavyBlue",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Horizon/Horizon_Gray.Horizon_Gray",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Horizon/Horizon_Green_0.Horizon_Green_0",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Horizon/Horizon_Brown.Horizon_Brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Horizon/Horizon_Orange.Horizon_Orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Horizon/Horizon_Yellow.Horizon_Yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Horizon/Horizon_Graphite.Horizon_Graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Horizon/Horizon_Light-Blue.Horizon_Light-Blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Horizon/Horizon_Light-Green.Horizon_Light-Green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Horizon/Horizon_SUPER-SILVER.Horizon_SUPER-SILVER",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Horizon/Horizon_SUPER-GOLD.Horizon_SUPER-GOLD",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Horizon/Horizon_SUPER-DIAMOND.Horizon_SUPER-DIAMOND",
 },
 ["Ignis"]={
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ignis/Ignis_Black_0.Ignis_Black_0",
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ignis/Ignis_White_0.Ignis_White_0",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ignis/Ignis_Silver_0.Ignis_Silver_0",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ignis/Ignis_Gray.Ignis_Gray",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ignis/Ignis_NavyBlue.Ignis_NavyBlue",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ignis/Ignis_Red_0.Ignis_Red_0",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ignis/Ignis_Blue.Ignis_Blue",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ignis/Ignis_Purple.Ignis_Purple",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ignis/Ignis_Gold.Ignis_Gold",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ignis/Ignis_Green.Ignis_Green",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ignis/Ignis_Brown.Ignis_Brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ignis/Ignis_Orange.Ignis_Orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ignis/Ignis_Yellow_0.Ignis_Yellow_0",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ignis/Ignis_Graphite.Ignis_Graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ignis/Ignis_light-blue.Ignis_light-blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ignis/Ignis_light-green.Ignis_light-green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ignis/ardena-ignis-silver.ardena-ignis-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ignis/ardena-ignis-gold.ardena-ignis-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ignis/ardena-ignis-diamond.ardena-ignis-diamond",
 },
 ["Journey"]={
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Journey/Journey_Black_0.Journey_Black_0",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Journey/Journey_Graphite_0.Journey_Graphite_0",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Journey/Journey_NavyBlue_0.Journey_NavyBlue_0",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Journey/Journey_Silver.Journey_Silver",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Journey/Journey_Red.Journey_Red",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Journey/Journey_Blue.Journey_Blue",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Journey/Journey_Purple.Journey_Purple",
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Journey/Journey_White.Journey_White",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Journey/Journey_Gray.Journey_Gray",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Journey/Journey_Gold.Journey_Gold",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Journey/Journey_Green.Journey_Green",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Journey/Journey_Brown.Journey_Brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Journey/Journey_Orange.Journey_Orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Journey/Journey_Yellow.Journey_Yellow",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Journey/Journey_Light-Blue.Journey_Light-Blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Journey/Journey_Light-Green.Journey_Light-Green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Largo/harmonia-largo-silver.harmonia-largo-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Largo/harmonia-largo-gold.harmonia-largo-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Largo/harmonia-largo-diamond.harmonia-largo-diamond",
 },
 ["Largo"]={
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Largo/Largo_Gray_0.Largo_Gray_0",
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Largo/Largo_Black_0.Largo_Black_0",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Largo/Largo_Blue_0.Largo_Blue_0",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Largo/Largo_Brown_0.Largo_Brown_0",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Largo/Largo_NavyBlue_0.Largo_NavyBlue_0",
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Largo/Largo_White.Largo_White",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Largo/Largo_Red.Largo_Red",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Largo/Largo_Silver.Largo_Silver",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Largo/Largo_Purple.Largo_Purple",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Largo/Largo_Gold.Largo_Gold",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Largo/Largo_Green.Largo_Green",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Largo/Largo_Orange.Largo_Orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Largo/Largo_Yellow.Largo_Yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Largo/Largo_Graphite.Largo_Graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Largo/Largo_Light-Blue.Largo_Light-Blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Largo/Largo_Light-Green.Largo_Light-Green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Largo/harmonia-largo-silver.harmonia-largo-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Largo/harmonia-largo-gold.harmonia-largo-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Largo/harmonia-largo-diamond.harmonia-largo-diamond",
 },
 ["LiftedTruck"]={
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/LiftedTruck/2white.2white",
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/LiftedTruck/2black.2black",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/LiftedTruck/2silver.2silver",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/LiftedTruck/2gray.2gray",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/LiftedTruck/2navyblue.2navyblue",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/LiftedTruck/2red.2red",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/LiftedTruck/2blue.2blue",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/LiftedTruck/2purple.2purple",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/LiftedTruck/2gold.2gold",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/LiftedTruck/2green.2green",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/LiftedTruck/2brown.2brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/LiftedTruck/2orange.2orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/LiftedTruck/2yellow.2yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/LiftedTruck/2graphite.2graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/LiftedTruck/2light-blue.2light-blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/LiftedTruck/2light-green.2light-green",
 },
 ["Nova"]={
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Nova/NGDNova_White.NGDNova_White",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Nova/Nova_Red_0.Nova_Red_0",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Nova/NGDNova_Gold.NGDNova_Gold",
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Nova/Nova_Black_0.Nova_Black_0",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Nova/NGDNova_Silver.NGDNova_Silver",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Nova/NGDNova_Blue.NGDNova_Blue",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Nova/NGDNova_Purple.NGDNova_Purple",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Nova/Nova_NavyBlue_0.Nova_NavyBlue_0",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Nova/NGDNova_Gray.NGDNova_Gray",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Nova/Nova_Green_0.Nova_Green_0",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Nova/NGDNova_Brown.NGDNova_Brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Nova/Nova_Orange_0.Nova_Orange_0",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Nova/NGDNova_Yellow.NGDNova_Yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Nova/NGDNova_Graphite.NGDNova_Graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Nova/NGDNova_Light-Blue.NGDNova_Light-Blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Nova/NGDNova_Light-Green.NGDNova_Light-Green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Nova/NGDNova_SpecialSilver.NGDNova_SpecialSilver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Nova/NGDNova_SpecialGold.NGDNova_SpecialGold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Nova/NGDNova_SpecialDiamond.NGDNova_SpecialDiamond",
 },
 ["P2"]={
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P2/P2_Black.P2_Black",
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P2/P2_White_0.P2_White_0",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P2/P2_Silver.P2_Silver",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P2/P2_Gray_0.P2_Gray_0",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P2/P2_NavyBlue.P2_NavyBlue",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P2/P2_Red.P2_Red",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P2/P2_Blue.P2_Blue",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P2/P2_Purple.P2_Purple",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P2/P2_Gold.P2_Gold",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P2/P2_Green.P2_Green",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P2/P2_Brown.P2_Brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P2/P2_Orange.P2_Orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P2/P2_Yellow.P2_Yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P2/P2_Graphite.P2_Graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P2/P2_Light-Blue.P2_Light-Blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P2/P2_Light-Green.P2_Light-Green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P2/Cargowise-p2-silver.Cargowise-p2-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P2/Cargowise-p2-gold.Cargowise-p2-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P2/Cargowise-p2-diamond.Cargowise-p2-diamond",
 },
 ["P3"]={
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P3/P3_Silver_0.P3_Silver_0",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P3/P3_Green_0.P3_Green_0",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P3/P3_Brown_0.P3_Brown_0",
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P3/P3_White_0.P3_White_0",
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P3/P3_Black.P3_Black",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P3/P3_Red.P3_Red",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P3/P3_Blue.P3_Blue",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P3/P3_Purple.P3_Purple",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P3/P3_NavyBlue.P3_NavyBlue",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P3/P3_Gray.P3_Gray",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P3/P3_Gold.P3_Gold",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P3/P3_Orange.P3_Orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P3/P3_Yellow.P3_Yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P3/P3_Graphite.P3_Graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P3/P3_Light-Blue.P3_Light-Blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P3/P3_Light-Green.P3_Light-Green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P3/cargowise-p3-silver.cargowise-p3-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P3/cargowise-p3-gold.cargowise-p3-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P3/cargowise-p3-diamond.cargowise-p3-diamond",
 },
 ["P4"]={
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P4/P4_White_0.P4_White_0",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P4/P4_Gray_0.P4_Gray_0",
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P4/P4_Black.P4_Black",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P4/P4_Red.P4_Red",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P4/P4_Silver.P4_Silver",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P4/P4_Blue.P4_Blue",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P4/P4_Purple.P4_Purple",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P4/P4_NavyBlue.P4_NavyBlue",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P4/P4_Gold.P4_Gold",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P4/P4_Green.P4_Green",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P4/P4_Brown.P4_Brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P4/P4_Orange.P4_Orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P4/P4_Yellow.P4_Yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P4/P4_Graphite.P4_Graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P4/P4_Light-Blue.P4_Light-Blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P4/P4_Light-Green.P4_Light-Green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P4/cargowise-p4-silver.cargowise-p4-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P4/cargowise-p4-gold.cargowise-p4-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/P4/cargowise-p4-diamond.cargowise-p4-diamond",
 },
 ["Pulse"]={
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Pulse/Pulse_Orange_0.Pulse_Orange_0",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Pulse/Pulse_Yellow_0.Pulse_Yellow_0",
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Pulse/Pulse_White_0.Pulse_White_0",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Pulse/Pulse_Green_0.Pulse_Green_0",
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Pulse/Pulse_Green.Pulse_Green",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Pulse/Pulse_Silver.Pulse_Silver",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Pulse/Pulse_Red.Pulse_Red",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Pulse/Pulse_Blue.Pulse_Blue",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Pulse/Pulse_Purple.Pulse_Purple",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Pulse/Pulse_NavyBlue.Pulse_NavyBlue",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Pulse/Pulse_Gray.Pulse_Gray",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Pulse/Pulse_Gold.Pulse_Gold",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Pulse/Pulse_Brown.Pulse_Brown",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Pulse/Pulse_Graphite.Pulse_Graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Pulse/Pulse_Light-Blue.Pulse_Light-Blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Pulse/Pulse_Light-Green.Pulse_Light-Green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Pulse/ngd-pulse-silver.ngd-pulse-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Pulse/ngd-pulse-gold.ngd-pulse-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Pulse/ngd-pulse-diamond.ngd-pulse-diamond",
 },
 ["Rapid"]={
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Rapid/rapid_white.rapid_white",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Rapid/Rapid_Red_0.Rapid_Red_0",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Rapid/rapid_gold.rapid_gold",
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Rapid/Rapid_Black_0.Rapid_Black_0",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Rapid/Rapid_Silver_0.Rapid_Silver_0",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Rapid/rapid_blue.rapid_blue",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Rapid/rapid_purple.rapid_purple",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Rapid/rapid_navyblue.rapid_navyblue",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Rapid/rapid_gray.rapid_gray",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Rapid/rapid_green.rapid_green",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Rapid/rapid_brown.rapid_brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Rapid/rapid_orange.rapid_orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Rapid/Rapid_Yellow_0.Rapid_Yellow_0",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Rapid/rapid_graphite.rapid_graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Rapid/rapid_light-blue.rapid_light-blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Rapid/rapid_light-green.rapid_light-green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Rapid/rapid_special-silver.rapid_special-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Rapid/rapid_special-gold.rapid_special-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Rapid/rapid_special-diamond.rapid_special-diamond",
 },
 ["Ravager"]={
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ravager/white.White",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ravager/Ravager_Red_0.Ravager_Red_0",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ravager/gold.Gold",
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ravager/Ravager_Black_0.Ravager_Black_0",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ravager/silver.Silver",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ravager/blue.Blue",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ravager/purple.Purple",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ravager/navyblue.NavyBlue",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ravager/gray.Gray",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ravager/green.Green",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ravager/brown.Brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ravager/orange.Orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ravager/yellow.Yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ravager/Ravager_Graphite_0.Ravager_Graphite_0",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ravager/light-blue.Light-Blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ravager/Ravager_Light-Green_0.Ravager_Light-Green_0",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ravager/special-silver.special-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ravager/special-gold.special-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ravager/special-diamond.special-diamond",
 },
 ["Ridge"]={
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ridge/Ridge_Black_0.Ridge_Black_0",
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ridge/Ridge_White.Ridge_White",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ridge/Ridge_Silver.Ridge_Silver",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ridge/Ridge_Gray.Ridge_Gray",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ridge/Ridge_NavyBlue.Ridge_NavyBlue",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ridge/Ridge_Red.Ridge_Red",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ridge/Ridge_Blue_0.Ridge_Blue_0",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ridge/Ridge_Purple.Ridge_Purple",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ridge/Ridge_Gold.Ridge_Gold",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ridge/Ridge_Green_0.Ridge_Green_0",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ridge/Ridge_Brown.Ridge_Brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ridge/Ridge_Orange.Ridge_Orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ridge/Ridge_yellow.Ridge_yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ridge/Ridge_Graphite.Ridge_Graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ridge/Ridge_Light-Blue.Ridge_Light-Blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ridge/Ridge_Light-Green.Ridge_Light-Green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ridge/offrider-ridge-silver.offrider-ridge-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ridge/offrider-ridge-gold.offrider-ridge-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ridge/offrider-ridge-diamond.offrider-ridge-diamond",
 },
 ["Striker"]={
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Striker/Striker_Black_0.Striker_Black_0",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Striker/Striker_Silver_0.Striker_Silver_0",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Striker/Striker_Red_0.Striker_Red_0",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Striker/Striker_Blue_0.Striker_Blue_0",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Striker/Striker_Purple_0.Striker_Purple_0",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Striker/Striker_NavyBlue_0.Striker_NavyBlue_0",
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Striker/Striker_White.Striker_White",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Striker/Striker_Gray.Striker_Gray",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Striker/Striker_Gold.Striker_Gold",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Striker/Striker_Green.Striker_Green",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Striker/Striker_Brown.Striker_Brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Striker/Striker_Orange.Striker_Orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Striker/Striker_Yellow.Striker_Yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Striker/Striker_Graphite.Striker_Graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Striker/Striker_Light-Blue.Striker_Light-Blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Striker/Striker_Light-Green.Striker_Light-Green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Striker/apex-striker-silver.apex-striker-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Striker/apex-striker-gold.apex-striker-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Striker/apex-striker-diamond.apex-striker-diamond",
 },
 ["Summit"]={
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Summit/white.white",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Summit/red.red",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Summit/gold.gold",
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Summit/Summit_Black_0.Summit_Black_0",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Summit/Summit_Silver_0.Summit_Silver_0",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Summit/Summit_Blue_0.Summit_Blue_0",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Summit/purple.purple",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Summit/navyblue.navyblue",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Summit/gray.gray",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Summit/green.green",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Summit/brown.brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Summit/orange.orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Summit/yellow.yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Summit/graphite.graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Summit/light-blue.light-blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Summit/light-green.light-green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Summit/special-silver.special-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Summit/special-gold.special-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Summit/special-diamond.special-diamond",
 },
 ["Tempest"]={
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Tempest/white.White",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Tempest/Tempest_Red_0.Tempest_Red_0",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Tempest/gold.Gold",
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Tempest/Tempest_Black_0.Tempest_Black_0",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Tempest/Tempest_Silver_0.Tempest_Silver_0",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Tempest/blue.Blue",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Tempest/purple.Purple",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Tempest/Tempest_NavyBlue_0.Tempest_NavyBlue_0",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Tempest/gray.Gray",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Tempest/green.Green",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Tempest/brown.Brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Tempest/orange.Orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Tempest/yellow.Yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Tempest/graphite.Graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Tempest/light-blue.Light-Blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Tempest/light-green.Light-Green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Tempest/special-silver.special-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Tempest/special-gold.special-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Tempest/special-diamond.special-diamond",
 },
 ["Thunder"]={
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Thunder/Thunder_Black_0.Thunder_Black_0",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Thunder/Thunder_Red_0.Thunder_Red_0",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Thunder/Thunder_Blue_0.Thunder_Blue_0",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Thunder/Thunder_Silver_0.Thunder_Silver_0",
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Thunder/Thunder_White_0.Thunder_White_0",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Thunder/Thunder_Purple.Thunder_Purple",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Thunder/Thunder_NavyBlue.Thunder_NavyBlue",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Thunder/Thunder_Gray.Thunder_Gray",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Thunder/Thunder_Gold.Thunder_Gold",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Thunder/Thunder_Green.Thunder_Green",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Thunder/Thunder_Brown.Thunder_Brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Thunder/Thunder_Orange.Thunder_Orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Thunder/Thunder_Yellow.Thunder_Yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Thunder/Thunder_Graphite.Thunder_Graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Thunder/Thunder_Light-Blue.Thunder_Light-Blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Thunder/Thunder_Light-Green.Thunder_Light-Green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Thunder/phantom-thunder-silver.phantom-thunder-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Thunder/phantom-thunder-gold.phantom-thunder-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Thunder/phantom-thunder-diamond.phantom-thunder-diamond",
 },
 ["ThunderX"]={
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/ThunderX/ThunderX_Black_0.ThunderX_Black_0",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/ThunderX/ThunderX_Red_1.ThunderX_Red_1",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/ThunderX/ThunderX_Silver_0.ThunderX_Silver_0",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/ThunderX/ThunderX_Gray_0.ThunderX_Gray_0",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/ThunderX/ThunderX_Yellow_0.ThunderX_Yellow_0",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/ThunderX/navyblue.navyblue",
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/ThunderX/white.white",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/ThunderX/blue.blue",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/ThunderX/purple.purple",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/ThunderX/gold.gold",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/ThunderX/green.green",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/ThunderX/brown.brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/ThunderX/orange.orange",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/ThunderX/graphite.graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/ThunderX/light-blue.light-blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/ThunderX/light-green.light-green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/ThunderX/phantom-thunderx-silver.phantom-thunderx-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/ThunderX/phantom-thunderx-gold.phantom-thunderx-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/ThunderX/phantom-thunderx-diamond.phantom-thunderx-diamond",
 },
 ["TowTruck"]={
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/TowTruck/white.white",
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/TowTruck/black.black",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/TowTruck/silver.silver",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/TowTruck/gray.gray",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/TowTruck/navyblue.navyblue",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/TowTruck/red.red",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/TowTruck/blue.blue",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/TowTruck/purple.purple",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/TowTruck/gold.gold",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/TowTruck/green.green",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/TowTruck/brown.brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/TowTruck/orange.orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/TowTruck/yellow.yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/TowTruck/graphite.graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/TowTruck/light_blue.light_blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/TowTruck/light_green.light_green",
 },
 ["TowTruckBig"]={
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Transporter/transporter.transporter",
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Transporter/transporter.transporter",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Transporter/transporter.transporter",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Transporter/transporter.transporter",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Transporter/transporter.transporter",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Transporter/transporter.transporter",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Transporter/transporter.transporter",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Transporter/transporter.transporter",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Transporter/transporter.transporter",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Transporter/transporter.transporter",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Transporter/transporter.transporter",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Transporter/transporter.transporter",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Transporter/transporter.transporter",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Transporter/transporter.transporter",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Transporter/transporter.transporter",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Transporter/transporter.transporter",
 },
 ["Trail"]={
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Trail/white.white",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Trail/red.red",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Trail/gold.gold",
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Trail/black.black",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Trail/Trail_Silver/Trail_Silver_0.Trail_Silver_0",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Trail/Trail_Blue/Trail_Blue_0.Trail_Blue_0",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Trail/purple.purple",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Trail/navyblue.navyblue",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Trail/gray.gray",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Trail/Trail_Green/Trail_Green_0.Trail_Green_0",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Trail/Trail_Brown/Trail_Brown_0.Trail_Brown_0",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Trail/orange.orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Trail/yellow.yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Trail/graphite.graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Trail/light-blue.light-blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Trail/light-green.light-green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Trail/off-rider-trail-silver.off-rider-trail-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Trail/off-rider-trail-gold.off-rider-trail-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Trail/off-rider-trail-diamond.off-rider-trail-diamond",
 },
 ["Vanguard"]={
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vanguard/Vanguard_Black_0.Vanguard_Black_0",
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vanguard/Vanguard_White_0.Vanguard_White_0",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vanguard/Vanguard_Silver_0.Vanguard_Silver_0",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vanguard/Vanguard_Gray_0.Vanguard_Gray_0",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vanguard/Vanguard_NavyBlue_0.Vanguard_NavyBlue_0",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vanguard/Vanguard_Red.Vanguard_Red",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vanguard/Vanguard_Blue.Vanguard_Blue",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vanguard/Vanguard_Purple.Vanguard_Purple",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vanguard/Vanguard_Gold.Vanguard_Gold",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vanguard/Vanguard_Green.Vanguard_Green",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vanguard/Vanguard_Brown.Vanguard_Brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vanguard/Vanguard_Orange.Vanguard_Orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vanguard/Vanguard_Yellow.Vanguard_Yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vanguard/Vanguard_Graphite.Vanguard_Graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vanguard/Vanguard_Light-Blue.Vanguard_Light-Blue",
  ["Light_Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vanguard/Vanguard_Light-Green.Vanguard_Light-Green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vanguard/apex-vanguard-silver.apex-vanguard-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vanguard/apex-vanguard-gold.apex-vanguard-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vanguard/apex-vanguard-diamond.apex-vanguard-diamond",
 },
 ["Ventus"]={
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ventus/Ventus_White_0.Ventus_White_0",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ventus/Ventus_Red_0.Ventus_Red_0",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ventus/gold.gold",
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ventus/Ventus_Black_0.Ventus_Black_0",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ventus/silver.silver",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ventus/blue.blue",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ventus/purple.purple",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ventus/navyblue.navyblue",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ventus/gray.gray",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ventus/green.green",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ventus/brown.brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ventus/orange.orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ventus/Ventus_Yellow_0.Ventus_Yellow_0",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ventus/grahite.grahite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ventus/light-blue.light-blue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ventus/light-green.light-green",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ventus/silver-special.silver-special",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ventus/gold-special.gold-special",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Ventus/diamond-special.diamond-special",
 },
 ["Vesper"]={
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vesper/Vesper_White.Vesper_White",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vesper/Vesper_Red.Vesper_Red",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vesper/Vesper_Gold.Vesper_Gold",
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vesper/Vesper_Black.Vesper_Black",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vesper/Vesper_Silver.Vesper_Silver",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vesper/Vesper_Blue.Vesper_Blue",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vesper/Vesper_Purple.Vesper_Purple",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vesper/Vesper_NavyBlue.Vesper_NavyBlue",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vesper/Vesper_Gray.Vesper_Gray",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vesper/Vesper_Green.Vesper_Green",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vesper/Vesper_Brown.Vesper_Brown",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vesper/Vesper_Orange.Vesper_Orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vesper/Vesper_Yellow.Vesper_Yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vesper/Vesper_Graphite.Vesper_Graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vesper/Vesper_LightBlue.Vesper_LightBlue",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vesper/Vesper_LightGreen.Vesper_LightGreen",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vesper/Vesper_SuperSilver.Vesper_SuperSilver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vesper/Vesper_SuperGold.Vesper_SuperGold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Vesper/Vesper_SuperDiamond.Vesper_SuperDiamond",
 },
 ["Voyager"]={
  ["Black"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Voyager/Voyager_Black_0.Voyager_Black_0",
  ["White"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Voyager/Voyager_White_0.Voyager_White_0",
  ["Silver"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Voyager/Voyager_Silver.Voyager_Silver",
  ["Gray"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Voyager/Voyager_Gray.Voyager_Gray",
  ["NavyBlue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Voyager/Voyager_NavyBlue_0.Voyager_NavyBlue_0",
  ["Red"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Voyager/Voyager_Red.Voyager_Red",
  ["Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Voyager/Voyager_Blue.Voyager_Blue",
  ["Purple"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Voyager/Voyager_Pruple.Voyager_Pruple",
  ["Gold"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Voyager/Voyager_Gold.Voyager_Gold",
  ["Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Voyager/Voyager_Green.Voyager_Green",
  ["Brown"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Voyager/Voyager_Brown_0.Voyager_Brown_0",
  ["Orange"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Voyager/Voyager_Orange.Voyager_Orange",
  ["Yellow"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Voyager/Voyager_Yellow.Voyager_Yellow",
  ["Graphite"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Voyager/Voyager_Graphite.Voyager_Graphite",
  ["Light-Blue"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Voyager/Voyager_Light-Blue_0.Voyager_Light-Blue_0",
  ["Light-Green"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Voyager/Voyager_Light-Green_0.Voyager_Light-Green_0",
  ["SUPER-SILVER"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Voyager/Voyager-silver.Voyager-silver",
  ["SUPER-GOLD"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Voyager/Voyager-gold.Voyager-gold",
  ["SUPER-DIAMOND"]="/Game/CarDealerSim/Core/Vehicle/VehicleProperties/VehiclePhotos/Voyager/Voyager-diamond.Voyager-diamond",
 },
}
local RUNTIME_CAR_MODEL_ALIASES={
 ["cavallaro 280g"]="280G",
 ["280g"]="280G",
 ["cavallaro 350s"]="350s",
 ["350s"]="350s",
 ["umx 600c"]="600C",
 ["600c"]="600C",
 ["umx 700r"]="700R",
 ["700r"]="700R",
 ["umx 800c"]="800C",
 ["800c"]="800C",
 ["harmonia vehicles allegretto"]="Allegretto",
 ["harmonia allegretto"]="Allegretto",
 ["allegretto"]="Allegretto",
 ["harmonia vehicles andante"]="Andante",
 ["harmonia andante"]="Andante",
 ["andante"]="Andante",
 ["harmonia vehicles largo"]="Largo",
 ["harmonia largo"]="Largo",
 ["largo"]="Largo",
 ["zen motors ascend"]="Ascend",
 ["zen ascend"]="Ascend",
 ["ascend"]="Ascend",
 ["zen motors ascendl"]="AscendL",
 ["zen motors ascend l"]="AscendL",
 ["zen ascendl"]="AscendL",
 ["ascendl"]="AscendL",
 ["zen motors horizon"]="Horizon",
 ["zen horizon"]="Horizon",
 ["horizon"]="Horizon",
 ["zen motors journey"]="Journey",
 ["zen journey"]="Journey",
 ["journey"]="Journey",
 ["zen motors rapid"]="Rapid",
 ["zen rapid"]="Rapid",
 ["rapid"]="Rapid",
 ["aurora outrider"]="Aurora",
 ["outrider"]="Aurora",
 ["aurora"]="Aurora",
 ["aurora highrunner"]="Highrunner",
 ["highrunner"]="Highrunner",
 ["apex motors strike"]="Striker",
 ["apex strike"]="Striker",
 ["strike"]="Striker",
 ["striker"]="Striker",
 ["apex motors vanguard"]="Vanguard",
 ["apex vanguard"]="Vanguard",
 ["vanguard"]="Vanguard",
 ["ardena ignis"]="Ignis",
 ["ignis"]="Ignis",
 ["ardena ventus"]="Ventus",
 ["ventus"]="Ventus",
 ["ngd nova"]="Nova",
 ["nova"]="Nova",
 ["ngd pulse"]="Pulse",
 ["pulse"]="Pulse",
 ["offrider boulder"]="Boulder",
 ["off rider boulder"]="Boulder",
 ["boulder"]="Boulder",
 ["offrider canyon"]="Canyon",
 ["off rider canyon"]="Canyon",
 ["canyon"]="Canyon",
 ["offrider highland"]="Highland",
 ["off rider highland"]="Highland",
 ["highland"]="Highland",
 ["offrider ridge"]="Ridge",
 ["off rider ridge"]="Ridge",
 ["ridge"]="Ridge",
 ["offrider summit"]="Summit",
 ["off rider summit"]="Summit",
 ["summit"]="Summit",
 ["offrider trail"]="Trail",
 ["off rider trail"]="Trail",
 ["trail"]="Trail",
 ["offrider ravager"]="Ravager",
 ["off rider ravager"]="Ravager",
 ["ravager"]="Ravager",
 ["phantom tempest"]="Tempest",
 ["tempest"]="Tempest",
 ["phantom cortega"]="Cortega",
 ["cortega"]="Cortega",
 ["phantom gale"]="Gale",
 ["gale"]="Gale",
 ["phantom thunder"]="Thunder",
 ["thunder"]="Thunder",
 ["phantom thunderx"]="ThunderX",
 ["phantom thunder x"]="ThunderX",
 ["thunderx"]="ThunderX",
 ["thunder x"]="ThunderX",
 ["phantom voyager"]="Voyager",
 ["voyager"]="Voyager",
 ["cargowise p2"]="P2",
 ["cargo wise p2"]="P2",
 ["p2"]="P2",
 ["cargowise p3"]="P3",
 ["cargo wise p3"]="P3",
 ["p3"]="P3",
 ["cargowise p4"]="P4",
 ["cargo wise p4"]="P4",
 ["p4"]="P4",
 ["liftedtruck"]="LiftedTruck",
 ["lifted truck"]="LiftedTruck",
 ["towtruck"]="TowTruck",
 ["tow truck"]="TowTruck",
 ["transporter"]="TowTruckBig",
 ["vesper"]="Vesper",
 ["elevate"]="Elevate",
}
local runtimeCarPhotoBatchPending=false
local function runtime_car_model_key(model)
 local s=string.lower(tostring(model or "")):gsub("%s+"," "):gsub("^%s+",""):gsub("%s+$","")
 if RUNTIME_CAR_MODEL_ALIASES[s] then return RUNTIME_CAR_MODEL_ALIASES[s] end
 local compact=s:gsub("[^a-z0-9]","")
 local best=nil local bestLen=0
 for k,v in pairs(RUNTIME_CAR_MODEL_ALIASES) do
  local kc=k:gsub("[^a-z0-9]","")
  if #kc>=3 and (compact==kc or compact:sub(-#kc)==kc) and #kc>bestLen then best=v;bestLen=#kc end
 end
 return best
end
local function runtime_car_color_key(raw)
 local s=tostring(raw or "")
 local n=tonumber(s)
 local numeric={ [0]="Black",[1]="Silver",[2]="Red",[3]="Blue",[4]="Purple",[5]="NavyBlue",[6]="White",[7]="Gray",[8]="Gold",[9]="Green",[10]="Brown",[11]="Orange",[12]="Yellow",[13]="Graphite",[14]="Light-Blue",[15]="Light-Green",[16]="SUPER-SILVER",[17]="SUPER-GOLD",[18]="SUPER-DIAMOND",[19]="Custom" }
 if n and numeric[n] then return numeric[n] end
 local en=s:match("NewEnumerator(%d+)")
 if en then
  local enumMap={ [0]="Black",[1]="Silver",[2]="Red",[3]="Blue",[4]="Purple",[5]="NavyBlue",[7]="White",[8]="Gray",[9]="Gold",[10]="Green",[11]="Brown",[12]="Orange",[13]="Yellow",[14]="Graphite",[15]="Light-Blue",[16]="Light-Green",[17]="SUPER-SILVER",[18]="SUPER-GOLD",[19]="SUPER-DIAMOND",[20]="Custom" }
  if enumMap[tonumber(en)] then return enumMap[tonumber(en)] end
 end
 for _,name in ipairs({"Black","Silver","Red","Blue","Purple","NavyBlue","White","Gray","Gold","Green","Brown","Orange","Yellow","Graphite","Light-Blue","Light-Green","SUPER-SILVER","SUPER-GOLD","SUPER-DIAMOND","Custom"}) do
  if string.lower(s)==string.lower(name) then return name end
 end
 return nil
end
local function runtime_car_cache_name(modelKey,colorKey)
 return tostring(modelKey):gsub("[^%w_-]","_").."__"..tostring(colorKey):gsub("[^%w_-]","_")
end
local function runtime_car_photo_requests(cars)
 local out={} local seen={}
 local fallbackOrder={"White","Silver","Gray","Black","Red","Blue","NavyBlue","Graphite","Green","Yellow","Orange","Brown","Purple","Light-Blue","Light-Green","Gold","SUPER-SILVER","SUPER-GOLD","SUPER-DIAMOND"}
 for _,c in ipairs(cars or {}) do
  local mk=runtime_car_model_key(c.model)
  local ck=runtime_car_color_key(c.color)
  local photos=mk and RUNTIME_CAR_PHOTOS[mk] or nil
  local asset=photos and ck and photos[ck] or nil

  -- Custom paint is arbitrary, so the game's static VehiclePhotos table has no
  -- exact texture for it. Generate Model__Custom.png from a normal stock photo
  -- so custom-painted cars still show the correct model instead of a blank image.
  if photos and ck=="Custom" and not asset then
   for _,fallbackColor in ipairs(fallbackOrder) do
    if photos[fallbackColor] then asset=photos[fallbackColor];break end
   end
   if not asset then for _,candidate in pairs(photos) do asset=candidate;break end end
  end

  if asset and mk and ck then
   local name=runtime_car_cache_name(mk,ck)
   local path=carPhotoCacheRoot.."\\"..name..".png"
   local f=io.open(path,"rb")
   if f then f:close() elseif not seen[name] then seen[name]=true;table.insert(out,{asset=asset,name=name}) end
  end
 end
 return out
end
local function runtime_car_photo_diag(line)
 local path=diagnosticsRoot.."\\runtime_car_photos.txt"
 local f=io.open(path,"a")
 if f then f:write(os.date("%Y-%m-%d %H:%M:%S").."  "..tostring(line or "").."\n");f:close() end
end
local function queue_runtime_car_photos(cars)
 local requests=runtime_car_photo_requests(cars)
 runtime_car_photo_diag("Cars scan: "..tostring(#(cars or {})).." car(s), "..tostring(#requests).." missing runtime photo(s).")
 if #requests==0 or runtimeCarPhotoBatchPending then return end
 runtimeCarPhotoBatchPending=true
 -- Always perform the streaming command on the game thread. The earlier test build
 -- could queue this from the reader's current callback and gave no visible photos.
 ExecuteInGameThread(function()
  local world=FindFirstOf("BP_GameMode_C") or FindFirstOf("BP_CDSGameInstance_C")
  local system=StaticFindObject("/Script/Engine.Default__KismetSystemLibrary")
  if not world or not system then
   runtime_car_photo_diag("STOP: world/system library unavailable.")
   runtimeCarPhotoBatchPending=false
   return
  end
  local offOk,offErr=pcall(function() system:ExecuteConsoleCommand(world,"r.TextureStreaming 0",nil) end)
  runtime_car_photo_diag("r.TextureStreaming 0 = "..tostring(offOk)..(offErr and (" | "..tostring(offErr)) or ""))
  if not offOk then runtimeCarPhotoBatchPending=false;return end

  -- Proven quality path: streaming OFF, wait 2 seconds BEFORE LoadAsset.
  ExecuteWithDelay(2000,function()
   ExecuteInGameThread(function()
    local okBatch,errBatch=pcall(function()
     local library=StaticFindObject("/Script/Engine.Default__KismetRenderingLibrary")
     if not library then error("KismetRenderingLibrary unavailable") end
     for _,req in ipairs(requests) do
      runtime_car_photo_diag("Generating "..tostring(req.name).." <- "..tostring(req.asset))
      local texture=LoadAsset(req.asset)
      if not texture then
       runtime_car_photo_diag("FAILED LoadAsset: "..tostring(req.asset))
      else
       local rt=library:CreateRenderTarget2D(world,1024,1024,3,{R=0.0,G=0.0,B=0.0,A=1.0},false,false)
       if not rt then
        runtime_car_photo_diag("FAILED render target: "..tostring(req.name))
       else
        local canvasOut,sizeOut,contextOut={},{},{}
        library:BeginDrawCanvasToRenderTarget(world,rt,canvasOut,sizeOut,contextOut)
        local canvas=canvasOut.Canvas
        if canvas and sizeOut.RenderTarget then
         canvas:K2_DrawTexture(texture,{X=0.0,Y=0.0},{X=1024.0,Y=1024.0},{X=0.0,Y=0.0},{X=1.0,Y=1.0},{R=1.0,G=1.0,B=1.0,A=1.0},0,0.0,{X=0.0,Y=0.0})
         library:EndDrawCanvasToRenderTarget(world,sizeOut)
         library:ExportRenderTarget(world,rt,carPhotoCacheRoot,req.name)
         local raw=carPhotoCacheRoot.."\\"..req.name
         local png=raw..".png"
         local rf=io.open(raw,"rb")
         if rf then
          rf:close()
          os.remove(png)
          local renamed,renameErr=os.rename(raw,png)
          runtime_car_photo_diag("Exported "..tostring(req.name)..".png | rename="..tostring(renamed)..(renameErr and (" | "..tostring(renameErr)) or ""))
         else
          -- Some UE builds may append an extension themselves.
          local pf=io.open(png,"rb")
          if pf then pf:close();runtime_car_photo_diag("Exported "..tostring(req.name)..".png")
          else runtime_car_photo_diag("FAILED export file: "..tostring(req.name)) end
         end
        else
         runtime_car_photo_diag("FAILED canvas/context: "..tostring(req.name))
        end
       end
      end
     end
    end)
    pcall(function() system:ExecuteConsoleCommand(world,"r.TextureStreaming 1",nil) end)
    runtimeCarPhotoBatchPending=false
    if not okBatch then
     runtime_car_photo_diag("BATCH ERROR: "..tostring(errBatch))
     log("Runtime car photo batch error: "..tostring(errBatch))
    else
     runtime_car_photo_diag("Batch complete: "..tostring(#requests).." image(s). Streaming restored.")
     log("Runtime car photo cache updated: "..tostring(#requests).." image(s).")
    end
   end)
  end)
 end)
end



local refreshSettingsPath=base.."\\refresh_settings.ini"
local readerRefreshRequestPath=base.."\\reader_refresh_request.txt"
local performanceLogPath=base.."\\reader_performance.log"
local refreshSettings={
 dashboard_seconds=10,
 contracts_seconds=30,
 inventory_seconds=10,
 storage_seconds=30,
 cars_seconds=300,
 debug_enabled=false
}

local function load_refresh_settings()
 local f=io.open(refreshSettingsPath,"r")
 if not f then return end
 for line in f:lines() do
  local key,value=line:match("^%s*([%w_]+)%s*=%s*([^%s#]+)")
  if key and value and refreshSettings[key]~=nil then
   if key=="debug_enabled" then
    refreshSettings[key]=(string.lower(value)=="true")
   else
    local n=tonumber(value)
    if n then refreshSettings[key]=math.max(0,math.floor(n)) end
   end
  end
 end
 f:close()
 -- v0.44.0.61: retire the old 5-second Contracts default even if the
 -- overlay has not started yet. This keeps the game-thread reader at the
 -- safer 30-second cadence used by the UI migration.
 if refreshSettings.contracts_seconds==5 then refreshSettings.contracts_seconds=30 end
end

local function consume_reader_refresh_request()
 local f=io.open(readerRefreshRequestPath,"r")
 if not f then return nil end
 local raw=f:read("*a") or ""
 f:close()
 os.remove(readerRefreshRequestPath)
 local target=raw:match("^%s*([%w_%-]+)")
 if not target then return nil end
 return string.lower(target)
end

local function interval_due(seconds,tick)
 local n=tonumber(seconds) or 0
 if n<=0 then return false end
 local ticks=math.max(1,math.ceil(n/5))
 return (tick%ticks)==0
end
local ready=false
local storageReady=false
local cachedWorldInventory=nil
local cachedEconomySystem=nil
local cachedClockWidget=nil
local cachedWholesaleSubsystem=nil
local cachedPawnShopSubsystem=nil
local cachedPawnRequestsJson=nil
local cachedTonyReputation=nil
local cachedEventHandler=nil

local function log(s) print("["..MOD.."] "..tostring(s).."\n") end

-- Permanent manual-scan diagnostic. This has no periodic cost: it is reset and
-- populated only when the user presses SCAN CARS. It intentionally remains in
-- LocalAppData so future fitted-part problems can be diagnosed without a special build.
local function fitted_diag_write(text,mode)
 if not diagnostics_enabled() then return true end
 local f,err=io.open(fittedPartsDiagnosticPath,mode or "a")
 if not f then
  log("ERROR: could not write fitted-parts diagnostic: "..tostring(err))
  return false
 end
 f:write(tostring(text or ""))
 f:close()
 return true
end

local function fitted_diag_reset()
 if not diagnostics_enabled() then return true end
 pcall(function() os.execute('if not exist "'..base..'" mkdir "'..base..'"') end)
 return fitted_diag_write(
  "CAR DEALER COMPANION - FITTED PARTS DIAGNOSTIC\n"..
  "Reader: "..MOD.."\n"..
  "Manual scan started: "..os.date("%Y-%m-%d %H:%M:%S").."\n"..
  "Diagnostic is retained by design and refreshed on each manual SCAN CARS.\n\n",
  "w"
 )
end
local function esc(s)
 s=tostring(s or ""):gsub("\\","\\\\"):gsub('"','\\"'):gsub("\r","\\r"):gsub("\n","\\n")
 return s
end
local function clean(n)
 if not n then return "<unknown>" end
 return n:gsub("^BP_Product_",""):gsub("_C$",""):gsub("_"," ")
end
local function name_of(stack)
 local result=nil
 local ok,a=pcall(function() return stack.ItemInstances end)
 if ok and a then
  pcall(function()
   a:ForEach(function(_,e)
    if result then return end
    local p=e:get()
    if p and p:IsValid() then
     local okd,d=pcall(function() return p.DisplayName end)
     if okd and d then
      local okt,t=pcall(function() return d:ToString() end)
      if okt and t and t~="" then result=t end
     end
    end
   end)
  end)
 end
 if result then return result end
 local okc,c=pcall(function() return stack.ItemClass end)
 if okc and c and c:IsValid() then return clean(c:GetFName():ToString()) end
 return "<unknown>"
end
local function type_of(stack)
 local ok,v=pcall(function() return stack.ItemType end)
 if not ok or v==nil then return "Unknown" end
 return tostring(v)
end
local function counts_of(stack)
 local qty,full,repair,unknown=0,0,0,0
 local ok,a=pcall(function() return stack.ItemInstances end)
 if not ok or not a then return qty,full,repair,unknown end
 pcall(function()
  a:ForEach(function(_,e)
   local p=e:get()
   if p and p:IsValid() then
    qty=qty+1
    local okd,d=pcall(function() return p.Durability end)
    local n=nil
    if okd and d~=nil then n=tonumber(d) end
    if n==nil then
     unknown=unknown+1
    else
     if n>=0 and n<=1.0001 then n=n*100 end
     if n>=99.999 then full=full+1 else repair=repair+1 end
    end
   end
  end)
 end)
 return qty,full,repair,unknown
end
local function find_inventory()
 local all=FindAllOf("BP_InventoryComp_C")
 if not all then return nil end
 for _,inv in ipairs(all) do
  if inv and inv:IsValid() then
   local n=inv:GetFullName()
   if n:find("WorldMap.WorldMap:PersistentLevel",1,true)
   and n:find("BP_PlayerController_C_",1,true)
   and n:find(".BP_InventoryComp",1,true) then return inv end
  end
 end
 return nil
end
local function write_waiting(msg)
 local f=io.open(jsonPath..".tmp","w"); if not f then return end
 f:write('{"version":"0.8","connected":false,"message":"'..esc(msg)..'","items":[]}')
 f:close(); os.remove(jsonPath); os.rename(jsonPath..".tmp",jsonPath)
end
local function scan()
 if not ready then return false end
 local inv=cachedWorldInventory
 if not inv or not inv:IsValid() then
  write_waiting("Waiting for stable WorldMap inventory")
  return false
 end
 local ok,items=pcall(function() return inv.Items end)
 if not ok or not items then
  write_waiting("WorldMap inventory found; waiting for Items")
  return false
 end

 local merged,order={},{}
 local okIter=pcall(function()
  items:ForEach(function(_,e)
   local stack=e:get()
   if stack and stack:IsValid() then
    local name=name_of(stack)
    local typ=type_of(stack)
    local qty,full,repair,unknown=counts_of(stack)
    local key=string.lower(name).."||"..string.lower(typ)
    if not merged[key] then merged[key]={name=name,typ=typ,qty=0,full=0,repair=0,unknown=0}; table.insert(order,key) end
    merged[key].qty=merged[key].qty+qty
    merged[key].full=merged[key].full+full
    merged[key].repair=merged[key].repair+repair
    merged[key].unknown=merged[key].unknown+unknown
   end
  end)
 end)
 if not okIter then write_waiting("Inventory is changing; waiting for next safe refresh"); return end

 table.sort(order,function(a,b) return string.lower(merged[a].name)<string.lower(merged[b].name) end)
 local f=io.open(jsonPath..".tmp","w"); if not f then return end
 local total=0
 f:write('{"version":"0.8","connected":true,"message":"Live safe inventory","items":[')
 for i,key in ipairs(order) do
  local r=merged[key]; total=total+r.qty
  if i>1 then f:write(",") end
  f:write('{"name":"'..esc(r.name)..'","qty":'..r.qty..',"full":'..r.full..',"repair":'..r.repair..',"unknown":'..r.unknown..',"type":"'..esc(r.typ)..'"}')
 end
 f:write('],"total":'..total..'}')
 f:close(); os.remove(jsonPath); os.rename(jsonPath..".tmp",jsonPath)
 log("Safe refresh complete: "..#order.." rows, "..total.." items.")
 return true
end


local function write_json_atomic(path, content)
 local tmp=path..".tmp"
 local f=io.open(tmp,"w")
 if not f then return false end
 f:write(content)
 f:close()
 for _=1,3 do
  os.remove(path)
  if os.rename(tmp,path) then return true end
 end
 local direct=io.open(path,"w")
 if direct then
  direct:write(content)
  direct:close()
  os.remove(tmp)
  return true
 end
 return false
end

local function is_player_inventory(full_name)
 if not full_name then return false end
 return full_name:find("BP_PlayerController_C_",1,true) ~= nil
    and full_name:find(".BP_InventoryComp",1,true) ~= nil
end

local function looks_like_storage(full_name)
 if not full_name then return false end
 local n=string.lower(full_name)
 return n:find("storage",1,true) ~= nil
     or n:find("warehouse",1,true) ~= nil
     or n:find("shelf",1,true) ~= nil
     or n:find("stock",1,true) ~= nil
end

local function get_container_stacks(container)
 if container==nil then return nil,"no container" end

 -- First try the direct Items property used by storage/player inventory.
 local ok_items,items=pcall(function() return container.Items end)
 if ok_items and items~=nil then return items,"Items property" end

 -- Repair-machine containers inherit BC_ItemContainer_C. The game's
 -- confirmed public Blueprint API exposes GetAllItemsStackList().
 local ok_func,result=pcall(function() return container:GetAllItemsStackList() end)
 if ok_func and result~=nil then return result,"GetAllItemsStackList" end

 return nil,"no readable stack list"
end

-- Performance Pass 2:
-- FaultyMods mining showed the safest high-value pattern here is:
-- discover long-lived objects once -> cache -> validate -> rediscover only
-- when invalid or deliberately requested.
local cachedStorageContainers=nil
local cachedStorageDiscoveredAt=0
local STORAGE_CACHE_REDISCOVER_SECONDS=600

local function object_is_valid(obj)
 if obj==nil then return false end
 local ok,v=pcall(function() return obj:IsValid() end)
 return ok and v==true
end

local function discover_storage_containers()
 local all=FindAllOf("BC_ItemContainer_C")
 local found={}

 if all then
  for _,container in ipairs(all) do
   if object_is_valid(container) then
    local full_name=""
    pcall(function() full_name=container:GetFullName() end)

    if full_name~=""
    and not is_player_inventory(full_name)
    and looks_like_storage(full_name) then
     table.insert(found,{obj=container,name=full_name})
    end
   end
  end
 end

 table.sort(found,function(a,b) return tostring(a.name)<tostring(b.name) end)
 cachedStorageContainers=found
 cachedStorageDiscoveredAt=os.time()

 log("Storage cache discovery complete: "..tostring(#found).." candidate containers cached.")
 return found
end

local function get_cached_storage_containers(forceDiscovery)
 local now=os.time()

 if forceDiscovery
 or cachedStorageContainers==nil
 or (now-cachedStorageDiscoveredAt)>=STORAGE_CACHE_REDISCOVER_SECONDS then
  return discover_storage_containers(),true
 end

 local valid={}
 local invalidCount=0

 for _,entry in ipairs(cachedStorageContainers) do
  if entry and object_is_valid(entry.obj) then
   table.insert(valid,entry)
  else
   invalidCount=invalidCount+1
  end
 end

 -- If the world unloaded/reloaded or every cached object vanished, do one
 -- controlled rediscovery instead of carrying stale pointers forward.
 if #valid==0 and #cachedStorageContainers>0 then
  log("Storage cache invalidated; rediscovering containers.")
  return discover_storage_containers(),true
 end

 -- Keep surviving objects. Missing/invalid entries are dropped immediately.
 if invalidCount>0 then
  cachedStorageContainers=valid
  log("Storage cache dropped "..tostring(invalidCount).." invalid container reference(s).")
 end

 return valid,false
end

local function invalidate_storage_container_cache()
 cachedStorageContainers=nil
 cachedStorageDiscoveredAt=0
end

local function scan_storage(forceDiscovery)
 local entries,rediscovered=get_cached_storage_containers(forceDiscovery==true)

 if not entries or #entries==0 then
  write_json_atomic(storageJsonPath,'{"version":"0.18","connected":false,"message":"No storage containers found","containers":[],"items":[]}')
  return
 end

 local merged={}
 local order={}
 local containers={}
 local storage_count=0

 for _,entry in ipairs(entries) do
  local container=entry.obj

  if object_is_valid(container) then
   local full_name=entry.name or ""
   local items,items_source=get_container_stacks(container)

   if items then
    storage_count=storage_count+1
    local container_total=0

    pcall(function()
     items:ForEach(function(_,e)
      local stack=e:get()
      if stack and stack:IsValid() then
       local name=name_of(stack)
       local typ=type_of(stack)
       local q,f,r,u=counts_of(stack)
       container_total=container_total+q

       local key=string.lower(name).."||"..string.lower(typ)
       if not merged[key] then
        merged[key]={name=name,typ=typ,qty=0,full=0,repair=0,unknown=0}
        table.insert(order,key)
       end

       merged[key].qty=merged[key].qty+q
       merged[key].full=merged[key].full+f
       merged[key].repair=merged[key].repair+r
       merged[key].unknown=merged[key].unknown+u
      end
     end)
    end)

    table.insert(containers,{name=full_name,total=container_total})
   end
  end
 end

 table.sort(order,function(a,b) return string.lower(merged[a].name)<string.lower(merged[b].name) end)

 local parts={}
 table.insert(parts,'{"version":"0.18","connected":true,"message":"Storage scan complete","containers":[')

 for i,c in ipairs(containers) do
  if i>1 then table.insert(parts,",") end
  table.insert(parts,'{"name":"'..esc(c.name)..'","total":'..tostring(c.total)..'}')
 end

 table.insert(parts,'],"items":[')

 for i,key in ipairs(order) do
  local r=merged[key]
  if i>1 then table.insert(parts,",") end
  table.insert(parts,
   '{"name":"'..esc(r.name)..
   '","qty":'..tostring(r.qty)..
   ',"full":'..tostring(r.full)..
   ',"repair":'..tostring(r.repair)..
   ',"unknown":'..tostring(r.unknown)..
   ',"type":"'..esc(r.typ)..'"}')
 end

 table.insert(parts,'],"containerCount":'..tostring(storage_count)..
  ',"cacheRediscovered":'..tostring(rediscovered==true)..'}')

 write_json_atomic(storageJsonPath,table.concat(parts))

 log("Storage scan complete: "..tostring(storage_count)..
  " cached containers, "..tostring(#order).." item rows; rediscovered="..tostring(rediscovered==true)..".")
end


local function write_json_atomic(path, content)
 local tmp=path..".tmp"
 local f=io.open(tmp,"w")
 if not f then return false end
 f:write(content)
 f:close()
 os.remove(path)
 os.rename(tmp,path)
 return true
end

local cachedRepairContainers=nil
local cachedRepairDiscoveredAt=0
local REPAIR_CACHE_REDISCOVER_SECONDS=600

local function discover_repair_containers()
 local all=FindAllOf("BPC_CarPartsRepairMachineContainer_C")
 local valid={}
 if all then
  for _,container in ipairs(all) do
   if object_is_valid(container) then
    local fullName=""
    pcall(function() fullName=container:GetFullName() end)
    table.insert(valid,{obj=container,name=fullName})
   end
  end
 end
 table.sort(valid,function(a,b) return tostring(a.name)<tostring(b.name) end)
 cachedRepairContainers=valid
 cachedRepairDiscoveredAt=os.time()
 log("Repair cache discovery complete: "..tostring(#valid).." machine container(s) cached.")
 return valid
end

local function get_cached_repair_containers(forceDiscovery)
 local now=os.time()
 if forceDiscovery
 or cachedRepairContainers==nil
 or (now-cachedRepairDiscoveredAt)>=REPAIR_CACHE_REDISCOVER_SECONDS then
  return discover_repair_containers()
 end

 local valid={}
 for _,entry in ipairs(cachedRepairContainers) do
  if entry and object_is_valid(entry.obj) then table.insert(valid,entry) end
 end

 if #valid==0 and #cachedRepairContainers>0 then
  return discover_repair_containers()
 end

 cachedRepairContainers=valid
 return valid
end

local function invalidate_repair_container_cache()
 cachedRepairContainers=nil
 cachedRepairDiscoveredAt=0
end

local function scan_repair_machine(forceDiscovery)
 local valid=get_cached_repair_containers(forceDiscovery==true)
 if not valid or #valid==0 then
  write_json_atomic(repairJsonPath,'{"version":"0.35.1","connected":false,"containerCount":0,"machines":[],"items":[],"total":0}')
  return
 end

 local merged={}
 local order={}
 local machines={}
 local total=0

 for machineIndex,entry in ipairs(valid) do
  local container=entry.obj
  local machineMerged={}
  local machineOrder={}
  local machineTotal=0

  local items,items_source=get_container_stacks(container)
  if items then
   log("Repair machine "..tostring(machineIndex).." stack source: "..tostring(items_source))
   pcall(function()
    items:ForEach(function(_,e)
     local stack=e:get()
     if stack and stack:IsValid() then
      local name=name_of(stack)
      local typ=type_of(stack)
      local q,f,r,u=counts_of(stack)

      if q>0 then
       machineTotal=machineTotal+q
       total=total+q

       local key=string.lower(name).."||"..string.lower(typ)

       if not machineMerged[key] then
        machineMerged[key]={name=name,typ=typ,qty=0,full=0,repair=0,unknown=0}
        table.insert(machineOrder,key)
       end
       machineMerged[key].qty=machineMerged[key].qty+q
       machineMerged[key].full=machineMerged[key].full+f
       machineMerged[key].repair=machineMerged[key].repair+r
       machineMerged[key].unknown=machineMerged[key].unknown+u

       if not merged[key] then
        merged[key]={name=name,typ=typ,qty=0,full=0,repair=0,unknown=0,m1=0,m2=0}
        table.insert(order,key)
       end
       merged[key].qty=merged[key].qty+q
       merged[key].full=merged[key].full+f
       merged[key].repair=merged[key].repair+r
       merged[key].unknown=merged[key].unknown+u
       if machineIndex==1 then merged[key].m1=merged[key].m1+q end
       if machineIndex==2 then merged[key].m2=merged[key].m2+q end
      end
     end
    end)
   end)
  else
   log("Repair machine "..tostring(machineIndex).." found but stack list is not readable yet.")
  end

  table.sort(machineOrder,function(a,b) return string.lower(machineMerged[a].name)<string.lower(machineMerged[b].name) end)

  local machineItems={}
  for _,key in ipairs(machineOrder) do
   table.insert(machineItems,machineMerged[key])
  end

  table.insert(machines,{
   index=machineIndex,
   name=entry.name,
   total=machineTotal,
   rows=machineItems
  })
 end

 table.sort(order,function(a,b) return string.lower(merged[a].name)<string.lower(merged[b].name) end)

 local parts={}
 table.insert(parts,'{"version":"0.35.1","connected":true,"containerCount":'..tostring(#valid)..',"machines":[')

 for mi,m in ipairs(machines) do
  if mi>1 then table.insert(parts,",") end
  table.insert(parts,'{"index":'..tostring(m.index)..',"name":"'..esc(m.name)..'","total":'..tostring(m.total)..',"items":[')
  for ii,r in ipairs(m.rows) do
   if ii>1 then table.insert(parts,",") end
   table.insert(parts,
    '{"name":"'..esc(r.name)..
    '","qty":'..tostring(r.qty)..
    ',"full":'..tostring(r.full)..
    ',"repair":'..tostring(r.repair)..
    ',"unknown":'..tostring(r.unknown)..
    ',"type":"'..esc(r.typ)..'"}')
  end
  table.insert(parts,']}')
 end

 table.insert(parts,'],"items":[')
 for i,key in ipairs(order) do
  local r=merged[key]
  if i>1 then table.insert(parts,",") end
  table.insert(parts,
   '{"name":"'..esc(r.name)..
   '","qty":'..tostring(r.qty)..
   ',"machine1":'..tostring(r.m1 or 0)..
   ',"machine2":'..tostring(r.m2 or 0)..
   ',"full":'..tostring(r.full)..
   ',"repair":'..tostring(r.repair)..
   ',"unknown":'..tostring(r.unknown)..
   ',"type":"'..esc(r.typ)..'"}')
 end
 table.insert(parts,'],"total":'..tostring(total)..'}')

 write_json_atomic(repairJsonPath,table.concat(parts))
 log("Repair machine scan complete: "..tostring(#valid).." machines, "..tostring(#order).." rows, "..tostring(total).." items.")
end

local function safe_prop(obj, names)
 if obj==nil then return nil end
 for _,n in ipairs(names) do
  local ok,v=pcall(function() return obj[n] end)
  if ok and v~=nil then return v end
 end
 return nil
end

local function unwrap_string(v)
 if v==nil then return "" end

 local tv=type(v)
 if tv=="string" or tv=="number" or tv=="boolean" then
  return tostring(v)
 end

 -- Common UE4SS wrappers / FText / FString access patterns.
 local attempts={
  function() return v:ToString() end,
  function() return v:GetString() end,
  function() return v:String() end,
  function() return v.Text end,
  function() return v.Value end,
  function() return v.String end,
  function() return v.Data end
 }

 for _,fn in ipairs(attempts) do
  local ok,res=pcall(fn)
  if ok and res~=nil then
   local s=tostring(res)
   if s~="" and s~="nil" and not s:find("TrivialObject",1,true) then
    return s
   end
  end
 end

 local ok,s=pcall(function() return tostring(v) end)
 if ok and s and not s:find("TrivialObject",1,true) then return s end
 return ""
end

local function clean_enum_value(v)
 if v==nil then return "" end
 local s=unwrap_string(v)

 -- UE4SS may render an enum as a plain number or NewEnumeratorX.
 local n=tonumber(s)
 if n~=nil then return tostring(math.floor(n)) end

 local enumNum=s:match("NewEnumerator(%d+)")
 if enumNum then return enumNum end

 return s
end

local function number_value(v)
 if v==nil then return 0 end
 if type(v)=="number" then return v end

 local s=unwrap_string(v)
 local n=tonumber(s)
 if n then return n end

 -- FText quantities can still contain printable text around the number.
 local first=s:match("[-+]?%d+%.?%d*")
 if first then return tonumber(first) or 0 end
 return 0
end

local function array_each(arr, callback)
 if arr==nil then return end

 pcall(function()
  arr:ForEach(function(_,element)
   local value=element
   pcall(function()
    local got=element:get()
    if got~=nil then value=got end
   end)
   callback(value)
  end)
 end)
end


local modelNameMap={}
local bodyNameMap={}
local carNameByCarId={}
local carNameSourceByCarId={}
local carNameByInfoPath={}
local carNameSourceByInfoPath={}
local carNameByFingerprint={}
local carNameSourceByFingerprint={}
local carFingerprintCollisions={}
local carNameByVehiclePath={}
local carNameSourceByVehiclePath={}

local function valid_game_text(s)
 if s==nil then return false end
 s=tostring(s)
 if s=="" or s=="nil" then return false end
 if s:find("TrivialObject",1,true) then return false end
 if s:find("UObject:",1,true) then return false end
 return true
end

local function remember_car_name(carId, friendly, source)
 local id=unwrap_string(carId)
 local name=unwrap_string(friendly)
 if id~="" and valid_game_text(name) then
  carNameByCarId[id]=name
  carNameSourceByCarId[id]=source or "game"
 end
end

local function remember_model(modelId, friendly)
 local key=clean_enum_value(modelId)
 local name=unwrap_string(friendly)
 if key~="" and name~="" and not name:find("TrivialObject",1,true) then
  modelNameMap[key]=name
 end
end

local function remember_body(bodyId, friendly)
 local key=clean_enum_value(bodyId)
 local name=unwrap_string(friendly)
 if key~="" and name~="" and not name:find("TrivialObject",1,true) then
  bodyNameMap[key]=name
 end
end

local function deref_vehicle_ref(v)
 if v==nil then return nil end
 local out=v
 pcall(function()
  local g=v:get()
  if g~=nil then out=g end
 end)
 return out
end


-- ============================================================
-- v0.44.0.73 PERFORMANCE PASS 3 - EVENT-DRIVEN VEHICLE REGISTRY
--
-- Automatic Cars refreshes reuse live UObject references instead of doing
-- repeated full object-array scans for vehicles, VehicleInfoObjects, trunks
-- and garage storage. The table is intentionally global to avoid pushing this
-- already-large Lua chunk over Lua's 200-active-local limit.
-- ============================================================
PerfV73={
 liveVehicles={},vehicleInfos={},vehicleSeeded=false,infoSeeded=false,
 generation=0,notifyArmed=false,vehicleContainers=nil,
 vehicleContainersGeneration=-1,vehicleContainersSeeded=false,vehicleContainerMap={},garageStorages=nil,
 autoCarsLastGeneration=-1,autoCarsLastSync=0
}

function PerfV73.key(obj)
 if not object_is_valid(obj) then return nil end
 local okAddr,addr=pcall(function() return obj:GetAddress() end)
 if okAddr and addr~=nil then return "A:"..tostring(addr) end
 local okName,name=pcall(function() return obj:GetFullName() end)
 if okName and name and tostring(name)~="" then return "N:"..tostring(name) end
 return nil
end

function PerfV73.add_info(obj)
 obj=deref_vehicle_ref(obj)
 if not object_is_valid(obj) then return false end
 local key=PerfV73.key(obj)
 if not key then return false end
 if PerfV73.vehicleInfos[key]==nil then PerfV73.vehicleInfos[key]=obj end
 return true
end

function PerfV73.add_vehicle(obj)
 obj=deref_vehicle_ref(obj)
 if not object_is_valid(obj) then return false end
 local key=PerfV73.key(obj)
 if not key then return false end
 if PerfV73.liveVehicles[key]==nil then
  PerfV73.liveVehicles[key]=obj
  PerfV73.generation=PerfV73.generation+1
 end
 local rawInfo=safe_prop(obj,{"VehicleInfoObject","VehicleInfo"})
 if rawInfo~=nil then pcall(PerfV73.add_info,rawInfo) end
 return true
end

function PerfV73.add_container(obj)
 obj=deref_vehicle_ref(obj)
 if not object_is_valid(obj) then return false end
 local key=PerfV73.key(obj)
 if not key then return false end
 if PerfV73.vehicleContainerMap[key]==nil then
  PerfV73.vehicleContainerMap[key]=obj
 end
 return true
end

function PerfV73.arm()
 if PerfV73.notifyArmed then return end
 PerfV73.notifyArmed=true
 local okVehicle=pcall(function()
  NotifyOnNewObject("/Script/CarDealerSimulator.CDSVehicle",function(obj)
   pcall(PerfV73.add_vehicle,obj)
  end)
 end)
 local okCar=pcall(function()
  NotifyOnNewObject("/Script/CarDealerSimulator.CDSCar",function(obj)
   pcall(PerfV73.add_vehicle,obj)
  end)
 end)
 local okContainer=pcall(function()
  NotifyOnNewObject("/Script/CarDealerSimulator.BC_VehicleContainer",function(obj)
   pcall(PerfV73.add_container,obj)
  end)
 end)
 log("Performance registry listeners: CDSVehicle="..tostring(okVehicle).."; CDSCar="..tostring(okCar).."; VehicleContainer="..tostring(okContainer))
end

function PerfV73.prune(registry)
 local out,removed={},0
 for key,obj in pairs(registry) do
  if object_is_valid(obj) then out[key]=obj else removed=removed+1 end
 end
 return out,removed
end

function PerfV73.vehicles(forceSeed)
 if forceSeed or not PerfV73.vehicleSeeded then
  local all=FindAllOf("BP_VehicleBase_C")
  if all then for _,obj in ipairs(all) do pcall(PerfV73.add_vehicle,obj) end end
  PerfV73.vehicleSeeded=true
 end
 PerfV73.liveVehicles=PerfV73.prune(PerfV73.liveVehicles)
 local result={}
 for _,obj in pairs(PerfV73.liveVehicles) do table.insert(result,obj) end
 return result
end

function PerfV73.infos(forceSeed)
 for _,vehicle in pairs(PerfV73.liveVehicles) do
  if object_is_valid(vehicle) then
   local rawInfo=safe_prop(vehicle,{"VehicleInfoObject","VehicleInfo"})
   if rawInfo~=nil then pcall(PerfV73.add_info,rawInfo) end
  end
 end
 if forceSeed or not PerfV73.infoSeeded then
  local all=FindAllOf("BP_VehicleInfoObject_C")
  if all then for _,obj in ipairs(all) do pcall(PerfV73.add_info,obj) end end
  PerfV73.infoSeeded=true
 end
 PerfV73.vehicleInfos=PerfV73.prune(PerfV73.vehicleInfos)
 local result={}
 for _,obj in pairs(PerfV73.vehicleInfos) do table.insert(result,obj) end
 return result
end

function PerfV73.containers(forceDiscovery)
 -- Pass 7: discover the full vehicle-container set once, then keep it alive
 -- from NotifyOnNewObject. A normal vehicle registry generation change no longer
 -- causes FindAllOf(BC_VehicleContainer_C). Known trunks are still decoded on
 -- each Cars refresh so item changes inside an existing trunk remain visible.
 if forceDiscovery or not PerfV73.vehicleContainersSeeded then
  if forceDiscovery then PerfV73.vehicleContainerMap={} end
  local all=FindAllOf("BC_VehicleContainer_C")
  if all then for _,obj in ipairs(all) do pcall(PerfV73.add_container,obj) end end
  PerfV73.vehicleContainersSeeded=true
 end
 PerfV73.vehicleContainerMap=PerfV73.prune(PerfV73.vehicleContainerMap)
 local valid={}
 for _,obj in pairs(PerfV73.vehicleContainerMap) do table.insert(valid,obj) end
 PerfV73.vehicleContainers=valid
 PerfV73.vehicleContainersGeneration=PerfV73.generation
 return valid
end

function PerfV73.garages(forceDiscovery)
 if forceDiscovery or PerfV73.garageStorages==nil then
  local all=FindAllOf("BPC_UndergroundGarageCarStorage_C")
  local found={}
  if all then for _,obj in ipairs(all) do if object_is_valid(obj) then table.insert(found,obj) end end end
  PerfV73.garageStorages=found
  return found
 end
 local valid={}
 for _,obj in ipairs(PerfV73.garageStorages) do if object_is_valid(obj) then table.insert(valid,obj) end end
 if #valid==0 and #PerfV73.garageStorages>0 then
  PerfV73.garageStorages=nil
  return PerfV73.garages(true)
 end
 PerfV73.garageStorages=valid
 return valid
end

function PerfV73.reset()
 PerfV73.liveVehicles={}
 PerfV73.vehicleInfos={}
 PerfV73.vehicleSeeded=false
 PerfV73.infoSeeded=false
 PerfV73.generation=PerfV73.generation+1
 PerfV73.vehicleContainers=nil
 PerfV73.vehicleContainersGeneration=-1
 PerfV73.vehicleContainersSeeded=false
 PerfV73.vehicleContainerMap={}
 PerfV73.garageStorages=nil
 PerfV73.autoCarsLastGeneration=-1
 PerfV73.autoCarsLastSync=0
 if PerfV78 then
  PerfV78.forSaleRows={}
  PerfV78.reusedThisScan=0
  PerfV78.cachedThisScan=0
 end
 if PerfV79 then
  PerfV79.undergroundRows={}
  PerfV79.reusedThisScan=0
  PerfV79.cachedThisScan=0
 end
end

function PerfV73.should_auto_scan()
 local now=os.time()
 local generationChanged=(PerfV73.autoCarsLastGeneration~=PerfV73.generation)
 local safetyDue=(PerfV73.autoCarsLastSync==0) or ((now-PerfV73.autoCarsLastSync)>=1800)
 if generationChanged or safetyDue then
  return true,(generationChanged and "registry-changed" or "30-minute-safety-sync")
 end
 return false,"registry-unchanged"
end

function PerfV73.mark_auto_scan_complete()
 PerfV73.autoCarsLastGeneration=PerfV73.generation
 PerfV73.autoCarsLastSync=os.time()
end

PerfV73.arm()

local function object_identity_path(obj)
 obj=deref_vehicle_ref(obj)
 if obj==nil then return "" end

 local full=""
 pcall(function() full=obj:GetFullName() end)
 full=tostring(full or "")

 -- Strip the UE4SS class-name prefix so identity remains comparable even when
 -- wrapper representations differ.
 local path=full:match("^%S+%s+(.+)$")
 if path and path~="" then return path end
 return full
end

local function remember_car_name_for_info(info,friendly,source)
 local path=object_identity_path(info)
 local name=unwrap_string(friendly)

 if path~="" and valid_game_text(name) then
  carNameByInfoPath[path]=name
  carNameSourceByInfoPath[path]=source or "game"
 end
end

local function number_value(v)
 if v==nil then return nil end
 if type(v)=="number" then return v end
 local s=unwrap_string(v)
 if s=="" then return nil end
 return tonumber(s)
end

local function vehicle_fingerprint_from_info(info)
 info=deref_vehicle_ref(info)
 if info==nil then return "" end

 local year=number_value(safe_prop(info,{"ProductionYear","Year"}))
 local mileage=number_value(safe_prop(info,{"CurrentMileage","Mileage"}))

 if not year or not mileage then return "" end

 -- Mileage in BP_VehicleInfoObject_C is a floating-point value while the UI
 -- shows whole miles.  Round to the nearest integer so the same vehicle
 -- fingerprints identically from both live and owned-info paths.
 local miles=math.floor(mileage+0.5)
 local y=math.floor(year+0.5)

 return tostring(y).."|"..tostring(miles)
end

local function remember_car_name_for_fingerprint(info,friendly,source)
 local fp=vehicle_fingerprint_from_info(info)
 local name=unwrap_string(friendly)
 if fp=="" or not valid_game_text(name) then return end

 if carNameByFingerprint[fp] and carNameByFingerprint[fp]~=name then
  carFingerprintCollisions[fp]=true
  carNameByFingerprint[fp]=nil
  carNameSourceByFingerprint[fp]=nil
  return
 end

 if not carFingerprintCollisions[fp] then
  carNameByFingerprint[fp]=name
  carNameSourceByFingerprint[fp]=source or "live vehicle fingerprint"
 end
end

local function parent_vehicle_path_from_board(board)
 local path=object_identity_path(board)
 if path=="" then return "" end

 -- Expected board path shape:
 --   /Game/...BP_PickupVehicle_C_123.BP_ForSaleBoard
 -- or similar child-object suffixes.
 --
 -- Remove the final child component and retain the live vehicle actor path.
 local parent=path:match("^(.*)%.([^%.]+)$")
 if parent and parent~="" then return parent end
 return ""
end

local function remember_car_name_for_vehicle_path(vehiclePath,friendly,source)
 local name=unwrap_string(friendly)
 if vehiclePath~="" and valid_game_text(name) then
  carNameByVehiclePath[vehiclePath]=name
  carNameSourceByVehiclePath[vehiclePath]=source or "ForSaleBoard parent vehicle path"
 end
end

local function refresh_vehicle_name_maps()
 carNameByCarId={}
 carNameSourceByCarId={}
 carNameByInfoPath={}
 carNameSourceByInfoPath={}
 carNameByFingerprint={}
 carNameSourceByFingerprint={}
 carFingerprintCollisions={}
 carNameByVehiclePath={}
 carNameSourceByVehiclePath={}
 -- CONFIRMED FROM v0.21 DISCOVERY:
 -- Every live vehicle has a BP_ForSaleBoard_C child and that board exposes
 -- the real in-game model name through CarModel.
 --
 -- We DO NOT use board existence as a For Sale flag because the discovery
 -- proved boards exist on ordinary owned vehicles too.
 --
 -- Instead, use the board only as a name source:
 -- board.Owner -> live vehicle -> VehicleInfoObject -> CarId -> board.CarModel.
 pcall(function()
  local boards=FindAllOf("BP_ForSaleBoard_C")
  if boards then
   for _,board in ipairs(boards) do
    if board and board:IsValid() then
     local realName=unwrap_string(safe_prop(board,{"CarModel"}))
     local owner=deref_vehicle_ref(safe_prop(board,{"Owner","OwningVehicle","Vehicle","Car"}))

     -- v0.30.2 primary name source:
     -- derive the live vehicle actor path directly from the child ForSaleBoard
     -- object path. This avoids unreliable Owner/VehicleInfoObject wrappers.
     local boardVehiclePath=parent_vehicle_path_from_board(board)
     if boardVehiclePath~="" and valid_game_text(realName) then
      remember_car_name_for_vehicle_path(
       boardVehiclePath,
       realName,
       "BP_ForSaleBoard_C.CarModel via parent vehicle path"
      )
     end

     if owner~=nil and valid_game_text(realName) then
      local info=deref_vehicle_ref(safe_prop(owner,{"VehicleInfoObject","VehicleInfo"}))
      local id=""

      if info~=nil then
       id=unwrap_string(safe_prop(info,{"CarId","CarID"}))

       -- PRIMARY v0.28 association:
       -- use the exact VehicleInfoObject owned by the same live vehicle actor.
       -- This avoids CarId values such as "Car1" that are not reliable enough
       -- to join the display list back to the live actor.
       remember_car_name_for_info(
        info,
        realName,
        "BP_ForSaleBoard_C.CarModel via VehicleInfoObject identity"
       )
       remember_car_name_for_fingerprint(
        info,
        realName,
        "BP_ForSaleBoard_C.CarModel via year+mileage fingerprint"
       )
      end

      -- Keep the old CarId map only as a secondary fallback.
      if id=="" then
       id=unwrap_string(safe_prop(owner,{"CarId","CarID"}))
      end

      if id~="" then
       remember_car_name(id,realName,"BP_ForSaleBoard_C.CarModel")
      end
     end
    end
   end
  end
 end)

 -- The game's dealership objects contain a friendly model FString.
 pcall(function()
  local rows=FindAllOf("BP_CarDealershipContainerObject_C")
  if rows then
   for _,row in ipairs(rows) do
    if row and row:IsValid() then
     remember_model(
      safe_prop(row,{"CarModelId"}),
      safe_prop(row,{"Model"})
     )
    end
   end
  end
 end)

 -- The auto-dealer cart also exposes the friendly model name.
 pcall(function()
  local rows=FindAllOf("BP_AutodealerCartObject_C")
  if rows then
   for _,row in ipairs(rows) do
    if row and row:IsValid() then
     remember_model(
      safe_prop(row,{"CarModelId"}),
      safe_prop(row,{"CarModelName"})
     )
    end
   end
  end
 end)

 -- When this game UI exists, cache the exact localized body-type label
 -- displayed by the game itself.
 pcall(function()
  local widgets=FindAllOf("WBP_AutodealerCartItem_C")
  if widgets then
   for _,widget in ipairs(widgets) do
    if widget and widget:IsValid() then
     local data=safe_prop(widget,{"Data"})
     local body=safe_prop(data,{
      "BodyType",
      "BodyType_33_C1A2909A402B1CE89175158B2E38F089"
     })

     local textBox=safe_prop(widget,{"BodyTypeTextBox"})
     local display=nil
     if textBox then
      display=safe_prop(textBox,{"Text"})
      if display==nil then
       pcall(function() display=textBox:GetText() end)
      end
     end

     remember_body(body,display)
    end
   end
  end
 end)
end

local function get_preset_field(preset, names)
 if preset==nil then return nil end
 return safe_prop(preset,names)
end

local function get_model_display(obj, preset, modelId)
 local key=clean_enum_value(modelId)
 if modelNameMap[key] then return modelNameMap[key] end

 -- Try a friendly class/asset path from the preset as a useful fallback.
 local cls=get_preset_field(preset,{
  "VehicleBaseClass",
  "VehicleBaseClass_70_9EA4EDEE4D9F8A5F6265F5ABEEA1A0AA"
 })
 local classText=unwrap_string(cls)
 if classText~="" and not classText:find("TrivialObject",1,true) then
  local tail=classText:match("([^/%.:]+)$")
  if tail and tail~="" then
   tail=tail:gsub("^BP_",""):gsub("_C$",""):gsub("_"," ")
   if tail~="" then return tail end
  end
 end

 if key~="" then return "Model "..key end
 return "Unknown Model"
end

local OFFICIAL_BODY_NAMES={
 ["0"]="Hatchback",
 ["1"]="Sedan",
 ["2"]="SUV",
 ["3"]="Coupe",
 ["4"]="Muscle Car",
 ["5"]="Pickup",
 ["6"]="Wagon",
 ["7"]="Van",
 ["8"]="Bus"
}

local TIRE_PRESSURE_BY_BODY={
 ["0"]={min=1.0,opt=2.1,max=6.0},
 ["1"]={min=1.2,opt=2.5,max=6.0},
 ["2"]={min=1.5,opt=2.7,max=6.0},
 ["3"]={min=1.2,opt=2.5,max=6.0},
 ["4"]={min=1.3,opt=2.9,max=6.0},
 ["5"]={min=1.6,opt=3.0,max=6.0},
 ["6"]={min=1.3,opt=2.9,max=6.0},
 ["7"]={min=2.0,opt=3.5,max=6.0},
 ["8"]={min=2.0,opt=3.8,max=6.0}
}

local function get_body_display(bodyId)
 local key=clean_enum_value(bodyId)
 if bodyNameMap[key] then return bodyNameMap[key] end
 if OFFICIAL_BODY_NAMES[key] then return OFFICIAL_BODY_NAMES[key] end
 if key~="" then return "Body Type "..key end
 return "Unknown Type"
end

local function get_tire_pressure_spec(bodyId)
 local key=clean_enum_value(bodyId)
 return TIRE_PRESSURE_BY_BODY[key]
end

local function deref_object(v)
 if v==nil then return nil end

 -- UE4SS Blueprint object properties are often returned as TrivialObject /
 -- wrapper values.  v0.26.1 proved VehicleInfoObject is one of them.
 local out=v

 pcall(function()
  local g=v:get()
  if g~=nil then out=g end
 end)

 pcall(function()
  if out==v and v.Get then
   local g=v:Get()
   if g~=nil then out=g end
  end
 end)

 return out
end

local function full_object_path(obj)
 if obj==nil then return "" end
 local full=""
 pcall(function() full=obj:GetFullName() end)
 full=tostring(full or "")

 -- UE4SS GetFullName() format:
 --   BP_PickupVehicle_C /Game/...BP_PickupVehicle_C_123
 --   BC_VehicleContainer_C /Game/...BP_PickupVehicle_C_123.BC_VehicleContainer
 --
 -- v0.24 compared the WHOLE strings, so the different class prefixes made
 -- every comparison fail and produced "live trunk map=0".
 local p=full:match("^%S+%s+(.+)$")
 if p and p~="" then return p end
 return full
end

local function car_id_from_vehicle(vehicle)
 if vehicle==nil then return "" end

 local rawInfo=safe_prop(vehicle,{"VehicleInfoObject","VehicleInfo"})
 local info=deref_object(rawInfo)

 -- Preferred: dereferenced VehicleInfoObject.
 local id=unwrap_string(safe_prop(info,{"CarId","CarID","VehicleId","VehicleID"}))
 if id~="" then return id end

 -- Some UE4SS wrappers allow field access without an explicit :get().
 id=unwrap_string(safe_prop(rawInfo,{"CarId","CarID","VehicleId","VehicleID"}))
 if id~="" then return id end

 -- Last direct actor fallback.
 return unwrap_string(safe_prop(vehicle,{"CarId","CarID","VehicleId","VehicleID"}))
end

local function decode_trunk_container(container)
 -- v0.27 proved the association works, but the first live test later fatal-errored.
 -- Keep the useful mapping and make trunk decoding deliberately conservative.
 --
 -- v0.26.1 proved the reference Canyon reported 30 container rows while the
 -- in-game trunk showed 30/60.  For now, treat each row as one occupied trunk
 -- slot instead of probing quantity/condition structures on every stack.

 local rows={}
 local total=0
 local items,source=get_container_stacks(container)

 if not items then
  return rows,total,source or ""
 end

 -- First count rows without touching stack contents.
 local rowCount=0
 pcall(function()
  items:ForEach(function(_,e)
   rowCount=rowCount+1
  end)
 end)

 if rowCount<=0 then
  return rows,0,source or ""
 end

 -- Only non-empty trunks are decoded.
 pcall(function()
  items:ForEach(function(_,e)
   local ok,err=pcall(function()
    local stack=deref_object(e)
    if not stack then return end

    local valid=true
    pcall(function() valid=stack:IsValid() end)
    if not valid then return end

    local itemName="Unknown Item"
    pcall(function()
     local n=name_of(stack)
     if n and tostring(n)~="" then itemName=tostring(n) end
    end)

    total=total+1
    table.insert(rows,{
     name=itemName,
     qty=1,
     durability=-1,
     typ="",
     full=0,
     repair=0,
     unknown=1
    })
   end)

   if not ok then
    -- Skip a bad/transient stack rather than risking the whole scan.
   end
  end)
 end)

 -- If any individual stack was skipped, preserve the known occupied-slot count.
 -- This makes the Trunk column useful even if one stack cannot be decoded.
 if total<rowCount then total=rowCount end

 table.sort(rows,function(a,b)
  return string.lower(a.name or "")<string.lower(b.name or "")
 end)

 return rows,total,source or ""
end


local function build_live_vehicle_map()
 -- Build everything from the SAME live BP_VehicleBase_C actor:
 --
 --   live actor
 --      -> VehicleInfoObject -> CarId
 --      -> <actor path>.BC_VehicleContainer
 --
 -- This is the relationship proved by v0.26.1.
 local result={}
 local byPath={}
 local vehicles=PerfV73.vehicles(false)

 if not vehicles then return result,byPath,0,0 end

 local liveCount=0
 local idCount=0

 for _,vehicle in ipairs(vehicles) do
  if vehicle and vehicle:IsValid() then
   liveCount=liveCount+1

   local vpath=full_object_path(vehicle)
   local carId=car_id_from_vehicle(vehicle)

   if vpath~="" then
    byPath[vpath]={
     vehicle=vehicle,
     carId=carId,
     objectName=object_identity_path(vehicle),
     trunk=nil,
     trunkPath=""
    }
   end

   if carId~="" then
    idCount=idCount+1

    -- Bridge the path-derived board name onto the same live vehicle's CarId.
    if vpath~="" and carNameByVehiclePath[vpath] then
     remember_car_name(
      carId,
      carNameByVehiclePath[vpath],
      carNameSourceByVehiclePath[vpath] or "vehicle path bridge"
     )
    end

    result[carId]={
     vehicle=vehicle,
     vehiclePath=vpath,
     trunk=nil,
     trunkPath="",
     rows={},
     total=0
    }
   end
  end
 end

 return result,byPath,liveCount,idCount
end

local function attach_live_trunks(result,byPath,forceDiscovery)
 local containers=PerfV73.containers(forceDiscovery==true)
 if not containers then return 0,0,0 end
 if forceDiscovery==true or refreshSettings.debug_enabled then
  log("Trunk container cache: count="..tostring(#containers).."; fullDiscovery="..tostring(forceDiscovery==true))
 end

 local containerCount=0
 local attachedCount=0
 local nonemptyCount=0

 for _,container in ipairs(containers) do
  local okContainer,errContainer=pcall(function()
   if not container or not container:IsValid() then return end

   containerCount=containerCount+1

   local cpath=full_object_path(container)
   local parentPath=cpath:gsub("%.BC_VehicleContainer$","")
   local live=byPath[parentPath]

   if not live then return end

   attachedCount=attachedCount+1

   local rows,total,source=decode_trunk_container(container)
   if total>0 then nonemptyCount=nonemptyCount+1 end

   live.trunk=container
   live.trunkPath=cpath
   live.rows=rows
   live.total=total
   live.source=source

   if live.carId~="" and result[live.carId] then
    result[live.carId].trunk=container
    result[live.carId].trunkPath=cpath
    result[live.carId].rows=rows
    result[live.carId].total=total
    result[live.carId].source=source
   end
  end)

  if not okContainer then
   -- A vehicle/container may unload while this pass is running.
   -- Skip it and continue instead of carrying the failure outward.
  end
 end

 return containerCount,attachedCount,nonemptyCount
end


local activeLiveVehicleMap={}
local activeLiveVehicleByPath={}
local activeTrunkStats={live=0,withId=0,containers=0,attached=0,nonempty=0}

local function refresh_live_vehicle_trunks(forceDiscovery)
 local result,byPath,liveCount,idCount=build_live_vehicle_map()
 local containerCount,attachedCount,nonemptyCount=attach_live_trunks(result,byPath,forceDiscovery==true)

 activeLiveVehicleMap=result
 activeLiveVehicleByPath=byPath
 activeTrunkStats={
  live=liveCount,
  withId=idCount,
  containers=containerCount,
  attached=attachedCount,
  nonempty=nonemptyCount
 }
end

local function read_trunk(obj)
 local carId=unwrap_string(safe_prop(obj,{"CarId","CarID","VehicleId","VehicleID"}))

 if carId~="" and activeLiveVehicleMap[carId] then
  local live=activeLiveVehicleMap[carId]
  return live.rows or {},live.total or 0,live.trunkPath or ""
 end

 return {},0,""
end


local function sale_info_for_car(obj)
 -- v0.37.2.2: direct read-only sale-state route proven by the Your Ads chain.
 -- BP_VehicleInfoObject_C.VehicleOffer points to the active BP_VehicleOffer_C.
 -- No UI scan, no Blueprint function call and no extra world scan.
 local raw=safe_prop(obj,{"VehicleOffer"})
 local offer=deref_vehicle_ref(raw)
 if offer==nil then return false,nil,nil end

 local valid=true
 local ok,res=pcall(function() return offer:IsValid() end)
 if ok then valid=(res==true or res==1) end
 if not valid then return false,nil,nil end

 local price=number_value(safe_prop(offer,{"OfferPrice"}))
 local days=number_value(safe_prop(offer,{"DaysLeft"}))
 return true,price,days
end

local function sale_status_for_car(obj, carId, modelId)
 local listed=select(1,sale_info_for_car(obj))
 if listed then return "For Sale" end
 return "Waiting"
end

local function get_direct_vehicle_display_name(info)
 if info==nil then return "","" end

 local ok,res=pcall(function()
  return info:GetVehicleDisplayName(" ")
 end)

 if not ok or res==nil then
  return "","GetVehicleDisplayName failed"
 end

 local text=""

 -- v0.32.1 proved this exact path works on every owned vehicle tested.
 pcall(function()
  text=res:ToString()
 end)

 text=unwrap_string(text)

 if valid_game_text(text) then
  return text,"GetVehicleDisplayName().ToString()"
 end

 return "","GetVehicleDisplayName returned unreadable FText"
end

local function safe_vehicle_field(obj,name)
 if obj==nil then return nil end
 local ok,v=pcall(function() return obj[name] end)
 if ok then return v end
 return nil
end

local function safe_vehicle_number(obj,name)
 local v=safe_vehicle_field(obj,name)
 if v==nil then return nil end
 local n=tonumber(unwrap_string(v))
 if n~=nil then return n end
 return nil
end

local function safe_vehicle_text(obj,name)
 local v=safe_vehicle_field(obj,name)
 if v==nil then return "" end
 local s=unwrap_string(v)
 if s==nil then return "" end
 return tostring(s)
end

local function safe_vehicle_color_name(obj)
 local color=safe_vehicle_field(obj,"Color")
 if color==nil then return "" end

 local value=nil
 pcall(function() value=color.ColorName end)
 if value==nil then
  pcall(function() value=color["ColorName_4_4D6C228D4CC534E6BCB645A290657AC9"] end)
 end

 if value==nil then return "" end
 return unwrap_string(value)
end


-- ============================================================
-- v0.37 SELECTED CAR DETAILS
-- Exact fields proven by the v0.36.7 known-struct sweep.
-- No guessed Blueprint condition calls are used here.
-- ============================================================

local PART_INSTALLED="Installed_1_FE67A71B41D0DCCFF9FF5BA9AB7E9E54"
local PART_DURABILITY="Durability_5_E5CEF82A49BAFF9F95BAEAB8DB143B18"
local PART_ID="PartID_14_43E0C71045F6642C694B38B4135E891E"

local FUSE_INSTALLED="Installed_1_FE67A71B41D0DCCFF9FF5BA9AB7E9E54"
local FUSE_DURABILITY="Durability_5_E5CEF82A49BAFF9F95BAEAB8DB143B18"

local COLOR_NAME_FIELD="ColorName_4_4D6C228D4CC534E6BCB645A290657AC9"
local COLOR_LINEAR_FIELD="Color_5_D977B97A40BA529FAD896B8C9058AC94"

local DETAIL_GROUPS={
 "BrakesParts",
 "SuspentionParts",
 "ExhaustParts",
 "ClutchParts",
 "EngineParts",
 "RadiatorParts",
 "ElectricParts"
}

local function direct_struct_field(obj,name)
 if obj==nil then return nil end
 local v=nil
 pcall(function() v=obj[name] end)
 return v
end


-- ============================================================
-- v0.44.0.78 PERFORMANCE PASS 8 - FOR-SALE PROCESSED CAR CACHE
--
-- Cars that are actively advertised cannot be moved/worked on by the player.
-- Once a complete row has been built, automatic Cars scans reuse that processed
-- row while the sale offer still exists. We only reread the lightweight sale
-- offer fields so taking a car off sale is detected immediately. Manual Scan
-- Cars always bypasses this cache and refreshes the complete row.
-- ============================================================
PerfV78=PerfV78 or {forSaleRows={},reusedThisScan=0,cachedThisScan=0}

function PerfV78.try_reuse_for_sale(obj,carId,fullDiscovery)
 if fullDiscovery or carId==nil or carId=="" then return nil end
 local cached=PerfV78.forSaleRows[carId]
 if cached==nil then return nil end
 local isForSale,listingPrice,listingDaysLeft=sale_info_for_car(obj)
 if not isForSale then
  PerfV78.forSaleRows[carId]=nil
  return nil
 end
 cached.isForSale=true
 cached.hasSaleOffer=true
 cached.saleStatus="For Sale"
 cached.listingPrice=listingPrice
 cached.listingDaysLeft=listingDaysLeft
 PerfV78.reusedThisScan=(PerfV78.reusedThisScan or 0)+1
 return cached
end

-- ============================================================
-- v0.44.0.79 PERFORMANCE PASS 9 - UNDERGROUND READY-CAR CACHE
--
-- Save discovery proved the owned collection is split across normal vehicle
-- state and UndergroundGarageCarStorage. Pass 9 conservatively caches only
-- underground cars that have already reached 95%+ mechanical condition and
-- are not wrecks or sale listings. Underground Waiting/repair cars continue
-- through full processing on every refresh so their condition can progress.
-- Manual Scan Cars always bypasses this cache and rebuilds every row.
-- ============================================================
PerfV79=PerfV79 or {undergroundRows={},reusedThisScan=0,cachedThisScan=0}

function PerfV79.try_reuse_underground(obj,carId,inUnderground,fullDiscovery)
 if fullDiscovery or not inUnderground or carId==nil or carId=="" then return nil end
 local cached=PerfV79.undergroundRows[carId]
 if cached==nil then return nil end
 -- A sale offer is a contradictory live state. Invalidate rather than trust
 -- a stale underground row if the game ever exposes both at once.
 local isForSale=select(1,sale_info_for_car(obj))
 if isForSale then
  PerfV79.undergroundRows[carId]=nil
  return nil
 end
 cached.inUndergroundGarage=true
 cached.hasLiveVehicle=false
 cached.hasSaleOffer=false
 cached.isVehicleInfoOnly=false
 cached.location="Underground Garage"
 cached.locationSource="StoredCars"
 cached.saleStatus="Waiting"
 cached.isForSale=false
 cached.listingPrice=nil
 cached.listingDaysLeft=nil
 PerfV79.reusedThisScan=(PerfV79.reusedThisScan or 0)+1
 return cached
end

local function read_color_details(obj)
 local enum,r,g,b,a="",nil,nil,nil,nil
 local color=safe_vehicle_field(obj,"Color")
 if color==nil then return enum,r,g,b,a end

 local ev=direct_struct_field(color,COLOR_NAME_FIELD)
 if ev==nil then
  pcall(function() ev=color.ColorName end)
 end
 if ev~=nil then enum=unwrap_string(ev) end

 local linear=direct_struct_field(color,COLOR_LINEAR_FIELD)
 if linear~=nil then
  r=tonumber(unwrap_string(safe_prop(linear,{"R"})))
  g=tonumber(unwrap_string(safe_prop(linear,{"G"})))
  b=tonumber(unwrap_string(safe_prop(linear,{"B"})))
  a=tonumber(unwrap_string(safe_prop(linear,{"A"})))
 end

 return enum,r,g,b,a
end

local function json_number_or_null(v)
 if v==nil then return "null" end
 local n=tonumber(v)
 if n==nil then return "null" end
 return tostring(n)
end

local function read_selected_car_request()
 local f=io.open(selectedCarRequestPath,"r")
 if not f then return "" end
 local s=f:read("*a") or ""
 f:close()
 s=s:gsub("^%s+",""):gsub("%s+$","")
 return s
end

local function selected_details_already_current(carId)
 if carId==nil or carId=="" then return false end
 local f=io.open(selectedCarDetailsPath,"r")
 if not f then return false end
 local s=f:read("*a") or ""
 f:close()
 if s=="" then return false end
 local needle='"carId":"'..esc(carId)..'"'
 return s:find(needle,1,true)~=nil
end

local function find_owned_car_by_id(carId)
 if carId==nil or carId=="" then return nil end

 -- Resolve fresh only for an explicit Vehicle Details request.
 -- Do not hold BP_VehicleInfoObject references between periodic scans.
 local all=FindAllOf("BP_VehicleInfoObject_C")
 if not all then return nil end

 for _,obj in ipairs(all) do
  if obj and obj:IsValid() then
   local owned=safe_prop(obj,{"PlayerOwned","bPlayerOwned","IsPlayerOwned"})
   if owned==true or owned==1 then
    local id=unwrap_string(safe_prop(obj,{"CarId","CarID","VehicleId","VehicleID"}))
    if id==carId then return obj end
   end
  end
 end
 return nil
end

local function collect_part_details(obj)
 local result={}
 for _,groupName in ipairs(DETAIL_GROUPS) do
  local group=safe_prop(obj,{groupName})
  if group~=nil then
   pcall(function()
    group:ForEach(function(a,b)
     local key=a
     local state=b
     pcall(function() key=a:get() end)
     pcall(function() state=b:get() end)

     local keyText=unwrap_string(key)
     if keyText and keyText~="" and state~=nil then
      local installed=direct_struct_field(state,PART_INSTALLED)
      local durability=direct_struct_field(state,PART_DURABILITY)
      local partId=direct_struct_field(state,PART_ID)

      result[keyText]={
       installed=(installed==true or installed==1),
       durability=tonumber(unwrap_string(durability)),
       partId=unwrap_string(partId) or ""
      }
     end
    end)
   end)
  end
 end
 return result
end

-- v0.43.7.2: read the live car-parts component the same way the game does.
-- The BP_CarPartAndVehicleComponent exposes GetAllCarParts(), returning a
-- TMap<Name,S_VehiclePartState>. This is the authoritative path for current
-- PartID values such as BrakeDiscSport / BrakeDiscRace.
local function collect_part_details_from_map(group)
 local result={}
 if group==nil then return result end
 pcall(function()
  group:ForEach(function(a,b)
   local key=a
   local state=b
   pcall(function() key=a:get() end)
   pcall(function() state=b:get() end)
   local keyText=unwrap_string(key)
   if keyText and keyText~="" and state~=nil then
    local installed=direct_struct_field(state,PART_INSTALLED)
    local durability=direct_struct_field(state,PART_DURABILITY)
    local partId=direct_struct_field(state,PART_ID)
    result[keyText]={
     installed=(installed==true or installed==1),
     durability=tonumber(unwrap_string(durability)),
     partId=unwrap_string(partId) or ""
    }
   end
  end)
 end)
 return result
end

local function count_table_entries(t)
 local n=0
 for _ in pairs(t or {}) do n=n+1 end
 return n
end

local function collect_live_car_parts(liveVehicle,diagnosticLabel)
 local empty={}
 local diag=(diagnosticLabel~=nil)
 if liveVehicle==nil then
  if diag then fitted_diag_write("  LIVE VEHICLE: <nil>\n") end
  return empty
 end

 if diag then
  fitted_diag_write("  LIVE VEHICLE: "..tostring(object_identity_path(liveVehicle)).."\n")
 end

 local component=nil
 local componentNames={
  "BP_CarPartAndVehicleComponent_GEN_VARIABLE",
  "BP_CarPartAndVehicleComponent",
  "CarPartAndVehicleComponent"
 }
 for _,propName in ipairs(componentNames) do
  local candidate=safe_prop(liveVehicle,{propName})
  if diag then
   fitted_diag_write("  component property "..propName.." = "..tostring(candidate~=nil).."\n")
  end
  if component==nil and candidate~=nil then component=candidate end
 end

 local targets={
  {name="component",obj=component},
  {name="vehicle",obj=liveVehicle}
 }
 for _,entry in ipairs(targets) do
  local target=entry.obj
  if target~=nil then
   local ok,map=pcall(function() return target:GetAllCarParts() end)
   if diag then
    fitted_diag_write("  GetAllCarParts on "..entry.name.." -> ok="..tostring(ok).." map="..tostring(map~=nil).."\n")
   end
   if ok and map~=nil then
    local parsed=collect_part_details_from_map(map)
    local parsedCount=count_table_entries(parsed)
    if diag then fitted_diag_write("  parsed fitted states from "..entry.name..": "..tostring(parsedCount).."\n") end
    if next(parsed)~=nil then return parsed end
   end
  elseif diag then
   fitted_diag_write("  GetAllCarParts on "..entry.name.." -> target missing\n")
  end
 end
 return empty
end

local function collect_fuse_summary(obj)
 local group=safe_prop(obj,{"FusesState"})
 if group==nil then return nil end

 local count=0
 local installedCount=0
 local total=0
 local bad=0

 pcall(function()
  group:ForEach(function(_,b)
   local state=b
   pcall(function() state=b:get() end)
   if state~=nil then
    count=count+1
    local installed=direct_struct_field(state,FUSE_INSTALLED)
    local durability=tonumber(unwrap_string(direct_struct_field(state,FUSE_DURABILITY)))
    if installed==true or installed==1 then
     installedCount=installedCount+1
     if durability~=nil then
      total=total+durability
      if durability<0.5 then bad=bad+1 end
     end
    end
   end
  end)
 end)

 local avg=nil
 if installedCount>0 then avg=total/installedCount end
 return {count=count,installed=installedCount,average=avg,bad=bad}
end

local function count_exhaust_holes(obj)
 local group=safe_prop(obj,{"ExhaustHoles"})
 if group==nil then return nil end
 local count=0
 pcall(function()
  group:ForEach(function(_,_) count=count+1 end)
 end)
 return count
end


local function read_windshield_state(obj)
 local group=safe_prop(obj,{"MiscParts"})
 if group==nil then return nil end

 local found=nil
 pcall(function()
  group:ForEach(function(a,b)
   if found~=nil then return end
   local key=a
   local state=b
   pcall(function() key=a:get() end)
   pcall(function() state=b:get() end)

   local keyText=string.lower(unwrap_string(key) or "")
   keyText=keyText:gsub("[^a-z]","")
   if keyText=="windshield" and state~=nil then
    local installed=direct_struct_field(state,PART_INSTALLED)
    local durability=direct_struct_field(state,PART_DURABILITY)
    local partId=direct_struct_field(state,PART_ID)
    found={
     installed=(installed==true or installed==1),
     durability=tonumber(unwrap_string(durability)),
     partId=unwrap_string(partId) or ""
    }
   end
  end)
 end)
 return found
end

local function read_tire_pressures(obj)
 local arr=safe_vehicle_field(obj,"TirePressures")
 local out={nil,nil,nil,nil}
 if arr==nil then return out end

 local pos=0
 pcall(function()
  arr:ForEach(function(_,element)
   pos=pos+1
   if pos<=4 then
    local value=element
    pcall(function()
     local got=element:get()
     if got~=nil then value=got end
    end)
    out[pos]=tonumber(unwrap_string(value))
   end
  end)
 end)
 return out
end

local function write_selected_car_details()
 local carId=read_selected_car_request()
 if carId=="" then return end

 -- Completed details stay cached until REFRESH DETAILS explicitly requests
 -- one new read by removing selected_car_details.json.
 if selected_details_already_current(carId) then return end

 local obj=find_owned_car_by_id(carId)
 if obj==nil then
  write_json_atomic(selectedCarDetailsPath,
   '{"version":"0.37","connected":false,"carId":"'..esc(carId)..'"}')
  return
 end

 local modelName=""
 pcall(function()
  local t=obj:GetVehicleDisplayName(" ")
  if t~=nil then modelName=t:ToString() end
 end)

 local partsMap=collect_part_details(obj)
 local fuses=collect_fuse_summary(obj)
 local exhaustHoles=count_exhaust_holes(obj)
 local colorEnum,cr,cg,cb,ca=read_color_details(obj)
 local windshield=read_windshield_state(obj)
 local tires=read_tire_pressures(obj)

 -- v0.37.2.0 SALE STATE PROOF
 -- Read-only inspection of the already-selected BP_VehicleInfoObject_C only.
 -- No Blueprint calls, no UI scan, no extra world scan, no state mutation.
 local canCreateOfferRaw=safe_prop(obj,{"CanCreateOffer"})
 local canCreateOffer=nil
 if canCreateOfferRaw~=nil then
  canCreateOffer=(canCreateOfferRaw==true or canCreateOfferRaw==1)
 end

 local vehicleOfferRaw=safe_prop(obj,{"VehicleOffer"})
 local vehicleOffer=deref_vehicle_ref(vehicleOfferRaw)
 local vehicleOfferValid=false
 if vehicleOffer~=nil then
  local okValid,resValid=pcall(function() return vehicleOffer:IsValid() end)
  if okValid then vehicleOfferValid=(resValid==true or resValid==1) else vehicleOfferValid=true end
 end

 local offerPrice=nil
 local offerDaysLeft=nil
 local offerParkingSlotId=""
 if vehicleOfferValid then
  offerPrice=number_value(safe_prop(vehicleOffer,{"OfferPrice"}))
  offerDaysLeft=number_value(safe_prop(vehicleOffer,{"DaysLeft"}))
  offerParkingSlotId=unwrap_string(safe_prop(vehicleOffer,{"ParkingSlotID","ParkingSlotId"})) or ""
 end

 -- v0.37.1.1: fuel is read from the already-mapped live BP_VehicleBase_C actor.
 -- This is a direct saved DoubleProperty read; no Blueprint out-parameter call is used.
 local liveVehicle=nil
 if activeLiveVehicleMap[carId] then liveVehicle=activeLiveVehicleMap[carId].vehicle end
 local fuelCurrent=nil
 if liveVehicle~=nil then
  local rawFuel=safe_prop(liveVehicle,{"Fuel"})
  if rawFuel~=nil then fuelCurrent=number_value(rawFuel) end
 end

 local preset=safe_prop(obj,{"ModelPresetInfo"})
 local bodyId=nil
 if preset~=nil then
  bodyId=get_preset_field(preset,{
   "BodyType",
   "BodyType_33_C1A2909A402B1CE89175158B2E38F089"
  })
 end
 local bodyKey=clean_enum_value(bodyId)
 local bodyDisplay=get_body_display(bodyId)
 local tireSpec=get_tire_pressure_spec(bodyId)
 local fuelMax=nil
 if preset~=nil then
  local rawFuelMax=get_preset_field(preset,{
   "FuelTankCapacity",
   "FuelTankCapacity_46_975C065E4844E8DA82598AA39622D1B8"
  })
  if rawFuelMax~=nil then fuelMax=number_value(rawFuelMax) end
 end
 if fuelMax~=nil and fuelMax<=0 then fuelMax=nil end
 local fuelPercent=nil
 if fuelCurrent~=nil and fuelMax~=nil and fuelMax>0 then
  fuelPercent=(fuelCurrent/fuelMax)*100.0
 end

 local chunks={}
 table.insert(chunks,
  '{"version":"0.37","connected":true'..
  ',"carId":"'..esc(carId)..'"'..
  ',"model":"'..esc(modelName or "")..'"'..
  ',"year":'..tostring(math.floor(number_value(safe_prop(obj,{"ProductionYear","Year"})) or 0))..
  ',"mileage":'..tostring(number_value(safe_prop(obj,{"CurrentMileage","Mileage"})) or 0)..
  ',"buyingPlayerPrice":'..tostring(safe_vehicle_number(obj,"BuyingPlayerPrice") or 0)..
  ',"gearboxType":"'..esc(safe_vehicle_text(obj,"GearboxType"))..'"'..
  ',"fuelType":"'..esc(safe_vehicle_text(obj,"FuelType"))..'"'..
  ',"fuelCurrent":'..json_number_or_null(fuelCurrent)..
  ',"fuelMax":'..json_number_or_null(fuelMax)..
  ',"fuelPercent":'..json_number_or_null(fuelPercent)..
  ',"saleProbeCanCreateOffer":'..(canCreateOffer==nil and 'null' or tostring(canCreateOffer))..
  ',"saleProbeVehicleOfferValid":'..tostring(vehicleOfferValid)..
  ',"saleProbeOfferPrice":'..json_number_or_null(offerPrice)..
  ',"saleProbeDaysLeft":'..json_number_or_null(offerDaysLeft)..
  ',"saleProbeParkingSlotId":"'..esc(offerParkingSlotId or "")..'"'..
  ',"carplateCleaned":'..tostring(safe_prop(obj,{"CarplateCleaned"})==true or safe_prop(obj,{"CarplateCleaned"})==1)..
  ',"carplateId":"'..esc(unwrap_string(safe_prop(obj,{"CarplateID"})) or "")..'"'..
  ',"colorEnum":"'..esc(colorEnum or "")..'"'..
  ',"colorR":'..json_number_or_null(cr)..
  ',"colorG":'..json_number_or_null(cg)..
  ',"colorB":'..json_number_or_null(cb)..
  ',"colorA":'..json_number_or_null(ca)..
  ',"bodyType":"'..esc(bodyDisplay or "")..'"'..
  ',"bodyTypeId":"'..esc(bodyKey or "")..'"'..
  ',"exhaustHoles":'..json_number_or_null(exhaustHoles)..
  ',"windshieldInstalled":'..tostring(windshield~=nil and windshield.installed or false)..
  ',"windshield":'..json_number_or_null(windshield and windshield.durability or nil)..
  ',"windshieldPartId":"'..esc((windshield and windshield.partId) or "")..'"'..
  ',"tire1":'..json_number_or_null(tires[1])..
  ',"tire2":'..json_number_or_null(tires[2])..
  ',"tire3":'..json_number_or_null(tires[3])..
  ',"tire4":'..json_number_or_null(tires[4])..
  ',"tireMin":'..json_number_or_null(tireSpec and tireSpec.min or nil)..
  ',"tireOpt":'..json_number_or_null(tireSpec and tireSpec.opt or nil)..
  ',"tireMax":'..json_number_or_null(tireSpec and tireSpec.max or nil)..
  ',"parts":{')

 local first=true
 for key,state in pairs(partsMap) do
  if not first then table.insert(chunks,",") end
  first=false
  table.insert(chunks,
   '"'..esc(key)..'":{'..
   '"installed":'..tostring(state.installed)..
   ',"durability":'..json_number_or_null(state.durability)..
   ',"partId":"'..esc(state.partId or "")..'"}')
 end

 table.insert(chunks,'}')

 if fuses~=nil then
  table.insert(chunks,
   ',"fuses":{"count":'..tostring(fuses.count or 0)..
   ',"installed":'..tostring(fuses.installed or 0)..
   ',"average":'..json_number_or_null(fuses.average)..
   ',"bad":'..tostring(fuses.bad or 0)..'}')
 else
  table.insert(chunks,',"fuses":null')
 end

 table.insert(chunks,'}')
 write_json_atomic(selectedCarDetailsPath,table.concat(chunks))
end


local READINESS_GROUPS={
 {key="Brakes",prop="BrakesParts"},
 {key="Suspension",prop="SuspentionParts"},
 {key="Exhaust",prop="ExhaustParts"},
 {key="Clutch",prop="ClutchParts"},
 {key="Engine",prop="EngineParts"},
 {key="Radiator",prop="RadiatorParts"},
 {key="Electrical",prop="ElectricParts"}
}

local function score_part_group(obj,propName)
 local group=safe_prop(obj,{propName})
 if group==nil then return nil end
 local total=0
 local count=0
 pcall(function()
  group:ForEach(function(_,b)
   local state=b
   pcall(function() state=b:get() end)
   if state~=nil then
    count=count+1
    local installed=direct_struct_field(state,PART_INSTALLED)
    local durability=tonumber(unwrap_string(direct_struct_field(state,PART_DURABILITY)))
    if installed==true or installed==1 then
     total=total+(durability or 0)
    end
   end
  end)
 end)
 if count<=0 then return nil end
 return total/count
end

local function score_named_part(obj,propName,wantedName)
 local group=safe_prop(obj,{propName})
 if group==nil then return nil end
 local found=nil
 pcall(function()
  group:ForEach(function(a,b)
   local key=a
   local state=b
   pcall(function() key=a:get() end)
   pcall(function() state=b:get() end)
   local keyText=(unwrap_string(key) or ""):lower()
   if state~=nil and keyText:find(wantedName:lower(),1,true) then
    local installed=direct_struct_field(state,PART_INSTALLED)
    local durability=tonumber(unwrap_string(direct_struct_field(state,PART_DURABILITY)))
    if installed==true or installed==1 then found=durability else found=0 end
   end
  end)
 end)
 return found
end

local function count_array_items(arr)
 if arr==nil then return 0 end
 local n=0
 pcall(function() arr:ForEach(function(_,_) n=n+1 end) end)
 return n
end

local function collect_readiness_summary(obj)
 local scores={}
 local sum=0
 local count=0
 for _,g in ipairs(READINESS_GROUPS) do
  local v=score_part_group(obj,g.prop)
  scores[g.key]=v
  if v~=nil then sum=sum+v; count=count+1 end
 end

 -- WBP_ScanRaport.CalculateConditionPercent calls GetScoreForParts.
 -- The current PAK shows GetScoreForParts is composed from these seven
 -- mechanical groups plus exhaust-hole score.  We mirror those direct
 -- inputs without invoking the Blueprint out-parameter function.
 local holes=count_exhaust_holes(obj)
 local holesScore=nil
 if holes~=nil then
  holesScore=(holes==0) and 1.0 or 0.0
  sum=sum+holesScore
  count=count+1
 end
 local condition=nil
 if count>0 then condition=sum/count end

 local windshield=read_windshield_state(obj)
 local tires=read_tire_pressures(obj)

 -- These two checklist rows existed but were never populated into cars_owned.json.
 local fuseSummary=collect_fuse_summary(obj)
 local fusesScore=nil
 if fuseSummary~=nil then fusesScore=fuseSummary.average end

 local batteryScore=score_named_part(obj,"ElectricParts","battery")

 local captured=count_array_items(safe_prop(obj,{"CapturedPoints"}))
 local capturedMax=number_value(safe_prop(obj,{"CapturedPointsMax"})) or 7
 local plateClean=safe_prop(obj,{"CarplateCleaned"})
 local photoStudio=safe_prop(obj,{"PhotoMadeByPhotoStudio"})

 return {
  condition=condition,brakes=scores.Brakes,suspension=scores.Suspension,
  exhaust=scores.Exhaust,clutch=scores.Clutch,engine=scores.Engine,
  radiator=scores.Radiator,electrical=scores.Electrical,
  fuses=fusesScore,battery=batteryScore,
  exhaustHoles=holes,windshield=windshield and windshield.durability or nil,
  tire1=tires[1],tire2=tires[2],tire3=tires[3],tire4=tires[4],
  photos=captured,photosMax=capturedMax,plateClean=(plateClean==true or plateClean==1),
  photoStudio=(photoStudio==true or photoStudio==1)
 }
end

local function normalize_car_id(v)
 local s=unwrap_string(v)
 if s==nil then return "" end
 s=tostring(s)
 s=s:gsub("^%s+",""):gsub("%s+$","")
 s=s:gsub("^['\"]+",""):gsub("['\"]+$","")
 s=s:gsub("%s+","")
 return string.lower(s)
end

local function read_underground_garage_car_ids(forceDiscovery)
 local ids={}
 local storageCount=0
 local keyCount=0
 local valueCarCount=0
 local keySamples={}
 local valueSamples={}

 local storages=PerfV73.garages(forceDiscovery==true)
 if not storages then return ids,storageCount,keyCount,valueCarCount,keySamples,valueSamples end

 for _,storage in ipairs(storages) do
  if storage and storage:IsValid() then
   storageCount=storageCount+1
   local stored=safe_prop(storage,{"StoredCars"})
   if stored~=nil then
    pcall(function()
     stored:ForEach(function(key,value)
      local rawKey=unwrap_string(key)
      local normKey=normalize_car_id(rawKey)
      if normKey~="" then
       ids[normKey]=true
       keyCount=keyCount+1
       if #keySamples<5 then table.insert(keySamples,rawKey) end
      end

      local obj=value
      pcall(function()
       local got=value:get()
       if got~=nil then obj=got end
      end)
      if obj and obj:IsValid() then
       local rawId=unwrap_string(safe_prop(obj,{"CarId","CarID","VehicleId","VehicleID"}))
       local normId=normalize_car_id(rawId)
       if normId~="" then
        ids[normId]=true
        valueCarCount=valueCarCount+1
        if #valueSamples<5 then table.insert(valueSamples,rawId) end
       end
      end
     end)
    end)
   end
  end
 end

 return ids,storageCount,keyCount,valueCarCount,keySamples,valueSamples
end

local function is_utility_vehicle_name(name)
 local n=string.lower(tostring(name or ""))
 return n=="transporter"
     or n=="e_max transporter"
     or n:find("e_max transporter",1,true)~=nil
     or n:find("tow truck",1,true)~=nil
end

PerfV76=PerfV76 or {}
function PerfV76.cars_stage(label,stageStarted,scanStarted)
 local now=os.clock()
 local stageMs=math.floor(((now-(stageStarted or now))*1000)+0.5)
 local totalMs=math.floor(((now-(scanStarted or now))*1000)+0.5)
 local line=os.date("%Y-%m-%d %H:%M:%S").." | cars-stage:"..tostring(label).." | "..tostring(stageMs).." ms | cumulative="..tostring(totalMs).." ms\n"
 local pf=io.open(performanceLogPath,"a"); if pf then pf:write(line); pf:close() end
 local df=io.open(diagnosticsRoot.."\\reader_performance.log","a"); if df then df:write(line); df:close() end
 log("CARS STAGE "..tostring(label).." = "..tostring(stageMs).." ms (cumulative "..tostring(totalMs).." ms)")
 return now
end

local function scan_cars_owned(fullDiscovery)
 local perfScanStarted=os.clock()
 local perfStageStarted=perfScanStarted
 if fullDiscovery then fitted_diag_reset() end
 -- Performance build: the recurring 3-minute pass does not rebuild every
 -- dealership/UI name map. GetVehicleDisplayName() is already the primary
 -- model-name source. Full discovery is retained for manual Scan Cars.
 if fullDiscovery then
  refresh_vehicle_name_maps()
 end
 perfStageStarted=PerfV76.cars_stage("name-maps",perfStageStarted,perfScanStarted)
 refresh_live_vehicle_trunks(fullDiscovery==true)
 perfStageStarted=PerfV76.cars_stage("live-trunks",perfStageStarted,perfScanStarted)
 local undergroundIds,garageStorageCount,garageKeyCount,garageValueCarCount,garageKeySamples,garageValueSamples=read_underground_garage_car_ids(fullDiscovery==true)
 perfStageStarted=PerfV76.cars_stage("garage-ids",perfStageStarted,perfScanStarted)

 local all=PerfV73.infos(fullDiscovery==true)
 perfStageStarted=PerfV76.cars_stage("vehicle-infos",perfStageStarted,perfScanStarted)
 if not all then
  write_json_atomic(carsJsonPath,'{"version":"0.35.1","connected":false,"cars":[]}')
  return
 end

 local cars={}
 local directNameCount=0
 -- Pass 10 identified trunk+readiness as the dominant remaining full-row
 -- bucket. Split those two existing calls without changing their behaviour so
 -- we can see whether trunk reads, readiness calculations, or both deserve the
 -- next optimisation. Instrumentation only: no Cars data, cache eligibility,
 -- UI, refresh cadence, Contracts, Personal Cars or hotkey focus behaviour changes.
 if PerfV78 then PerfV78.reusedThisScan=0; PerfV78.cachedThisScan=0 end
 if PerfV79 then PerfV79.reusedThisScan=0; PerfV79.cachedThisScan=0 end

 for _,obj in ipairs(all) do
  if obj and obj:IsValid() then
   local owned=safe_prop(obj,{"PlayerOwned","bPlayerOwned","IsPlayerOwned"})
   local isOwned=(owned==true or owned==1)

   if isOwned then
    local preset=safe_prop(obj,{"ModelPresetInfo"})
    local modelId=safe_prop(obj,{"ModelName"})

    if preset then
     local presetModel=get_preset_field(preset,{
      "Model",
      "Model_27_D8DD805745959006898DA39315144340"
     })
     if presetModel~=nil then modelId=presetModel end
    end

    local bodyId=nil
    if preset then
     bodyId=get_preset_field(preset,{
      "BodyType",
      "BodyType_33_C1A2909A402B1CE89175158B2E38F089"
     })
    end

    local carId=unwrap_string(safe_prop(obj,{"CarId","CarID","VehicleId","VehicleID"}))
    local normalizedCarId=normalize_car_id(carId)
    local inUnderground=(normalizedCarId~="" and undergroundIds[normalizedCarId]==true)
    local reusedForSale=(PerfV78 and PerfV78.try_reuse_for_sale(obj,carId,fullDiscovery)) or nil
    local reusedUnderground=nil
    if not reusedForSale then
     reusedUnderground=(PerfV79 and PerfV79.try_reuse_underground(obj,carId,inUnderground,fullDiscovery)) or nil
    end
    local reusedProcessed=reusedForSale or reusedUnderground
    if reusedProcessed then
     table.insert(cars,reusedProcessed)
    else
    local year=number_value(safe_prop(obj,{"ProductionYear","Year"}))
    local mileage=number_value(safe_prop(obj,{"CurrentMileage","Mileage"}))
    local buying=number_value(safe_prop(obj,{"BuyingPlayerPrice","BuyingMarketPrice","BuyingPrice","BuyPrice"}))
    local selling=number_value(safe_prop(obj,{"SellingPlayerPrice","SellingPrice","SellPrice"}))
    local modelDisplay=""
    local modelSource=""
    local infoPath=object_identity_path(obj)
    local fingerprint=vehicle_fingerprint_from_info(obj)

    -- v0.33 primary source:
    -- Ask the game itself for the full vehicle display name.
    -- v0.32.1 proved GetVehicleDisplayName(" "):ToString()
    -- succeeds for every owned VehicleInfoObject tested.
    local directName,directSource=get_direct_vehicle_display_name(obj)

    if directName~="" then
     modelDisplay=directName
     modelSource=directSource
    elseif carId~="" and carNameByCarId[carId] then
     modelDisplay=carNameByCarId[carId]
     modelSource=carNameSourceByCarId[carId] or "legacy CarId fallback"
    elseif fingerprint~="" and carNameByFingerprint[fingerprint] then
     modelDisplay=carNameByFingerprint[fingerprint]
     modelSource=carNameSourceByFingerprint[fingerprint] or "legacy fingerprint fallback"
    elseif infoPath~="" and carNameByInfoPath[infoPath] then
     modelDisplay=carNameByInfoPath[infoPath]
     modelSource=carNameSourceByInfoPath[infoPath] or "legacy info-object fallback"
    else
     modelDisplay=get_model_display(obj,preset,modelId)
     modelSource="fallback"
    end

    local bodyDisplay=get_body_display(bodyId)
    local bodyKey=clean_enum_value(bodyId)

    local trunkRows,trunkTotal,trunkPath=read_trunk(obj)
    local readiness=collect_readiness_summary(obj)

    -- v0.43.7.2: authoritative fitted-part path. Prefer the live vehicle's
    -- BP_CarPartAndVehicleComponent:GetAllCarParts() map so current PartID
    -- values (including Sport/Race variants) are preserved. Fall back to the
    -- VehicleInfoObject maps for stored/non-live cars.
    local installedParts={}
    local installedMap={}
    if carId~="" and activeLiveVehicleMap[carId] and activeLiveVehicleMap[carId].vehicle then
     installedMap=collect_live_car_parts(activeLiveVehicleMap[carId].vehicle, fullDiscovery and modelDisplay or nil)
    end
    if next(installedMap)==nil then installedMap=collect_part_details(obj) end
    if fullDiscovery then
     fitted_diag_write("CAR: "..tostring(modelDisplay).." | carId="..tostring(carId).." | live="..tostring(carId~="" and activeLiveVehicleMap[carId]~=nil).."\n")
     local wrote=false
     for dkey,dstate in pairs(installedMap) do
      wrote=true
      fitted_diag_write("  "..tostring(dkey).." | installed="..tostring(dstate and dstate.installed).." | partId="..tostring(dstate and dstate.partId or "").." | durability="..tostring(dstate and dstate.durability or "").."\n")
     end
     if not wrote then fitted_diag_write("  <NO FITTED PART MAP RETURNED>\n") end
     fitted_diag_write("\n")
    end
    for key,state in pairs(installedMap) do
     if state and state.installed then
      table.insert(installedParts,{key=key,partId=state.partId or "",durability=state.durability})
     end
    end
    table.sort(installedParts,function(a,b) return tostring(a.key or "")<tostring(b.key or "") end)

    local readinessTireSpec=get_tire_pressure_spec(bodyId)
    local isForSale,listingPrice,listingDaysLeft=sale_info_for_car(obj)
    local saleStatus=isForSale and "For Sale" or "Waiting"
    local colorEnum,colorR,colorG,colorB,colorA=read_color_details(obj)

    if modelSource=="GetVehicleDisplayName().ToString()" then
     directNameCount=directNameCount+1
    end

    local hasLiveVehicle=(carId~="" and activeLiveVehicleMap[carId]~=nil)
    local location=""
    local locationSource=""

    if inUnderground then
     location="Underground Garage"
     locationSource="StoredCars"
    elseif isForSale then
     location="For Sale - area unknown"
     locationSource="VehicleOffer"
    elseif hasLiveVehicle then
     location="Active World"
     locationSource="BP_VehicleBase"
    else
     location="Unknown - VehicleInfo only"
     locationSource="VehicleInfoOnly"
    end

    local isUtility=is_utility_vehicle_name(modelDisplay)

    -- v0.38.3.3: expose live fuel percentage on the Cars summary so the
    -- Ready Check can display it without requesting a separate detail scan.
    local fuelCurrent=nil
    local fuelMax=nil
    local fuelPercent=nil
    if hasLiveVehicle and activeLiveVehicleMap[carId] and activeLiveVehicleMap[carId].vehicle then
     local liveVehicle=activeLiveVehicleMap[carId].vehicle
     local rawFuel=safe_prop(liveVehicle,{"Fuel"})
     if rawFuel~=nil then fuelCurrent=number_value(rawFuel) end
    end
    if preset~=nil then
     local rawFuelMax=get_preset_field(preset,{
      "FuelTankCapacity",
      "FuelTankCapacity_46_975C065E4844E8DA82598AA39622D1B8"
     })
     if rawFuelMax~=nil then fuelMax=number_value(rawFuelMax) end
    end
    if fuelMax~=nil and fuelMax<=0 then fuelMax=nil end
    if fuelCurrent~=nil and fuelMax~=nil and fuelMax>0 then
     fuelPercent=(fuelCurrent/fuelMax)*100.0
    end

    -- A sold car can leave behind a still-valid VehicleInfoObject whose
    -- PlayerOwned flag has not yet been cleaned up by Unreal.  Once a car has
    -- no live actor, no garage membership and no active sale offer, it is no
    -- longer backed by any current owned-car source.  Do not carry that stale
    -- object into cars_owned.json.  This is the state that previously showed
    -- as location "-" until a full game restart.
    local isUnbackedOwned=(not inUnderground and not isForSale and not hasLiveVehicle)

    if not isUnbackedOwned then
    table.insert(cars,{
     carId=carId,
     model=modelDisplay,
     modelSource=modelSource,
     fingerprint=fingerprint,
     modelId=clean_enum_value(modelId),
     bodyType=bodyDisplay,
     bodyTypeId=bodyKey,
     location=location,
     locationSource=locationSource,
     normalizedCarId=normalizedCarId,
     inUndergroundGarage=inUnderground,
     hasLiveVehicle=hasLiveVehicle,
     hasSaleOffer=isForSale,
     isVehicleInfoOnly=(not inUnderground and not isForSale and not hasLiveVehicle),
      isWreckForSell=(safe_prop(obj,{"IsWreckForSell"})==true or safe_prop(obj,{"IsWreckForSell"})==1),
      isAbandonedWreck=(safe_prop(obj,{"IsAbandonedWreck"})==true or safe_prop(obj,{"IsAbandonedWreck"})==1),
      wasWreck=(safe_prop(obj,{"WasWreck"})==true or safe_prop(obj,{"WasWreck"})==1),
     isUtility=isUtility,
     year=year,
     mileage=mileage,
     buying=buying,
     selling=selling,
     saleStatus=saleStatus,
     isForSale=isForSale,
     listingPrice=listingPrice,
     listingDaysLeft=listingDaysLeft,
     trunk=trunkRows,
     trunkTotal=trunkTotal,
     trunkPath=trunkPath,
     installedParts=installedParts,
     buyingPlayerPrice=safe_vehicle_number(obj,"BuyingPlayerPrice"),
     buyingMarketPrice=safe_vehicle_number(obj,"BuyingMarketPrice"),
     sellingPlayerPrice=safe_vehicle_number(obj,"SellingPlayerPrice"),
     currentDirtValue=safe_vehicle_number(obj,"CurrentDirtValue"),
     currentRustValue=safe_vehicle_number(obj,"CurrentRustValue"),
     curWashValue=safe_vehicle_number(obj,"CurWashValue"),
     curPolishValue=safe_vehicle_number(obj,"CurPolishValue"),
     vehicleScoreCache=safe_vehicle_number(obj,"VehicleScoreCache"),
     mechanicalCondition=readiness.condition,
     scoreBrakes=readiness.brakes,
     scoreSuspension=readiness.suspension,
     scoreExhaust=readiness.exhaust,
     scoreClutch=readiness.clutch,
     scoreEngine=readiness.engine,
     scoreRadiator=readiness.radiator,
     scoreElectrical=readiness.electrical,
     readinessFuses=readiness.fuses,
     readinessBattery=readiness.battery,
     readinessExhaustHoles=readiness.exhaustHoles,
     readinessWindshield=readiness.windshield,
     readinessTire1=readiness.tire1,readinessTire2=readiness.tire2,
     readinessTire3=readiness.tire3,readinessTire4=readiness.tire4,
     readinessTireOpt=readinessTireSpec and readinessTireSpec.opt or nil,
     readinessPhotos=readiness.photos,readinessPhotosMax=readiness.photosMax,
     readinessPlateClean=readiness.plateClean,readinessPhotoStudio=readiness.photoStudio,
     buyingCarPartsScore=safe_vehicle_number(obj,"BuyingCarPartsScore"),
     gearboxType=safe_vehicle_text(obj,"GearboxType"),
     fuelType=safe_vehicle_text(obj,"FuelType"),
     color=(colorEnum~="" and colorEnum or safe_vehicle_color_name(obj)),
     colorR=colorR,
     colorG=colorG,
     colorB=colorB,
     colorA=colorA,
     fuelCurrent=fuelCurrent,
     fuelMax=fuelMax,
     fuelPercent=fuelPercent
    })
    if isForSale and carId~="" and PerfV78 then
     PerfV78.forSaleRows[carId]=cars[#cars]
     PerfV78.cachedThisScan=(PerfV78.cachedThisScan or 0)+1
    elseif carId~="" and PerfV78 then
     PerfV78.forSaleRows[carId]=nil
    end
    local undergroundReady=(inUnderground and (not isForSale) and (not isUtility)
      and readiness.condition~=nil and readiness.condition>=0.95
      and not (safe_prop(obj,{"IsWreckForSell"})==true or safe_prop(obj,{"IsWreckForSell"})==1)
      and not (safe_prop(obj,{"IsAbandonedWreck"})==true or safe_prop(obj,{"IsAbandonedWreck"})==1))
    if undergroundReady and carId~="" and PerfV79 then
     PerfV79.undergroundRows[carId]=cars[#cars]
     PerfV79.cachedThisScan=(PerfV79.cachedThisScan or 0)+1
    elseif carId~="" and PerfV79 then
     PerfV79.undergroundRows[carId]=nil
    end
    else
     log("Sold/stale owned VehicleInfo skipped: carId="..tostring(carId)..
         "; model="..tostring(modelDisplay)..
         "; no live actor, garage membership or sale offer")
    end
    end -- reused processed row / normal processing
   end
  end
 end
 perfStageStarted=PerfV76.cars_stage("process-owned-cars",perfStageStarted,perfScanStarted)
 if PerfV78 then
  log("Pass 8 for-sale processed cache: reused="..tostring(PerfV78.reusedThisScan or 0).."; freshly-cached="..tostring(PerfV78.cachedThisScan or 0))
 end
 if PerfV79 then
  log("Pass 9 underground Ready cache: reused="..tostring(PerfV79.reusedThisScan or 0).."; freshly-cached="..tostring(PerfV79.cachedThisScan or 0))
 end

 -- FindAllOf can expose duplicate/stale VehicleInfoObject instances for one
 -- saved car.  Keep one row per CarID before any dashboard/category counts.
 local uniqueCars={}
 local seenCarIds={}
 local duplicateOwnedCount=0
 for _,c in ipairs(cars) do
  local key=tostring(c.carId or "")
  if key~="" then
   if not seenCarIds[key] then
    seenCarIds[key]=true
    table.insert(uniqueCars,c)
   else
    duplicateOwnedCount=duplicateOwnedCount+1
   end
  else
   -- No stable ID: preserve the row rather than accidentally losing a car.
   table.insert(uniqueCars,c)
  end
 end
 cars=uniqueCars

 table.sort(cars,function(a,b)
  local ag=string.lower(a.bodyType or "")
  local bg=string.lower(b.bodyType or "")
  if ag==bg then
   local am=string.lower(a.model or "")
   local bm=string.lower(b.model or "")
   if am==bm then return (a.year or 0)<(b.year or 0) end
   return am<bm
  end
  return ag<bg
 end)
 perfStageStarted=PerfV76.cars_stage("dedupe-sort",perfStageStarted,perfScanStarted)

 local parts={}
 table.insert(parts,'{"version":"0.35.1","connected":true,"cars":[')

 for i,c in ipairs(cars) do
  if i>1 then table.insert(parts,",") end

  table.insert(parts,
   '{"carId":"'..esc(c.carId)..
   '","model":"'..esc(c.model)..
   '","modelSource":"'..esc(c.modelSource or "")..
   '","fingerprint":"'..esc(c.fingerprint or "")..
   '","modelId":"'..esc(c.modelId)..
   '","bodyType":"'..esc(c.bodyType)..
   '","bodyTypeId":"'..esc(c.bodyTypeId)..
   '","location":"'..esc(c.location or "")..
   '","locationSource":"'..esc(c.locationSource or "")..
   '","normalizedCarId":"'..esc(c.normalizedCarId or "")..
   '","inUndergroundGarage":'..tostring(c.inUndergroundGarage==true)..
   ',"hasLiveVehicle":'..tostring(c.hasLiveVehicle==true)..
   ',"hasSaleOffer":'..tostring(c.hasSaleOffer==true)..
   ',"isVehicleInfoOnly":'..tostring(c.isVehicleInfoOnly==true)..
    ',"isWreckForSell":'..tostring(c.isWreckForSell==true)..
    ',"isAbandonedWreck":'..tostring(c.isAbandonedWreck==true)..
    ',"wasWreck":'..tostring(c.wasWreck==true)..
   ',"isUtility":'..tostring(c.isUtility==true)..
   ',"year":'..tostring(math.floor(c.year or 0))..
   ',"mileage":'..tostring(c.mileage or 0)..
   ',"buyingPrice":'..tostring(c.buying or 0)..
   ',"sellingPrice":'..tostring(c.selling or 0)..
   ',"saleStatus":"'..esc(c.saleStatus or "Owned")..'"'..
   ',"isForSale":'..tostring(c.isForSale==true)..
   ',"listingPrice":'..json_number_or_null(c.listingPrice)..
   ',"listingDaysLeft":'..json_number_or_null(c.listingDaysLeft)..
   ',"trunkTotal":'..tostring(c.trunkTotal or 0)..
   ',"trunkPath":"'..esc(c.trunkPath or "")..'"'..
   ',"buyingPlayerPrice":'..tostring(c.buyingPlayerPrice or 0)..
   ',"buyingMarketPrice":'..tostring(c.buyingMarketPrice or 0)..
   ',"sellingPlayerPrice":'..tostring(c.sellingPlayerPrice or 0)..
   ',"currentDirtValue":'..tostring(c.currentDirtValue or 0)..
   ',"currentRustValue":'..tostring(c.currentRustValue or 0)..
   ',"curWashValue":'..tostring(c.curWashValue or 0)..
   ',"curPolishValue":'..tostring(c.curPolishValue or 0)..
   ',"vehicleScoreCache":'..tostring(c.vehicleScoreCache or 0)..
   ',"mechanicalCondition":'..json_number_or_null(c.mechanicalCondition)..
   ',"scoreBrakes":'..json_number_or_null(c.scoreBrakes)..
   ',"scoreSuspension":'..json_number_or_null(c.scoreSuspension)..
   ',"scoreExhaust":'..json_number_or_null(c.scoreExhaust)..
   ',"scoreClutch":'..json_number_or_null(c.scoreClutch)..
   ',"scoreEngine":'..json_number_or_null(c.scoreEngine)..
   ',"scoreRadiator":'..json_number_or_null(c.scoreRadiator)..
   ',"scoreElectrical":'..json_number_or_null(c.scoreElectrical)..
   ',"readinessFuses":'..json_number_or_null(c.readinessFuses)..
   ',"readinessBattery":'..json_number_or_null(c.readinessBattery)..
   ',"readinessExhaustHoles":'..json_number_or_null(c.readinessExhaustHoles)..
   ',"readinessWindshield":'..json_number_or_null(c.readinessWindshield)..
   ',"readinessTire1":'..json_number_or_null(c.readinessTire1)..
   ',"readinessTire2":'..json_number_or_null(c.readinessTire2)..
   ',"readinessTire3":'..json_number_or_null(c.readinessTire3)..
   ',"readinessTire4":'..json_number_or_null(c.readinessTire4)..
   ',"readinessTireOpt":'..json_number_or_null(c.readinessTireOpt)..
   ',"readinessPhotos":'..tostring(c.readinessPhotos or 0)..
   ',"readinessPhotosMax":'..tostring(c.readinessPhotosMax or 7)..
   ',"readinessPlateClean":'..tostring(c.readinessPlateClean==true)..
   ',"readinessPhotoStudio":'..tostring(c.readinessPhotoStudio==true)..
   ',"buyingCarPartsScore":'..tostring(c.buyingCarPartsScore or 0)..
   ',"gearboxType":"'..esc(c.gearboxType or "")..'"'..
   ',"fuelType":"'..esc(c.fuelType or "")..'"'..
   ',"fuelCurrent":'..json_number_or_null(c.fuelCurrent)..
   ',"fuelMax":'..json_number_or_null(c.fuelMax)..
   ',"fuelPercent":'..json_number_or_null(c.fuelPercent)..
   ',"color":"'..esc(c.color or "")..'"'..
   ',"colorR":'..json_number_or_null(c.colorR)..
   ',"colorG":'..json_number_or_null(c.colorG)..
   ',"colorB":'..json_number_or_null(c.colorB)..
   ',"colorA":'..json_number_or_null(c.colorA)..
   ',"trunk":[')

  for j,t in ipairs(c.trunk) do
   if j>1 then table.insert(parts,",") end
   table.insert(parts,
    '{"name":"'..esc(t.name)..
    '","qty":'..tostring(t.qty or 0)..
    ',"durability":'..tostring(t.durability or 0)..'}')
  end

  table.insert(parts,'],"installedParts":[')
  for j,p in ipairs(c.installedParts or {}) do
   if j>1 then table.insert(parts,",") end
   table.insert(parts,
    '{"key":"'..esc(p.key or "")..
    '","partId":"'..esc(p.partId or "")..
    '","durability":'..json_number_or_null(p.durability)..'}')
  end
  table.insert(parts,']}')
 end

 table.insert(parts,']}')
 perfStageStarted=PerfV76.cars_stage("json-build",perfStageStarted,perfScanStarted)
 write_json_atomic(carsJsonPath,table.concat(parts))
 perfStageStarted=PerfV76.cars_stage("json-write",perfStageStarted,perfScanStarted)
 queue_runtime_car_photos(cars)
 perfStageStarted=PerfV76.cars_stage("photo-queue",perfStageStarted,perfScanStarted)

 if fullDiscovery or refreshSettings.debug_enabled then
  log("Garage ID diagnostic: storages="..tostring(garageStorageCount)..
     "; keys="..tostring(garageKeyCount)..
     "; value car IDs="..tostring(garageValueCarCount)..
     "; key samples="..table.concat(garageKeySamples or {},", ")..
     "; value samples="..table.concat(garageValueSamples or {},", "))
  for _,c in ipairs(cars) do
   if not c.isUtility and not c.isForSale and ((c.mechanicalCondition or -1)<0.95) then
    log("Car diagnostic: model="..tostring(c.model)..
        "; year="..tostring(c.year)..
        "; carId="..tostring(c.carId)..
        "; normalized="..tostring(c.normalizedCarId)..
        "; underground="..tostring(c.inUndergroundGarage)..
        "; live="..tostring(c.hasLiveVehicle)..
        "; sale="..tostring(c.hasSaleOffer)..
        "; infoOnly="..tostring(c.isVehicleInfoOnly)..
        "; location="..tostring(c.location)..
        "; source="..tostring(c.locationSource))
   end
  end
 end

 perfStageStarted=PerfV76.cars_stage("diagnostics",perfStageStarted,perfScanStarted)
 log("Cars owned scan complete: "..tostring(#cars)..
     " unique owned vehicles; duplicates skipped="..tostring(duplicateOwnedCount)..
     "; live vehicles="..tostring(activeTrunkStats.live or 0)..
     "; vehicle IDs="..tostring(activeTrunkStats.withId or 0)..
     "; containers="..tostring(activeTrunkStats.containers or 0)..
     "; attached trunks="..tostring(activeTrunkStats.attached or 0)..
     "; nonempty trunks="..tostring(activeTrunkStats.nonempty or 0)..
     "; vehicle-path-name map="..tostring((function()
       local n=0 for _ in pairs(carNameByVehiclePath) do n=n+1 end return n end)())..
     "; fingerprint-name map="..tostring((function()
       local n=0 for _ in pairs(carNameByFingerprint) do n=n+1 end return n end)())..
     "; fingerprint collisions="..tostring((function()
       local n=0 for _ in pairs(carFingerprintCollisions) do n=n+1 end return n end)())..
     "; info-name map="..tostring((function()
       local n=0 for _ in pairs(carNameByInfoPath) do n=n+1 end return n end)())..
     "; id-name map="..tostring((function()
       local n=0 for _ in pairs(carNameByCarId) do n=n+1 end return n end)())..
     "; model map="..tostring((function()
       local n=0 for _ in pairs(modelNameMap) do n=n+1 end return n end)())..
     "; body map="..tostring((function()
       local n=0 for _ in pairs(bodyNameMap) do n=n+1 end return n end)()))
end


local function diag_vector_xyz(v)
 if v==nil then return nil,nil,nil end
 local x,y,z=nil,nil,nil
 pcall(function() x=number_value(v.X) end)
 pcall(function() y=number_value(v.Y) end)
 pcall(function() z=number_value(v.Z) end)
 if x==nil then pcall(function() x=number_value(safe_prop(v,{"X"})) end) end
 if y==nil then pcall(function() y=number_value(safe_prop(v,{"Y"})) end) end
 if z==nil then pcall(function() z=number_value(safe_prop(v,{"Z"})) end) end
 return x,y,z
end

local function scan_distance_diagnostic()
 local officeResolved=false
 local gx,gy,gz=nil,nil,nil
 local gameModes=FindAllOf("BP_GameMode_C")
 if gameModes then
  for _,gm in ipairs(gameModes) do
   if gm and gm:IsValid() then
    local ok,loc=pcall(function() return gm:GetGarageLocation() end)
    if ok and loc~=nil then
     gx,gy,gz=diag_vector_xyz(loc)
     if gx~=nil and gy~=nil and gz~=nil then
      officeResolved=true
      break
     end
    end
   end
  end
 end

 local rows={}
 local liveCount=0
 local positionedCount=0
 for carId,live in pairs(activeLiveVehicleMap or {}) do
  if carId~=nil and carId~="" and live~=nil and live.vehicle~=nil then
   liveCount=liveCount+1
   local x,y,z=nil,nil,nil
   local ok,loc=pcall(function() return live.vehicle:K2_GetActorLocation() end)
   if ok and loc~=nil then x,y,z=diag_vector_xyz(loc) end
   if x~=nil and y~=nil and z~=nil then
    positionedCount=positionedCount+1
    local miles=nil
    if officeResolved then
     local dx=x-gx
     local dy=y-gy
     local dz=z-gz
     miles=math.sqrt(dx*dx+dy*dy+dz*dz)/160934.4
    end
    table.insert(rows,{carId=tostring(carId),x=x,y=y,z=z,miles=miles})
   end
  end
 end

 local chunks={'{"version":"0.38.0.3"'}
 table.insert(chunks,',"officeResolved":'..tostring(officeResolved))
 table.insert(chunks,',"officeX":'..json_number_or_null(gx))
 table.insert(chunks,',"officeY":'..json_number_or_null(gy))
 table.insert(chunks,',"officeZ":'..json_number_or_null(gz))
 table.insert(chunks,',"liveVehicles":'..tostring(liveCount))
 table.insert(chunks,',"positionedVehicles":'..tostring(positionedCount))
 table.insert(chunks,',"rows":[')
 for i,row in ipairs(rows) do
  if i>1 then table.insert(chunks,",") end
  table.insert(chunks,
   '{"carId":"'..esc(row.carId)..
   '","x":'..json_number_or_null(row.x)..
   ',"y":'..json_number_or_null(row.y)..
   ',"z":'..json_number_or_null(row.z)..
   ',"miles":'..json_number_or_null(row.miles)..'}')
 end
 table.insert(chunks,"]}")
 write_json_atomic(distanceDiagnosticPath,table.concat(chunks))
 log("Distance diagnostic: office="..tostring(officeResolved)..
     "; live="..tostring(liveCount)..
     "; positioned="..tostring(positionedCount))
end

local function run_distance_diagnostic_checked(reason)
 local ok,err=pcall(scan_distance_diagnostic)
 if not ok then
  log("ERROR: Distance diagnostic failed ["..tostring(reason or "unknown").."]: "..tostring(err))
 end
 return ok
end

local function scan_player_spawn_diagnostic()
 local spawns=FindAllOf("BP_PlayerSpawn_C")
 local rows={}
 local count=0
 local positioned=0

 if spawns then
  for _,spawn in ipairs(spawns) do
   if spawn and spawn:IsValid() then
    count=count+1

    local id=""
    pcall(function()
     local raw=safe_prop(spawn,{"ID"})
     if raw~=nil then id=tostring(raw) end
    end)

    local x,y,z=nil,nil,nil
    local okLoc,loc=pcall(function() return spawn:K2_GetActorLocation() end)
    if okLoc and loc~=nil then
     x,y,z=diag_vector_xyz(loc)
    end
    if x~=nil and y~=nil and z~=nil then
     positioned=positioned+1
    end

    local objectName=""
    pcall(function() objectName=tostring(spawn:GetFullName()) end)
    if objectName=="" then
     pcall(function() objectName=tostring(spawn:GetName()) end)
    end

    table.insert(rows,{
     id=id,
     objectName=objectName,
     x=x,y=y,z=z
    })
   end
  end
 end

 local chunks={'{"version":"0.38.0.4"'}
 table.insert(chunks,',"spawnCount":'..tostring(count))
 table.insert(chunks,',"positionedCount":'..tostring(positioned))
 table.insert(chunks,',"rows":[')

 for i,row in ipairs(rows) do
  if i>1 then table.insert(chunks,",") end
  table.insert(chunks,
   '{"id":"'..esc(row.id)..
   '","objectName":"'..esc(row.objectName)..
   '","x":'..json_number_or_null(row.x)..
   ',"y":'..json_number_or_null(row.y)..
   ',"z":'..json_number_or_null(row.z)..'}')
 end

 table.insert(chunks,"]}")
 write_json_atomic(playerSpawnDiagnosticPath,table.concat(chunks))
 log("PlayerSpawn diagnostic: spawns="..tostring(count)..
     "; positioned="..tostring(positioned))
end

local function run_player_spawn_diagnostic_checked(reason)
 local ok,err=pcall(scan_player_spawn_diagnostic)
 if not ok then
  log("ERROR: PlayerSpawn diagnostic failed ["..tostring(reason or "unknown").."]: "..tostring(err))
 end
 return ok
end

local function scan_safe_car_distances()
 -- FModel + live diagnostic showed GetGarageLocation ultimately uses a
 -- BP_PlayerSpawn_C actor, and there is exactly one live PlayerSpawn.
 -- Use that actor directly and mirror the game's Vector_Distance2D logic.
 local spawns=FindAllOf("BP_PlayerSpawn_C")
 local office=nil
 if spawns then
  for _,spawn in ipairs(spawns) do
   if spawn and spawn:IsValid() then
    office=spawn
    break
   end
  end
 end

 if office==nil then
  write_json_atomic(carsDistancePath,'{"version":"0.38.0.5","officeResolved":false,"distances":{}}')
  log("Safe distance: no BP_PlayerSpawn_C found.")
  return
 end

 local okOffice,officeLoc=pcall(function() return office:K2_GetActorLocation() end)
 if not okOffice or officeLoc==nil then
  write_json_atomic(carsDistancePath,'{"version":"0.38.0.5","officeResolved":false,"distances":{}}')
  log("Safe distance: PlayerSpawn location unavailable.")
  return
 end

 local ox,oy,oz=diag_vector_xyz(officeLoc)
 if ox==nil or oy==nil then
  write_json_atomic(carsDistancePath,'{"version":"0.38.0.5","officeResolved":false,"distances":{}}')
  log("Safe distance: PlayerSpawn vector invalid.")
  return
 end

 local rows={}
 local count=0
 for carId,live in pairs(activeLiveVehicleMap or {}) do
  if carId~=nil and carId~="" and live~=nil and live.vehicle~=nil then
   local okLoc,loc=pcall(function() return live.vehicle:K2_GetActorLocation() end)
   if okLoc and loc~=nil then
    local x,y,z=diag_vector_xyz(loc)
    if x~=nil and y~=nil then
     local dx=x-ox
     local dy=y-oy
     local cm=math.sqrt(dx*dx+dy*dy)
     local meters=cm/100.0
     rows[tostring(carId)]=meters
     count=count+1
    end
   end
  end
 end

 local chunks={'{"version":"0.38.0.5","officeResolved":true'}
 table.insert(chunks,',"officeX":'..json_number_or_null(ox))
 table.insert(chunks,',"officeY":'..json_number_or_null(oy))
 table.insert(chunks,',"officeZ":'..json_number_or_null(oz))
 table.insert(chunks,',"distanceMode":"2D","units":"m"')
 table.insert(chunks,',"distances":{')
 local first=true
 for carId,meters in pairs(rows) do
  if not first then table.insert(chunks,",") end
  first=false
  table.insert(chunks,'"'..esc(carId)..'":'..json_number_or_null(meters))
 end
 table.insert(chunks,"}}")
 write_json_atomic(carsDistancePath,table.concat(chunks))
 log("Safe distance: office resolved from PlayerSpawn; vehicles="..tostring(count))
end

local function run_safe_car_distances_checked(reason)
 local ok,err=pcall(scan_safe_car_distances)
 if not ok then
  log("ERROR: Safe distance failed ["..tostring(reason or "unknown").."]: "..tostring(err))
 end
 return ok
end

local function run_cars_scan_checked(reason,fullDiscovery)
 local ok,err=pcall(function() return scan_cars_owned(fullDiscovery==true) end)
 if not ok then
  log("ERROR: Cars owned scan failed ["..tostring(reason or "unknown").."]: "..tostring(err))
 end
 return ok
end

local function consume_cars_refresh_request()
 local f=io.open(carsRefreshRequestPath,"r")
 if not f then return false end
 local reason=f:read("*a") or "manual"
 f:close()
 os.remove(carsRefreshRequestPath)
 if reason=="" then reason="manual" end
 log("Cars refresh requested: "..tostring(reason))
 return true
end




local function get_cached_runtime_object(className,cached,preferText)
 if cached and cached:IsValid() then return cached end
 local all=FindAllOf(className)
 if not all then return nil end
 local fallback=nil
 for _,obj in ipairs(all) do
  if obj and obj:IsValid() then
   local full=""
   pcall(function() full=obj:GetFullName() end)
   if not full:find("Default__",1,true) and not full:find("GEN_VARIABLE",1,true) then
    if fallback==nil then fallback=obj end
    if preferText and full:find(preferText,1,true) then return obj end
   end
  end
 end
 return fallback
end

local function get_wholesale_subsystem(allowDiscovery)
 if cachedWholesaleSubsystem and cachedWholesaleSubsystem:IsValid() then return cachedWholesaleSubsystem end
 if allowDiscovery==false then return nil end
 cachedWholesaleSubsystem=get_cached_runtime_object("BPS_Wholesale_Subsystem_C",cachedWholesaleSubsystem,"BP_CDSGameInstance_C")
 return cachedWholesaleSubsystem
end

local function get_pawnshop_subsystem(allowDiscovery)
 if cachedPawnShopSubsystem and cachedPawnShopSubsystem:IsValid() then return cachedPawnShopSubsystem end
 if allowDiscovery==false then return nil end
 cachedPawnShopSubsystem=get_cached_runtime_object("BPS_PawnShop_Subsystem_C",cachedPawnShopSubsystem,"BP_CDSGameInstance_C")
 return cachedPawnShopSubsystem
end
local function get_world_event_handler(allowDiscovery)
 if cachedEventHandler and cachedEventHandler:IsValid() then return cachedEventHandler end
 if allowDiscovery==false then return nil end
 cachedEventHandler=nil
 local pcs=FindAllOf("BP_PlayerController_C")
 if not pcs then return nil end
 for _,pc in ipairs(pcs) do
  if pc and pc:IsValid() then
   local full=""
   pcall(function() full=pc:GetFullName() end)
   if full:find("WorldMap.WorldMap:PersistentLevel",1,true) then
    local eh=safe_prop(pc,{"EventHandlerComponent"})
    if eh and eh:IsValid() then cachedEventHandler=eh; return eh end
   end
  end
 end
 return nil
end

local function json_bool_or_null(v)
 if v==nil then return "null" end
 return tostring(v==true or v==1)
end

local function get_object_full_name(obj)
 if obj==nil then return "" end
 local s=""
 pcall(function() s=obj:GetFullName() end)
 return s or ""
end

local function get_cached_economy_system()
 if cachedEconomySystem and cachedEconomySystem:IsValid() then
  return cachedEconomySystem
 end

 cachedEconomySystem=nil
 local systems=FindAllOf("BP_EconomySystem_C")
 if not systems or #systems==0 then return nil end

 for _,obj in ipairs(systems) do
  if obj and obj:IsValid() then
   cachedEconomySystem=obj
   return obj
  end
 end
 return nil
end


local function get_cached_clock_widget()
 if cachedClockWidget and cachedClockWidget:IsValid() then
  return cachedClockWidget
 end

 cachedClockWidget=nil
 local widgets=FindAllOf("WBP_ClockWidget_C")
 if not widgets or #widgets==0 then return nil end

 for _,obj in ipairs(widgets) do
  if obj and obj:IsValid() then
   local okName,fullName=pcall(function() return obj:GetFullName() end)
   if okName and fullName and not fullName:find("Default__",1,true) then
    cachedClockWidget=obj
    return obj
   end
  end
 end
 return nil
end

local function datetime_ticks(value)
 if value==nil then return nil end
 local ticks=nil

 -- Direct struct field.
 pcall(function() ticks=number_value(value.Ticks) end)
 if ticks~=nil then return ticks end

 -- UE4SS property accessor.
 ticks=number_value(safe_prop(value,{"Ticks","ticks"}))
 if ticks~=nil then return ticks end

 -- Some wrappers require get() before struct members are visible.
 local unwrapped=nil
 pcall(function() unwrapped=value:get() end)
 if unwrapped~=nil and unwrapped~=value then
  pcall(function() ticks=number_value(unwrapped.Ticks) end)
  if ticks~=nil then return ticks end
  ticks=number_value(safe_prop(unwrapped,{"Ticks","ticks"}))
  if ticks~=nil then return ticks end
 end

 -- FS_GameTime-style nested Time.
 local timePart=safe_prop(value,{"Time"})
 if timePart~=nil then
  pcall(function() ticks=number_value(timePart.Ticks) end)
  if ticks~=nil then return ticks end
  ticks=number_value(safe_prop(timePart,{"Ticks","ticks"}))
  if ticks~=nil then return ticks end
 end

 return nil
end

local function format_game_datetime_time(value)
 if value==nil then return nil end
 local clock=get_cached_clock_widget()
 if clock==nil then return nil end
 local holder={}
 local ok=pcall(function() clock:GetTimeString(value,holder) end)
 if not ok then return nil end
 local raw=holder.String
 if raw==nil then raw=safe_prop(holder,{"String","Value","Text","Data"}) end
 local text=unwrap_string(raw)
 if text=="" or text=="nil" or text:find("TrivialObject",1,true) then return nil end
 return text
end

local function remaining_seconds_to(endDate)
 local econ=get_cached_economy_system()
 if econ==nil or endDate==nil then return nil end
 local nowTicks=datetime_ticks(safe_prop(econ,{"GameDateTime"}))
 local endTicks=datetime_ticks(endDate)
 if nowTicks~=nil and endTicks~=nil then
  return math.max(0,(endTicks-nowTicks)/10000000)
 end
 return nil
end

local function get_game_time_string(econ)
 if econ==nil then return nil end
 local gameDateTime=safe_prop(econ,{"GameDateTime"})
 if gameDateTime==nil then return nil end

 local clock=get_cached_clock_widget()
 if clock==nil then return nil end

 local holder={}
 local ok=pcall(function()
  clock:GetTimeString(gameDateTime,holder)
 end)
 if not ok then return nil end

 local raw=holder.String
 if raw==nil then raw=safe_prop(holder,{"String","Value","Text","Data"}) end
 local text=unwrap_string(raw)
 if text=="" or text=="nil" or text:find("TrivialObject",1,true) then return nil end
 return text
end

local function append_wholesale_contract(chunks,key,contract,requirementsContract)
 if contract==nil then
  table.insert(chunks,',"'..key..'":null')
  return
 end

 local reqOwner=requirementsContract or contract
 local reqs=safe_prop(reqOwner,{"OrderArray","OrderArray_17_A62EA3764F532CED8DA92082FF294016"})
 local minBody=number_value(safe_prop(contract,{"MinBodyCondition","MinBodyCondition_49_FA5519204A32DBAEBFDD7196EFAD798B"}))
 local minMech=number_value(safe_prop(contract,{"MinMechCondition","MinMechCondition_50_15F31B784A0DEB8ACF9637B188AC61E5"}))
 local rewardBonus=number_value(safe_prop(contract,{"RewardBonus","RewardBonus_21_A10BDD574ADD5855C5128D9D1FA862A0"}))
 local earlyBonus=number_value(safe_prop(contract,{"EarlyDeliveryBonus","EarlyDeliveryBonus_53_FE22E4BC4C3EB2B4CF7C6799B06CAFFD"}))
 local overall=number_value(safe_prop(contract,{"OverallMoneyReward","OverallMoneyReward_25_B4B46B0E4DF9B7F97BA62084F47FA7F6"}))
 local needsDlc=safe_prop(contract,{"bRequiresSpecificDLCPart","bRequiresSpecificDLCPart_55_28EA616448E5D24C54C4A7A6F98582BF"})
 local statusRaw=unwrap_string(safe_prop(contract,{"OrderStatus_19_9B18E5F044432E9FF1269B833988C0EE","OrderStatus"}))
 local endDate=safe_prop(contract,{"EndDate","EndDate_37_F6DDC9C041EE8E3E48108F905D78D7A0"})
 local endTime=format_game_datetime_time(endDate)
 local remainingSeconds=remaining_seconds_to(endDate)
 local currentDay=nil
 local estimatedEndDay=nil
 local econ=get_cached_economy_system()
 if econ~=nil then currentDay=number_value(safe_prop(econ,{"DayCounter"})) end
 if currentDay~=nil and remainingSeconds~=nil then
  -- EndDate/remainingSeconds are in GAME time. Keep this entirely in the
  -- simulator's clock domain; do not compare to Windows/real-world time.
  estimatedEndDay=currentDay+math.floor(remainingSeconds/86400)
 end

 table.insert(chunks,',"'..key..'":{'..
  '"statusRaw":"'..esc(statusRaw)..'",'..
  '"endTime":'..(endTime and ('"'..esc(endTime)..'"') or 'null')..
  ',"remainingSeconds":'..json_number_or_null(remainingSeconds)..
  ',"estimatedEndDay":'..json_number_or_null(estimatedEndDay)..
  ',"minBodyCondition":'..json_number_or_null(minBody)..
  ',"minMechCondition":'..json_number_or_null(minMech)..
  ',"rewardBonus":'..json_number_or_null(rewardBonus)..
  ',"earlyDeliveryBonus":'..json_number_or_null(earlyBonus)..
  ',"overallMoneyReward":'..json_number_or_null(overall)..
  ',"requiresDLCPart":'..json_bool_or_null(needsDlc)..
  ',"requirements":[')

 local first=true
 array_each(reqs,function(r)
  if r==nil then return end
  local vehicleType=safe_prop(r,{"VehicleType","VehicleType_8_A62EA3764F532CED8DA92082FF294016"})
  local requiredColor=safe_prop(r,{"RequiredColor","RequiredColor_10_9B18E5F044432E9FF1269B833988C0EE"})
  local rMinBody=number_value(safe_prop(r,{"MinBodyCondition","MinBodyCondition_12_F6DDC9C041EE8E3E48108F905D78D7A0"}))
  local rMinMech=number_value(safe_prop(r,{"MinMechCondition","MinMechCondition_14_A10BDD574ADD5855C5128D9D1FA862A0"}))
  local idx=number_value(safe_prop(r,{"CarOrderIndex","CarOrderIndex_20_E58980E64055BCD2AA16C9B5CB9C17C7"}))
  local assigned=safe_prop(r,{"IsCarAssigned","IsCarAssigned_23_5E3D726E4FA2E24A8F144396B12693F6"})
  local reqBrand=safe_prop(r,{"bRequiresSpecificBrand","bRequiresSpecificBrand_36_E1F83F2A4740165CCC2659A2154ED74B"})
  local brand=safe_prop(r,{"RequiredCarBrand","RequiredCarBrand_38_15B25FA2401FC9D8662322837A775C20"})

  -- Ignore unused/default FS_VehicleRequirement_Wholesale array slots.
  local isDefaultSlot=(
   rMinBody==0 and
   rMinMech==0 and
   (idx==nil or idx==0)
  )
  if isDefaultSlot then return end

  if not first then table.insert(chunks,",") end
  first=false
  table.insert(chunks,'{'..
   '"vehicleTypeRaw":"'..esc(unwrap_string(vehicleType))..'"'..
   ',"bodyType":"'..esc(get_body_display(vehicleType))..'"'..
   ',"requiredColorRaw":"'..esc(unwrap_string(requiredColor))..'"'..
   ',"minBodyCondition":'..json_number_or_null(rMinBody)..
   ',"minMechCondition":'..json_number_or_null(rMinMech)..
   ',"carOrderIndex":'..json_number_or_null(idx)..
   ',"isCarAssigned":'..json_bool_or_null(assigned)..
   ',"requiresBrand":'..json_bool_or_null(reqBrand)..
   ',"requiredBrandRaw":"'..esc(unwrap_string(brand))..'"}')
 end)
 table.insert(chunks,']}')
end



PawnDeal=PawnDeal or {lastProbeDay=nil,lastRefreshDay=nil,detected=false}

function PawnDeal.scan(pawn,forceProbe)
 -- Keep the last proven daily-content day through background refreshes.
 -- Tony/Pawn itself remains manual-snapshot only.
 local result={detected=PawnDeal.detected,lastRefreshDay=PawnDeal.lastRefreshDay}
 if pawn~=nil then
  local liveRefreshDay=number_value(safe_prop(pawn,{"LastDailyContentRefreshDay"}))
  if liveRefreshDay~=nil then result.lastRefreshDay=liveRefreshDay end
 end

 if result.lastRefreshDay~=nil then
  if PawnDeal.lastRefreshDay==nil then
   PawnDeal.lastRefreshDay=result.lastRefreshDay
  elseif result.lastRefreshDay~=PawnDeal.lastRefreshDay then
   PawnDeal.lastRefreshDay=result.lastRefreshDay
   PawnDeal.lastProbeDay=nil
   PawnDeal.detected=false
   result.detected=false
  end
 end

 -- Manual FULL SCAN only: no background FindAllOf hitch during play.
 -- Keep this helper independent of later local declarations so Contracts
 -- serialization cannot abort before contracts.json is written.
 local shouldProbe=(forceProbe==true)
 if not shouldProbe then return result end

 -- SAFE narrow class-only presence probe. Never scan global TextBlock objects.
 local widgets=FindAllOf("WBP_BuyDailyDeal_C")
 local found=false
 if widgets then
  for _,w in ipairs(widgets) do
   if w and w:IsValid() then found=true break end
  end
 end

 -- The BuyDailyDeal widget is created only when that screen is opened, so widget
 -- absence cannot mean "no deal". A successful manual Pawn snapshot proves the
 -- daily-content system is live; use that as the safe availability fallback.
 -- This avoids any new Blueprint calls or global UI/TextBlock reads.
 if not found and pawn~=nil then found=true end

 PawnDeal.detected=found
 result.detected=found
 return result
end

local function scan_contracts(forceDiscovery,cachedOnly)
 if forceDiscovery==true then
  cachedPawnShopSubsystem=nil
  cachedPawnRequestsJson=nil
 end
 local chunks={}
 table.insert(chunks,'{"version":"0.44.0.64","connected":true')

 local wholesale=get_wholesale_subsystem(cachedOnly~=true)
 if wholesale~=nil then
  -- v0.44.0.64 screenshot-verified UI mapping. The game's internal property
  -- names are counter-intuitive: Current Order Wholesale is the payload shown
  -- on the B2B CONTRACTS screen, while CurrentB2BContract is the payload shown
  -- on the DEALER CONTRACTS screen. Keep them separate and map by proven UI.
  local b2bUiSource=safe_prop(wholesale,{"Current Order Wholesale","CurrentOrderWholesale"})
  local dealerUiSource=safe_prop(wholesale,{"CurrentB2BContract"})
  append_wholesale_contract(chunks,"b2b",b2bUiSource)
  append_wholesale_contract(chunks,"dealerContract",dealerUiSource)
 else
  table.insert(chunks,',"b2b":null')
  table.insert(chunks,',"dealerContract":null')
 end

 local pawnChunks={}
 -- v0.44.0.59: Tony/Pawn remains MANUAL snapshot only; restore proven wholesale status/filter.
 -- Background contract refreshes reuse the last safe snapshot and never touch
 -- the live Pawn Shop subsystem while it may be changing state.
 local pawn=nil
 if forceDiscovery==true then
  pawn=get_pawnshop_subsystem(true)
 end
 local firstPawn=true
 if pawn~=nil then
  cachedTonyReputation=number_value(safe_prop(pawn,{"ReputationExp"}))
  local requests=safe_prop(pawn,{"CurrentRequests"})
  local pawnCount=0
  array_each(requests,function(_) pawnCount=pawnCount+1 end)
  if pawnCount==0 then
   log("Contracts Pawn: live subsystem found but CurrentRequests count=0")
  else
   log("Contracts Pawn: CurrentRequests count="..tostring(pawnCount))
  end
  array_each(requests,function(req)
   if req==nil then return end

   local status=unwrap_string(safe_prop(req,{"RequestStatus","RequestStatus_36_695EC3884F7A00A84ECE6695E9DD15DE"}))

   -- Keep every entry in CurrentRequests, including Completed/Failed.
   -- The game keeps those current slots visible until their next refresh.
   if not firstPawn then table.insert(pawnChunks,",") end
   firstPawn=false
   local name=unwrap_string(safe_prop(req,{"RequestName","RequestName_3_5B061BC0420B6B1B71166CB1E7F929EB"}))
   local desc=unwrap_string(safe_prop(req,{"RequestDescription","RequestDescription_33_FA72DF87466E81576654CDB3771E0CF9"}))
   local typ=unwrap_string(safe_prop(req,{"RequestType","RequestType_6_16F5B24F414996F541E8F89E9BF91907"}))
   local difficulty=unwrap_string(safe_prop(req,{"Difficulty","Difficulty_9_36BDA00748732460EF9E668E803F6EBB"}))
   local rewardRep=number_value(safe_prop(req,{"RewardReputation","RewardReputation_21_7271030640B86115080736BD69CAB35F"}))
   local rewardMoney=unwrap_string(safe_prop(req,{"RewardMoney","RewardMoney_41_99E445BF4735988365C15496DA3850E6"}))
   local conditions=safe_prop(req,{"Conditions","Conditions_13_76E6EE4A46245B418122CCB2AF88370C"})

   local startDate=safe_prop(req,{"StartDate"})
   local endDate=safe_prop(req,{"EndDate"})
   local startTicks=datetime_ticks(startDate)
   local endTicks=datetime_ticks(endDate)

   local secondsUntilRefresh=remaining_seconds_to(endDate)

   if secondsUntilRefresh==nil then
    local econ=get_cached_economy_system()
    if econ~=nil and pawn~=nil then
     local currentDay=number_value(safe_prop(econ,{"DayCounter"}))
     local lastRefreshDay=number_value(safe_prop(pawn,{"LastRequestRefreshDay"}))
     local refreshDays=number_value(safe_prop(pawn,{"RefreshRequestIntervalDays"}))
     local currentTime=get_game_time_string(econ)
     local endTimeText=format_game_datetime_time(endDate)

     local function hhmm_seconds(text)
      if text==nil then return nil end
      local h,m=tostring(text):match("(%d+):(%d+)")
      h=tonumber(h);m=tonumber(m)
      if h==nil or m==nil then return nil end
      return h*3600+m*60
     end

     if currentDay~=nil and lastRefreshDay~=nil and refreshDays~=nil then
      local targetDay=lastRefreshDay+refreshDays
      local nowSec=hhmm_seconds(currentTime) or 0
      local endSec=hhmm_seconds(endTimeText) or 0
      secondsUntilRefresh=math.max(0,((targetDay-currentDay)*86400)+(endSec-nowSec))
     end
    end
   end

   table.insert(pawnChunks,'{'..
    '"requestName":"'..esc(name)..'"'..
    ',"description":"'..esc(desc)..'"'..
    ',"typeRaw":"'..esc(typ)..'"'..
    ',"difficultyRaw":"'..esc(difficulty)..'"'..
    ',"statusRaw":"'..esc(status)..'"'..
    ',"startDateTicks":'..json_number_or_null(startTicks)..
    ',"endDateTicks":'..json_number_or_null(endTicks)..
    ',"secondsUntilRefresh":'..json_number_or_null(secondsUntilRefresh)..
    ',"rewardReputation":'..json_number_or_null(rewardRep)..
    ',"rewardMoney":"'..esc(rewardMoney)..'"'..
    ',"conditions":[')

   local firstCond=true
   array_each(conditions,function(c)
    if c==nil then return end
    if not firstCond then table.insert(pawnChunks,",") end
    firstCond=false
    table.insert(pawnChunks,'{'..
     '"className":"'..esc(get_object_full_name(c))..'"'..
     ',"conditionId":"'..esc(unwrap_string(safe_prop(c,{"ConditionID"})))..'"'..
     ',"conditionName":"'..esc(unwrap_string(safe_prop(c,{"ConditionName"})))..'"'..
     ',"itemId":"'..esc(unwrap_string(safe_prop(c,{"ItemId"})))..'"'..
     ',"requiredQuantity":'..json_number_or_null(number_value(safe_prop(c,{"RequiredQuantity"})))..
     ',"modelRaw":"'..esc(unwrap_string(safe_prop(c,{"Model"})))..'"'..
     ',"colorRaw":"'..esc(unwrap_string(safe_prop(c,{"Color"})))..'"'..
     ',"brandRaw":"'..esc(unwrap_string(safe_prop(c,{"Brand"})))..'"'..
     ',"bodyTypeRaw":"'..esc(unwrap_string(safe_prop(c,{"BodyType"})))..'"'..
     ',"minTechnicalCondition":'..json_number_or_null(number_value(safe_prop(c,{"MinTechnicalCondition"})))..
     ',"minProductionYear":'..json_number_or_null(number_value(safe_prop(c,{"MinProductionYear"})))..
     ',"maxProductionYear":'..json_number_or_null(number_value(safe_prop(c,{"MaxProductionYear"})))..
     ',"rustStateRaw":"'..esc(unwrap_string(safe_prop(c,{"RustState"})))..'"'..
     '}')
   end)
   table.insert(pawnChunks,']}')
  end)
 end
 local pawnJson=table.concat(pawnChunks)
 if pawnJson~="" then
  cachedPawnRequestsJson=pawnJson
 elseif cachedPawnRequestsJson~=nil then
  pawnJson=cachedPawnRequestsJson
 end
 local deal=PawnDeal.scan(pawn,forceDiscovery==true)
 table.insert(chunks,',"dailyDeal":{'..
  '"detected":'..json_bool_or_null(deal.detected)..
  ',"lastRefreshDay":'..json_number_or_null(deal.lastRefreshDay)..
  '}')
 table.insert(chunks,',"pawnRequests":['..(pawnJson or "")..']')
 table.insert(chunks,',"tonyReputation":'..json_number_or_null(cachedTonyReputation))

 table.insert(chunks,',"events":[')
 local handler=get_world_event_handler(cachedOnly~=true)
 local firstEvent=true
 if handler~=nil then
  local events=safe_prop(handler,{"CurrentEvents"})
  array_each(events,function(ev)
   if ev==nil then return end
   local eventId=unwrap_string(safe_prop(ev,{"EventID"}))
   local displayName=unwrap_string(safe_prop(ev,{"DisplayName"}))

   -- Tony's Pawn Shop requests have their own dedicated Contracts section.
   -- Do not duplicate the generic Pawn Shop event in Missions / Tasks.
   if displayName~="Pawn Shop Request" then
    if not firstEvent then table.insert(chunks,",") end
    firstEvent=false
    local tasks=safe_prop(ev,{"CurrentTasks"})
    table.insert(chunks,'{'..
     '"eventId":"'..esc(eventId)..'"'..
     ',"displayName":"'..esc(displayName)..'"'..
     ',"className":"'..esc(get_object_full_name(ev))..'"'..
     ',"tasks":[')
    local firstTask=true
    array_each(tasks,function(task)
     if task==nil then return end
     if not firstTask then table.insert(chunks,",") end
     firstTask=false
     local taskText=unwrap_string(safe_prop(task,{"TaskText"}))
     local taskId=unwrap_string(safe_prop(task,{"TaskID"}))
     local current=number_value(safe_prop(task,{"CurrentValue"}))
     local target=number_value(safe_prop(task,{"TargetValue"}))
     local started=safe_prop(task,{"IsTaskStarted"})
     local hidden=safe_prop(task,{"Hidden"})
     table.insert(chunks,'{'..
      '"taskId":"'..esc(taskId)..'"'..
      ',"taskText":"'..esc(taskText)..'"'..
      ',"currentValue":'..json_number_or_null(current)..
      ',"targetValue":'..json_number_or_null(target)..
      ',"started":'..json_bool_or_null(started)..
      ',"hidden":'..json_bool_or_null(hidden)..'}')
    end)
    table.insert(chunks,']}')
   end
  end)
 end
 table.insert(chunks,']}')

 write_json_atomic(contractsJsonPath,table.concat(chunks))
 return true
end


local function read_int_array(arr)
 local out={}
 if arr==nil then return out end
 pcall(function()
  arr:ForEach(function(_,element)
   local value=element
   pcall(function()
    local got=element:get()
    if got~=nil then value=got end
   end)
   local n=number_value(value)
   if n~=nil then table.insert(out,math.floor(n)) end
  end)
 end)
 return out
end

local function calculate_reputation_progress(repExp,thresholds)
 if repExp==nil or thresholds==nil or #thresholds==0 then
  return nil,nil,nil,nil,nil
 end

 local highestIndex=1
 for i,v in ipairs(thresholds) do
  if repExp>=v then highestIndex=i end
 end

 local level=math.max(1,highestIndex-1)
 local currentThreshold=thresholds[highestIndex] or 0
 local nextThreshold=thresholds[highestIndex+1]

 if nextThreshold==nil then
  return level,currentThreshold,nil,0,100
 end

 local need=math.max(0,nextThreshold-repExp)
 local span=nextThreshold-currentThreshold
 local progress=0
 if span>0 then
  progress=((repExp-currentThreshold)/span)*100
  if progress<0 then progress=0 end
  if progress>100 then progress=100 end
 end

 return level,currentThreshold,nextThreshold,need,progress
end


local function scan_business()
 local econ=get_cached_economy_system()
 if econ==nil then
  write_json_atomic(businessJsonPath,'{"version":"0.44.0.14","connected":false}')
  return false
 end

 local money=number_value(safe_prop(econ,{"PlayerMoney"}))
 local repExp=number_value(safe_prop(econ,{"ReputationExperience"}))
 local gameDay=number_value(safe_prop(econ,{"DayCounter"}))

 -- Tony's Pawn Shop reputation is a separate progression system.
 -- Never touch the live Pawn Shop subsystem from the periodic business scan.
 -- Reuse the last manual Contracts snapshot instead.
 local tonyRep=cachedTonyReputation

 local thresholds=read_int_array(safe_prop(econ,{"ReputationExperienceTable"}))
 local repLevel,currentThreshold,nextThreshold,needToNext,progressPercent=
  calculate_reputation_progress(repExp,thresholds)

 local gameTime=get_game_time_string(econ)

 write_json_atomic(
  businessJsonPath,
  '{"version":"0.44.0.14","connected":true'..
  ',"money":'..json_number_or_null(money)..
  ',"reputationExperience":'..json_number_or_null(repExp)..
  ',"reputationLevel":'..json_number_or_null(repLevel)..
  ',"currentExperienceThreshold":'..json_number_or_null(currentThreshold)..
  ',"nextExperienceTotal":'..json_number_or_null(nextThreshold)..
  ',"needExperienceToNext":'..json_number_or_null(needToNext)..
  ',"differenceExperience":'..json_number_or_null(
    (nextThreshold~=nil and currentThreshold~=nil) and (nextThreshold-currentThreshold) or nil
  )..
  ',"reputationProgressPercent":'..json_number_or_null(progressPercent)..
  ',"tonyReputation":'..json_number_or_null(tonyRep)..
  ',"gameDay":'..json_number_or_null(gameDay)..
  ',"gameTime":'..(gameTime and ('"'..esc(gameTime)..'"') or 'null')..
  '}'
 )
 return true
end


-- ============================================================
-- v0.44.0.72.12.1.1.1 FULL PARTS ICON DISCOVERY PROBE
-- Local-limit-safe: all probe helpers live inside this nested
-- function, not in the main Lua chunk.
-- ============================================================
function run_full_parts_icon_probe()
 if __cdcPartsIconFullProbeDone then return true end
 __cdcPartsIconFullProbeDone=true

 local partsIconFullProbePath=diagnosticsRoot.."\\parts_icon_full_probe.txt"
 local PARTS_ICON_PROBE_FIELDS={
  "Icon","icon","ItemIcon","ItemIconTexture","IconTexture","Texture","Texture2D",
  "Image","ItemImage","ProductImage","Thumbnail","ThumbnailTexture","PreviewImage",
  "UIIcon","UI_Icon","IconImage","MainIcon","ProductIcon","PartIcon","InventoryIcon",
  "Brush","SlateBrush","ImageBrush","IconBrush","ItemBrush",
  "ItemData","ItemInfo","ItemDefinition","Definition","Data","DataAsset",
  "Product","ProductData","ProductInfo","ProductDefinition","ProductAsset",
  "StaticItemData","ItemClass","ItemType","Class","Asset","AssetData"
 }

 local function probe_safe_string(v)
  if v==nil then return "<nil>" end
  local ok,s=pcall(function() return tostring(v) end)
  if ok and s~=nil then return s end
  return "<unprintable>"
 end

 local function probe_obj_path(obj)
  if obj==nil then return "" end
  local candidates={}
  local function add(label,fn)
   local ok,v=pcall(fn)
   if ok and v~=nil then
    local s=probe_safe_string(v)
    if s~="" and s~="<nil>" then table.insert(candidates,label.."="..s) end
   end
  end
  add("FullName",function() return obj:GetFullName() end)
  add("FName",function() return obj:GetFName():ToString() end)
  add("Class",function()
   local c=obj:GetClass()
   if c~=nil then return c:GetFullName() end
   return nil
  end)
  if #candidates==0 then return probe_safe_string(obj) end
  return table.concat(candidates," | ")
 end

 local function probe_prop(obj,name)
  if obj==nil then return nil,false end
  local ok,v=pcall(function() return obj[name] end)
  if ok then return v,true end
  return nil,false
 end

 local probe_write_field
 probe_write_field=function(f,prefix,obj,name,seen,depth)
  local v,ok=probe_prop(obj,name)
  if not ok or v==nil then return end

  local rawv=probe_safe_string(v)
  f:write(prefix..name.." = "..rawv.."\n")

  local path=probe_obj_path(v)
  if path~="" and path~=rawv then
   f:write(prefix.."  -> "..path.."\n")
  end

  if depth>=2 then return end
  local key=path
  if key=="" then key=rawv end
  if seen[key] then return end
  seen[key]=true

  local lname=string.lower(name)
  if lname:find("data",1,true)
  or lname:find("product",1,true)
  or lname:find("icon",1,true)
  or lname:find("image",1,true)
  or lname:find("brush",1,true)
  or lname:find("texture",1,true)
  or lname:find("asset",1,true)
  or lname:find("class",1,true) then
   for _,child in ipairs(PARTS_ICON_PROBE_FIELDS) do
    probe_write_field(f,prefix.."    ",v,child,seen,depth+1)
   end
  end
 end

 local function probe_dump_object(f,label,obj)
  f:write(label.."\n")
  f:write(string.rep("-",80).."\n")
  if obj==nil then
   f:write("<nil>\n")
   return
  end
  f:write("OBJECT: "..probe_obj_path(obj).."\n")
  local seen={}
  for _,field in ipairs(PARTS_ICON_PROBE_FIELDS) do
   probe_write_field(f,"  ",obj,field,seen,0)
  end
 end

 local function probe_first_instance(stack)
  local arr,ok=probe_prop(stack,"ItemInstances")
  if not ok or arr==nil then return nil end
  local first=nil
  pcall(function()
   arr:ForEach(function(_,e)
    if first~=nil then return end
    local v=e
    pcall(function()
     local got=e:get()
     if got~=nil then v=got end
    end)
    if v~=nil then first=v end
   end)
  end)
  return first
 end

 local function probe_default_object_from_class(cls)
  if cls==nil then return nil end
  local obj=nil
  pcall(function() obj=cls:GetDefaultObject() end)
  if obj~=nil then return obj end
  pcall(function() obj=cls:ClassDefaultObject() end)
  return obj
 end

 local f=io.open(partsIconFullProbePath,"w")
 if not f then
  log("FULL PARTS ICON PROBE: could not create diagnostic file")
  return false
 end

 f:write("CAR DEALER COMPANION - FULL PARTS ICON DISCOVERY PROBE\n")
 f:write("Build: v0.45.0.0\n")
 f:write("Generated: "..os.date("%Y-%m-%d %H:%M:%S").."\n")
 f:write("Purpose: discover the real live icon/image/texture source chain for every loaded item stack.\n")
 f:write("Read-only: property reads / object identity only. No gameplay-changing calls.\n")
 f:write(string.rep("=",100).."\n\n")

 local all=FindAllOf("BP_ItemStack_C")
 if not all then
  f:write("FindAllOf(BP_ItemStack_C) returned nil.\n")
  f:close()
  log("FULL PARTS ICON PROBE: no BP_ItemStack_C objects found")
  return false
 end

 local rows={}
 for _,stack in ipairs(all) do
  if stack~=nil and object_is_valid(stack) then
   local nm=name_of(stack)
   local typ=type_of(stack)
   local path=probe_obj_path(stack)
   table.insert(rows,{obj=stack,name=nm,typ=typ,path=path})
  end
 end

 table.sort(rows,function(a,b)
  local an=string.lower(tostring(a.name or ""))
  local bn=string.lower(tostring(b.name or ""))
  if an==bn then return tostring(a.path or "")<tostring(b.path or "") end
  return an<bn
 end)

 f:write("TOTAL LIVE BP_ItemStack_C OBJECTS: "..tostring(#rows).."\n\n")

 local uniqueNames={}
 local uniqueCount=0
 for i,row in ipairs(rows) do
  local stack=row.obj
  local name=tostring(row.name or "<unknown>")
  local typ=tostring(row.typ or "Unknown")
  local key=string.lower(name).."||"..string.lower(typ)
  if not uniqueNames[key] then uniqueNames[key]=true; uniqueCount=uniqueCount+1 end

  f:write("\n")
  f:write(string.rep("=",100).."\n")
  f:write(string.format("[%03d] %s\n",i,name))
  f:write("TYPE: "..typ.."\n")
  f:write("STACK: "..tostring(row.path or "").."\n")

  probe_dump_object(f,"STACK PROPERTIES",stack)

  local itemClass=nil
  pcall(function() itemClass=stack.ItemClass end)
  if itemClass~=nil then
   f:write("\n")
   probe_dump_object(f,"ITEM CLASS",itemClass)

   local cdo=probe_default_object_from_class(itemClass)
   if cdo~=nil then
    f:write("\n")
    probe_dump_object(f,"ITEM CLASS DEFAULT OBJECT",cdo)
   end
  end

  local inst=probe_first_instance(stack)
  if inst~=nil then
   f:write("\n")
   probe_dump_object(f,"FIRST ITEM INSTANCE",inst)
  end
 end

 f:write("\n\n")
 f:write(string.rep("=",100).."\n")
 f:write("SUMMARY\n")
 f:write("Live stack objects: "..tostring(#rows).."\n")
 f:write("Unique name/type combinations: "..tostring(uniqueCount).."\n")
 f:write("Probe complete.\n")
 f:close()

 log("FULL PARTS ICON PROBE COMPLETE: "..tostring(#rows).." live stacks, "..tostring(uniqueCount).." unique rows -> "..partsIconFullProbePath)
 return true
end


log("Loaded. Crash-safe startup gate active. No live reads until the WorldMap player inventory is stable.")

-- ============================================================
-- v0.38.3.3 READER STABILITY + CARS LIVE REFRESH/PERFORMANCE
--
-- Presentation/data calculations are unchanged. This scheduler reduces the
-- chance of native UE4SS access violations by:
--   * caching the known-good WorldMap player inventory after startup,
--   * validating that cached object before every repeating batch,
--   * pausing all live reads if the cached WorldMap object becomes invalid,
--   * reacquiring the WorldMap only through the existing 3-pass gate,
--   * preventing overlapping ExecuteInGameThread batches,
--   * logging BEGIN/END around each reader so a future crash is attributable.
-- ============================================================

local liveReadsEnabled=false
local startupDelayElapsed=false
local worldReadyPasses=0
local worldReadyProbeInFlight=false
local liveBatchInFlight=false
local liveBatchRequestedClock=0
local REQUIRED_WORLD_READY_PASSES=3

local function probe_worldmap_ready()
 local inv=find_inventory()
 if not inv or not inv:IsValid() then
  return false,"WorldMap player inventory not found",nil
 end

 local okItems,items=pcall(function() return inv.Items end)
 if not okItems or items==nil then
  return false,"WorldMap player inventory exists but Items is not readable yet",nil
 end

 return true,"WorldMap player inventory and Items are readable",inv
end

local function validate_cached_worldmap()
 local inv=cachedWorldInventory
 if not inv or not inv:IsValid() then
  return false,"cached WorldMap player inventory is invalid"
 end

 local okName,fullName=pcall(function() return inv:GetFullName() end)
 if not okName or not fullName
 or not fullName:find("WorldMap.WorldMap:PersistentLevel",1,true)
 or not fullName:find("BP_PlayerController_C_",1,true) then
  return false,"cached inventory no longer belongs to the loaded WorldMap player"
 end

 local okItems,items=pcall(function() return inv.Items end)
 if not okItems or items==nil then
  return false,"cached WorldMap inventory Items became unreadable"
 end

 return true,"cached WorldMap inventory is valid"
end

local function pause_live_reads(reason)
 if liveReadsEnabled then
  log("LIVE READS PAUSED: "..tostring(reason or "WorldMap became unsafe"))
 end
 liveReadsEnabled=false
 ready=false
 storageReady=false
 worldReadyPasses=0
 cachedWorldInventory=nil
 cachedEconomySystem=nil
 invalidate_storage_container_cache()
 invalidate_repair_container_cache()
 if PerfV73 then PerfV73.reset() end
end

local function safe_run(label,fn)
 local started=os.clock()
 log("BEGIN "..label)
 local ok,result=pcall(fn)
 local elapsedMs=math.floor(((os.clock()-started)*1000)+0.5)

 -- Keep normal gameplay logging quiet. Only slow reader operations are written
 -- to the dedicated performance log unless Debug is enabled.
 if elapsedMs>=50 or refreshSettings.debug_enabled then
  local line=os.date("%Y-%m-%d %H:%M:%S").." | "..tostring(label).." | "..tostring(elapsedMs).." ms\n"
  local pf=io.open(performanceLogPath,"a")
  if pf then pf:write(line); pf:close() end
  local df=io.open(diagnosticsRoot.."\\reader_performance.log","a")
  if df then df:write(line); df:close() end
 end

 if not ok then
  log("ERROR "..label..": "..tostring(result))
  return false
 end
 log("END "..label.." ("..tostring(elapsedMs).." ms)")
 return result~=false
end

local function run_startup_batch()
 load_refresh_settings()
 if (tonumber(refreshSettings.inventory_seconds) or 0)>0 then safe_run("inventory[startup]",scan) end
 if (tonumber(refreshSettings.dashboard_seconds) or 0)>0 then
  safe_run("business[startup]",scan_business)
 end
 if (tonumber(refreshSettings.contracts_seconds) or 0)>0 then
  safe_run("contracts[startup]",function() return scan_contracts(false,false) end)
 end
 if (tonumber(refreshSettings.storage_seconds) or 0)>0 then
  safe_run("storage[startup]",function() return scan_storage(true) end)
  safe_run("repair[startup]",function() return scan_repair_machine(true) end)
 end
 -- Keep the fast-start cache on screen and do not force the expensive Cars
 -- world-discovery pass while the game is still settling. Cars remain automatic
 -- on the user-selected cadence below, and SCAN CARS still forces a full scan.
 log("Cars startup scan deferred; cached Cars data remains visible until auto/manual refresh.")
end

local function enable_live_reads_once(inv)
 if liveReadsEnabled then return end

 cachedWorldInventory=inv
 liveReadsEnabled=true
 ready=true
 storageReady=true
 log("WorldMap stable across "..tostring(REQUIRED_WORLD_READY_PASSES).." checks. Live reads enabled.")
 run_startup_batch()
 -- v0.44.0.74: retired icon discovery is no longer executed during normal gameplay.
 -- The probe implementation is intentionally left dormant for recovery/developer use only.
end

-- Preserve the 60-second minimum delay, but do not enable reads here.
LoopAsync(60000,function()
 startupDelayElapsed=true
 log("60-second minimum delay complete. Waiting for stable loaded WorldMap before live reads.")
 return true
end)

local periodicTick=0

LoopAsync(5000,function()
 if not startupDelayElapsed then
  return false
 end

 if not liveReadsEnabled then
  if not worldReadyProbeInFlight then
   worldReadyProbeInFlight=true
   ExecuteInGameThread(function()
    local okProbe,isReady,reason,inv=pcall(probe_worldmap_ready)

    if okProbe and isReady then
     worldReadyPasses=worldReadyPasses+1
     log("WorldMap readiness check "..tostring(worldReadyPasses).."/"..tostring(REQUIRED_WORLD_READY_PASSES).." passed.")

     if worldReadyPasses>=REQUIRED_WORLD_READY_PASSES then
      enable_live_reads_once(inv)
     end
    else
     if worldReadyPasses~=0 then
      log("WorldMap readiness lost; resetting stability counter.")
     end
     worldReadyPasses=0
     cachedWorldInventory=nil
     if okProbe then
      log("Waiting for loaded WorldMap: "..tostring(reason or "not ready"))
     else
      log("WorldMap readiness probe safely failed; waiting for next check.")
     end
    end

    worldReadyProbeInFlight=false
   end)
  end
  return false
 end

 -- Do not queue another game-thread batch while a previous one is still active.
 if liveBatchInFlight then
  local activeMs=0
  if liveBatchRequestedClock and liveBatchRequestedClock>0 then
   activeMs=math.floor(((os.clock()-liveBatchRequestedClock)*1000)+0.5)
  end
  log("Live batch skipped: previous game-thread batch still active (approx active="..tostring(activeMs).." ms).")
  return false
 end

 liveBatchInFlight=true
 liveBatchRequestedClock=os.clock()
 ExecuteInGameThread(function()
  local enteredClock=os.clock()
  local queueWaitMs=math.floor(((enteredClock-liveBatchRequestedClock)*1000)+0.5)
  local batchStarted=enteredClock
  if queueWaitMs>=50 or refreshSettings.debug_enabled then
   log("GAME THREAD ENTER: queue-wait="..tostring(queueWaitMs).." ms")
  end
  if queueWaitMs>=50 or refreshSettings.debug_enabled then
   local line=os.date("%Y-%m-%d %H:%M:%S").." | game-thread-queue-wait | "..tostring(queueWaitMs).." ms\n"
   local pf=io.open(performanceLogPath,"a"); if pf then pf:write(line); pf:close() end
   local df=io.open(diagnosticsRoot.."\\reader_performance.log","a"); if df then df:write(line); df:close() end
  end
  local okBatch,batchErr=pcall(function()
   local worldOk,worldReason=validate_cached_worldmap()
   if not worldOk then
    pause_live_reads(worldReason)
    return
   end

   periodicTick=periodicTick+1
   load_refresh_settings()

   local readerRequest=consume_reader_refresh_request()
   local manualCarsRefresh=consume_cars_refresh_request()
   local carsAutoDue=interval_due(refreshSettings.cars_seconds,periodicTick)

   -- Manual Settings-page refresh requests take priority and affect only the
   -- reader the user asked for. This keeps the approved pages uncluttered.
   if readerRequest=="dashboard" then
    safe_run("business[manual]",scan_business)
   elseif readerRequest=="contracts" then
    safe_run("contracts[manual]",function() return scan_contracts(true,false) end)
   elseif readerRequest=="inventory" then
    safe_run("inventory[manual]",scan)
    safe_run("storage[manual-inventory]",function() return scan_storage(true) end)
    safe_run("repair[manual-inventory]",function() return scan_repair_machine(true) end)
   elseif readerRequest=="storage" then
    safe_run("storage[manual]",function() return scan_storage(true) end)
    safe_run("repair[manual]",function() return scan_repair_machine(true) end)
   else
    if interval_due(refreshSettings.inventory_seconds,periodicTick) then
     safe_run("inventory[auto]",scan)
    end
    if interval_due(refreshSettings.dashboard_seconds,periodicTick) then
     safe_run("business[auto]",scan_business)
    end
    if interval_due(refreshSettings.contracts_seconds,periodicTick) and not carsAutoDue then
     safe_run("contracts[auto]",function() return scan_contracts(false,true) end)
    end

    -- Storage/repair FindAllOf scans are deliberately kept away from the Cars
    -- auto tick so the heavier object searches do not pile into the same frame.
    if interval_due(refreshSettings.storage_seconds,periodicTick) and not carsAutoDue and not manualCarsRefresh then
     safe_run("storage[auto]",scan_storage)
     safe_run("repair[auto]",scan_repair_machine)
    end
   end

   -- Cars keep both forms of automation: user-selected auto cadence plus the
   -- existing full SCAN CARS request. Manual always wins over the auto tick.
   if manualCarsRefresh then
    safe_run("cars[manual]",function() return run_cars_scan_checked("manual",true) end)
    safe_run("car-distance[manual]",function() return run_safe_car_distances_checked("manual") end)
   elseif carsAutoDue and not readerRequest then
    local shouldScan,autoReason=PerfV73.should_auto_scan()
    if shouldScan then
     local autoOk=safe_run("cars[auto:"..tostring(autoReason).."]",function() return run_cars_scan_checked("auto",false) end)
     if autoOk then PerfV73.mark_auto_scan_complete() end
    else
     log("Cars auto refresh skipped: vehicle registry unchanged; manual SCAN CARS remains available.")
    end
    -- Pass 5: normal five-minute Cars ticks no longer rebuild unchanged Cars data.
    -- A registry change triggers an auto rebuild; a 30-minute safety sync catches
    -- non-construction state changes. Manual SCAN CARS remains a full recovery sync.
   end
  end)

  if not okBatch then
   log("ERROR live batch wrapper: "..tostring(batchErr))
  end
  local batchElapsedMs=math.floor(((os.clock()-batchStarted)*1000)+0.5)
  if batchElapsedMs>=50 or refreshSettings.debug_enabled then
   local line=os.date("%Y-%m-%d %H:%M:%S").." | live-batch-total | "..tostring(batchElapsedMs).." ms\n"
   local pf=io.open(performanceLogPath,"a"); if pf then pf:write(line); pf:close() end
   local df=io.open(diagnosticsRoot.."\\reader_performance.log","a"); if df then df:write(line); df:close() end
  end
  liveBatchInFlight=false
  liveBatchRequestedClock=0
 end)

 return false
end)
