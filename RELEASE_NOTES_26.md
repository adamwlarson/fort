# Fort 26 — New faces, new land, clearer everything

Everyone must run **Fort 26**. Saves from Fort 14–25 load; saves written by Fort 26 (format 4) cannot be reopened in older builds. Back up `%APPDATA%\Godot\app_userdata\Fort\expeditions` before rolling back.

## Dwarves

- All eight playable dwarves are new sculpted, hand-painted characters: Iron Vanguard, Stone Warden, Forge Engineer and Wild Scout, plus the Copper, Amethyst, Jade and Dusk alternates as their own characters instead of recolours.
- Seventeen authored animations replace the old three: idle, walk, **run** (when sprinting), one-handed swing, two-handed heavy swing, gathering chop, hammering, ability shout, aim, aiming march, shoot and reload, pike thrust, airborne, riding, flinch, fall and a kneeling **downed** pose.
- Tools sit in the palm and point forward. The Forester's Axe is a separate model.

## Enemies

All eighteen were rebuilt one by one, each with its own skeleton and Idle / Walk / Attack / Hit / Death set:

Raider, Ember Runner, Brute, Sapper, Cinderlobber, Fire Archer (now its own model with a bow), Shieldguard, Prowler, Hexer, Chieftain, Colossus, Ashwing, Bombwing, Razorback, Direwolf, Stonebear, Emberdrake and Frostwyrm.

Attacks read differently by type: club swings, two-fist slams, bow draws, staff casts, a bowing mortar shot, double claw slashes, a boar gore, a wolf lunge, a rearing bear maul and a dragon breath with spread wings. Enemies still flash red when hit.

## The land

- **Rolling hills.** Walkable grassy knolls rise across the meadow and frontier. They come from the expedition seed, so every player and every save sees the same ones. Trees and rocks on a hill sit on its surface. You cannot build on a hill; the outer wall rides over them.
- A painted sky with drifting clouds, a sun and moon disc, and stars at night. Dawn and dusk warm the light.
- Three ranges of mountains on the horizon, warmer sunlight, softer fog, cloud shadows drifting over the ground, lusher and drier patches of meadow, wildflowers, and motes of pollen by day and fireflies by night.

## Interface

- The HUD is much smaller: a slim strip top-left (day, hearth, stockpile), your health, pack and experience bottom-left, and one line of text at the bottom. Nothing sits over the middle of the view.
- The crew box in the top right is gone. When someone is downed, the top of the screen says `Player "name" down 34m`.
- **M cycles the map:** standard → wide → region → whole explored world → off. Bigger maps show resource patches.
- **Costs use symbols.** Every cost, refund, stock count and sign shows a number and the resource symbol rather than the word.
- Menus use smaller text and tighter buttons. The castle menu is shorter and says what to do in three plain steps.
- All controls are under **Esc → Controls**, including Tab and M.

## Clearer messages

Blocked actions now say why and what to do. A few examples:

- "Must build rooms from adjacent room's signs"
- "Enemy base in the way: Redfang Camp. Defeat its guards and open its chest, then build over it."
- "Each outer side of the castle needs at least one opening or gate. Open another doorway on this side first."
- "Too far from the hearth. Upgrade the hearth with U to build further out."
- Build mode shows "CANNOT BUILD: reason" or "OK to build here".

## Character sheet, levels and stats

Press **Tab** for your character sheet: weapon and its numbers, other weapons carried, armor, backpack, relics, ability, level and experience.

You earn experience by defeating monsters (shared with every dwarf within about 34 m), by building and by gathering. Each level gives one stat point. Seven stats, ten points each:

| Stat | Per point |
| --- | --- |
| Health | +12 maximum health |
| Damage | +6% weapon damage |
| Cooldown | −4% attack and ability cooldown |
| Speed | +3% movement speed |
| Storage | +3 pack slots |
| Mining Speed | −5% time between gathering swings |
| Mining Efficiency | +10% chance of a bonus resource |

Levels and stats belong to the character slot and are saved with it.

## Castle

- **Taller rooms.** Each storey is 5 m instead of 4 m, with walls, gates, windows and stairs to match. Older saves are lifted onto the new floor heights when loaded.
- **Corner posts.** Walled rooms get solid corner posts, closing the gap where three rooms meet.
- **Build over cleared bases.** Once a camp or wilderness base has been cleared and its chest opened, a room can be built over it. The base is razed and does not return. Villages cannot be built over.
- **Wall farms.** With the outer wall built, the keep sign offers a Tree farm, Rock mine, Crystal garden and Iron pit — up to four plots inside the wall's corners. They deliver to the shared stockpile every 12 seconds of daylight and move outward with the wall as the castle grows.
- Side options are now labelled Open doorway / Auto gate / Solid wall.

## Raids

- Raiders arrive from every direction rather than four fixed lanes.
- A raider that ends up below the ground or inside a hill dies at once (no experience is awarded for it).

## Also in this build (from the Fort 25 pass)

Gold and the merchant tent with a daily sale, releasing pack animals, the growing hearth and tidier starting keep, no floors above the hearth, flyers that cross walls to reach it, field turrets placed anywhere on a 30-second cooldown, room upgrades, sentry rooms with window cannons, the expanding outer wall with corner gates, bombers that run three times faster and break walls, bosses that damage rooms, fire archers and burning wooden structures, repairs, and the Controls menu.

## How the art was made

Concept sheets and per-character reference images were generated with Higgsfield, converted to textured meshes, then rigged, weighted and animated in Blender by the scripts in `art_source/rig26`. References are in `art_source/concepts/fort26`, raw meshes in `art_source/gen26`, and editable rigged scenes in `art_source/blender/*26.blend`.

## Known limits

- The four pets and the pony still use their earlier models.
- Hills are scenery you can walk on, not full terrain: the keep and the first stretch of meadow around it stay level, and pack animals path as if the ground were flat.
- Skinning is automatic. Extreme poses can pinch at the shoulders, and thin props such as the Colossus's moss can stretch slightly.
- Experience numbers and stat values are a first pass and have not been balanced over long eight-player sessions.
- Multiplayer was checked with local multi-process runs, not across separate machines.
