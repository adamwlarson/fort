# Fort 18 — Make room for the castle

Castle expansion now clears its footprint when the blueprint is placed. No need to chop or mine every tree and rock first. Cleared harvestable resources disappear without giving harvest loot; loose rocks, ordinary landmark props, quarry carts and instanced biome obstacles are also removed where they overlap.

## Defenses in the way

The architect shows resource/scenery/defense counts and the exact shared-stock salvage refund. If defenses overlap, click to review, then confirm their removal and placement of the wing. The host rechecks the affected defenses and refund before accepting; stale confirmations and duplicate requests cannot double-pay.

- Completed defenses return the existing salvage value: 50% of actually paid materials, scaled by remaining health, rounded down per resource. Completed upgrades are included in the paid ledger.
- Unfinished construction/upgrade reservations additionally return their unused-material portion under existing cancellation rules. Temporary free turrets give no refund.
- Overlap uses wall extent and orientation, not just its center. Defenses on other storeys or outside the footprint are retained.
- Operators are dismounted safely when their ballista is cleared.
- Existing salvage safety remains: expansions that remove defenses must happen during daylight with no enemies within 12 metres of those defenses.

## Construction and persistence

The new wing is still a blueprint: hold E at its sign to supply from shared stock, then carried supplies, and continue building. Costs, hearth range and upper-storey/support requirements are unchanged. New defenses cannot be placed inside an unfinished castle footprint.

Resource respawn is blocked by both unfinished and completed castle footprints. Canceling a blueprint does not restore demolished defenses or repeat their refunds. Harvestable resources may regrow normally once the space is unoccupied; cleared decorative scenery stays removed, including across save/load and multiplayer synchronization.

Encounter sites (villages, guarded treasure locations and wilderness encounters), essential fort services and authored terrain remain protected/not removed by clearance. This change applies to castle wings, not the separate B-menu defense placement tool or room remodeling safety rules.

Everyone should use Fort 18. Earlier Fort 14–17 saves load; schema remains 2 with optional cleared-scenery records. Use Fort 18 to resume its saves so earlier builds do not regenerate cleared scenery. Prior ZIP versions are retained.
