# Fort art sources

The game loads the GLB files under `assets/models/fort`. Blender is an authoring dependency only.

## Direct Blender art pass

- `model_foliage12.py`: animated elder oak, amberwood and giant mushrooms, plus woodland brush, bluebells, forest-floor litter, dry sedge and frost shrubs. Exposes `build()` for Blender MCP and preserves the open scene.
- `model_dragons12.py`: concept-guided Emberdrake/Frostwyrm rebuild with continuous lofted anatomy, articulated wing fingers/membranes and retained animation pivots. The generated reference and exact prompt are recorded in `concepts/README.md`.

- `model_raiders.py`: raider, brute, sapper. Models faces, outfits, weapons and equipment directly with Blender geometry and named animation pivots.
- `model_camp.py`: workshop, stockpile, barrel and supply crate. Shares the character pass's restrained palette and geometry helpers.
- `model_world.py`: animated pine/birch trees, fern, flowers, moss rock, ruin arch, waystone, quarry cart, canvas tent and cliff ridge. Tree clips retain the `Idle`, `Hit`, `Destruction` contract.
- `build_assets.py`: shared edge finishing, animation authoring, GLB export and source-library saving. Also supports the earlier Godot blockouts from `export_prototypes.gd`.

Run the Python files in Blender via MCP or its Python CLI. `model_raiders.py` and `model_camp.py` resolve the project from their file location; the base exporter still has a ROOT constant to change if moving the repository. Rebuilding overwrites that generator's GLB and corresponding source files. Preserve manual edits elsewhere before rebuilding.

## Editable files

`blender/*_sculpt.blend` keeps individually selectable features and the animation tracks before static mesh batching. The matching `blender/*.blend` is the optimized, animated runtime source. Both are Blender library files containing a dedicated asset scene. Select that scene after opening if necessary.

The generator creates new scenes, never deletes existing user objects, and restores the original active scene. The dwarf and tree originals were copied into this folder during the first pass.

## Coordinate and animation contract

Blender: Z up, -Y forward, meters. Godot imports as Y up, +Z forward. Keep `ArmL`, `ArmR`, `LegL`, `LegR` as named enemy pivots, and the clips `Idle`, `Walk`, `Attack`, `Hit`, `Death`. Weapon grips, shoulder armor and boots must stay parented to their moving limbs. Runtime aiming depends on the `Turret` pivot in tower/ballista exports.

Workshop and stockpile exports have origins at ground level; gameplay positions and collision footprints remain owned by Godot. Their detailed render meshes replace the older submodels in the fort without changing interaction positions or physics.

Static mesh batching only combines unanimated leaf meshes with the same parent and materials. It does not merge moving pivots. This reduced the new enemies from 75–86 scene objects to 35–36, and the workshop from 104 to 9, with the original geometry retained in the sculpt sources.

## Inspect

Fort 7 adds `model_frontier7.py`: ten new scenes for the stair-free watchtower, iron/aether upgrade fittings, Pike and Repeater, Sapper charge, Cinderlobber, animated Bombwing, enterable village house and well. The Bombwing appends an independent copy of the authored Ashwing sculpt and retains its wing animation tracks. The generator restores the original Blender scene after exporting. `tests/fort7_test.gd` renders tower tiers, healing coverage, the expanded forge, a village, siege enemies and both equipped weapons. Godot's fixed-defense aim convention is -Z; `FortArt.make_defense` rotates the watchtower's hand-weapon art under the turret to match it.

`tests/art_gallery.gd` renders enemy idle, attack, face detail and camp galleries in Godot. `tests/visual_review.gd` renders actual day/night gameplay, gathering focus and traversal. `tests/asset_test.gd` checks imported geometry and that every expected animation contains changing track values.

The world review also captures Pinewatch Grove, Old Quarry, Moonwell Ruins and an overview. `tests/world_test.gd` walks the actual trails with player input and verifies resource clearance, tree collision lifecycle and raider obstacle avoidance. Vegetation uses shared MultiMesh batches; windblown grass and biome/trail ground shading are Godot shaders, not bitmap textures.
