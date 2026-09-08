# Fort — Hold the Hearth

A playable Godot co-op survival build for one to four dwarves. Gather by day, return resources to a shared stockpile, recruit gathering pets, explore new biomes, and keep the hearth alive through endless night raids.

## Play

Fort 19 also grounds the hearth fire, fills collision gaps on solid world props, and adds **Hollowback Ridge at hearth level 2**: a lantern-lit walk-through cavern with crystal and a climbable summit with iron. Find its trail sign beyond the original ward; its direction varies by expedition seed. The starting castle remains on flat ground.

Fort 19 fixes the Escape-key binding so the camp/save menu opens correctly. Press Esc → Save expedition as host, or enable Show FPS counter for a small persistent performance display. If a building preview is active, Esc first cancels it; press again to open the menu. See [RELEASE_NOTES_19.md](RELEASE_NOTES_19.md).

Fort 18 automatically clears trees, rocks and loose scenery when you place a castle wing. Overlapping defenses can be removed with an itemized partial refund to shared stock after confirmation. Hold E at the new sign to supply and build. See [RELEASE_NOTES_18.md](RELEASE_NOTES_18.md) for salvage, safety and persistence details.

Fort 17 lets you **hold E at a castle project sign to supply and build directly from shared stock**, with carried materials covering any shortage. Keep holding E to finish the work; the K-menu funding button is optional. See [RELEASE_NOTES_17.md](RELEASE_NOTES_17.md).

Fort 16 makes gathering and rewards easier to read: RTS-style resource badges and shared-stock icons, floating harvest gains, itemized treasure receipts, and small health bars above damaged enemies. Castle signs now explain locked options and the **plan → supply → hold E to build** sequence. See [RELEASE_NOTES_16.md](RELEASE_NOTES_16.md). Fort 14/15 saves remain supported.

Fort 15 adds castle remodeling, hands-on dismantling, an architect overview camera, detailed room/stair/entrance previews, and clearer project signs. Press **K at a castle sign** and choose **Expand**, **Remodel**, or **Dismantle**. Completed remodeling/demolition returns half the old room's materials; safety checks protect connected wings, supporting floors and workers. See [RELEASE_NOTES_15.md](RELEASE_NOTES_15.md). Fort 14 saves load, but new format-2 saves cannot be reopened in Fort 14—back up the save folder if you want to roll back.

Fort 14 adds host-controlled save/load. Press **Esc → Save expedition** for three manual slots, or **Save & return to title** for an exit checkpoint. Dawn autosaves use a separate slot. On the title screen, select your previous dwarf class and choose **Load expedition** to reopen a host lobby. See [RELEASE_NOTES_14.md](RELEASE_NOTES_14.md) for saved progress, backups and multiplayer rules.

Fort 13 adds a player-built castle: an open raised keep, selectable hand-built wings, resource signposts, damageable curtain walls, and supported upper storeys with stairs. Press **K** at the sign south of the hearth to plan; supply the project and hold **E** to build. Merchant, gathering, research and defensive additions have working services. The four dwarves and all eighteen enemies receive Blender art refinements. See [RELEASE_NOTES_13.md](RELEASE_NOTES_13.md) for recipes, controls and current limits.

Fort 12 adds denser windblown grass, groundcover, eight new foliage models, harvestable biome forests, and redesigned animated ember/frost dragons. Hold E at any standing tree or giant mushroom to harvest it. Amberwood and Mooncaps require Forester's Axe level 2; Starcaps require level 3. Upgrade the axe at the Workshop (T); it does not need to be equipped to gather. See [RELEASE_NOTES_12.md](RELEASE_NOTES_12.md) for species yields and details.

Fort 11 adds 67 wilderness destinations across the eight-tier map: camps, beasts, shrines, ruined observatories, caravan caches and six dragon roosts. Discover sites, defeat their guardians and press E at their chests for shared rewards. See [RELEASE_NOTES_11.md](RELEASE_NOTES_11.md) for the exploration rules.

Fort 10 adds automatic UPnP router mapping, public-IP sharing and clearer connection diagnostics. It includes all Fort 9 gameplay, including gathering pets. See [RELEASE_NOTES_10.md](RELEASE_NOTES_10.md) for this networking update.

