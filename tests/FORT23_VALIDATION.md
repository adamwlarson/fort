# Fort 23 validation

Godot 4.5.2 / Windows / OpenGL Compatibility / RTX 5090, September 8, 2026.

## Minimap coverage

`tests/minimap23_test.gd` covers default-off resource patches, actual M-key input, fixed north-up scale, local centering, castle footprint, three crew markers including downed and distant allies, discovered/unclaimed sites, capped resources, marker separation, menu/build/end suppression, and world-badge exclusion.

The crowd fixture collapses 80 live raiders into one local threat group while excluding far enemies and distant camp guards. A first iteration hid that group when its marker overlapped a crew marker; threat groups now seek clear nearby slots. Point-blank threats remain visible beside the player marker. The additional surrounded-player case checks all eight threat directions.

Rendered views: `build/minimap23_clean.png`, `minimap23_resources.png`, and `minimap23_exploration.png`. The clean and resource views were inspected; a dark legend backing was added after the first review showed text competing with foliage. No bitmap or Blender assets are needed for this code-native UI pass.

## Regression results

`tests/run_art_pass.ps1 -Render -Export` completed with `ART_PASS_CHECKS_OK`: 32 headless suites, 29 rendered suites, and Windows export passed. The eight-direction surrounded-player assertion was added after the initial headless minimap run and passed in the final rendered minimap run. The clean, resource-layer and distant-exploration screenshots were inspected.

The standard 100-enemy stress fixture passed at 42.2 average FPS / 138.564 ms worst frame, compared with Fort 22's recorded 32.2 FPS / 146.381 ms. Short runs vary; no controlled profiling establishes the cause of this difference, and this is not a general performance or 60 FPS guarantee.

## Multiplayer results

All four packaged four-player local scenarios passed on their first Fort 23 run: siege/minimap, readability feedback, save/load with reconnecting players, and core multiplayer (16 passing peer results). The extended siege driver verifies each minimap centers its local dwarf, retains the other three players, shows the replicated bomber once, clears dead enemies and preserves each computer's independent resource-layer choice through full resync.

## Design limits

This is an intentionally approximate local navigation display, not a world atlas or exact targeting radar. Markers may be nudged to avoid overlaps. The 100m radius does not increase with the hearth; global assault information stays in Siege Watch. Resources are capped at ten representative patches, exploration sites at four, and threat directions at eight. Only completed ground-floor castle rooms appear in the footprint. Resource-layer selection resets for each expedition and is local to each computer.

No network protocol or save-schema change is introduced. No resources, encounters, collision, combat or world-generation rules are changed by this pass. Two-computer LAN/public-IP testing is outside this UI validation; Fort 21's earlier intermittent forestry-test failure is not claimed fixed here.

## Version preservation

`tests/package_version.ps1 -Version 23` completed with `VERSION_23_ARCHIVE_VERIFIED`; source, folder and ZIP-contained executable hashes match. File version is 0.23.0. `git diff --check` passed.

- Fort_23.zip: 60,334,557 bytes; SHA256 `B5FA3C4E525238143EF6038CF9000583F9946CBD7412165630DD385ED4AC908B`
- Fort_23/Fort.exe: 124,529,368 bytes; SHA256 `9789532517C5E0D2EBB57187355C1CAEBC2E80FE0BBDE7A4AE0F75559086C6FC`

Verified Fort_22.zip still has SHA256 `D370EE7E518B80AA6D994AE23100D860FAB7D6E0310082BAB7D853A1E0BA6C88`. Prior numbered folders and ZIPs remain untouched. Existing Fort 20–22 working-tree changes are preserved; nothing is committed or pushed as part of this pass.
