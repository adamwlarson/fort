# Fort 33 — Wildlife and cooking

Everyone must run **Fort 33**. Saves from earlier builds load; the new game and meals start at zero.

## Wildlife

The land now has animals. They can be hunted with any weapon, each has its own temperament and its own voice, and they get stranger the further out you go.

| Animal | Where | Temperament | Drops |
| --- | --- | --- | --- |
| Rabbit | First ring | **Skittish.** Bolts when you come within 8 m, zig-zagging | Game meat |
| Deer | First ring, in herds | **Herd.** Startle one and the whole herd runs | Venison |
| Wild Boar | First ring | **Territorial.** Snorts a warning, then charges if you stay close | Game meat |
| Fox | Second ring | **Curious.** Trails you and watches; runs if you approach | Game meat |
| Hill Ram | Second ring | **Stubborn.** Ignores you until struck, then butts back | Game meat |
| Stag | Second ring | **Herd.** Wary from further off | Venison |
| Woolly Yak | Third ring | **Stubborn.** Slow and very tough; hits hard when angered | Venison |
| Amber Stag | Amberwood | **Herd.** Fast, with glowing antlers | Venison, amber resin |
| Sporeback Tortoise | Mycelium Hollow | **Placid.** Pulls into its shell when struck and shrugs off 70% of blows | Glowcap flesh |
| Cinder Salamander | Cinder Wastes | **Aggressive.** Hunts any dwarf on its ground | Embertail |
| Frost Hare | Glacier Reach | **Skittish.** Bigger and faster than a rabbit | Frost hare |
| Sunhorn | Ancient Gardens | **Stubborn.** A golden ram that hits harder | Sunhorn cut |

- Animals arrive by day, out of sight, and keep to their own ring or biome. The ward holds them in as it does you.
- They call now and then in their own voices, cry out when hit, and show their name when you are close.
- **Raids ignore them and towers never shoot them.** They do not appear on the map as threats.
- A slain animal leaves its game in a pile on the ground. Walk over it to put it in your pack, carry it home and deposit it at the stockpile like wood or stone.

## The cooking pot

Build a **Cooking Pot** from the build menu (**B**, second page, now called **CAMP**): 14 wood and 10 stone, available from the first day. Stand beside it and press **E**.

Cooking turns game from the shared stockpile into servings, which also sit in the shared stockpile, so one dwarf can cook for the crew. Each batch makes two servings and uses one log. Eating a serving at the pot restores health at once and starts a boost that lasts a few minutes.

| Dish | Needs | Restores | Boost |
| --- | --- | --- | --- |
| Hunter's Stew | 2 game meat | 60 | **Hearty:** +2 health a second for 3:00 |
| Roast Haunch | 2 venison | 80 | **Fleet:** +15% movement speed for 3:00 |
| Glowcap Broth | 1 glowcap, 1 game meat | 50 | **Glowing:** +4 health a second and a light around you for 2:30 |
| Embertail Skewers | 1 embertail, 1 game meat | 50 | **Fired up:** +25% weapon damage for 2:30 |
| Frost Hotpot | 1 frost hare, 1 venison | 50 | **Thick-skinned:** 25% less damage taken for 2:30 |
| Sunhorn Platter | 1 sunhorn cut, 1 venison | 50 | **Bountiful:** +1 on every gather and 20% faster gathering for 3:00 |

- Different boosts stack; eating the same dish again renews its timer.
- Active boosts and their time left show above your health bar.
- Dishes made from game the crew has never brought home appear as "???" until you find it.
- Meals are eaten at a pot, not carried into the field.

## Art and sound

The twelve animals were sculpted and animated locally with the same Blender tools as the pets (`art_source/rig26/build_wildlife.py`). Their calls and the cooking sounds were generated with Higgsfield and processed like the Fort 30 audio.

## Known limits

- Numbers (animal health, drop amounts, boost strengths) are a first pass and have not been played through a long expedition.
- Animals share the walk cycle of the pets; they have no separate run, graze or sleep animation.
- Boosts are lost when an expedition is saved and loaded. Meals in the stockpile are kept.
- Pets cannot hunt, and there is no fishing in the lakes yet.
- Animals do not fight raiders or each other.

## Checks

- New suite `tests/wildlife33_test.gd` (48 checks): where each species lives, each temperament's behaviour, drops and deposit, the pot, every dish and boost, and saves.
- `tests/wildlife33_review.gd` renders the animals, the pot and the menu to `build/wildlife33_*.png`.
- All 44 headless suites pass. Three older tests were updated for the longer material list and the extra build-menu entry.
- Four-player network drivers: the eight run all pass on the development build.
- Packaged build: `save_network_driver` failed twice straight after the export and then passed ten times in a row (five development, five packaged). The failing check reads the joining client's state without waiting for it, so it is sensitive to a busy machine.
- A soak run of a normal game (wildlife on, hearth 1 to 5, through a night raid) ran without errors.
