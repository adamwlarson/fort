# Fort 4 — Beyond the Ward

- Host-run four-player lobby, ready-up, unique classes, and host-controlled start. Late join remains supported.
- Editable UDP port, LAN adapter picker and Copy IP, cancellable connections, 15-second timeout, and clearer troubleshooting. Blank addresses no longer silently use loopback. All players need Fort 4.
- Blender-authored Ashwings: animated wings, flight over walls, and low diving attacks. Crossbows and towers counter them; low dives expose them to melee.
- Blender-authored Ember Runners: faster enemies that ignore dwarf bait and attack the hearth for heavy damage.
- Much larger group-based night spawns, scaling with crew size, night, and hearth tier, up to 100 simultaneous enemies.
- U near the hearth opens daytime upgrades. Tier 2 costs 50 wood / 40 stone / 8 crystal; tier 3 costs 90 / 70 / 18. Shared supplies fund them.
- Each upgrade adds 500 hearth health, 30m accessible radius, 48 harvestable resource nodes, camps, and foliage. The frontier ward and minimap expand. Upgrades attract larger, stronger swarms.
- Enemy spatial-grid separation and baked vertex-color mesh batches reduce the cost of larger raids. Class palettes are reused across menu reconnection.

Includes LAN help and a read-only network diagnostic script. No firewall or router changes are made automatically. The lobby does not bypass NAT, firewall, guest-network isolation, or mismatched versions.

Validation includes gameplay and animation checks, rendered views, a 100-enemy stress scene, and four-process networking for gameplay, crafting, lobby readiness/reconnects, and live upgrades. Real two-PC LAN/WAN validation and extended difficulty tuning remain necessary. Sessions are not saved; the host must remain connected.