Fort 9 adds eight hearth tiers, five seeded random biomes, endless nights and milestone bosses, three gathering pets, seven weapons, three towers, new raiders, random day events, building salvage, stronger physical hammer knockback, and safe resource respawns. See [RELEASE_NOTES_9.md](RELEASE_NOTES_9.md) for recipes and rules. The earlier solo/co-op balance support remains.

Run `build/Fort.exe`. It contains the game data; Godot and Blender are not required to play. Alternatively, open `project.godot` in Godot 4.5.2 and press F5.

Everyone must run **Fort 19**. The host chooses a UDP port (default **24567**) and selects **Host Fort** to open a lobby. For LAN play, share the active Ethernet/Wi-Fi address using **Copy IP**. For internet play, leave the **Internet hosting** checkbox on, wait for router status, then use **Copy Public IP**. Others enter that IP and the same port (or paste `IP:port`), select **Join Crew**, then **Ready Up**. The host selects **Start Expedition** when everyone is ready. Solo play starts with one dwarf. Classes are unique: if a requested class is taken, the host assigns a free one. Late joining a running expedition is supported.

- Same PC: join `127.0.0.1`.
- Same LAN: join the host's local IPv4 address.
- Internet: Fort requests a router mapping for the **chosen UDP port** through UPnP. If unavailable, manual UDP forwarding is still needed. Players join the host's public IPv4 address. Mapping does not bypass Windows Firewall, double NAT or carrier-grade NAT; there is no relay or matchmaking.

Connection attempts can be cancelled. Contacting the host and registering in its lobby each have a separate 15-second deadline and error message. **127.0.0.1 means this computer**, not another computer on your Wi-Fi. See `NETWORK_HELP.md` for troubleshooting and a read-only diagnostic script. A version in a new folder needs a firewall rule for that exact executable path. The game never changes Windows Firewall; enabling internet hosting requests a router UDP mapping and removes it on normal leave/exit. Uncheck the option for LAN-only / manual forwarding.

The host must stay in the game. Leaving the host ends the live session for everyone; **Save & return to title** preserves the expedition first. Closing the host window also attempts an exit checkpoint and stays open if saving fails. Manual saves and dawn autosaves remain separate. Saving does not pause the crew.

Saves live in `%APPDATA%\Godot\app_userdata\Fort\expeditions`, not alongside the executable. Each slot has a verified backup; loading automatically tries it if the primary is damaged. Copy the whole `expeditions` folder to transfer saves to another host. Dwarf progress belongs to the four **class slots**, not player names or network IDs: choose your previous class before joining. Saves are local only, with no cloud sync or host migration. Fort 13 had no save files to import.

## Controls

| Input | Action |
| --- | --- |
| WASD / mouse | Move / camera and aim |
| Shift / Space | Sprint / jump; hold Space for jetpack thrust |
| Hold left click | Swing axe, fire mounted ballista, or place a defense in build mode |
| Hold E | Gather, deposit, work on construction, or revive a nearby downed ally |
| E at ballista | Mount / dismount |
| E at workshop / C | Open weapons, backpacks and relics / cycle owned weapons |
| Right mouse held with crossbow / Repeater | Aim while walking; shoulder camera and projected impact cursor |
| G beside a defense | Upgrade, cancel construction, or confirm daylight salvage of a completed building |
| K beside a castle sign | Plan wings, fund projects, add walls, or use room services; close and hold E to build |
| E at a treasure chest | Unlock with 2 shared crystals after defeating any guards |
| Hold R | Repair a nearby defense or the hearth using shared wood |
| U near the hearth, during daytime | Review / buy a shared hearth upgrade |
| F | Class ability |
| B / 1–9 and 0 / Q | Toggle construction / choose one of ten defenses / rotate preview |
| T | Cycle unlocked walking, horse, and jetpack modes |
| Enter | Vote to begin the next night early; all present players must be ready |
| Esc | Close construction or open the camp menu |

The camp menu changes sensitivity and sound and lets you leave. It does not pause the shared world.

## Working together

- **Iron Vanguard:** 150 health, stronger melee, a crowd-damaging Ground Slam that briefly stuns enemies.
- **Stone Warden:** 120 health; Rally heals and hastens nearby teammates.
- **Forge Engineer:** 110 health, 25% cheaper construction, double-strength repairs, and a temporary field turret.
- **Wild Scout:** 100 health, faster movement, a 26-slot pack instead of 18, three resources per gather instead of two, and a dash.

