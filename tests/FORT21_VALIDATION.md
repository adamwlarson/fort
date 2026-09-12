# Fort 21 validation

Godot 4.5.2, Windows / OpenGL Compatibility / RTX 5090, September 7–8, 2026.

## Castle planner

`planner21_test.gd` passed headless and rendered. It covers:

- Finished rooms and valid/locked expansions across floors; gold unfinished projects.
- Real mouse selection of a footprint and its source room, and mouse-wheel zoom.
- Remote inspection without moving the dwarf, closing the architect, or authorizing remote construction/funding.
- Exact missing-support selection, floor switch and coral highlight, including choosing the downstairs sign rather than the upstairs sign.
- World-space sign marker and return to play; reaching the marked sign enables the valid plan.
- Actual blueprint placement and hand-built support changing the original upper cell to ready.

The final rendered layout was inspected at 1280×720 and rerun after reserving height for its two-line caption. `build/planner21_upstairs.png`, `planner21_support.png`, and `planner21_ready.png` record the states. Long reasons also remain in the main architect panel and tooltips. No new raster or Blender art was required for this code-native interface.

## Physical traversal

`navigation21_test.gd` passed headless and rendered:

- A real enemy-sized body exits a U-shaped obstacle, takes the detour, and reaches the goal without teleportation.
- Body-width checks reject a gap that a thin center ray would accept.
- Added and removed defenses invalidate navigation caches.
- Player step assist does not push the dwarf into a low ceiling.
- Pet recall finds another clear landing when the old home position is occupied, preserving cargo.
- Player fall-through recovery uses authoritative checked ground and cannot be requested from safe standing ground.
- Enemy-sized physics ascends and descends the actual castle staircase; live raid AI retains an upstairs target long enough to reach that floor.

Existing pet delivery regression now verifies a physical jump **or a measured lateral detour** around its barricade, followed by harvesting and shared-stock delivery. The earlier assertion required jumping even when the new ground detour successfully delivered cargo.

## Regression and performance

All 30 headless suites and 27 rendered suites passed, followed by Windows export. Existing save/load, castle/remodel/clearance, movement, combat, progression, terrain and asset checks remain included. Tests use `--fort-test` isolation.

The final standard 100-enemy rendered fixture passed with 100 active enemies: 30.0 average FPS, 152.253 ms worst frame. A separate earlier run recorded 30.0 FPS / 160.556 ms. Fort 19's recorded standard fixture was 30.6 FPS / 145.432 ms. These are short local samples, not a low-end-hardware guarantee or proof that performance work is finished.

Local routing is bounded (144 expanded nodes, at most two search starts per physics frame); it is not a complete world navigation mesh. Difficult sealed routes can still require breaching, clearing space or pet recall.

## Multiplayer test setup

The recovery driver now waits for all world-ready acknowledgments and keeps the recovered peer connected while observers inspect it. The legacy gathering/deposit driver likewise waits for world readiness, with a longer client observation deadline. Early runs exposed fixture races from sending controlled teleports before a peer was ready and disconnecting it before observer assertions. Both drivers passed all four peers after synchronization corrections; these did not change the live connection protocol.

All 16 packaged four-process scenarios ultimately passed: recovery, core networking, weapons, lobby, progression, construction, frontier, balance, expedition/pets, wilderness, forestry, castle, save/load, remodeling, readability, and clearance. Castle clients additionally verify remote inspection is read-only and completion updates the floor plan. Recovery clients exercise an actual owner-to-host fall request and verify synchronized safe landing, health and inventory.

This was not a clean single-pass network run. In addition to the corrected fixture synchronization, one balance client missed the transient repair-break window; the unchanged test passed on independent rerun. An initial forestry batch failed its exact-total inventory assertion; a diagnostic rerun, without changing that assertion or gameplay, passed with exactly 24 timber (eight per client). That initial forestry failure was not reproduced or conclusively explained. Final results are recorded per scenario; these are local four-process tests, not a new two-computer/public-internet validation.

## Package

The final log audit found 64 passing peer results across all 16 scenarios. `tests/package_version.ps1 -Version 21` verified the source, folder and ZIP-contained executable hashes.

- Executable: 124,514,880 bytes, SHA-256 `878EC19DAF63CFFE375A7FF23F0368E6527C7B067B14B02B8098C833106FA91F`.
- `Fort_21.zip`: SHA-256 `8872DBCC2002D71E668A469C93930FB70FB9E4AF528E074BA637EEB8825988C4`.
- `Fort_20.zip` remains unchanged: SHA-256 `52203C704B66D52C2829447B4DDCF244CF27EE7EE188B66B9CCA17CDFBBDF770`.
