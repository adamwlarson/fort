# Fort 24 validation

Windows, Godot 4.5.2, OpenGL Compatibility, RTX 5090. Blender 5.2.1 LTS. September 11, 2026.

## Automated and visual coverage

`tests/run_art_pass.ps1 -Render -Export` completed with `ART_PASS_CHECKS_OK`: all 35 headless suites, 31 rendered suites and the Windows release export passed. Two additional fixtures passed separately and are now included in the runner for future runs (36 headless / 32 rendered): `crew24_role_test.gd` and `gate24_review.gd`.

- `gate24_test.gd`: actual paid placement and cooperative construction; castle entrance snapping and clearance; authored moving mechanism, collision, eight reinforcement groups, operator revisions, held versus fresh E input, dwarf/downed/pet/enemy obstruction, dusk/manual operation, save state, UI pagination, siege targeting and salvage.
- `gate24_edge_test.gd`: physical character capsule traversal/stopping; frame construction safety; partial, closed and moving gate disk-save restoration; old snapshot ordering; open-gate navigation; upper-tier geometry and physics-based low-ceiling rejection.
- `crew24_test.gd`: eight-slot lobby and safe spawn pads, four shared ability roles, distinct coordinated variant palettes, authored skeletal animations, carrying capacity, extended balance curves, eight-player HUD, all seven co-located teammate minimap markers, eight independent saved inventories restored under new peer IDs, compatibility with original four-character saves, rejection of a ninth saved slot.
- `crew24_role_test.gd`: real Copper Vanguard slam damage/stun, Amethyst Warden heal/haste, Jade Engineer field turret, repair and construction bonus, Dusk Scout dash and three-unit harvest. An initial repair fixture incorrectly expected healing beyond the temporary turret's maximum; it was corrected to test with sufficient missing HP. No repair gameplay change was necessary.

Actual rendered gate worksite/open/closed/upgraded/settings views, eight-character lineup and lobby were inspected. `gate24_review.gd` renders the gate fitted to existing finished curtain walls in daylight and at night; the daytime join and open nighttime lantern view were inspected. This caught and corrected an old 1-4 crew legend in the minimap. The export includes the corrected 1-8 legend.

The eight-character save/reload render fixture initially freed the restored world before its first rendered frame, producing two OpenGL texture teardown warnings. Rendering the restored world before teardown resolved the warnings; the final complete runner reported no errors. This is not claimed as an engine leak fix.

The 100-enemy stress fixture passed at 41.6 average FPS / 187.686 ms worst frame. This short, uncontrolled run is not an eight-PC performance test or a 60 FPS guarantee. Fort 23 recorded 42.2 FPS / 138.564 ms on its run; the difference has not been causally attributed.

## Eight-player networking

Both source and exported executable eight-player scenarios passed, including a ninth connection probe. One host plus seven local clients use custom UDP port 24768 and production snapshot broadcasting. The scenario verifies unique character allocation, all seven world-readiness handshakes, exact +36 shared wood from eight packs despite repeated requests, simultaneous normal E-key gate commands accepting one revision, delivery of 100 enemies and all eight dwarves, every client's seven teammate markers, disk saves of all eight inventories, eighth-player disconnect/rejoin with preserved slot/health/pack, and matching eight-player raid pressure. The ninth connection cannot enter a full lobby or world. Nine processes reported success.

Source four-player gatehouse networking also passed. It exercises paid late-join construction, collision/animation, simultaneous controls, remote-player obstruction, dusk closure, reinforcement, checkpoint state and exact salvage refunds. A cross-channel ordering issue discovered during development was fixed by adding a monotonic gate-state sequence alongside the operation revision.

Three repeated source four-player forestry checks each passed with exactly 24 timber total. The older intermittent Fort 21 forestry discrepancy was not reproduced or root-caused; it is not claimed fixed.

All six additional packaged four-player scenarios passed: gatehouse, core multiplayer, save/load, siege/minimap indicators, cooperative defense construction and castle wings/curtain walls. All 24 participating processes reported success, alongside the nine successful eight-player/capacity processes above. These are local multi-process checks, not a public-IP connectivity test.

## Art provenance and limits

The built-in image generator (not the CLI fallback) produced `art_source/concepts/gatehouse24_concept.png`; the exact prompt and provenance are in `art_source/concepts/gatehouse24_prompt.md`. That reference guided the fitted ashlar, bronze, heraldry, banners and mechanical silhouette. The finished in-game assets are Blender-authored 3D geometry, painted material/normal textures and named moving parts, not the concept bitmap.

`art_source/model_gatehouse24.py` regenerates the gate and three worksite stages. Editable source: `art_source/blender/gatehouse24_sculpt.blend`. Game assets: `assets/models/fort/gatehouse*.glb`; texture sources: `assets/textures/gatehouse24/`. The unrelated dirty interactive Blender scene was left untouched; generation used a separate background process. Static meshes are batched by parent/material, and higher-level reinforcement groups are hidden until earned.

The four new dwarf choices reuse the finished animated role models with distinct clothing/headwear/beard palettes; they are not four new abilities. Connected walkable battlements remain a later feature. Gate safety prevents crushing by keeping moving doors non-solid and making occupied closure reopen; low headroom or blocked footprints still prevent placement.

The original one-to-four-player balance curve is unchanged; raids, camp guards and wilderness bosses now extend to eight. Active raid enemies remain capped at 100, with four approach fronts. Three pets remain shared across the crew. Extended eight-human balance, latency/loss, and real separate-PC LAN/WAN testing remain necessary. Everyone must use Fort 24; this is a development build, not a commercial-release certification.

No firewall/router configuration was changed, and no GitHub commit or push was authorized for this pass. Existing dirty Fort 20-23 work and all older numbered releases are preserved.

## Verified release package

`tests/package_version.ps1 -Version 24` completed with `VERSION_24_ARCHIVE_VERIFIED`. Source, numbered-folder and ZIP-contained executable hashes match; executable file version is 0.24.0. `git diff --check` passed.

- `build/Fort_24.zip`: 67,196,537 bytes; SHA256 `4CD6D577FEED26B2F8BDC420D631176838948414F9DBB436325C87BDCF270D79`.
- `build/Fort_24/Fort.exe`: 131,558,560 bytes; SHA256 `BDFFB9427C4C37D9A16946994E9B0E8BD0990912C1C54887BB2A8880660FA18B`.

Prior archives were rechecked unchanged: Fort 23 SHA256 `B5FA3C4E525238143EF6038CF9000583F9946CBD7412165630DD385ED4AC908B`, Fort 22 SHA256 `D370EE7E518B80AA6D994AE23100D860FAB7D6E0310082BAB7D853A1E0BA6C88`. No old release was overwritten.