Carry wood, stone, crystal, iron, and aether home and hold E at the stockpile. Only deposited resources pay for shared construction. Eight total deposited crystals unlock horses for the whole crew; twenty unlock jetpacks. Jetpacks have limited thrust fuel and recharge on the ground.

Approaching the stockpile opens a contextual supply panel: **your pack**, **shared supplies**, a prominent **Hold E to Deposit All** prompt, and the next crew travel unlock. Construction has seven illustrated recipe cards showing real costs (including Engineer discounts), hearth requirements, and missing resources.

Watchtowers automatically fire from a redesigned stair-free platform. Barricades block enemies. Ballistae are player-operated, with one occupant each. Menders repair nearby defenses/the hearth and heal dwarves. Placement previews check cost, overlap, entrances, and distance; invalid positions cannot spend resources.

## Construction and sieges — Fort 6

Defenses no longer appear finished when placed. **B** opens construction; **1–9 and 0** choose the recipe, **Q** rotates, and clicking reserves the supplies and places a foundation. Wall ends snap to existing walls, including right-angle corners, and the build-range boundary is visible while placing.

Close construction mode and **hold E beside the project** to work. Anyone can help, each with an independent work cadence; Engineers contribute twice as much. Walls take six ordinary strokes and towers ten. Visible stages progress from foundation to scaffold to partial structure. A construction hammer, impact chips and a small gold progress bar show the work. **R** also contributes when a project is nearby.

Foundations have 30% of normal health and cannot fire, heal or be mounted. Once finished, structures receive their normal maximum health, retaining any damage taken during construction. **G** starts an eight-stroke upgrade project; the existing tower stays operational at its old level while you work. Hammering spends no additional materials beyond the reserved recipe.

The project owner or host can use **G → Cancel Project → Confirm** to return the unused fraction of reserved resources, rounded down. Anyone can help build, but other crew members cannot cancel your project. Structures destroyed by enemies return no materials. Progress, partial models and refunds synchronize to late joiners.

Raiders and hearth runners look for short routes around exposed wall ends, then breach if no short route is available. Brutes prioritize nearby walls and telegraph heavy structural hits; sappers favor work sites and towers. Camp guards patrol and investigate alarms, but stay near their camps. Chieftains stop during their slam windup, and Ashwings show a warning before diving.

**Rustscar Quarry** now has two climbable terraces and connected ramps/landings, with eight iron deposits above ground level. Explore its crane, timber crossing, retaining walls, ore carts, short mine rails and sealed mine entrance. The Fort 6 quarry pass added five Blender assets; Fort 7 brings the library to 64 models. The entrance is decorative, not a separate dungeon; the other regions retain their existing layouts.

When someone falls, hold E beside them for three revive interactions. Without help, they recover at the hearth after 18 seconds; solo gets one 8-second rescue per night. The hearth reaching zero ends the run. Nights continue beyond ten, with a giant Colossus every tenth night. Days last 150 seconds plus 30 per hearth upgrade; solo gets another 30 seconds on the opening day. Nights grow with progression and reserve travel time on larger maps; see RELEASE_NOTES_9.md. Saves preserve the day/night clock and ongoing raid budget.

## Weapon forge — version 3

Walk beside the **WORKSHOP**, press **E**, and choose **Craft & Equip**. Weapon recipes spend deposited shared supplies, but the crafted weapon belongs to your dwarf for this run. All classes can use every weapon. Weapon prices are fixed; the Engineer discount still applies only to defenses.

| Weapon | Wood | Stone | Crystal | Role |
| --- | --- | --- | --- | --- |
| Forester's Axe | Free | Free | Free | Original fast melee weapon; hits up to three enemies |
| Hearthbreaker hammer | 14 | 18 | 2 | Slower, stronger sweep; knocks back and briefly stuns up to five enemies |
| Trailguard crossbow | 22 | 8 | 4 | Aimed single-target shots, with a reload delay and reusable ammunition |

Close the forge with **Esc**. Press **C** to cycle owned weapons and **hold left-click** to attack. Crossbows and ballistae aim in three dimensions, including at flying enemies. Their cursor uses the same targeting calculation as the shot: red over an enemy, gold when blocked by terrain or a building. The crossbow cursor is visible while stationary or while holding **right mouse** to aim on the move; mounted ballistae always show it. Switching cannot cancel an attack cooldown. Gathering and repairing temporarily bring back the axe, then restore the equipped weapon. Gear survives rescue and is included in expedition saves. The workshop does not pause the raid.

## The Marchlands

