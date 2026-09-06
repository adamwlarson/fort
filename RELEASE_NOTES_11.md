# Fort 11 — The Living March

An exploration-focused update. All Fort 10 networking improvements and Fort 9 progression, weapons, towers and gathering pets remain included. Everyone should use Fort 11 together.

## More destinations

There are **67 additional exploration sites** across the fully upgraded frontier, alongside the existing nine treasure sites and villages. Three new sites are available at Hearth 1; upgrades add six at Hearth 2, eight at Hearth 3, and ten at each tier from 4 through 8. Layouts are seeded and synchronized for the whole crew. They use reusable, dressed encounter layouts rather than 67 individually authored dungeons.

| Site | What you find |
| --- | --- |
| Lost caravans | Broken wagons, cargo and unguarded shared supply caches |
| Beast dens | Rock shelters, bones, territorial razorbacks, bears and wolf packs |
| Blackthorn outposts | Tents, supply crates, banners and patrolling raiders; armored guards in later tiers |
| Forgotten shrines | Crystal altars, rune pillars and guardians; Hexers appear from tier three |
| Starwatch ruins | Broken observatories, ancient stonework, guardians and weapon treasures |
| Dragon roosts | Eggs, bones, gold hoards and an Emberdrake or Frostwyrm; first appear at Hearth 3 |

Each site includes surrounding rocks, foliage, trail signs and a soft, textured ground patch. Outer resource placement leaves the encounter clearings open without removing harvest nodes; the maximum remains 594. Building placement respects site footprints. Dens and major structures have simplified collision, while decorative nest bones and small rubble are walk-through.

## Finding and clearing a site

Approach a landmark to discover it for the crew. Within 160m, the compass provides a bearing and distance to a nearby unclaimed destination; the name is revealed once discovered. Discovered sites get colored square minimap markers; claimed sites become muted outlines. Tall totems, ruins, shrines and trail signs provide visual cues.

Guardians become active within 28m. They patrol locally, defend their territory and persist through dawn. They do **not** target the hearth or deliberately follow players home. A guardian displaced beyond its territory returns and heals; an uncleared encounter abandoned more than 80m away for 30 seconds hibernates and resets, without paying rewards. Cleared and claimed sites do not respawn guardians during that expedition.

Defeat the guardians, approach the chest, and press **E**. New wilderness chests have **no crystal/key cost**. Rewards go straight into shared supplies; weapon and armor unlocks apply to the crew, including late joiners. The original nine chests retain their existing two-crystal locks.

## Five new creatures

- **Razorback:** a tusked boar with a marked charge lane. Sidestep it; walls block the charge and its damage.
- **Direwolf:** a fast pack hunter with close-range bites.
- **Stonebear:** a heavy, stone-armored beast with a marked close-range slam and knockback resistance.
- **Emberdrake:** a winged territorial dragon with a 16m fire-breath cone. Its fixed ground warning gives 1.4 seconds to dodge sideways before the strike.
- **Frostwyrm:** an icy dragon with a marked 4.5m-radius frost burst at the target's position. Move out of the circle before it resolves.

Dragons are ground-based territorial encounters in this pass, not free-flying world bosses. Their wings, jaws, legs and tails are animated. All five creatures have Blender-authored idle, movement, attack, hit and death clips. Dragon attacks include flame/frost particles. Stuns interrupt pending guardian attacks; obstacles block strike damage.

## Crew balance and rewards

Encounter size/health is set when first activated. Solo camps start with two defenders; a four-player camp has five. The first solo dragon has 720 health; dragon health grows with tier and crew. Joining later does not inflate an already active encounter. There can be at most **24 active wilderness guardians**, separate from the nightly raid population allowance; additional encounters wait until capacity is available.

Every cache grants wood, stone and crystal. Tier-two sites also grant iron; tier-three and later sites also grant aether. Normal supplies are `12 + 3*tier` each for wood/stone and `3 + tier` each for the unlocked rarer resources. Dragon hoards double these amounts.

Ruins at tiers 2–3 unlock the **Breach Pick**; later ruins unlock the **Farwatch Longrifle**. Dragon hoards unlock **Mountainfall Maul** at tiers 3–4, **Stormcaller Staff** at tiers 5–6, and **Dawnbreaker** at tiers 7–8, plus **Ironheart armor**. These reward shortcuts bypass crafting requirements. Rewards are claimed once per site, not once per player; duplicate/concurrent requests cannot pay twice.

## Art and verification

Twelve new Blender-made models bring the Fort GLB library to 98: five creatures and seven environmental props. Editable source scenes and `art_source/model_wilderness11.py` are included in the project. The user's previously open tree scene was preserved. Blender is not required to play.

New tests cover seeded placement, resource clearings, animations, crew scaling, telegraphs and dodge geometry, blocked charges, stun interruption, territory limits, dawn persistence, hibernation, population limits, shared rewards and stale state. A dedicated four-process network test checks late-join site state, damaged dragons, remote attack warnings and simultaneous treasure claims.

Release validation passed **16 headless suites, 14 rendered checks, Windows export and nine four-process multiplayer suites against the exported game**. Forty layout seeds were checked for overlapping site footprints. The 100-enemy stress scene averaged 40.4 FPS with a 113.7ms worst frame on this machine (RTX 5090, Compatibility renderer); this is not a 60-FPS or low-end-hardware guarantee. Versioned ZIP packaging checks the embedded executable against the export by SHA-256.

This remains a development build: human encounter-balance and low-end performance testing are still needed. There are no separate dungeon interiors, persistent campaign saves or host migration. The existing UPnP internet-hosting setup is unchanged.
