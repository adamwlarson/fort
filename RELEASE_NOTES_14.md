# Fort 14 — Return to the Hearth

This pass adds persistent expeditions to the Fort 13 castle build. Everyone in a crew should use Fort 14.

## Save and resume

- Host: press **Esc → Save expedition** and pick one of three manual slots. Click an occupied slot twice to confirm overwriting.
- Every dawn creates a separate **Dawn autosave** after the new day begins.
- **Esc → Save & return to title** writes the **Save & exit** slot before disconnecting the crew. Closing the host window attempts the same checkpoint; a failed save keeps the game open.
- On the title screen select your previous dwarf class, choose **Load expedition**, and select a checkpoint. Loading opens a host lobby; join and ready up as usual, then the host resumes. Late joining also works.
- Slots show save time, day/night, hearth tier and room count. A damaged primary automatically falls back to its verified backup and is marked **BACKUP RECOVERY**.

The live world keeps playing while menus are open. Only the host can save. Leaving without saving requires confirmation; it does not erase existing checkpoints. Ended expeditions cannot overwrite a living checkpoint.

## What persists

- Map seed and biome order; hearth/workshop tiers, shared materials and hearth health.
- Castle layout and storeys, research, room assignments, partial resource donations and construction work.
- Placed defenses, upgrades, damage, temporary lifetimes and paid/refund ledgers.
- Four class-based dwarf slots: location, health, carried materials, weapons and upgrades, relics, armor, backpacks, travel mode/fuel and ability cooldowns. Disconnected classes are retained.
- Gathering pets, assignments, cargo and location; depleted resources and respawn timers.
- Exploration encounters and claimed treasure; events and boss history.
- Day/night clock, surviving enemies and health, raid threat already spent, scheduling and random-generator state.

Character slots follow **class**, not a person's name or network ID. Choose the same class on return. A different person choosing that class inherits its expedition progress; saves are not an account system.

Combat resumes at a safe checkpoint boundary: in-flight attacks/projectiles and visual effects are cleared, enemy attacks must telegraph again, dwarves briefly receive protection, and mounted weapons resume unoccupied. Pet routes are recalculated with cargo intact. The wave does not restart or receive a new threat budget.

## Files and recovery

Windows saves: `%APPDATA%\Godot\app_userdata\Fort\expeditions`.

Each slot uses a `.fortsave` file, a `.bak` previous checkpoint, and a temporary file while writing. New data is flushed and verified with a SHA-256 checksum before replacing the old primary. A damaged primary never replaces a good backup. Copy the whole folder to back up or transfer an expedition; changing game folders does not change the save location.

Save format 1 is bounded and version checked; object deserialization is disabled. There is no cloud sync or automatic host migration. Fort 13 sessions cannot be recovered retroactively because that version did not write saves. The host must load from the title screen, not replace a world while other players are in it.