Follow the trails from Hearthhold to three marked destinations: **Pinewatch Grove (G)** for wood, **Old Quarry (Q)** for stone, and **Moonwell Ruins (R)** for crystal. The minimap shows the trails and markers; the compass names your current region. Resources also remain scattered elsewhere, so the landmarks are useful destinations rather than mandatory collection zones.

The starting map has 48 harvestable trees in three varieties, 24 stone deposits, and 18 crystal deposits. Tree trunks collide while standing and clear immediately when felled. Low undergrowth is decorative and does not block movement. Rock formations and camp equipment have collision; construction keeps them and standing resources clear. Raiders steer around small obstacles.

## Hearth progression and expanded construction (Fort 5)

During the day, stand within 5m of the hearth and press **U**. The panel explains the cost and increased danger before you buy. Any living dwarf can spend deposited shared supplies; coordinate before upgrading. Repairing remains **R**.

| Upgrade | Shared wood / stone / crystal | Maximum hearth health | Exploration / build radius |
| --- | --- | --- | --- |
| Tier 1: Hearthhold | Starting tier | 1,000 | 73m / 23m |
| Tier 2: Elder March | 50 / 40 / 8 | 1,500 | 153m / 65m |
| Tier 3: Starfall Reach | 90 / 70 / 18 | 2,000 | 243m / 115m |

Each upgrade adds 72 core resource deposits, plus harvestable forests in the relevant rings. Tier two opens **Rustscar Quarry** to the east for iron and **Elderwood** to the west for timber, stone and crystal. Tier three opens **Stormglass Basin** to the north for aether and **Frostvein Ridge** to the south for iron and crystal, bringing the map to 486m across with 234 core deposits plus the new edge woods and additional camps and waystones. Tiers 4–8 each reveal a randomly ordered new biome with distinct ground, foliage and landmarks: Amberwood, Mycelium Hollow, Cinder Wastes, Glacier Reach or Ancient Gardens. The maximum map is **1,286m across with 594 core deposits plus hundreds of individually harvestable forest trees and giant mushrooms**. The visible ward moves outward and the minimap rescales. Each upgrade restores 500 hearth health, adds runestones around the fire and increases daylight by 30 seconds. Upgrades persist for the current run only. See [Fort 9 release notes](RELEASE_NOTES_9.md) for the full eight-tier table.

Nights have three assaults (four from night 4), with finite threat allowances scaled by crew size: **1 / 1.75 / 2.6 / 3.5**. Stronger enemies cost more allowance; simultaneous bombers and Sappers are limited. Reinforcements pause between assaults so you can repair while finishing off survivors. Orange minimap arrows show the attack fronts. Each hearth upgrade adds **10% base threat allowance and 5% base enemy health**, not extra active slots. Raiders spawn beyond your expanded construction perimeter, with a travel-aware reinforcement cutoff before dawn. Camp guards scale when first activated. Ordinary raiders retreat at dawn, but Colossi stay until defeated. Night ten is no longer the end of the expedition.

- **Ashwing:** appears from night 2. Animated bat-like flyer that bypasses walls and dives down to strike dwarves or the hearth. Counter it with crossbows, watchtowers, ballistas, or melee during its low dive; ground melee cannot reach cruising flyers overhead.
- **Ember Runner:** appears from night 1. Fast furnace-backed raider that ignores nearby dwarves and heads for the hearth. Block the gates, stun it, or focus ranged fire. It attacks nearby defenses and deals heavy hearth damage.
- Raiders, Brutes and Sappers remain in the mix. Enemy palettes are baked into vertex colors for fewer draw calls while preserving animation pivots and editable Blender sculptures.

## Iron, aether, and upgraded defenses

| Key / defense | Wood / stone / crystal / iron / aether | Hearth | Function |
| --- | --- | --- | --- |
| 5 / Metal Wall | 4 / 8 / 0 / 14 / 0 | 2 | 850-health armored barrier |
| 6 / Storm Spire | 8 / 16 / 4 / 12 / 8 | 3 | Lightning chains through three enemies, with decreasing damage |
| 7 / Frost Mortar | 12 / 18 / 2 / 16 / 6 | 3 | Lobbed shells damage and slow groups in a 4.8m blast |
| 8 / Embercoil | 20 / 25 / 8 / 28 / 10 | 4 | Close-range pulses scorch nearby enemies |
| 9 / Gravity Well | 12 / 40 / 15 / 32 / 22 | 5 | Pulls enemies inward and slows crowds |
| 0 / Sunlance | 30 / 35 / 20 / 50 / 35 | 6 | Long-range armor-piercing beam |

