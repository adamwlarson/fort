# Fort 31 — Raids that answer your fort, elites, and biome materials

Everyone must run **Fort 31**. Saves from earlier builds load; the new materials start at zero.

## Raids grow with the fort

Until now a raid depended only on the night, the crew and the hearth tier. A crew with forty upgraded towers faced the same horde as one with five.

- **Fort strength.** Every finished tower counts by kind and upgrade level (a level-1 Watchtower is 10, a level-3 one is 20, a Sunlance four times that). Walls count a point each, castle rooms 6, building pieces a little.
- **A modest fort is free.** The first 60 points plus 60 per hearth tier draw no extra attention.
- **Beyond that the raid grows.** Every further 400 points adds another full raid's worth of threat, up to 2.25 times the base. Raiders are also tougher (up to +50% health at the cap), and more may be alive at once (up to 140, was 100).
- **You are told.** At dusk the crew sees "THE HORDE ANSWERS YOUR WALLS" with the fort strength and the bonus. Siege Watch shows the bonus during an assault, and the hearth menu (**U**) shows your current strength.

## Elite raiders

From **night 8** the raid spends part of its budget on champions. Each costs a little over twice the threat of the raider it replaces, wears a glowing crest and ring, and shows its name.

| Elite | What it does | How to answer it |
| --- | --- | --- |
| **Ironhide** | 2.6 times the health, hits 20% harder, slightly slower | Focus fire; do not let it soak your towers |
| **Frenzied** | 45% faster, hits 50% harder, 1.5 times the health | Stop it before it reaches the wall |
| **Warbanner** | Twice the health; raiders within 9 m take 30% less damage | Kill the banner first |

Raiders, Brutes, Ember Runners, Prowlers and Shieldguards can be elite. The chance starts at 5% and climbs with the night and with a strong fort, to at most 30%. At most a few are alive at once (crew size + 1, rising slowly).

Killing one pays the whole crew: 2 crystal, triple experience, and from hearth 4 one or two of your newest biome's material.

## One material per outer biome

The five outer biomes used to hand out the same five materials as the first three rings. Each now grows one of its own:

| Biome | Material |
| --- | --- |
| Amberwood | Amber resin |
| Mycelium Hollow | Glowspore |
| Cinder Wastes | Cinderite |
| Glacier Reach | Frostglass |
| Ancient Gardens | Sunbloom |

One deposit in six in each biome ring is its material (twelve per ring), tinted in the material's colour. Gather, carry and deposit it like anything else. Wilderness treasure in a biome includes some. Because each expedition shuffles its biomes, the order you meet them in changes from run to run.

## What the materials buy

- **The hearth.** From tier 5 on, the next tier also needs the material of the biome you opened last (8, then 12, 16, 20).
- **Tower levels 5 to 8.** Reinforcing a defense past level 4 needs a few of a biome material: the first biome's for level 5, the next for level 6, and so on.
- **Hearth boons (new).** Press **U** at the hearth. Each material buys a permanent boon for the whole crew, in three ranks costing 6, 12 and 20 of it plus some aether:

| Material | Boon | Each rank |
| --- | --- | --- |
| Amber resin | Sealed Timber | +25% repair, walls take 8% less damage |
| Glowspore | Glowspore Salve | Dwarves regenerate 1 health a second |
| Cinderite | Cinderite Shot | +8% tower damage |
| Frostglass | Frostglass Ward | The hearth takes 12% less damage |
| Sunbloom | Sunbloom Harvest | 25% chance of +1 on every gather |

## Known limits

- The numbers are a first pass and have not been played through a long expedition. Expect the fort-strength curve and elite chances to need tuning; tell me where it feels unfair or too easy.
- Biome materials cannot be traded at the merchant, gathered by pets, or used in weapon upgrades yet.
- Elites use the ordinary raider models with a crest, ring and (for the Warbanner) a standard; they have no unique art.
- Existing forts on old saves will see harder raids from the first night after loading, because their strength now counts.

## Checks

- New suite `tests/fort31_test.gd` (41 checks): fort strength and pressure, the budget and raider health they drive, each elite's effect and reward, elites within budget on a night-20 raid, the materials in the biome rings, the costs they feed, every boon, and saves from before Fort 31.
- `tests/fort31_review.gd` renders the elites, a material deposit and the hearth menu to `build/fort31_*.png`.
- All 43 headless suites pass. Six older tests were updated: four compared the stockpile or the material list against the old five, one overrode a function that gained a parameter, and the Fort 6 quarry test assumed the quarry stood at height zero.
- Four-player network drivers: the twelve run all pass, plus two on the packaged build.
- Also fixed from Fort 30: on seeds with very broad lakes, some trees and ore were left standing in the water. They now reach the shore.
- `improvements25_test` fails about one run in ten on "outer wall moves outward as castle expands". It depends on where that seed puts a wilderness site and predates Fort 31.
