# Fort 24: connecting up to eight dwarves

1. Extract the ZIP on every PC. Everyone must run Fort 24; older builds may use different networking messages. One host and seven guests can play together.
2. On the host, choose a UDP port (default 24567) and click Host Fort. Leave the lobby open.
3. In the lobby, pick the IP for the adapter actually connected to your home network, usually Ethernet or Wi-Fi. Copy IP copies just the address. VirtualBox, Hyper-V, WSL, and VPN adapters can have different, unusable addresses for your other PC.
4. On the other PC, enter that host IP and exactly the same port. Click Join Crew, then Ready Up. The host starts the expedition.

`127.0.0.1` always refers to the computer running that particular copy of Fort. It cannot connect two different computers. LAN clients use the host's internal address; internet clients need the public address and forwarded UDP port. See the [Godot networking guide](https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html).

## Internet hosting (new in Fort 10)

Leave **Internet hosting: request router UDP mapping (UPnP)** checked before clicking **Host Fort**. Fort asks the router to map only the selected UDP port in the background. Wait for the lobby's router status, then use **Copy Public IP** for friends on another internet connection. They enter that IP and matching port, or paste `IP:port`. LAN players should continue using the separate LAN address picker.

**Router mapped UDP ...** means the router accepted the request, not that an outside connection has been verified. Fort refreshes successful mappings every five minutes and removes them on normal leave/exit. A crash or forced termination can leave a mapping behind; remove that Fort mapping manually if needed. The game does not enable UPnP in the router or change Windows Firewall. Uncheck the option for LAN-only / manual forwarding. **Retry UPnP** in the lobby explicitly requests another attempt.

- **UPnP unavailable / refused:** manually forward the selected UDP port to the hosting PC's LAN address, or use another host.
- **Mapping conflict:** leave and select a different unused port on both PCs. Fort does not delete a conflicting mapping. Fort and CodenameMule both default to 24567; do not host both on that port at once.
- **WAN IP not public / CGNAT:** the router reports a private or shared address. Double NAT / ISP carrier-grade NAT may require upstream configuration, an ISP-provided public address or another host. There is no relay or automatic CGNAT bypass.
- **Host not reached:** UDP has not connected. Check host lobby, IP, port, mapping and firewall.
- **Host reached, but lobby registration timed out:** UDP connected but Fort's lobby exchange did not complete. Ensure both PCs run Fort 24 and inspect the host log for RPC errors.

Test public-IP joining from another internet connection. Some routers cannot route their own public IP back inside the same LAN (NAT loopback); use the LAN IP there. See [Godot's UPnP documentation](https://docs.godotengine.org/en/stable/classes/class_upnp.html).

## If the second PC still cannot connect

- Confirm the host is in the lobby or a running game, not on the title screen.
- Check the address against the host's active adapter and confirm both ports match. Do not enter the joining PC's own IP.
- Allow the extracted **Fort_24/Fort.exe** in Windows Firewall for the profile your trusted network actually uses. An allow rule for an older version in a different folder does not cover this executable. Check for explicit blocking rules, too. Application rules use full paths, and explicit block rules override allow rules. See [Microsoft's firewall rule documentation](https://learn.microsoft.com/en-us/windows/security/operating-system-security/network-security/windows-firewall/rules).
- Do not disable the firewall. If adding an exception for LAN-only play, scope it to this executable, the chosen UDP port, and your local subnet. A local-subnet-only rule will not allow remote internet clients. Fort never changes Windows Firewall.
- Confirm neither device is on guest Wi-Fi or a router network that isolates clients. Being connected to the same router does not necessarily mean devices can communicate.
- Check whether a VPN or third-party security suite is changing routing or blocking local connections. Only change its settings if you understand and trust the network.
- For a local test, try swapping which PC hosts. Record the exact IP, selected port, and timeout/error message on each side.

Normal LAN play does not require router port forwarding. Internet hosting generally does; forward the chosen **UDP**, not only TCP, port to the host. Carrier-grade NAT may prevent inbound internet hosting. This is a host-run lobby, not a public directory or relay service.

## Read-only diagnostics

With the host lobby open, open PowerShell in the extracted Fort_24 folder and run:

```powershell
& .\Network-Diagnostics.ps1 -Port 24567
```

Use your selected port if different. The script only reads adapter addresses, network profiles, matching firewall entries, and local UDP listeners. It makes no network/security changes and sends no probes. If local PowerShell policy or permissions prevent it, do not disable those protections; an administrator can run the individual read-only commands shown in the script.

Share the output, exact router status and connection error privately with the person helping debug. Godot's user log also includes `FORT_NET` stage messages. A listening socket, accepted mapping or successful same-PC test does **not** establish that packets can travel between two PCs. Automated tests validate a simulated router, eight local game processes, and rejection of a ninth participant; real LAN/WAN play still needs your separate-PC check.
