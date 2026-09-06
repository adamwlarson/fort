# Fort 9 — The Endless Expedition

Fort 9 expands the existing game rather than replacing the early campaign. Everyone in a multiplayer session must use this version. **Sessions are still not saved**: leaving the host ends the expedition and its progression.

## Longer progression

There are now **eight hearth tiers**. The two familiar early upgrades still unlock Rustscar/Elderwood and Stormglass/Frostvein. Each upgrade to tiers 4–8 reveals one of five new biomes, shuffled without repeats for that run. The host's seed synchronizes the same terrain, resource types and positions for late joiners.

| Hearth | Exploration radius | Build radius | Daylight |
| --- | ---: | ---: | ---: |
| 1 | 73m | 23m | 150s |
| 2 | 153m | 65m | 180s |
| 3 | 243m | 115m | 210s |
| 4 | 323m | 160m | 240s |
| 5 | 403m | 205m | 270s |
| 6 | 483m | 250m | 300s |
| 7 | 563m | 295m | 330s |
| 8 | 643m | 340m | 360s |

Each upgrade adds 500 maximum hearth health, restores 500 health and immediately adds 30 seconds to the current day. Solo retains its extra 30 seconds on the opening day. The maximum map is 1,286m across with 594 harvest nodes. Every tier adds 72 nodes; the existing five resource currencies remain in use.

New biomes:

- **Amberwood:** golden broadleaf groves; mostly timber, plus crystal and iron.
- **Mycelium Hollow:** giant violet mushrooms and luminous gills; aether, crystal and timber.
- **Cinder Wastes:** basalt columns with glowing seams; iron, stone and aether.
- **Glacier Reach:** pale ice spires; crystal, iron and stone.
- **Ancient Gardens:** vine-covered stone arches; aether, timber, stone and crystal.

The new regions include textured ground, travel lanes, instanced undergrowth, biome landmarks and obstacle collision. They are surface exploration zones, not separate dungeon levels.

Tier 4 costs 125 wood, 105 stone, 26 crystal, 30 iron and 12 aether. Each subsequent upgrade adds 35 wood, 30 stone, 8 crystal, 25 iron and 12 aether to that recipe. U shows the exact shared cost before purchase.

Nights continue indefinitely. Their base duration is `85 + 5*min(night-1,29) + 15*(hearth-1)` seconds. At tiers 4–8 the minimum is raised when needed to allow slow enemies to travel from beyond the build perimeter, plus a reinforcement window. Threat allowances continue growing beyond night ten, but the 100-active-raider ceiling and solo/co-op specialist limits remain. Long-run human balance and low-end performance still need playtesting.

## Bosses, enemies and day events

Every tenth **night** brings a **Runeforged Colossus**, with a warning during the preceding day. This giant approaches buildings, telegraphs a 6m area slam for 1.8 seconds, resists knockback, and does not vanish at dawn. Only one Colossus can be active at once. Its health scales with crew, hearth tier and milestone number.

Defeating it awards 25 shared iron, 12 aether, 10 crystal, and unlocks the Dawnbreaker weapon for the crew, including later joiners. Repeated death requests cannot repeat the reward. The expedition continues to night 11, 20, 30 and beyond rather than displaying victory after night ten.

New raiders join the weighted assault pool:

- **Prowler**, from night 6: a fast, spined beast that chases dwarves.
- **Shieldguard**, from night 8: tougher infantry with a tower shield; resists ordinary automatic-tower damage and displacement. Breach Picks and Sunlances counter it.
- **Hexer**, from night 12: a staff-carrying support enemy that heals wounded enemies within 8m every seven seconds. Prioritize it before its allies recover.

After the first day, each dawn has a 55% chance of one event:

- **Bountiful Dawn:** doubles player and pet gathering yields until dusk, respecting resource availability and pack limits.
- **Supply Caravan:** a free, one-use shared-supplies chest northeast of the hearth. Approach and press E; it disappears at dusk if unclaimed.
- **Warband Scouts:** warns of a small eastern raiding party arriving after 30 seconds, during daylight.

## Workshop gathering pets

Press E at the workshop and select **Gathering Pets**. Up to **three pets are shared by the entire crew**, not three per player.

| Pet | Requirement | Shared recruitment cost | Pack |
| --- | --- | --- | ---: |
| Pack Badger | Hearth 1 | 35 wood, 10 stone, 4 crystal | 8 |
| Copper Mole | Hearth 2 | 30 wood, 20 stone, 6 crystal | 10 |
| Grove Sprite | Hearth 3 | 20 wood, 12 crystal, 8 aether | 6 |

Choose **wood, stone, crystal, iron, aether or REST** independently for each pet. Iron requires Hearth 2; aether requires Hearth 3. Pets visibly travel to real harvest nodes, consume their resources, carry the gathered material, and return to deposit it into the shared stockpile. Crystal deliveries also count toward shared travel unlocks. Assignment changes send a pet home with its current pack before beginning its next job.

Pets gather during daylight and return home at night. They steer around scenery, jump low obstacles, and use a visible magical recall if trapped or fallen through terrain. Recall preserves the existing pack; it does not generate extra resources. Temporarily unreachable nodes are skipped before retrying. Companions are noncombat helpers and are not enemy damage targets.

