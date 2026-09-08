# Fort 18 validation

Test environment: Windows, Godot 4.5.2, OpenGL Compatibility / RTX 5090, 2026-09-06 local date.

## New clearance checks

`clearance18_test.gd` passed headless and rendered:

- Resources and clearable scenery permit expansion; protected sites and nighttime defense-salvage restrictions remain.
- Footprint checks include wall extents while retaining outside defenses and defenses on another storey.
- Refunds combine health-scaled actual paid costs and unused construction/upgrade reservations, excluding free temporary towers.
- The first destructive UI click changes nothing; the server rejects missing/stale confirmation and repeated plan requests do not double-pay.
- Confirmed placement creates an unfinished wing, clears resources and scenery, disables scenery collision, credits the exact shared refund and dismounts ballista operators.
- Resource respawn and new defense placement are blocked inside unfinished castle footprints.
- Saving/loading retains cleared scenery identities, removed defenses, blueprints and refunded stock. Canceling does not restore objects or repeat salvage.
- Rendered verification confirms only the selected instance in a batched biome prop is removed. GPU instance-transform checks are skipped in the headless dummy renderer.

Inspected `build/clearance18_preview.png`: the removal counts, exact refund, cancellation warning and confirmation button are visible with normal menu scrolling.

The source `clearance_network_driver` passed with four local processes, including a remote architect, rejected stale confirmation, duplicate requests, replicated resource/scenery removal, exact refunds, owner-client ballista dismount, and resynchronization without repeated salvage. This is not a new two-computer public-internet playtest.

## Release regression

`tests/run_art_pass.ps1 -Render -Export -Network` completed with `ART_PASS_CHECKS_OK`: 25 headless suites, 22 rendered suites, Windows export and all 15 packaged four-process multiplayer scenarios passed, including the new clearance scenario.

The 100-enemy fixture passed at 36.8 average FPS and 145.723 ms worst frame on this machine. This is a bounded stress fixture, not a maximum-castle or other-hardware performance guarantee.

`tests/package_version.ps1 -Version 18` verified matching source, copied and ZIP-contained executable hashes. Fort_18.zip is 60,278,777 bytes; SHA-256 `007680C83EFC5567402A75ACE36A12B33248F7FCAE55D57F059E4EBE09D1C57E`. The executable is 124,478,000 bytes, version 0.18.0.

Fort_17.zip was retained unchanged: SHA-256 `0DBDA6ED82F21A42266609C6D7F26353E7CEF628D9FC3F626F4C5E126C5AFBC9`.
