# Fort 13 validation

Validated on 2026-09-06 with Godot 4.5.2, Windows, OpenGL Compatibility / RTX 5090.

`tests/run_art_pass.ps1 -Render -Export -Network` completed with `ART_PASS_CHECKS_OK`:

- 19 headless suites, including castle construction and all updated character/enemy animation assets.
- 17 rendered suites, including stair movement, castle services, model galleries and the existing gameplay/UI reviews.
- 11 four-process multiplayer scenarios against `build/Fort.exe`: base networking, weapons, lobby, progression, construction, frontier, balance, expedition, wilderness, forestry, castle.
- Castle multiplayer verifies partially supplied late-join state, concurrent donations, client hands-on construction, exact material accounting and all sixteen initial curtain-wall models on every peer.
- Additional final rendered castle check builds ten completed rooms across three storeys, with 160 real curtain-wall defenses. Player ascent/descent, alternating third-floor stairs, ground attacker entry, merchant trades, lodges, research, cancellation and elevated Engineer turrets pass.
- Swarm stress: 100 active enemies, 38.6 average FPS, 137.617ms worst frame on this machine. This is a stress measurement, not a performance guarantee on other hardware or a maximum-sized castle benchmark.

Visual artifacts: `build/cast13_heroes.png`, `build/cast13_heroes_attack.png`, `build/cast13_enemies_*.png`, `build/castle13_overview.png`, `build/castle13_detail.png`, `build/castle13_menu.png`.

Network tests use separate local processes. No new two-PC public-internet test was performed in this pass; the existing UPnP/public-IP connection flow is retained and its diagnostics/lobby regressions pass.

Fort_12.zip remains unchanged with SHA256 `1D94DAFF8E10205BCC4DB582273F171F902A3966D61946005D1AE93FB5205EF5`.
