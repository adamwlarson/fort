# Fort 23 — A quieter minimap

- Fixed-scale, north-up local navigation: the white arrow is you, and 100 metres is the radius. The map follows your dwarf instead of compressing the entire growing world.
- Gold square: hearth. A gold rim arrow points home when it is outside the local view. A subtle footprint shows completed ground-floor castle rooms.
- Numbered circles: other dwarves, matched to the crew list. A plus marks a downed ally; a double ring marks an ally outside local range. Nearby overlapping markers are gently separated for readability.
- Red markers group threats into at most eight directions. A ring means multiple enemies. Close threat markers are nudged into clear slots rather than hidden under the player arrow. Distant enemies are omitted, and camp/wilderness guards appear only within 35 metres. Global assault fronts remain in Siege Watch.
- Gold diamonds: up to four nearby discovered, unclaimed exploration sites. Hidden and completed sites no longer clutter the minimap.
- **M toggles resource patches** during play. Off by default each expedition; when enabled, at most ten patches represent nearby resources, with rarer materials preferred within each patch. These are approximate navigation hints, not exact quantities or every deposit.
- Removed the all-world resource-dot cloud, old landmark letters, trail spaghetti and duplicate raid-front arrows. The map refreshes five times per second and skips resource scanning when that layer is off.
- The minimap hides in menus and building mode. Resource labels cannot draw over it, and the compact legend has a dark backing for readability.

This is a local HUD change: no new network messages, save-schema changes, combat changes or resource mutations. Everyone should use Fort 23. Previous numbered packages are preserved; no GitHub push is part of this pass.

Validated with 32 headless checks, 29 rendered checks and four packaged four-player local scenarios. This is not a new two-computer internet playtest.
