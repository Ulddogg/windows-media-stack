# CLAUDE.md — operating this stack with Claude Code

This repo is a **native-Windows (no Docker) media automation stack**. This file is the
runbook: it gives you (Claude) the context to install, configure, verify and debug the
stack by calling each app's REST API from PowerShell. Read it before acting.

## Golden rules

1. **Never commit secrets.** API keys, provider/tracker credentials, Plex tokens, real
   IPs, personal paths or names do not belong in any tracked file. Everything secret is
   read from `.env` (gitignored) or from the app's own config at runtime.
2. **Never publicize a private tracker.** Do not write a private tracker's name, URL or
   key into any file that could be committed. Most trackers ban members for this.
3. **Confirm before outward or destructive actions** — pushing to a remote, deleting
   library files, removing/disabling a download client or indexer, or anything that
   changes state outside this machine. Read before you delete or overwrite.
4. **This is infrastructure, not a content source.** Help with the plumbing. Indexers
   and providers are the user's to bring and configure lawfully.

## The stack

| App | Port | Config location | Notes |
|---|---|---|---|
| Prowlarr | 9696 | `C:\ProgramData\Prowlarr\config.xml` | indexer manager; syncs indexers to Sonarr/Radarr |
| Sonarr | 8989 | `C:\ProgramData\Sonarr\config.xml` | TV; API v3 |
| Radarr | 7878 | `C:\ProgramData\Radarr\config.xml` | movies; API v3 |
| Bazarr | 6767 | `C:\ProgramData\Bazarr\` | subtitles; re-execs to base Python (see docs) |
| SABnzbd | 8085 | `C:\ProgramData\SABnzbd\sabnzbd.ini` | Usenet; runs via console exe (see docs/usenet.md) |
| qBittorrent | 8081 | app settings | torrents; bound to VPN adapter (kill-switch) |
| Seerr | 5055 | `C:\seerr\config\settings.json` | request front-end |
| Plex | 32400 | — | player; Radarr/Sonarr notify it on import |

The API key for each `*arr` app is the `<ApiKey>` element in its `config.xml`; SABnzbd's
is `api_key` in `sabnzbd.ini`; Seerr's is `main.apiKey` in its `settings.json`. Prefer
reading these at runtime over hardcoding, and never echo them into committed files.

## Storage model

Everything under **one NTFS volume**, root `C:\data`:

```
C:\data\
├── torrents\{movies,tv}    # qBittorrent downloads (seeded)
├── usenet\{incomplete,complete\{tv,movies}}   # SABnzbd
└── media\{movies,tv}       # the library Plex reads
```

Downloads and library share the volume so imports **hardlink** (one copy on disk).
The `*arr` apps enforce a Minimum Free Space guard so imports stop before the OS drive
fills. Never point Plex at the download folders.

## Talking to the apps (PowerShell)

- Headers: `@{ 'X-Api-Key' = $key }`. Base paths: `.../api/v3/...` for Sonarr/Radarr,
  `.../api/v1/...` for Prowlarr. SABnzbd uses `?mode=...&output=json&apikey=...`.
- **PowerShell 5.1 array-wrapping gotcha (important):** accessing a scalar property on
  an object from `Invoke-RestMethod`/`ConvertFrom-Json` can return `System.Object[]`
  instead of the value. Always unwrap: `[int]"$(@($obj.id)[0])"`, and build JSON fields
  explicitly (e.g. `languages = @(@{ id = 6; name = 'Danish' })`) or POSTs 500 on
  serialization. This has bitten every indexer/profile script here.
- To add an indexer/download client: GET the `/schema`, fill the field `value`s, POST to
  `/test`, then POST to the real endpoint. Indexers need `appProfileId` (usually 1).
- After changing indexers in Prowlarr, POST `{"name":"ApplicationIndexerSync"}` to
  `/api/v1/command` to push them to the apps.

## Key operational knowledge

- **Usenet-first routing.** The catch-all **delay profile** on Sonarr & Radarr is set
  `preferredProtocol=usenet`, `usenetDelay=0`, `torrentDelay=60`, `bypassIfHighestQuality=false`.
  Result: NZBs grab instantly; torrents wait 60 min for Usenet to land first. The delay
  is a release-*age* gate, so it only holds genuinely new releases — back-catalog torrents
  are eligible immediately. See `docs/configuration.md`.
- **Custom formats** (`config/custom-formats/`): an audio-language requirement
  (title-regex + parsed-language, min-score gate) and an **Audio Description blocker**
  (−10000 so AD/narration releases are rejected). See `docs/custom-formats.md`.
- **VPN kill-switch.** qBittorrent is bound to the VPN adapter by name. After the VPN
  reconnects it can hold a stale/empty bound address → `connection_status=disconnected`,
  torrents stuck in `metaDL`. Fix: re-apply the binding to the adapter's current IP. See
  `docs/vpn-killswitch.md`.
- **SABnzbd on Windows** runs via `SABnzbd-console.exe` from a hidden VBS launcher + a
  logon task, because the native 5.x Windows service is broken. See `docs/usenet.md`.
- **Import blocked by edition tags.** A completed download that says "done" but never
  reaches Plex is usually stuck in Activity → Queue as `importBlocked` because an edition
  tag (DC/Extended/IMAX/Remastered/Unrated) confused the parser. Fix with a manual import
  (`/api/v3/manualimport` → `ManualImport` command). See `docs/troubleshooting.md`.

## Where to look

- `docs/architecture.md` — the signal path and the no-Docker rationale
- `docs/installation.md` — native install order + the hardlink verification test
- `docs/configuration.md` — API-driven config: clients, indexers, quality & delay profiles
- `docs/vpn-killswitch.md` — adapter binding + the stale-rebind fix
- `docs/usenet.md` — SABnzbd console-service workaround; providers are bring-your-own
- `docs/custom-formats.md` — language requirement and AD blocker
- `docs/troubleshooting.md` — the failure modes this stack has actually hit
