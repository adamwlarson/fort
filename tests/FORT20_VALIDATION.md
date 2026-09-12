# Fort 20 validation

Godot 4.5.2, Windows, September 7, 2026.

- `tests/run_art_pass.ps1 -Export`: all 28 headless suites passed, plus import and export (`ART_PASS_CHECKS_OK`). This includes existing castle stairs/traversal, terrain, save/load, clearance, combat and progression coverage.
- `recovery20_test.gd`: passed headless and rendered. Checks walking off the campfire without jumping from three starting positions at hearth tier 8; decorative rune collision; low-ledge traversal; ordinary wall blocking; embedded-player detection; real Escape/Enter recovery; clear same-storey landing; unchanged health/pack/no new protection; cooldown; downed recovery; validated automatic requests; and verified hearth fallback.
- Staircase reproduction: a completed stairwell alone reports 1/4; an unfinished fourth wing reports 3/4; four finished wings enable upstairs at hearth tier 1; the upstairs blueprint can be supplied and hand-built. Tests check both the dropdown progress and explanation adjacent to the button.
- The final compact architect layout was rerun rendered after removing duplicated text. Screenshots inspected: `build/recovery20_menu.png`, `build/recovery20_upstairs_locked.png`, `build/recovery20_upstairs_ready.png`.
- `tests/run_network.ps1 -Driver recovery_network_driver`: host plus three clients passed. Repeated with `-Packaged` against the final exported executable: all four passed. Verified owner-only recovery, replicated clear destination, cooldown, no healing/protection/pack clearing, and rejection of a forged destination/player target in the request payload.

The rendered movement test pins camera yaw so incidental desktop mouse input cannot steer its scripted walking path. An early assertion incorrectly expected the dwarf to walk through the stockpile beyond the fire; the corrected check requires leaving the fire and reaching the surrounding floor.

The exact player-reported campfire trap was not reproduced in the initial Fort 19 probe. Fort 20 reduces likely snag points and provides checked manual recovery rather than claiming all world geometry is now snag-free. Network verification uses four local processes, not a new public-internet test. No save-format change; tests use `--fort-test` isolation.
