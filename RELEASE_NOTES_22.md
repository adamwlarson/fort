# Fort 22 — Siege Watch

This pass adds tactical indicators, not new gatehouses or balance changes.

## Reading the indicators

- **Siege Watch**, below the shared stockpile display: N/E/S/W are fixed directions from the hearth. A gold edge marks the raid director's expected attack fronts. Numbers count living raid enemies in each sector, not remaining spawns; camp guards and wild encounters do not inflate them.
- **Fort condition**: two prioritized repair entries with building name, direction, health percentage and distance. Recent health loss shows UNDER ATTACK for four seconds; 35% health or lower shows CRITICAL. A damaged hearth reserves the first entry. The count includes all damaged defenses; unfinished foundations are omitted from repair recommendations.
- **Priority threats**: up to three compact markers for Sappers, Bombwings, Brutes, Cinderlobbers, Colossi and EmberRunners. Lit fuses rank first, then bombers and bosses. Labels identify the threat and distance; arrows indicate targets outside the central combat view, with BEHIND explicitly labeled. These tactical markers intentionally remain informative through cover; enemy health bars retain their existing occlusion rules.
- **Urgent repair marker**: at most one additional teal marker for the top repair target when recently hit or critical. Hold R near the structure to repair as before.
- Distant encounter guards are excluded; nearby special guards can warn explorers. Raid specialists threaten the fort even if your dwarf is away gathering.

The overlay hides during menus, build placement, downed state and the end screen. Peaceful, undamaged forts have no panel. Repaired or removed structures and dead enemies clear from the alerts. Resource badges no longer cover the siege panel or marker captions.

## Multiplayer and compatibility

Everyone should use Fort 22. Warnings are read-only and ranked locally from existing replicated raid, position and health data. Sappers now include an armed flag in full and batched enemy snapshots, so the HUD does not depend on catching a one-time fuse effect. Existing save format is unchanged. No extra threat-scanning physics rays, audio spam, or per-enemy UI nodes were added; ranking refreshes five times per second.

Previous version folders and ZIPs are preserved. This package is local; it has not been pushed to GitHub.

Validated with 31 headless checks, 28 rendered checks and four packaged four-player local scenarios (siege warnings, feedback, save/load and core multiplayer). This does not replace a two-computer internet playtest.
