# Fort 22 validation

Godot 4.5.2 / Windows / OpenGL Compatibility / RTX 5090, September 8, 2026.

## Siege indicators

`siege22_test.gd` passes headless and rendered. Checks cover:

- Fixed cardinal convention matching the raid director, expected fronts versus actual live raiders, exclusion of distant camp guards.
- Armed Sapper ranking, the three-threat marker cap and one urgent repair marker.
- Actual building damage, recent-hit status, critical health, hearth damage, repair clearing and removal cleanup.
- Armed flags in both full and incremental enemy snapshots and their receivers.
- Suppression during menus, placement, downed state and end screen; cleanup at dawn.
- Resource badges avoid protected siege UI; clustered marker captions remain separated and within the combat HUD area.

Inspected `build/siege22_indicators.png` and `build/siege22_night.png` at 1280x720. The first review exposed overlapping resource badges; those now respect the siege panel and caption rectangles. The first test run incorrectly expected the Bombwing at (8,6,4) in the south sector; corrected the fixture to east (the existing sector convention and implementation were correct).

No new bitmap or Blender assets are needed for this code-native HUD pass. No changes to combat balance, AI, navigation or construction mechanics were made for Fort 22.

## Multiplayer

The new `siege_network_driver.gd` passed with four local source-project processes. It exercises real batched snapshots, full resync, lit-fuse priority, matching fronts, building health, recent-hit warnings, repair clearing, enemy death and dawn cleanup on every peer.

The exported Fort 22 executable also passed all four peers in each of four packaged scenarios: siege indicators, readability/loot feedback, save/load with reconnecting players, and core multiplayer gather/deposit/late-join replication. All four scenarios passed on the first packaged run (16 successful peer results).

Full-state recovery is tested; this is not a fresh two-computer LAN or public-IP connectivity test. Fort 21's unexplained initial forestry inventory-test failure is not claimed fixed by this UI pass.

## Regression

All 31 headless suites passed in the broader regression runner. The final caption-layout revision was also checked separately headlessly and in the runner's rendered siege test.

All 28 rendered suites and the Windows release export passed. `tests/run_art_pass.ps1 -Render -Export` completed with `ART_PASS_CHECKS_OK`. Existing coverage includes combat, reticles, resources, castle planning, navigation, recovery, pets, progression, save/load and remodeling.

The standard 100-enemy rendered stress fixture passed with 32.2 average FPS and 146.381 ms worst frame, versus Fort 21's recorded 30.0 FPS / 152.253 ms. These short runs vary; this is not evidence of a general performance improvement or a 60 FPS guarantee. This pass does not increase swarm counts.

## Version preservation

`tests/package_version.ps1 -Version 22` completed with `VERSION_22_ARCHIVE_VERIFIED`, checking source, folder and ZIP-contained executable hashes. Windows executable version is 0.22.0. `git diff --check` passed.

- Fort_22.zip: 60,328,020 bytes; SHA256 `D370EE7E518B80AA6D994AE23100D860FAB7D6E0310082BAB7D853A1E0BA6C88`
- Fort_22/Fort.exe: 124,523,888 bytes; SHA256 `C18116B8607E4E2D97B15136F0CEFE2A64979003D882B6D69DEA861E1B22D3DF`

Verified unchanged SHA256 hashes:

- Fort_21.zip: `8872DBCC2002D71E668A469C93930FB70FB9E4AF528E074BA637EEB8825988C4`
- Fort_20.zip: `52203C704B66D52C2829447B4DDCF244CF27EE7EE188B66B9CCA17CDFBBDF770`

All Fort 20/21 working-tree changes are preserved. No GitHub commit, push or PR mutation is part of this pass.