The Engineer's construction discount applies to these recipes. Stand within 4m of a permanent defense and press **G** to start its upgrade, then hold E to finish the work. Level two costs **12 wood, 10 stone, 8 iron** and requires Hearth 2. Level three costs **12 wood, 16 stone, 16 iron, 5 aether** and requires Hearth 3. Reinforcement continues through **level 8**, requiring the matching hearth tier and increasing supplies. Each completed upgrade adds 65% of the original building health and, for offensive/support towers, 40% of its base damage/healing. Existing damage still needs repair. Walls gain health only; temporary Engineer turrets cannot be upgraded. Upgrade costs are fixed for all classes. Small health bars appear on nearby buildings and damaged buildings within 22m, without showing through walls.

## Backpacks and crew treasure

At the workshop, open **Backpacks and Relics**. The **Trail Pack** costs 16 wood and 2 crystal and adds 12 capacity. Its upgrade, the **Expedition Frame**, costs 24 wood, 4 crystal and 12 iron, requires Hearth 2, and replaces that bonus with 28. Normal dwarves carry 18 / 30 / 46; Scouts carry 26 / 38 / 54. Both have visible Blender-made equipment models.

Nine permanent treasure locations include the original caches/camps and three guarded villages. Press **E** near a chest to spend **2 shared crystals** on its lock. Guards activate as you approach and remain through daylight. Defeat one through four escorts (depending on crew size) and a Chieftain first. Chests can be claimed once per run. The random Supply Caravan is a separate, free event chest.

- **Redfang Camp:** Embermaul, a crowned rare hammer with +28 damage and a longer stun.
- **Rustscar Stronghold:** Ironheart armor, +40 maximum health and 20% incoming-damage reduction.
- **Stormglass Sanctum:** Stormstring, a crystal-limbed rare crossbow with 80 bolt damage.

Rare rewards go to **every crew member**, including late joiners, so nobody has to fight over loot. Supply caches add shared materials. Relics, backpacks and upgrades survive rescue and save/load. Claimed treasures stay claimed when resuming.

## Art and animation

`assets/models/fort/` contains 106 glTF assets. Fort 12 adds eight Blender-authored foliage models and replaces both dragons with concept-guided, animated models. Editable sculptures, the generated dragon reference and its prompt, and repeatable scripts are included in `art_source/`. Use `model_foliage12.py` for the woodland kit and `model_dragons12.py` for the dragons. Both preserve the open Blender scene. The game loads GLBs, so Blender is not required to play.

The second art pass models the three enemies, workshop, stockpile, barrel, and supply crate directly in Blender. Raiders have facial features, distinct clothing, and attached weapons/equipment. Camp props include individual shingles, a shaped anvil, vise, hanging tools, braced planks, metal hoops, and rivets. Static parts sharing a material and animation pivot are combined for the game; `*_sculpt.blend` files retain the separated artist geometry.

Gathering highlights the selected resource with a ground ring and remaining-supply indicator, and the dwarf turns toward it when harvesting.

The world pass adds region-specific ground shading, connected dirt trails, lit windblown grass, grouped foliage rendering, distant woodland and ridgelines, and lived-in camp dressing. The playable ground remains level; the cliffs are scenery, not a new climbable terrain system.

Editable sources are in `art_source/blender/`, including copies of the original dwarf and tree sources. The original tree scene was preserved while new scenes were created through Blender MCP.

- Dwarf: authored Idle, Walk, and Axe_Swing, plus runtime air/riding poses. Swing actions are protected from locomotion interruption and melee has a delayed impact.
- Tree: Idle, Hit, and Destruction connected to harvesting and depletion, with bursts of wood chips, falling leaves, and bark dust on the final chop. All clients receive the destruction event; joining a game does not replay old bursts.
- Campfire: continuous animated flame particles, rising embers, soft drifting smoke, and gently flickering warm light. Effects use bounded CPU particle counts compatible with the game's Compatibility renderer; tree effects clean themselves up independently of hidden trees.
- Minerals: mining chips and a distinct impact sound; remaining geometry tracks resource supply, including late-join restoration and regrowth.
- Interface: charcoal/brass/teal styling, code-drawn recipe icons, clearer host/join fields, contextual stockpile panel, construction affordability cards, and a working weapon forge.
- Weapons: original skinned axe separated at runtime without altering the source dwarf; new weapons follow its hand bone. Hammer uses a slower swing timed to impact; crossbow has aim, movement, firing/reload poses and a visible reload cycle.
- Each enemy: Blender Idle, Walk, Attack, Hit, and Death clips.
- Horse: Blender Gallop; jetpack: thrust-controlled flames.
- Materials share a restrained stone/timber/teal palette. Lighting transitions between day and night. Terrain, grass, effects, and synthesized sound cues are generated in Godot.

