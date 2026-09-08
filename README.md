# Car Dealer Companion

Car Dealer Companion is a read-only companion for Car Dealer Simulator.

This repository contains the human-readable source and support files corresponding to:

**Car Dealer Companion v0.45.0.0**

The application is script-based. There is no separately compiled EXE or DLL in this release.

## Submitted Nexus release

`CarDealerCompanion_v0.45.0.0.zip`

SHA-256:

`E89C15D0255EC301B5BC20B24C7043C28D21477951155A3F4C1E2F74312F00EB`

## Source

The principal source files are:

- `CarDealerInventoryReader/Scripts/main.lua` - UE4SS Lua integration
- `Overlay/Overlay.ps1` - Companion UI
- `Overlay/GameWatcher.ps1` - game/process watcher
- `Overlay/LaunchOverlay.vbs` - overlay launcher
- `Overlay/LaunchWatcher.vbs` - watcher launcher
- Root CMD files - install/start/uninstall scripts
- `Overlay/Catalog.json` - supporting catalogue/configuration data

UE4SS is an external runtime dependency and is not bundled with Car Dealer Companion.

## Build instructions

See `BUILD_INSTRUCTIONS.md`.

## Security review

This repository is provided for Nexus Mods security review of Car Dealer Companion v0.45.0.0.
