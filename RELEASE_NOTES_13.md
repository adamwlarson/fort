# Fort 13 — The Growing Castle

All players must use Fort 13. Existing numbered ZIPs are kept unchanged.

## Build your castle

Start on an open 20m-square raised stone courtyard with broad entrance steps. The hearth, shared stockpile and workshop remain in their familiar positions.

1. Stand beside the brass-and-wood castle signpost south of the hearth and press **K**.
2. Choose an adjoining direction and a wing type. The colored footprint shows the proposed location and explains anything blocking it. Chop/mine resources in the footprint first; immovable landmarks and encounters remain protected.
3. Place the blueprint. Planning itself costs nothing. Carry materials to its sign and hold **E**, or use **Add supplies from shared stockpile** in the K menu. Partial contributions are supported.
4. Once supplied, close the menu and hold **E** at that sign to build. Everyone can help; Engineers work twice as fast and existing solo/small-crew work assistance applies. Wings do not finish automatically.
5. A finished wing gets its own architect sign. Keep extending from those signs to choose your layout. Upgrade the hearth for more territory and higher-tier rooms.

Complete four ground-floor wings, including a **Grand stairwell**, to expand upward. Choose **Upstairs** at the stairwell's sign. Every upper room requires a completed supporting room below. Stairs alternate sides on successive floors so stacked stairs leave headroom. Free-placement defenses use the floor you are standing on; stairwells and signs are kept clear.

| Addition | Material cost | Minimum hearth |
|---|---|---|
| Open courtyard | 30 wood, 55 stone | 1 |
| Grand stairwell | 35 wood, 75 stone | 1 |
| Defensive terrace | 65 wood, 90 stone | 1 |
| Merchant hall | 65 wood, 65 stone, 8 crystal | 2 |
| Gatherers' lodge | 80 wood, 50 stone, 10 crystal | 2 |
| Rune research hall | 60 wood, 90 stone, 16 crystal, 15 iron | 3 |
| Curtain-wall project on a finished room | 40 wood, 100 stone | 1 |

Curtain walls are sixteen real, damageable wall segments with four open gateways. Repair them with R; use G for upgrades or daylight salvage. Their refund ledger uses the materials actually paid, not the normal metal-wall recipe. A defensive terrace includes a working watchtower plus space to build your own defenses.

An unfinished castle project can be canceled at its sign. Only its unused paid materials return to shared stock, rounded down. Finished room foundations, stairwells and service halls are permanent in this pass: they cannot be demolished or destroyed. Their walls and placed defenses can be destroyed. Rooms have fixed 20m modules; this is not free-form wall/floor editing. The current safety limit is 128 rooms and eight storeys, with hearth progression restricting height and footprint. Run state is synchronized for late joining; this does not add save-to-disk persistence.

## Useful rooms

- **Merchant:** use its K menu to trade 8 stone for 5 wood, 8 wood for 5 stone, 20 wood + 10 stone for 2 iron, or 15 wood + 15 stone for 2 crystal. Transactions use shared supplies.
- **Gatherers:** choose wood, stone, crystal, iron or aether at the room sign. The first four completed lodges are staffed. Each delivers up to 2 resources every 12 seconds in daylight, consuming an actual available node within 60m. Hearth/forestry requirements and world bounds still apply. No available node means no delivery. Workers are represented at the lodge; these deliveries do not simulate an NPC walking the entire harvesting route. Existing recruitable pets remain separate.
- **Research:** fund and hand-build Masonry (60 stone, 15 iron: +15% construction work), Ballistics (60 wood, 25 iron, 10 crystal: +15% automatic tower damage), and Logistics (50 wood, 15 crystal: +6 capacity for every dwarf). Research is shared and purchased once per run. Manually fired ballistas retain their existing damage progression.

## Art and playability

- Four separate Blender-authored dwarf outfits: vanguard armor, warden rune collar, engineer goggles/tools, ranger hood/cape. Existing movement, attacks and weapon sockets remain functional.
- Refinement passes across all eighteen enemy models: layered armor, facial scars/trophies, more readable explosive harnesses and flying payloads, beast manes and dragon jaw details. The recent dragon anatomy and wing redesign is retained.
- Six Blender castle-kit models, patterned stone paving, construction scaffolds and resource signs; service halls have visible attendants.
- Initial construction radius grows from 23m to 36m to fit the first castle wings. Four starting expansion routes exclude immovable scenery, while resource clearing remains necessary.
- Raised-floor spawning/rescue, stair clearance, stacked wall placement, enemy approach routing and flyer dive height updated for castle geometry.
- Resources cannot regrow in planned or completed ground-floor wings.

The concept references and exact image-generation prompts are documented in `art_source/concepts/FORT13_PROMPTS.md`; editable Blender sources and rebuild scripts are included in the project.
