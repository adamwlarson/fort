# Fort 28 — New walls, towers and upgrade stages

Everyone must run **Fort 28**. Saves from earlier builds load unchanged.

## Castle walls, windows, gates and sentry cannons

The plain grey boxes are gone.

- **Walls** are coursed stone on a plinth with a gold-capped cornice. The outer face has a buttress with an arrow slit and a small teal shield; the inner face has a lantern bracket.
- **Window walls** have a real opening you can see through, with a stone sill, lintel and keystone, and wooden shutters folded back outside.
- **Gates** have stone posts, an arched lintel with a keystone and shield, and two iron-banded plank doors with ring handles. The doors now **swing open on their hinges** instead of squashing flat.
- **Sentry cannons** are an iron barrel with brass bands on a wooden carriage and stone base, with a stack of shot beside it.

## All ten towers rebuilt

Watchtower, Barricade, Ballista, Mender, Metal Wall, Storm Spire, Frost Mortar, Embercoil, Gravity Well and Sunlance are new models in one consistent painted style.

- **Watchtower:** timber frame on stone footings, plank deck with a parapet, ladder, pennant and a mounted crossbow.
- **Barricade:** sharpened log palisade with rope bindings and outward stakes.
- **Ballista:** wheeled carriage with a large bow, winch and loaded bolt.
- **Mender:** stone basin with gold arms holding a floating crystal.
- **Metal Wall:** riveted iron plates between two posts on a stone footing.
- **Storm Spire:** iron lattice mast with copper coils and a crystal orb.
- **Frost Mortar:** squat banded barrel on a sled with a pile of frost shells.
- **Embercoil:** stone-ringed fire bowl of coals under a rising copper coil.
- **Gravity Well:** dark orb inside three gold rings between leaning pylons.
- **Sunlance:** brass tripod carrying a lens tube that tracks its target.

## Upgrades you can see

Every defense, wall and gate now has its own upgrade parts instead of the same iron posts and crystals on everything.

| Level | What shows |
| --- | --- |
| 1–2 | Base model |
| 3–5 | Second stage: iron reinforcement, spikes, guards, extra coils or crystals, depending on the defense |
| 6–8 | Third stage: gold fittings, crowns, rings, roofs and aether crystals |

Some examples: the Watchtower gains iron brackets and shields, then a teal tiled roof. The Barricade gets iron tips and a band, then shields and crystals. The Sunlance grows sun-ray petals, then a halo ring and second lens. A small "LV n" tag above the defense shows the exact level from level 2 up.

## Siege Watch

The large panel is now a thin strip directly under the day / night display: one line of raider counts by compass direction, plus up to two short repair lines only when something is damaged. The on-screen threat markers are unchanged.

## Fix: Gatehouse dusk closing

Since Fort 25 the large Gatehouse had been opening and closing by itself like a room doorway, which overrode its E toggle and its close-at-dusk setting. Only room doorways (auto gates) open by proximity now; the Gatehouse is manual again and closes at dusk when that option is on.

## How they were made

Everything was built locally in Blender by `art_source/rig26/props.py` (a chamfered, vertex-painted prop kit) and `build_defenses.py` (the fourteen designs). Editable scenes are saved as `art_source/blender/def_*26.blend`.

## Known limits

- Levels within a stage look the same apart from the level tag: 1 and 2 share a look, as do 3–5 and 6–8.
- The Gatehouse keeps its Fort 24 model and its own eight reinforcement stages; it is more detailed than the new pieces and in a slightly different style.
- The new models are painted with flat colours and baked shading, not textures, so they are cleaner and simpler than the dwarves and enemies up close.
- Storm Spire, Embercoil, Gravity Well and Mender have no moving parts.
- The construction scaffold and the half-built preview still use the earlier scaffold model.
