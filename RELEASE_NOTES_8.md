# Fort 8 — Crew balance

This pass targets an easier solo opening and meaningful pressure for every added dwarf, without raising crafting costs or weakening personal weapons. All Fort 7 content remains.

## Raid rules

- Nights use finite threat allowances instead of endlessly refilling spawn groups. Each extra dwarf now matters: allowances scale by **1 / 1.75 / 2.6 / 3.5** for one through four connected players. Downed players count. Joining or leaving changes the next assault, never enemies already alive.
- Nights 1–3 have three assaults; nights 4–10 have four. Release windows are separated by repair breaks. Directions appear in the objective and as orange inward arrows on the north-up minimap. Existing enemies still attack during breaks: these are reinforcement pauses, not guaranteed safety.
- Early solo nights approach from one side; solo nights 6–10 use two sides. Two, three and four dwarves defend two, three and four sides. The main side changes each night.
- Strong enemies cost more allowance: Raider 10, EmberRunner 13, Ashwing 18, Sapper 25, Brute/Cinderlobber 30, Bombwing 35. Existing health and damage remain unchanged.
- Simultaneous Sappers are capped at the crew size. Cinderlobbers and Bombwings share a combined cap: solo 1 through night 6, then 2; co-op 3 / 4 / 5. Brutes and Ashwings also have separate concurrency caps. Camp guards do not consume raid slots.
- Active raid caps on nights 1 / 5 / 10: solo **22 / 36 / 54**, duo **34 / 50 / 70**, trio **46 / 64 / 87**, full crew **58 / 78 / 100**. Excess allowance is discarded when an assault closes, not unleashed as a delayed backlog.
- Hearth upgrades add only 10% base threat per tier (tier 3 = 120%). Night duration stays 85 seconds on night 1, +5 seconds each later night, +15 seconds per hearth upgrade. Final reinforcement cutoff reserves travel time for slow enemies, so extra travel time is not itself a source of unlimited enemies.

## Solo and exploration

- A solo expedition starts with a 180-second first day instead of 150. Later days remain 150 seconds; Enter still votes to start early.
- When playing alone, construction and upgrades receive 25% more work per hammer stroke. A Watchtower takes 8 strokes instead of 10, or 4 instead of 5 for the Engineer. Co-op construction rates and material costs are unchanged.
- Once per night, a solo knockdown triggers an 8-second rescue instead of 18. Later knockdowns that night take 18 seconds. The pack is retained as before. This benefit requires both a one-player roster and a solo-scaled assault; leaving a four-player fight does not immediately grant a fast rescue.
- A camp locks its difficulty when first activated: 1 / 2 / 3 / 4 escorts plus a chief, with chief health at 65% / 100% / 135% / 170% of the old value. Escort health rises 8% per additional dwarf. Already-activated camps never gain health or respawn guards because someone joins. Treasure remains a shared reward.
- Engineer field turrets, Mender stacking, gathering, shared starting supplies, equipment and recipe prices are unchanged in this pass.

## Tuning and diagnostics

The server emits a `FORT_BALANCE` JSON record at dawn or defeat in the Godot log (`%APPDATA%/Godot/app_userdata/Fort/logs/godot.log`). Records include spawned/killed enemies, peak raid count, crew, knockdowns, fast rescues, hearth/building damage, repair wood, actual Mender healing, and player/permanent-tower/field-turret damage. Damage and healing are clamped to the health actually lost or restored. These reports help identify dominant defenses without prematurely nerfing solo play.

Threat formula: `(70 + 18*n + 4*n*n) * 10 * crew_multiplier * (1 + 0.1*(hearth-1))`, where `n = night-1`. This is an allowance, not a promised enemy count: enemy mix, concurrency limits and expired release windows change actual spawns.

Automated validation includes all 120 night/hearth/crew combinations, 72 deterministic director traces with no turnover or a fixed 20-second enemy lifetime, all four solo construction roles, rescue refresh/limits, camp scaling, roster changes, stale snapshots, and multiplayer state replication. Synthetic lifetime traces test scheduling and safety limits; they are **not human playtests or measured win rates**. Further solo and four-person play sessions are needed to tune the feel, especially late-game tower-heavy forts.

Release checks passed: 12 gameplay/asset suites, 11 rendered reviews, Windows export, and all seven four-process network suites against the exported executable. The staged 100-raider scene averaged 41 FPS with a 127.2ms worst frame on this machine (RTX 5090); late-game performance still needs optimization and this is not a guarantee for other hardware. The assault and breather HUD captures were visually reviewed.

Everyone must use Fort 8. IP/UDP hosting is unchanged; packaged loopback tests do not establish connectivity between two physical PCs or through an internet router.