To rebuild the base asset library (this replaces generated exports, so preserve manual asset edits first):

1. Run Godot with `--headless --path . --script res://art_source/export_prototypes.gd`.
2. Run `art_source/build_assets.py` in Blender, either through MCP or `blender --background --python art_source/build_assets.py`. Update its ROOT path if the project moved.
3. Run `art_source/model_raiders.py`, `art_source/model_camp.py`, `art_source/model_world.py`, `art_source/model_fire.py`, `art_source/model_minerals.py`, and `art_source/model_weapons.py` in Blender for the directly modeled art passes. These create fresh scenes and preserve the originally active scene.
4. Reimport the Godot project. The game loads GLB files, so Blender is not needed at runtime.

## Verification

Validated with Godot **4.5.2** and Blender **5.2.1**. Run these from the project directory using your Godot console executable:

```powershell
$godotExe = '.tools\godot45\Godot_v4.5.2-stable_win64_console.exe'
& $godotExe --headless --editor --path . --quit
& $godotExe --headless --path . --script res://tests/asset_test.gd
& $godotExe --headless --path . --script res://tests/gameplay_test.gd
& $godotExe --headless --path . --script res://tests/raid_test.gd
& $godotExe --headless --path . --script res://tests/world_test.gd
& $godotExe --headless --path . --script res://tests/particles_test.gd
& $godotExe --headless --path . --script res://tests/interface_test.gd
& $godotExe --headless --path . --script res://tests/weapons_test.gd -- --fort-test
& $godotExe --headless --path . --script res://tests/fort5_test.gd -- --fort-test
& $godotExe --headless --path . --script res://tests/fort6_test.gd -- --fort-test
& tests/run_network.ps1
& tests/run_network.ps1 -Packaged
& tests/run_network.ps1 -Packaged -Driver weapons_network_driver
& tests/run_network.ps1 -Packaged -Driver progression_network_driver
& tests/run_network.ps1 -Packaged -Driver construction_network_driver
```

The network test launches one host and three separate clients. It checks class uniqueness, late-join state, gathering/deposit actions, action animations, tree-destruction effects, downed state, and recovery on the controlling client. Gameplay checks include input routing, animation transitions, delayed melee, construction, ballista mounting, repairs/revival, traversal, gateway navigation, tower firing/climbing, and victory. Particle checks cover all three tree varieties, duplicate/late-join suppression, regrowth, cleanup, and continuous campfire emitters. `tests/visual_review.gd` captures staged title/day/night/crew/travel views; `tests/particles_review.gd` captures the campfire and successive tree-destruction frames. These captures are visual checks, not balance tests.

**Scope of validation:** local four-process networking has been tested. A real four-person session across different internet connections, latency/loss testing, and extended balance/performance playtesting are still needed. This is a playable development build, not a claim of a fully tested commercial release. There is no host migration, persistent campaign, or anti-cheat hardening.

## Export

```powershell
& $godotExe --headless --path . --export-release 'Windows Desktop' 'build/Fort.exe'
```

The Windows preset embeds game data and excludes tools, tests, Blender sources, and previous builds. Export templates for the matching Godot version must be installed.

For the complete art-pass validation, rendered galleries, export, and packaged four-player check, run `tests/run_art_pass.ps1 -Render -Export -Network`. Rendered previews are saved in `build/`; the helper stops if a check reports an error.

The helper uses isolated test ports and runs the general multiplayer, weapon-crafting/combat, and custom-port lobby/reconnect suites. Fort 4 checks also cover live hearth expansion, replicated flyers/runners, duplicate upgrade rejection, and a rendered 100-enemy stress scene. To preserve a successful export as a new version, run `tests/package_version.ps1 -Version 4` (use the next unused number). It creates a versioned folder and ZIP, verifies the archived executable's SHA-256, and refuses to overwrite saved versions.
