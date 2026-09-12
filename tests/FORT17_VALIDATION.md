# Fort 17 validation

Validated on 2026-09-06, Windows / Godot 4.5.2. Focused verification for shared castle funding; the full Fort 16 art/combat regression was not rerun for this small pass.

- Six headless suites passed: shared_castle17_test, castle13_test, remodel15_test, save14_test, save14_edge_test, readability16_test.
- shared_castle17_test also passed rendered, including the new guidance/prompt assertion. Inspected build/shared_castle17.png for text wrapping and menu layout.
- Checks cover exact outstanding recipe funding, shared-first priority, carried fallback, partial shortages, no negative stock, no unpaid work, distance authorization, restocking, one-time cancellation refunds and continued hands-on work without repeated charging.
- The exported executable passed three four-process scenarios: castle_network_driver, save_network_driver, remodel_network_driver. Castle clients now send only repeated interaction requests, without explicit funding requests, verifying automatic shared funding under concurrent input.
- Source-to-folder-to-ZIP executable hashes verified by tests/package_version.ps1. Fort_17.zip SHA-256: 0DBDA6ED82F21A42266609C6D7F26353E7CEF628D9FC3F626F4C5E126C5AFBC9.
- Fort_16.zip remains unchanged, SHA-256: 1E89DBD161543E61E457FF6E93535326DF793470A217385AC71099081E9797C2.

Multiplayer tests used separate local processes, not a new physical multi-computer internet test. Saved-game format remains schema 2.
