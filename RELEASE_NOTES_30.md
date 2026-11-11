# Fort 30 — Real terrain, water and sound

Everyone must run **Fort 30**. Saves from earlier builds load; anything that stood on the old flat ground is set down on the new land.

## What is new

The world is no longer a flat plane with hills placed on top. The whole map is one continuous landscape: rolling hills and hollows around the hearth, higher country in the outer rings, and a wall of real mountains beyond the last frontier.

- **Hearthhold sits in a level dale.** The keep and the ground inside the first ring of camps are flat, as before. The land starts to roll as you leave it and gets bolder with every ring you open.
- **Every camp, village, landmark and wilderness site has its own shelf** cut into the hills at its own height. Rustscar Quarry and Hollowback Ridge stand on theirs.
- **The four expedition roads follow gentler ground**, so there is always an easy way out and back.
- **Trees, rocks, crystals, grass, flowers, signs and props all stand on the ground**, wherever it is.
- **The ward line follows the land.** The frontier limit is drawn on the terrain itself, over every rise.
- **Each expedition has its own landscape.** The land is generated from the expedition seed, so a new expedition is new country, and a saved one always comes back the same.

## Water

- **Hollows hold lakes and ponds.** From the second ring outward, roughly a tenth of the land is water, with sandy shores, sedge along the margins, ripples and a line of foam at the edge.
- **Every lake can be waded.** No lake bed is deeper than about 1.15 m, so dwarves, pets and raiders can all cross. Dwarves move about a quarter slower while wading.
- **Nothing important is under water.** Camps and sites are never founded in a lake, the four roads cross wet ground on a low causeway, and trees, rocks and ore that would have stood in a lake grow on its shore instead.
- Castle rooms and foundations fill in the water beneath them like any other ground.
- The first ring has no water; the land there is too gentle to hold it.

## Sound and music

Fort 30 replaces the synthesized beeps with recorded audio.

- **Music that fades.** A warm title theme on the menu, a peaceful, mellow theme by day (guitar, flute and strings) and a brooding, drum-led theme at night. Tracks cross-fade into each other at dusk and dawn and loop without a gap.
- **Day and night sound different.** Birdsong and a breeze by day; crickets, an owl and wind at night. Water laps when you are near a lake, and the hearth fire crackles when you are near it.
- **Sounds come from where they happen.** Chopping, mining, hammering, shots, hits, explosions, gates and raiders are placed in the world, so they get quieter with distance and sit to the left or right.
- **Footsteps and wading.** Dwarves have footsteps on grass and on stone. Wading splashes, leaves rings and drops on the water, and landing in a lake makes a bigger splash. Raiders leave ripples when they wade.
- **The dwarves speak.** Each of the four roles has its own voice and twelve lines: battle shouts, cries when hurt or downed, thanks when revived, a shout for their ability, and remarks at nightfall, at dawn, on a full pack, on levelling up and on finishing a building. The second crew of four share the roles' voices at a slightly different pitch.
- **Raiders and beasts** grunt when hit and cry out when they fall. Brutes, wolves, dragons and the Colossus announce themselves; a war horn sounds at nightfall and a rooster at dawn.
- **Small things:** a click on every button, a fanfare on level-up, a chest opening on crew treasure, a swell when the hearth is upgraded, a tree falling, a crystal chime, the jetpack's hiss.
- **Settings** (Esc): separate switches for music and effects, and volume sliders for music, effects, voices and ambience.

The music, effects and voices were generated with Higgsfield (ElevenLabs Music, Mirelo SFX and Seed Audio) and processed locally; the crystal chime is synthesized. The raw files and the processing script are in `art_source/audio/`.

## The map

The minimap and the world map (**M**) now show the land: hills and hollows shaded as relief, lakes in blue, mountains at the rim.

## Building on it

- **Castle rooms level their own plot.** Plan a wing on a slope and the ground is cut flat under it, with banks running back up to the hill.
- **Foundations level the ground beneath them** too. You can start one where the ground is within about a metre of level and build across from there; steeper ground refuses with "The ground is too steep here".
- **Towers, walls and gates can be placed on open slopes.** They stand at ground height. The outer wall rides over the hills as before.
- **Farm plots** inside the outer wall get level beds.

## Raiders and pets

Raiders, beasts and bosses walk over the hills and still collide with walls, props and castle floors. Raids spawn on the ground at the edge of the build zone, wherever that ground is. Flyers hold their height above the land beneath them. Pets path over the terrain like dwarves do.

## Looks

- A new terrain surface: meadow, biome and trail colours as before, plus darker slopes, damp hollows, dry crests, rock on steep faces, forested foothills and snow on the peaks.
- The far mountain silhouettes now stand behind real mountains, and the air is clearer so you can see them.

## Performance

Measured on the development PC (windowed, uncapped), before and after:

| View | Fort 29 | Fort 30 |
| --- | --- | --- |
| Hearth 1, from the keep | 200 fps | 201 fps |
| Hearth 1, in the meadow | 192 fps | 193 fps |
| Hearth 3, from the keep | 157 fps | 152 fps |
| Hearth 3, out on the frontier | 222 fps | 214 fps |
| Hearth 3, 100 raiders at night | 81 fps | 83 fps |

The land near you is drawn in detail and the far country in a coarser mesh. Only the opened frontier has collision. Raiders follow the ground by height lookup instead of physics, which is why a full raid is no slower than on the old flat floor.

Opening a new ring takes about 0.25 s longer than before (once per hearth upgrade), and a new world about 0.2 s longer to load.

## Known limits

- The first ring is gentle on purpose: the starting camps sit close around the hearth and share its level.
- Water is still: there are no rivers or waterfalls, and no swimming, boats or fishing. Raiders are not slowed by wading.
- The sound mix was balanced by measurement, not by ear. Use the volume sliders if music, voices or effects sit too loud or too quiet, and tell me which.
- Volume settings are not saved between sessions.
- Only the four roles have voices; pets, merchants and villagers do not speak.
- Slopes are kept walkable. A survey of twelve seeds found none too steep to climb in the first three rings, and at most 0.01% of the ground in the outer biome rings. If you find a face you cannot climb, go round or use the jetpack.

## Checks

- New suite `tests/terrain30_test.gd` (run with `-- --fort-test`): level hearth, walkable slopes, collision matching the height lookup, level shelves under every site, wadeable lakes that leave sites, roads and resources dry, resources and scenery seated, a dwarf landing on a hillside, a raider walking in over the hills, towers on slopes, foundations and castle rooms levelling the land, the opened frontier, and identical land from the same seed.
- `tests/audio30_review.gd` (windowed, run with `--audio-driver Dummy`) checks that every sound has its file, music follows day and night with a cross-fade, ambience runs, footsteps and wading fire, and every role has all twelve lines.
- `tests/terrain30_review.gd` renders reference views to `build/terrain30_*.png`. `tests/terrain30_probe.gd` prints frame rates.
- All 42 headless suites pass. Two older suites were updated because they named the removed knolls and assumed the ridge stood at height zero (`fort26_test`, `terrain19_test`).
- Four-player network drivers: 17 of 20 pass. The other three behave exactly as they do on Fort 29 and are not caused by this change: `frontier_network_driver` checks tower part names that Fort 28 replaced, `improvements_network_driver` fails two pet and wall checks, and `pieces_network_driver` passes or fails from run to run on a timing race in the test.