To change your pet lineup, set a pet to REST, wait for it to return home empty, then select **RELEASE**. This frees its slot without a recruitment refund. Pet positions, packs and assignments are server-authoritative and synchronized to other players.

## Seven new weapons

The workshop now offers twelve weapons across four arsenal pages. All have Blender models attached to the dwarf's hand and working attack animations. Existing weapons and relics remain.

| Weapon | Hearth | Shared recipe | Role |
| --- | ---: | --- | --- |
| Ironbark Cleaver | 2 | 18 wood, 14 iron, 3 crystal | Fast sweeps, up to six targets |
| Breach Pick | 3 | 12 wood, 24 iron, 6 crystal | Heavy single-target hit; bonus against Shieldguards |
| Mountainfall Maul | 4 | 24 wood, 32 stone, 32 iron, 8 aether | Slow, huge sweep with strong knockback |
| Scattershot Cannon | 4 | 18 wood, 34 iron, 8 crystal, 10 aether | Short-range shell with a 3m impact burst |
| Farwatch Longrifle | 5 | 25 wood, 42 iron, 12 crystal, 16 aether | 48m precision shot, high damage and slower cadence |
| Stormcaller Staff | 6 | 30 wood, 20 iron, 25 crystal, 28 aether | Lightning leaps through four nearby targets |
| Dawnbreaker | 7, or boss reward | 28 wood, 48 iron, 24 crystal, 35 aether | Long, powerful rune-blade sweep |

Ranged weapons use the existing RMB aim and projected impact cursor, with reusable ammunition. Weapon reinforcement now reaches **level 8**, requiring the matching hearth tier. Each level still adds 25% of base damage; costs increase beyond level three.

Hammers now apply a physical knockback impulse over several frames, checked against world collision. The Hearthbreaker and Mountainfall Maul visibly shove lighter enemies; armored enemies and giants resist displacement. Swings cannot damage enemies through intervening walls. Armed Sapper warnings and explosions follow the enemy when it is pushed.

## Three new towers and higher reinforcement

B opens ten build cards. Use **1–9 and 0** to select them; Q rotates and click places a construction project.

| Key / tower | Hearth | Wood / stone / crystal / iron / aether | Behavior |
| --- | ---: | --- | --- |
| 8 / Embercoil | 4 | 20 / 25 / 8 / 28 / 10 | Scorches all enemies in its close-range radius |
| 9 / Gravity Well | 5 | 12 / 40 / 15 / 32 / 22 | Pulls and slows enemies; combines with area-damage towers |
| 0 / Sunlance | 6 | 30 / 35 / 20 / 50 / 35 | Long-range beam bypasses Shieldguard armor |

Permanent defenses now reinforce through **level 8** using G, then held E to complete the work. The matching hearth tier is required. Each level adds 65% base health and 40% base effectiveness; existing damage remains. Upgrade costs rise each level. Earlier armor/crown visuals remain, with additional visible ranks for higher tiers. Temporary Engineer turrets cannot be upgraded or salvaged.

## Building salvage and safe regrowth

Stand within 4m of a completed building and press **G**. The **SALVAGE** button previews the refund; click again to confirm removal. This is available in daylight, with no enemy within 12m and nobody mounted on that building.

Salvage returns **50% of the materials actually paid**, including completed upgrades, multiplied by the building's remaining-health fraction and rounded down. Engineer discounts are respected. Free temporary towers cannot become a source of refunds. Simultaneous/duplicate requests cannot pay twice. Unfinished projects retain their previous cancellation/refund rules.

Depleted trees and other resources now defer respawning when a built structure or construction site occupies their footprint. Rotated walls are checked in their local orientation. Regrowth resumes after the obstruction is removed, with a short recheck delay. Clear resources can still regrow nearby; they should no longer appear inside your walls.

## Verification and limits

The release validation passed **14 headless gameplay/asset suites, 12 rendered checks (including the swarm stress test), Windows export and eight four-process multiplayer suites against the exported build**. The versioned ZIP's executable is checked against the exported executable by SHA-256.

The final 100-active-enemy stress scene averaged 42.8 FPS with a 161.3ms worst frame on this machine (RTX 5090, Compatibility renderer). That is a synthetic stress result, not a 60-FPS guarantee; dense late-game battles still need performance optimization and testing on lower-end hardware.

New automated tests cover eight-tier expansion and seeded layouts, physical pet navigation/gathering/delivery, recall and assignments, exactly-once salvage, obstacle-safe knockback, actual damage/effects for all seven weapons, new tower behavior, enemy healing/armor, day events, boss persistence/rewards and late joins. A new four-process network suite covers the expanded frontier, shared pets, duplicate recruitment and salvage, and milestone-boss synchronization.

These are scripted checks, not human win-rate measurements or proof of two-PC LAN/WAN connectivity. The game remains host-run IP/UDP multiplayer without a relay, host migration, or saved expeditions. Save/resume would be the next important addition for long sessions.

There are 22 new Blender-authored GLBs, with editable source libraries and `art_source/model_expedition9.py`. The previously open tree scene was preserved. Blender is not needed to play.
