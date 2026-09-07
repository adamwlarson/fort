# Fort 15 validation

Validated on 2026-09-06, Godot 4.5.2 on Windows / OpenGL Compatibility / RTX 5090.

The full existing regression run (`tests/run_art_pass.ps1 -Render -Export -Network`) completed with `ART_PASS_CHECKS_OK`: 21 headless suites, 19 rendered suites and 12 packaged four-process network scenarios. The dedicated remodeling test also passed headless and rendered, and `tests/run_network.ps1 -Packaged -Driver remodel_network_driver` passed. Combined coverage is 22 headless suites, 20 rendered suites and 13 multiplayer scenarios. The runner now includes the new remodeling suites for subsequent runs.

New checks cover:

- Overview camera, detailed room/stair/entrance preview, confirmation, sign progress, and actual project target display.
- Original paid room ledger, full new-room cost, one-time old-room recovery, and cancellation without refund duplication.
- Save/load halfway through remodeling, format-2 output and acceptance of legacy format-1 room records.
- Keep protection, daytime/enemy/crew/defense checks, protected support floors and stairs, connection-room refusal, and building clearance around entrances/landings.
- Hands-on demolition and safe worker relocation.
- Three remote workers collaborating on one remodel and demolition, repeated network requests charging/refunding once, updated room kinds on every client and local-owner teleport replication.

The older gameplay fixture placed its ballista directly in the keep entrance. It was moved beside the newly protected entrance; construction, mounting, dismounting and the rest of that suite pass.

Visual inspection: `build/remodel15_preview.png` and `build/remodel15_project.png`. Preview labels were given an overview-appropriate visibility range and size; the architect no longer darkens the planning world like the pause menu.

The 100-enemy stress scene passed with 35.8 average FPS and a 183.352ms worst frame on this machine. This is not a performance guarantee for other hardware or maximum-sized castles.

Network tests use separate local processes; no new two-computer public-internet playtest was performed. Existing UPnP and public-IP behavior was retained.

Fort_14.zip is unchanged, SHA-256 `9F8A866C67EB6CC0919455F504EA98EE0785C398907D762278EBD18E9E547C86`.
