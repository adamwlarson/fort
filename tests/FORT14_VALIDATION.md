# Fort 14 validation

Validated on 2026-09-06 with Godot 4.5.2 on Windows, OpenGL Compatibility / RTX 5090.

The final `tests/run_art_pass.ps1 -Render -Export -Network` run completed with `ART_PASS_CHECKS_OK`:

- 21 headless suites and 19 rendered suites passed.
- 12 four-process multiplayer scenarios passed against the exported `build/Fort.exe` (version 0.14.0): base networking, weapons, lobby, progression, construction, frontier, balance, expedition, wilderness, forestry, castle and save/load.
- The new save/load scenario reopens a disk checkpoint, joins three clients with different network IDs, restores class-based health/inventory/equipment/location/view/fuel, rejects client saves, and finishes a partially donated castle wing without duplicate charges.
- Round-trip tests cover the map seed, hearth tier, midnight clock, raid budget and RNG/history, enemies, partial castle donations, equipment and research, pets and resources, claimed treasure and boss history.
- Additional edge checks restore a completed upper storey, sixteen damaged/skinned curtain walls, research, an unfinished tower upgrade and its refund ledger. A disconnected builder regains cancellation authority when returning to the same class. Saved pet cargo deposits exactly once.
- Recovery checks cover checksum/format validation, malformed dwarf data, invalid slot paths, backup rotation, corrupt-primary fallback, occupied-slot confirmation, preserving a valid backup while replacing a damaged primary, interrupted temporary writes, and failed save-and-exit/window-close attempts leaving the world open. Ended worlds cannot overwrite live checkpoints.
- Dawn autosave, host save/exit and all five load slots pass. Tests use isolated `build/` directories, not the player's real save folder.
- Rendered save, load and camp menus were visually inspected. A load-time lighting interpolation overshoot was fixed and regression-tested.

Screenshots: `build/save14_menu.png`, `build/save14_load.png`, `build/save14_camp.png`.

The existing 100-enemy stress scene passed at 38.2 average FPS, with a 183.95ms worst frame on this machine. This is a stress measurement, not a performance guarantee for other hardware or maximum-sized castles.

Networking verification used separate processes on this machine. No new two-computer/public-internet playtest was performed in this pass; the existing UPnP/public-IP connection flow remains unchanged.

Fort_13.zip remains unchanged: SHA-256 `10E55198AC9FF1128626D3098BF62E2844CCE5ABF780DAF8BF1EB069CEF4F165`.

Fort_12.zip remains unchanged: SHA-256 `1D94DAFF8E10205BCC4DB582273F171F902A3966D61946005D1AE93FB5205EF5`.
