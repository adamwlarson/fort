# Fort 13 concept references

Generated with the built-in image_gen imagegen tool, using the imagegen skill. These images guided the broad silhouettes, layered armor, ashlar/brass palette and modular castle kit; Blender meshes are independently modeled, rigged game assets rather than automatic 3D conversions.

## Cast

Saved reference: `art_source/concepts/cast13-reference.png`

Exact prompt:

Use case: stylized-concept. Production concept sheet for Fort, cooperative fantasy dwarf castle survival game, for Blender modeling. Show a coherent cast lineup on plain warm gray background: four stout adult dwarf heroes, a red iron vanguard with layered pauldrons and braided auburn beard, teal rune warden with long white split beard and rune collar, ochre engineer with brass goggles leather tool belt and square brown beard, green ranger with hood pointed cape and braided dark beard. Along a second row show their enemy families: sharp-faced green goblin raider, massive scarred armored ogre with heavy jaw, obvious explosive barrel-carrying sapper with glowing orange fuse, cloaked violet hexer with skull staff, batlike armored flying bomber with leather bomb harness, and a muscular wolf and bristled boar. High-quality stylized game art with broad sculpted forms, clear class-specific silhouettes, layered armor, believable faces and joint anatomy, weathered metal and leather, readable at gameplay distance. Neutral standing three-quarter poses, full bodies uncropped, no text, no watermark, no logos. Not photorealism, not primitive spheres and boxes.

## Castle

Saved reference: `art_source/concepts/castle13-reference.png`

Exact prompt:

Use case: stylized-concept. Asset type: modular dwarf castle production concept sheet for Blender modeling and Godot co-op survival. Neutral parchment gray background. Show a large isometric cutaway of a player-built dwarf stronghold: central open hearth courtyard on a low raised stone platform with broad entrance steps, square attachable wings on a grid, walls and corner buttresses of layered blue-gray ashlar stone with warm brass bands and teal banners. Some wings are partly built scaffolds with a small wooden resource signpost and stacks of materials. One completed lower wing supports a second floor reached by broad stone stairs with an open stairwell, not inaccessible stacked roofs. Show readable distinct additions: crenellated defensive terrace, covered merchant stall with wares, gathering lodge with pack animals and supplies, rune research observatory with brass astrolabe. Along bottom show clean separate modular wall/doorway, floor slab, stairs, signpost and crenellated corner pieces. Polished stylized game art, convincing stone thickness, practical walkable spaces, clear snap connections and open doorways, broad elegant forms, no tiny illegible labels, no text, no watermark, no unrelated landscape.

## Rebuild

Run `build()` from `art_source/model_castle13.py` and `art_source/model_cast13.py` through Blender. Scripts create copied/new scenes and restore the previously open scene. The cast script supports `heroes=True/False, enemies=True/False`; refinements are rerunnable and preserve animation tracks. Hero base: `art_source/blender/dwarf.blend`. Editable outputs live in `art_source/blender/`; game exports in `assets/models/fort/`.
