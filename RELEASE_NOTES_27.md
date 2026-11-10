# Fort 27 — Better movement, new pets and pony

Everyone must run **Fort 27**. Saves from Fort 26 and earlier load unchanged; nothing about the save format changed.

## Dwarf movement

The walk and sprint were rebuilt. The old cycle took small, stiff steps with straight arms held out from the body.

- **Walk** is now a quick trot: a real heel strike, a weight drop, a high knee on the swing leg and a push-off, with the body bouncing and leaning into it.
- **Sprint** uses a longer stride, a deeper lean and harder-pumping arms.
- Elbows stay bent and tucked in. Hips and chest counter-rotate, and the head stays level with a small nod on each landing.
- Step rate follows ground speed, so a dwarf slowed by aiming or working takes slower steps instead of jogging on the spot.
- **Aiming march** uses the same legs under a steady upper body.
- A rig fix makes elbows bend straight forward in every animation. Swings, gathering, hammering, aiming and riding all look tidier for it, on dwarves and enemies alike.
- Riding hands rest low at the reins instead of up by the face.

## Pets and the pony

All four were made locally in Blender and replace the last of the old blocky models.

- **Pack Badger:** grey coat, black legs, white face with the two dark stripes, saddlebags and a bedroll.
- **Copper Mole:** copper velvet coat, pink snout and big digging claws, brass goggles and a headlamp, wicker panniers with ore.
- **Grove Sprite:** a small green spirit under an acorn cap, with leaf wings and a seed pouch. It hovers and flaps.
- **Mountain pony:** chestnut with a cream mane, tail and feathered feet, a white blaze, saddle, blanket and saddlebags. It now stands and breathes when you stop, walks at low speed and canters when travelling, instead of freezing mid-stride.

## How they were made

`art_source/rig26/sculpt.py` fuses simple rounded shapes into one organic skin, paints it per vertex (base colours, markings, underside shading), then adds crisp parts such as eyes, claws and tack. `build_pets.py` holds the four designs and reuses the same skeleton and animation code as the enemies. Nothing was generated externally.

## Known limits

- The pets and pony are simpler and more cartoon-like than the dwarves and enemies, which were built from painted source meshes. They read clearly at game distance but have less surface detail up close.
- Dwarves cover ground faster than their short legs could really carry them, so feet still slide a little against the ground, most visibly when sprinting.
- The badger's and mole's legs are short, so their walk is subtle.
