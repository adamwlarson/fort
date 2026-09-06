# Fort 10 — Internet hosting update

Includes all Fort 9 gameplay. Eight hearth tiers, endless nights, biomes, weapons, towers and **gathering pets remain included**; see RELEASE_NOTES_9.md for their recipes and controls. Both players should run Fort 10.

## Connecting over the internet

- Hosting now requests a mapping for the selected UDP port using UPnP, matching CodenameMule's approach. The checkbox is on by default and can be disabled for LAN / manual forwarding.
- Discovery, mapping, five-minute refresh and normal-session cleanup run in the background. Application shutdown waits for pending work and cleans up a late successful mapping.
- The lobby shows router status and a **Copy Public IP** button, separate from the LAN address picker. It warns about private / carrier-grade-NAT WAN addresses and mapping conflicts.
- Failed mapping attempts never trigger deletion of the conflicting mapping. Choose another port instead. Fort and Mule both default to UDP 24567.
- Join accepts a bare IP with the separate port field, `IPv4:port`, or `[IPv6]:port`.
- Connection messages distinguish an unreachable UDP host from a host reached but failing lobby registration. Stale Fort 7 error text is removed. Diagnostic stages are logged with `FORT_NET`.

The game does not change Windows Firewall, enable router UPnP, or provide a relay. Allow this extracted executable's path in Windows Firewall. UPnP acceptance is not proof of internet reachability; another player on a separate internet connection must verify it. A crash or forced termination can leave a mapping requiring manual removal.

## Pets: already implemented

Press E at the workshop and choose **Gathering Pets**. Recruit Pack Badgers, Copper Moles or Grove Sprites, subject to their hearth tiers and shared supply costs. There are **three active pets shared by the whole crew**. Assign each wood, stone, crystal, iron, aether or REST. They harvest actual nodes, carry supplies home and deposit into shared storage. Pets gather during daylight and return at night, jump obstacles, steer around scenery and recall with their cargo if trapped. They are noncombat helpers.

## Verification

Release checks passed: 15 headless gameplay/asset/network-setup suites, rendered review of the new title/lobby UI, Windows export and all eight local four-process multiplayer suites against the exported executable. The expedition/pet suite passed twice after correcting its client ordering to wait for the preceding assignment revision before recruiting. ZIP packaging verifies the executable's SHA-256 against the export. The Fort 9 archive is preserved.

`tests/internet10_test.gd` uses a simulated router: endpoint validation, success/refusal/conflict, discovery failure, refresh, cleanup, cancel-during-setup, rapid rehosting, application exit, public-address warnings, lobby controls and both timeout stages. It never maps a real router port. Existing four-process network tests also disable automatic router mapping.

Real public-IP connectivity still requires the host and remote player to try this build. Sessions remain unsaved; this is a networking update, not a save/resume feature.
