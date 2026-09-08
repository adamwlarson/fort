# Fort 19 validation

Environment: Windows, Godot 4.5.2, OpenGL Compatibility / RTX 5090, 2026-09-06.

## New checks

`escape19_test.gd` injects real Escape/Enter events and checks menu opening, saving a readable checkpoint, nested closing, build-preview cancellation, camera restoration, downed-player access, FPS toggle persistence and restoring the preference in another expedition. Tests use isolated settings/save paths.

`terrain19_test.gd` checks:

- Deterministic ridge placement; 100 seeds preserve encounter clearings.
- Actual dwarf-sized physics traversal through the cave and up the summit slope without jumping.
- Ray-tested cavern walls, ceiling and eight-metre summit.
- Nonempty collision for all 28 audited solid asset keys; ray-tested arch opening, pillars, overhead stones and chest body.
- Mineral depletion/respawn disables/restores collision.
- Pet gathering accepts its target deposit but rejects a wall in front of it.
- The campfire model's lowest world-space vertex matches the castle floor.
- Old positions inside the new hill are placed on its surface, while cave occupants stay inside.
- A legacy save with a defense occupying the new terrain retains its building and flat layout; the compatibility flag reaches full network state.

Inspected rendered ridge, cavern and hearth captures in `build/terrain19_*.png`. The hill remains a contained terrain experiment, not a full-world terrain conversion.

The save multiplayer driver additionally checks seeded ridge reconstruction, saved depleted deposits and their disabled collision on joining clients, and independent host/client FPS preferences.

## Regression fixture changes

The old ballista targeting fixture now uses a flat outer-ring gap, rather than a location that can be inside the ridge. The dragon breath fixture runs in its clear apron instead of firing through newly solid hoard geometry. The forestry canopy count excludes non-tree terrain deposits. These changes preserve the original combat and forestry assertions.

## Release status

The first complete pass finished with `ART_PASS_CHECKS_OK`: all 27 headless suites, 24 rendered suites, Windows export and 15 packaged four-process network scenarios passed. Direct exported-executable Escape/FPS and terrain tests also passed.

The stress fixture exposed a performance regression with fully triangulated solid props. A controlled 100-enemy probe measured 19.6 / 23.4 FPS with that collision enabled versus 43.4 FPS disabled. Replacing solid-object collision with simplified convex hulls reduced the remaining triangle-collision count from 1,554,068 to 163,408 across 753 initially registered prop bodies. The optimized enabled runs measured 37.4 / 39.2 FPS versus 42.6 FPS disabled. Hollow architecture retains its triangle-shaped openings. These are short local stress measurements, not a guarantee for other hardware or maximum-size castles.

The optimized release also completed `tests/run_art_pass.ps1 -Render -Export -Network` with `ART_PASS_CHECKS_OK`: 27 headless suites, 24 rendered suites and all 15 packaged four-process scenarios passed again. Direct tests of the final exported executable passed for Escape/FPS and terrain/collision/legacy-save compatibility. Multiplayer checks use four local processes; this is not a new two-computer public-internet playtest.

The final standard 100-enemy fixture recorded 30.6 average FPS and 145.432 ms worst frame, including its initial frames. The warmed-up controlled measurements above are a separate fixture and should not be treated as the same metric.

Final executable: 124,492,184 bytes, version 0.19.0, SHA-256 `94BD0D900943325F0D1921774C22A9E85857E3A8CA555382C0AE7AFA0F26E773`.

`tests/package_version.ps1 -Version 19` verified the source, copied and ZIP-contained executable hashes. `Fort_19.zip` is 60,293,453 bytes; SHA-256 `8522277AE9E5D090EC26E233633BC53CE320AA9E750F2484D47A4C3956F2C6C0`.

`Fort_18.zip` remains unchanged: SHA-256 `007680C83EFC5567402A75ACE36A12B33248F7FCAE55D57F059E4EBE09D1C57E`.
