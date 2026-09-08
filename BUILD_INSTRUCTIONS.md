# Build Instructions - Car Dealer Companion v0.45.0.0

## Overview

Car Dealer Companion v0.45.0.0 is script-based.

There is no C, C++, C# or other compiled application build step. There is no Visual Studio solution and no EXE or DLL produced by this project.

The Nexus release is assembled directly from the human-readable Lua, PowerShell, VBS and CMD scripts together with the JSON and TXT support files.

## Requirements for packaging

- Windows
- PowerShell 5.1 or newer, or another ZIP utility
- The complete source files in this repository

UE4SS is required by the end user at runtime but is installed separately and is not bundled with this release.

## Release structure

The release package contains:

CarDealerInventoryReader\
    enabled.txt
    Scripts\
        main.lua

Overlay\
    Catalog.json
    GameWatcher.ps1
    LaunchOverlay.vbs
    LaunchWatcher.vbs
    Overlay.ps1

INSTALL.cmd
README_FIRST.txt
RELEASE_NOTES_v0.45.0.0.txt
START_COMPANION.cmd
START_UI.cmd
THIRD_PARTY_AND_RUNTIME_NOTICE.txt
UNINSTALL.cmd

## Packaging procedure

1. Place the release files in a clean staging directory using the structure shown above.
2. Do not include UE4SS itself.
3. Create a ZIP from the contents of the staging directory.

Example PowerShell command:

    Compress-Archive -Path "C:\Path\To\Staging\*" -DestinationPath "C:\Path\To\CarDealerCompanion_v0.45.0.0.zip" -CompressionLevel Optimal

No compilation is performed.

## Runtime overview

- `INSTALL.cmd` installs/registers the Companion support files.
- `GameWatcher.ps1` watches for the game process.
- `LaunchWatcher.vbs` launches the watcher without a persistent console window.
- `LaunchOverlay.vbs` launches the Companion UI without a persistent console window.
- `Overlay.ps1` implements the Companion user interface.
- `main.lua` runs through UE4SS and supplies the read-only game integration.
- `UNINSTALL.cmd` removes the Companion-installed/registered components.

## Submitted release verification

The exact v0.45.0.0 ZIP currently submitted to Nexus Mods has SHA-256:

E89C15D0255EC301B5BC20B24C7043C28D21477951155A3F4C1E2F74312F00EB

Recreating a ZIP from the source can produce a different archive hash because ZIP metadata, timestamps, compression and file ordering can differ. The source contents are what correspond to the submitted release.
