# Fort 12 — Living woodlands

## World detail

- Curved five-blade grass clumps, varying density, height and tint, wind gusts and local-dwarf bending. Grass fades from 58–82m; spatial batches cull at 105m, beyond their last faded blade. Small groundcover culls at 88m. Headless hosts skip decorative grass entirely.
- New Blender-authored elder oaks, amber trees, giant mushrooms, berry shrubs, bluebells, dry seed heads, frost shrubs and leaf-litter/twig/mushroom clusters. Eight new GLBs; editable Blender source and scripts included.
- Meadow moss breakup and small stones in paths. Biome-tinted grass and undergrowth preserve open roads and wilderness encounter clearings.

## Harvestable forests

The former distant-pine scenery now becomes individual resource trees when hearth tier 2 opens those woods. Amberwood groves and Mycelium Hollow's giant mushrooms are no longer unbreakable scenery batches. Every standing tree has a resource entry and removable trunk collision. Ordinary mineral landmarks, ruins and small decorative groundcover are not harvestable trees.

| Species | Yield per full node | Requirement |
| --- | --- | --- |
| Starter oak, pine, silver birch | 12 wood | Starter tools |
| Outer-edge elder oak | 18 wood | Starter tools |
| Amberwood | 24 wood | Forester's Axe level 2 |
| Mooncap | 12 crystal | Forester's Axe level 2 |
| Starcap | 8 aether | Forester's Axe level 3 |

Hold E close to the trunk. Upgrade the Forester's Axe at the Workshop (T); gathering automatically uses the tool, even with another weapon equipped. The interaction prompt explains unmet requirements. Your backpack still limits each collection. Resources enter carried inventory first; bring them to the shared stockpile as before.

Trees sway, recoil when chopped, fall on depletion, and release species-colored particles. Trunk collision clears immediately. Regrowth restores the species capacity and waits if a building or dwarf blocks the trunk. Existing gathering pets can collect these materials after the corresponding hearth training tier, within the unlocked ward. Pets still return their cargo to the shared inventory.

The original 594 core resource deposits remain at maximum hearth level; the individually harvestable woods and groves are additional. Exact forest totals vary with the biome seed and encounter clearings.

## Concept-guided dragons

Both Emberdrake and Frostwyrm have been rebuilt in Blender from the generated reference in `art_source/concepts/dragons12-reference.png`: curved necks and tails, wedge heads, swept horns, layered armor, clawed articulated legs, and finger-supported scalloped wing membranes. Existing Idle, Walk, Attack, Hit and Death clips remain connected. Encounter rewards, territory, telegraphs and difficulty are unchanged.

The concept is a design reference, not a screenshot or a promise of identical painted microdetail. `art_source/concepts/README.md` records the exact prompt and built-in image-generation workflow.

## Multiplayer and versions

Everyone should run Fort 12. The working Fort 10/11 internet-hosting flow is retained. Forest layout, chopping, collision removal and regrowth are server-authoritative and included in late-join state. Earlier numbered ZIPs are preserved.

Tests include the existing gameplay/art/encounter suites, new forestry and foliage checks, and a four-process forestry test that races three remote gatherers against one tree and verifies exact yields, late joins and regrowth. Internet connectivity outside this network still depends on router/firewall conditions; these automated network tests use local peers.

## Verified build

`tests/run_art_pass.ps1 -Render -Export -Network` passed: 17 headless suites, 15 rendered checks, Windows export and ten four-process packaged multiplayer scenarios. The 100-enemy stress scene averaged 39.6 FPS (worst frame 128.6ms) on the development RTX 5090 / OpenGL Compatibility setup, compared with 40.4 FPS in the preceding pass. This is not a lower-end hardware or steady-60-FPS guarantee.
