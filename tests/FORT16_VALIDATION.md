# Fort 16 validation

Validated on 2026-09-06 with Godot 4.5.2, Windows OpenGL Compatibility, RTX 5090.

## Readability coverage

`readability16_test.gd` passed headless and rendered. It checks all five shared-stock icon counters and their layout, persistent castle guidance for blocked/ready, unfunded and funded blueprints, real harvest events and unchanged quantities, nearby resource badges, resource/gear receipts, actual chest reward versus lock cost, duplicate opening protection, caravan resource filtering, damaged-only enemy bars, and full-health bar removal.

Inspected screenshots: `build/readability16_castle.png`, `build/readability16_resources.png`, `build/readability16_loot.png`, and `build/readability16_enemies.png`. Visual inspection caught and corrected a PanelContainer layout issue hiding the day display and overlap between harvest gain text and resource labels. Enemy screenshots show the damaged raider's bar and no bar over the full-health brute.

The source four-process `readability_network_driver` passed. It verifies a remote dwarf opening a chest twice produces one receipt on every peer; gross reward and separate cost agree with shared stock; nearby peers receive a harvest gain; damaged enemy HP replicates; and full snapshots do not replay reward feedback. An initial test teardown race was fixed by keeping the host connected until client assertions finish.

## Regression and packaging

The final `tests/run_art_pass.ps1 -Render -Export -Network` run completed with `ART_PASS_CHECKS_OK`: 23 headless suites, 21 rendered suites, Windows export, and all 14 packaged four-process multiplayer scenarios passed. The packaged readability scenario verified the same reward and health replication behavior as the source test.

The 100-enemy stress fixture passed at 35.2 average FPS, 192.346 ms worst frame on this machine. This fixture does not specifically damage every enemy and is not a maximum-visible-health-bar benchmark or a performance guarantee for other hardware.

Network checks use four separate local processes, not four physical computers or a new public-internet playtest. Existing hosting behavior is unchanged.

`tests/package_version.ps1 -Version 16` verified that the source, copied, and ZIP-contained executable hashes agree. Windows product version: 0.16.0; executable size: 124,471,616 bytes. Prior version folders and archives were retained.

Fort_15.zip remains unchanged: SHA-256 `D971A6C0654F3914D22520A79FC3E6F2738AEBEA56BB7651C7F0A9196C04B4A5`.

Fort_16.zip is 60,270,387 bytes; SHA-256 `1E89DBD161543E61E457FF6E93535326DF793470A217385AC71099081E9797C2`.
