# Fort 7 — Towers, Firepower and Frontier Villages

Extract Fort_7 and run Fort.exe. Every player must use version 7. Older version folders and ZIPs are preserved. Hosting remains IP-based with a chosen UDP port; the game does not change firewall or router settings.

## Tower clarity

- New Blender-modeled watchtower: octagonal stone footing, braced timber, armored parapets, hanging standard and rotating crossbow. The stairs and their collision ramp are removed.
- Level 2 defenses gain substantial iron fittings and gold rank markings. Level 3 adds aether crystal finials and a pennant; watchtower crystals rise above its platform.
- Placement shows the selected tower's range. Stand within 4m of an existing tower, or open its G upgrade panel, to inspect its current range without permanently cluttering the world.
- Tower ranges, in meters, at levels 1 / 2 / 3: Watchtower 17 / 19 / 21; Ballista 35 / 37 / 39; Mender 7 / 8 / 9; Storm Spire 22 / 24 / 26; Frost Mortar 28 / 30 / 32. Rings show distance coverage, not line-of-sight guarantees.
- Mender healing uses the same range for dwarves, buildings and the hearth. Green motes travel to damaged targets while healing; fully healthy targets do not generate idle healing spam. Downed dwarves still need rescuing.
- Mounted ballistae track both horizontal aim and elevation continuously, including on other players' screens. Upgraded defense visuals and aim restore for late joiners.

## New siege threats

- Cinderlobbers join raids from night 3. These mortar-carrying goblins stop at range and lob delayed explosive shells at defenses or the hearth. Their landing circle gives roughly one second to react.
- Bombwings join from night 4. These animated bat-like bomb carriers bypass walls and drop bombs on defenses, favoring towers. Orange landing circles warn for 1.2 seconds. Crossbows, Repeaters and towers can intercept them.
- Sappers now actually explode: an oversized red powder charge, tall glowing-colored fuse tip, hazard markings, a fuse sound and warning circle make them recognizable. They favor work sites and towers, stop to light a 1.6-second fuse, and damage nearby structures when it expires. Kill the Sapper to disarm it; stunning a lit fuse does not stop the countdown.
- Bomb damage is resolved by the host after impact, not instantly when the visual projectile launches. No automatic damage inflation was added to the existing hearth-tier health multiplier.

## Weapons and reinforcement

E at the workshop opens Field Tools and the new Frontier Arsenal tab. C cycles owned weapons. All weapons use reusable ammunition where applicable; crafting and upgrades spend the crew's deposited stockpile, but belong to the purchasing dwarf for this run.

| Weapon | Shared recipe | Requirement | Role |
| --- | --- | --- | --- |
| Ironthorn Pike | 16 wood, 2 crystal, 10 iron | Hearth 2 | 5.2m narrow thrust; up to 3 targets; 48 base damage; blocked by walls |
| Aether Repeater | 18 wood, 6 crystal, 16 iron, 6 aether | Hearth 3 | 29m rapid bolts; 34 base damage; 0.42s cadence; RMB aim while moving |

Every owned weapon can be reinforced at the workshop. Level 2 requires Hearth 2, 8 iron and 3 crystals, and adds 25% base damage. Level 3 requires Hearth 3, 16 iron, 6 aether and 5 crystals, reaching +50% base damage. Upgrades have visible grip markings and a +1 / +2 HUD suffix. Existing rare relic bonuses remain compatible. Duplicate or stale purchase requests cannot charge twice or downgrade equipment.

## Explore and survive

- Three guarded settlements join the six existing treasure sites: Bramblewick Village in the western Marchlands, Coppercross Hamlet in Rustscar, and Starfall Refuge in the outer northwestern frontier.
- Each has Blender-authored timber-and-plaster houses with open doorways, interior supplies, a well and a guarded chest in its square. Defeat the guards, then spend 2 shared crystals with E to claim shared supplies. These are abandoned exploration sites, not NPC quest hubs.
- Daytime remains 150 seconds. Night 1 starts at 85 seconds, each later night adds 5 seconds, and each hearth upgrade adds 15 seconds to future nights. Night 10 with Hearth 3 lasts 160 seconds. There are still ten nights and the existing 100-active-raider cap.

## Testing and limits

Release validation passed: all eleven gameplay/asset regression scripts, ten rendered reviews including the 100-raider stress scene, Windows export, and all six four-process network suites using the exported executable. The staged 100-raider scene averaged 46 FPS with a 112.3ms worst frame on this machine; this is a stress snapshot, not a guarantee for other PCs or an entire ten-night session.

The project includes a Fort 7 regression test covering art loading/animation, tower pivots and ranges, Mender healing, delayed explosions and disarming, weapon reinforcement, duplicate requests, village loot and open doorways. The four-process frontier test covers remote aiming, late-join upgrade visuals, weapon crafting/reinforcement and ranged building damage.

This is still a host-run lobby without a relay or host migration. Sessions are not saved. Local multi-process network tests do not prove connectivity between two physical PCs or over the internet. See NETWORK_HELP.md; use a firewall allowance for this version's exact executable path if needed.

Ten new Blender models and editable sculpt sources are included in the project (64 Fort GLB assets total). Blender is not required to play.
