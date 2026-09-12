# Fort 21 — Castle floor planner and traversal

## Plan the whole castle

Press **K at any castle sign**. The right-hand floor plan shows the castle one storey at a time:

- Finished rooms, gold construction projects with progress strips, green available expansions, and red locked expansions.
- Click a room to inspect its project or services. Click a + to select its source room, direction and blueprint preview. Hover a cell for its name, coordinates and status.
- **Show required support below** switches floors and highlights the exact supporting cell in coral. If the room is unfinished, finish it; if it is absent, build a connected room there. The planner selects the downstairs construction sign when a connection is available.
- **Mark selected room's sign & return to play** adds a temporary world-space sign marker. Walk there to place, supply or work on that project. **Your sign** returns the plan to the sign where you opened the menu.
- Use the floor selector, mouse wheel to zoom, and middle-mouse drag to pan larger layouts.

Inspecting a distant room does not authorize remote building, funding, trading or demolition. The host still checks sign proximity and project revisions. Costs, four-ground-wing requirement (starting keep excluded), structural support and hands-on construction remain unchanged. Planners update from synchronized castle state, including late joining and saved expeditions.

## Traversal and routing

- Enemy and pet obstacle checks account for body width, reducing routes through gaps that only a thin center ray can fit through.
- Added bounded local detour searches around scenery corners and concave obstacles. Searches use physics floor/headroom checks and are limited to two starts per physics frame, with cached paths.
- Routes invalidate when defenses are added/removed, castle geometry changes, or resources become solid/non-solid.
- Ground enemies can follow the actual alternating stair lanes to upstairs targets. Brief pursuit memory prevents immediately abandoning a player while detouring toward the stairs; vertically separated melee targets no longer make the attacker stop underneath them.
- Pets use the local routing and castle approaches, step over low lips, and only attempt hops with checked landing and overhead clearance. Final recall searches for clear stockpile-area ground and preserves cargo rather than using one fixed landing.
- Fall-through recovery for players now requests an authoritative checked landing instead of moving locally to the old fixed spawn. It preserves health and inventory. The existing Esc recovery button remains available.

This is local routing, not a complete world navigation-mesh conversion. Long sealed routes can still require breaching, clearing space or pet recall. Existing collision remains active; this pass does not add gates, siege units, new art, or change castle progression.

All multiplayer peers must use Fort 21. Existing saves remain supported; previous numbered ZIPs are preserved.
