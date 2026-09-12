# Fort 24 — Gatehouses and eight-player crews

## Eight dwarves, four roles

One host and seven guests can play through the existing IP/UDP-port lobby. Everyone should use Fort 24. The lobby, character picker, crew HUD and minimap support eight characters. A full server does not admit a ninth player.

The four familiar ability roles each have two visually distinct character choices. Copper Vanguard, Amethyst Warden, Jade Engineer and Dusk Scout join the original four, using the finished skeletal models and animations with coordinated clothing, headwear and beard palettes. These are not four new abilities. Both Engineers receive construction/repair bonuses and discounts; both Scouts retain their gathering/carrying bonuses.

Each of the eight character choices owns a separate saved inventory and progression record. Select the same character when returning; it must be unoccupied. Original four-character saves remain compatible. Pets remain a shared crew limit of three.

Raid budgets now scale through eight players. Existing one-to-four-player multipliers are unchanged. Camps, wilderness encounters and Colossi also scale beyond four. The active raid cap remains 100 enemies and there are still four physical approach fronts; extra pressure comes from the total assault allowance and specialist limits. Joining or leaving changes subsequent assault budgets, not an assault already underway.

## Build a real gatehouse

- **Select:** B opens building. Page Up/Down changes pages; page two, key 1 selects Gatehouse. The mouse wheel cycles all recipes. Q rotates. Align it with a castle entrance or connect curtain-wall ends.
- **Cost:** Hearth tier 2; 40 wood, 64 stone, 18 iron from shared stock. Engineers pay 30 wood, 48 stone, 14 iron. Base health is 1,200.
- **Construct:** place the foundation, then hold E nearby. Any dwarf can help. Three Blender-authored construction stages keep the passage open; work refuses to form piers around an actor. The finished gate starts open.
- **Operate:** tap E within four metres to open or close. Holding E will not repeatedly toggle it. G opens settings, upgrades and salvage. Hold R nearby to repair.
- **Safety:** a closing gate refuses occupied passages and reopens if a dwarf, downed ally, pet or enemy enters. Move clear and tap E again; there is no crushing damage. Gateframes need 6.5m of overhead space. Low roofs, intersecting structures and resources prevent placement.
- **Dusk setting:** optional, off by default, configured per gate in G. It attempts to close at the next dusk, using the same safety checks. Manual opening overrides it for that night; an obstructed attempt stays open until operated again or the following dusk.
- **Reinforce:** upgrades require shared supplies, the appropriate hearth tier and cooperative hammer work. All eight levels have authored reinforcement geometry. A small health bar/state glyph sits above the structure rather than across the doorway.
- **Salvage:** the existing daylight/no-nearby-enemy rule applies. Return 50% of paid materials scaled by remaining health. Castle expansion detects the tall frame and uses the existing confirmation/refund flow before clearing it.

The gatehouse has fitted stone courses, a segmental arch, carved dwarf heraldry, shaped teal banners, lantern cages, wood grain, forged rivets, and moving portcullis/winch/counterweights. Local mechanism sounds and warm lantern light complete it. It was built in Blender from a generated concept reference; the game uses the actual 3D asset, not the concept image.

Normal ground raiders can route through an open gate. Closed gatehouses attract breach specialists; Brutes use their telegraphed strike and Sappers can threaten them. Opening a gate clears stale breach behavior. This is not a complete rewrite of all enemy AI, and connected walkable battlements are not included in this pass.

Gate settings, health, reinforcement, construction progress and moving mechanism state survive saves and late joins. Ordered gate-state counters prevent older snapshots from undoing newer operation results. Normal E-key commands carry the operator's observed gate revision, so simultaneous presses cannot flip the gate repeatedly.

## Testing and version safety

See `tests/FORT24_VALIDATION.md` in the source project for final results. Local multi-process tests do not establish real internet routing or latency performance. The executable's new folder may need a Windows Firewall allowance, just like earlier numbered builds. Fort does not change firewall rules.

Older numbered folders and archives are preserved. No GitHub push is part of this pass.
