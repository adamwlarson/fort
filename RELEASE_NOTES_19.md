# Fort 19 — Hollowback Ridge, collision and camp menu fixes

Escape was bound to the ASCII value 27 instead of Godot's KEY_ESCAPE (4194305), so a real Escape press did not match the cancel action. The binding is corrected, and the player's cancel handler explicitly consumes the event after handling it.

- During play, press Esc to open the camp menu. The host can choose Save expedition or Save & return to title.
- When a building preview is active, the first Esc cancels placement; press Esc again to open the camp menu.
- Esc closes the castle architect or workshop. From the save screen it returns to the camp menu; another Esc returns to play.
- The game keeps running while menus are open. Only the host writes expedition saves.

This update includes all Fort 18 automatic castle clearance changes. Costs, refunds and save format are unchanged. Existing saves remain in the same folder. All players should use Fort 19.

## Hills and a traversable cavern

Hearth level 2 now reveals **Hollowback Ridge**, a first outer-world terrain trial. Look for the named trail sign just beyond the original ward, and the lantern-lit east/west cavern entrances. Its compass direction varies with the expedition seed to keep existing encounters and the quarry clear.

- Walk straight through the cavern for crystal deposits, or walk up the north/south slopes to the eight-metre summit for iron. Neither route requires a jetpack.
- The grassy slopes, rock walls and arched cavern ceiling have matching physical surfaces. The central castle area stays flat.
- Six additional deposits use ordinary harvesting, shared inventory, pet gathering, respawn and save/load systems.
- The hill is protected terrain, not a removable castle-expansion prop. This is one contained terrain landmark, not a full-map heightmap or an underground cave network.
- Terrain placement is deterministic for hosts, joining clients and resumed saves.
- If an older checkpoint already has a castle wing or defense in the ridge footprint, that world retains its flat layout. The compatibility choice is saved and synchronized; no existing buildings are deleted or buried.

## Grounded hearth and solid world props

The campfire's Blender model retained an offset from the old raised pedestal. Its coal bed now rests directly on the castle floor, with matching flame/ember/smoke offsets and a surrounding stone fire ring.

Solid scenery now receives cached collision: wilderness and event chests, arches, mine entrances, encounter props, crates, barrels, carts, rocks and quarry structures. Solid objects use simplified convex shapes for performance; hollow architecture keeps mesh-shaped openings instead of becoming solid bounding boxes. Mineral deposits disable their collision when depleted and restore it when they regrow. Grass, flowers and tiny instanced ground litter deliberately remain non-blocking.

## Optional FPS counter

Open Esc → Show FPS counter to enable a small frames-per-second readout between the objective and crew panels. It is off by default, updates four times per second and remains visible while menus are open. Hosts and clients control their own counter independently. The preference is stored locally in `user://display_settings.cfg` and is restored in later sessions; it is not part of an expedition save or shared network state.

New regression coverage injects actual key events through the viewport and verifies opening the menu, keyboard activation of Save expedition, writing a readable checkpoint, nested menu closing, build-mode cancellation, architect camera restoration, workshop closing and menu access while downed.
