# Troubleshooting — failure modes this stack has actually hit

## Download "completed" in the client but never appears in Plex

Almost always an **import blocked** in Sonarr/Radarr. Check Activity → Queue for an item
flagged `importBlocked` — often *"matched to movie by ID … Manual Import required."* The
usual cause is an **edition tag** (`DC`/Director's Cut, `Extended`, `IMAX`, `Remastered`,
`Unrated`) confusing the parser, so it won't auto-import for safety.

Fix in the UI: Activity → Queue → click the item → **Manual Import** → confirm the
movie/episode → Import. Via API: `GET /api/v3/manualimport?downloadId=<id>` then POST
`{name:"ManualImport", importMode:"move", files:[{path, folderName, movieId, quality,
languages, releaseGroup, downloadId}]}` to `/api/v3/command`. Build `languages` explicitly
(`@(@{id=1;name='English'})`) or the POST 500s on serialization. A Plex connection in the
app (Settings → Connect) with "On Import" on will re-scan Plex automatically once imported.

## Torrents won't download even with the VPN on

Stale VPN interface binding in qBittorrent — see [`vpn-killswitch.md`](vpn-killswitch.md).
Tell-tale: `connection_status=disconnected`, 0 DHT, torrents in `metaDL`, and an **empty**
`current_interface_address`.

## Every Usenet grab fails the same way ("cannot be completed")

Missing articles on your single provider — see [`usenet.md`](usenet.md). Expected for
brand-new or DMCA'd titles; the stack falls back to torrent. The real fix is a second
provider on a different backbone, not more retries.

## A grab went torrent when you expected Usenet

Check the history. Two legitimate reasons: (a) **every** NZB failed on the provider and it
fell back; or (b) the **release-age** delay — a back-catalog torrent is already past the
60-min gate, so it's eligible the instant Usenet is exhausted. Neither is a bug. Only
`bypassIfHighestQuality` can let a torrent skip the wait — keep it off if you always want
Usenet to get first crack. See [`configuration.md`](configuration.md).

## A wrong-audio or AD version got imported

Blocklist that release (so it isn't re-grabbed), delete the file, and re-search; the
[Audio Description blocker](custom-formats.md) or language requirement keeps the
replacement clean. Blocklist via `POST /api/v3/history/failed/<grabbedHistoryId>`; delete
via `DELETE /api/v3/episodefile/<id>` (or `moviefile`).

## Ethernet shows a 169.254.x address / Plex streaming stutters over Wi-Fi

The wired adapter failed DHCP and self-assigned an APIPA address (no gateway), so Windows
routes everything over Wi-Fi. If a router reboot doesn't fix it and Wi-Fi *does* get a
lease, the fault is the **wired path** (cable or the port it's in), not the PC — the NIC,
driver and link can all be fine. Swap the cable, try another port, bypass any intermediate
switch. Windows auto-prefers Ethernet once it gets a real lease (nothing to change on the
PC). To prove router-vs-cable: give Ethernet a temporary static IP in-subnet (no gateway)
and ping the router — a reply means it's a DHCP issue, no reply means a dead physical path.

## PowerShell reads return `System.Object[]` instead of a value

The 5.1 array-wrapping quirk. Unwrap scalars with `[int]"$(@($obj.prop)[0])"` and build
JSON body fields explicitly. It has corrupted indexer/profile reads throughout — when a
count or id looks wrong, suspect this before the API.
