# Configuration (API-driven)

The whole stack is configured by calling each app's REST API from PowerShell, so the
setup is reproducible and reviewable instead of a pile of UI clicks. Keys come from
`.env` or each app's `config.xml` at runtime — never hardcode them into tracked files.

See the PowerShell gotcha in [`../CLAUDE.md`](../CLAUDE.md) (the array-wrapping unwrap
`[int]"$(@($x.id)[0])"`) — it applies to every script below.

## Download clients

Add **both** clients to Sonarr and Radarr; leave each in place (don't reorder/remove the
other). Pattern: GET `/api/v3/downloadclient/schema`, pick the implementation
(`QBittorrent`, `Sabnzbd`), fill host/port/apiKey and the category field
(`tvCategory`/`movieCategory` on Sonarr, `movieCategory` on Radarr), POST to `/test`,
then POST to `/api/v3/downloadclient`.

Categories: `tv` and `movies`, mapped to paths under `C:\data` so imports hardlink.

## Indexers (Prowlarr → apps)

Add indexers **only in Prowlarr**, then let it sync them out. Add Sonarr and Radarr as
Applications in Prowlarr, then:

```
POST {PROWLARR}/api/v1/command   {"name":"ApplicationIndexerSync"}
```

Adding an indexer via API: GET `/api/v1/indexer/schema`, find the definition by name,
set its field `value`s (including `apikey` for Usenet/private-tracker definitions), set
`appProfileId` (usually 1) and `tags=@()`, POST to `/api/v1/indexer/test`, then to
`/api/v1/indexer`. Some Cardigann definitions resolve `baseUrl` via a provider action:
`POST /api/v1/indexer/action/getUrls` with the schema body.

> Keep private-tracker names and keys in your local Prowlarr only — never in a file here.

## Quality profiles (Recyclarr / TRaSH)

Don't hand-build quality profiles — sync them from the [TRaSH Guides](https://trash-guides.info/)
with **Recyclarr**. Sanitised configs are in [`../config/recyclarr/`](../config/recyclarr/):
a `WEB-1080p` profile for Sonarr and `HD Bluray + WEB` for Radarr, both capped at 1080p
with remux/BR-DISK excluded (a 1080p remux is 20–40 GB — the real space killer).

The committed configs use `api_key: !env_var SONARR_API_KEY` so no key is stored. Run
`recyclarr sync -c <config>` in a real terminal (it needs a live console).

## Delay profiles — Usenet-first, torrent-fallback

The catch-all delay profile (id 1) on **both** Sonarr and Radarr:

| Field | Value | Effect |
|---|---|---|
| `preferredProtocol` | `usenet` | prefer NZBs over torrents |
| `usenetDelay` | `0` | grab NZBs immediately |
| `torrentDelay` | `60` | hold torrents 60 min for Usenet to land |
| `bypassIfHighestQuality` | `false` | don't let a top-quality torrent skip the wait |

Set via PUT `/api/v3/delayprofile/1`. **Read it back to confirm** — don't assume.

Important nuance: the torrent delay is a release-**age** gate, not a timer that starts on
a failure. A brand-new episode's torrent is held ~60 min while Usenet indexers post the
NZB; a back-catalog torrent is already older than 60 min, so it's eligible immediately.
That's why an old title can drop to torrent seconds after a Usenet attempt fails.

## Indexer priority & per-indexer seeding

Prefer a (private) indexer over public ones by giving it a **lower priority number**
(lower = preferred; default 25). Set `priority` on the Prowlarr indexer and sync — it
propagates to the apps. Protocol preference (Usenet-first) operates above indexer
priority, so Usenet stays first regardless.

Per-indexer seed rules live in the indexer's `torrentBaseSettings`
(`seedRatio`, `seedTime` in minutes, `packSeedTime`) and override the client default for
that indexer's torrents — e.g. ratio `1.0` / `4320` min (3 days) to satisfy a tracker's
rules without over-seeding everything else.
