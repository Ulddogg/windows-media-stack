# VPN kill-switch (native, no Gluetun)

The Docker crowd gets a kill-switch from a Gluetun container. On native Windows the
equivalent is **binding qBittorrent to the VPN's network interface**: Options → Advanced
→ Network Interface → select the VPN adapter. qBittorrent then sends/receives *only* on
that interface, so if the VPN drops, the adapter goes down and the torrent client loses
all connectivity instead of leaking over your real connection.

API equivalent: set `current_network_interface` in qBittorrent preferences. Verify the
switch actually holds by turning the VPN off and confirming torrents stall with
`connection_status=disconnected` / 0 DHT nodes (they should **not** make progress).

## The recurring failure: stale binding after reconnect

**Symptom:** VPN is on and the adapter is up with an IP, but qBittorrent stays
`disconnected`, DHT = 0, and torrents are stuck in `metaDL` / not downloading.

**Cause:** qBittorrent is still bound to the interface *by name*, but when the VPN
reconnected (WireGuard adapters get a fresh IP each time) qBit held a stale/empty bound
address and never re-resolved it.

**Diagnose (qBittorrent Web API, v5):**

```powershell
$qb='http://127.0.0.1:8081'
(Invoke-RestMethod "$qb/api/v2/transfer/info").connection_status      # 'disconnected'
(Invoke-RestMethod "$qb/api/v2/app/preferences").current_interface_address   # EMPTY = the bug
```

**Fix:** re-apply the binding to the adapter's *current* IP, then kick the torrents.
(This stays on the VPN interface the whole time, so there's no leak window.)

```powershell
$qb='http://127.0.0.1:8081'
$ip = (Get-NetIPAddress -InterfaceAlias 'YourVpnAdapter' -AddressFamily IPv4).IPAddress
$json = '{"current_network_interface":"<your-iface-value>","current_interface_address":"' + $ip + '"}'
Invoke-RestMethod "$qb/api/v2/app/setPreferences" -Method Post -Body @{ json = $json }
# qBittorrent v5 renamed these: use /torrents/start and /torrents/stop (not resume/pause)
Invoke-RestMethod "$qb/api/v2/torrents/start"      -Method Post -Body @{ hashes='all' }
Invoke-RestMethod "$qb/api/v2/torrents/reannounce" -Method Post -Body @{ hashes='all' }
```

Get `<your-iface-value>` from `GET /api/v2/app/networkInterfaceList` (it maps your
adapter's display name to the internal value qBit stores).

**Trade-off:** pinning the explicit IP works now but breaks again if the VPN hands out a
different IP next reconnect. Binding by interface name alone *should* auto-follow but in
practice didn't refresh reliably — so after a reconnect, if torrents stall, this is the
first thing to check.
