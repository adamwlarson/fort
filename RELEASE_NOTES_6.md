# Fort 6 — Build Together, Hold Together

Extract Fort_6 and run Fort.exe. Every player must use version 6. Earlier version folders and ZIPs are preserved. Network hosting still uses an IP address and your chosen UDP port; no firewall or router settings are changed automatically.

## Collaborative construction

- B and 1–7 choose a defense. Clicking places a vulnerable foundation and reserves its shared materials.
- Hold E beside the project to hammer it into existence. R can also contribute. Anyone can help, with separate per-player cooldowns; Engineers contribute twice the work.
- Walls take six normal hammer strokes; towers take ten. Foundations become scaffolds, then partially assembled structures, then functional defenses.
- Unfinished defenses have 30% of normal health and do not attack or heal. Existing damage carries into the finished structure.
- G starts an eight-stroke upgrade project. The existing defense remains operational at its old level while being upgraded.
- G also displays unused materials and lets the project owner or host cancel after confirmation. Only the unused fraction is returned, rounded down. Enemy destruction returns nothing.
- Wall ends snap together, including right-angle corners. Crossing walls are rejected. The current build-range boundary is visible only during construction mode.
- Construction uses a visible hammer, impact chips, sounds, scaffolding, and a small progress bar. Progress, completion and refunds synchronize to late joiners.

## Siege behavior

- Raiders and hearth runners check short routes around exposed wall ends; if no short route is available, they breach instead of endlessly sliding along a wall.
- Brutes favor nearby walls and deliver telegraphed heavy structural hits.
- Sappers favor vulnerable work sites and towers. Other blocking defenses can still force a breach first.
- Camp guards patrol, investigate the last sighted position when an alarm is raised, and remain leashed to their camp. Chieftains hold still during their slam windup.
- Ashwings give a visible warning before diving.

## Rustscar quarry

Hearth tier two unlocks a rebuilt quarry with two climbable shelves, connecting ramps and landings, elevated harvestable iron, a crane, repaired timber crossing, sealed mine entrance, retaining walls, rails and carts. Five new Blender assets have editable source sculptures and repeatable generation scripts. The mine entrance is scenery, not a separate dungeon.

Controls remain U hearth, G project/upgrade, E gather/deposit/work, B construction, 1–7 recipe, Q rotate, R repair/work, RMB crossbow aim, LMB attack, C switch weapon, F ability, T travel gear.

Gameplay and rendered tests cover construction, refunds, snapping, routing, siege attacks and both quarry ramps. Four-process tests cover late joining, concurrent workers, upgrades, shared inventories, equipment and lobby behavior. Real two-PC LAN/WAN testing, lower-end hardware testing and extended balance playtesting remain necessary. No persistent saves or host migration.
