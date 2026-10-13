# Build spec (original design)

The design brief this stack was built from. Native Windows, no Docker/WSL2. Phase 1 is a
single-volume proof of concept on an internal SSD; phase 2 migrates media to a dedicated
NTFS drive (§7).

> Do the prerequisites yourself. **Don't hand credentials to an agent or paste them into a
> chat — enter them in each app's own web UI.**

## 1. Space budget — read first

Video is large and the OS drive is shared, so cap space on purpose. Reserve headroom for
Windows growth/updates; give the rest to `C:\data`. Enforce it with the **Minimum Free
Space** setting in Sonarr/Radarr (e.g. stop importing below 150 GB) so the library
self-limits before the OS drive is in trouble.

Rough 1080p sizes: WEB-DL movie 5–8 GB; TV episode 2–3 GB; **Bluray remux 20–40 GB** (the
space killer — exclude it); 4K remux 40–80 GB (out of scope in phase 1). Pick a lane:
a given volume is a films library *or* a TV library, not both at full tilt. Seeding costs
no extra space while it stays on the volume (hardlinks = one copy).

## 2. Folder layout

One root, one volume (this is what makes hardlinks work):

```
C:\data\
├── torrents\{movies,tv}
├── usenet\{incomplete,complete}
└── media\{movies,tv}
```

Never put downloads under `Downloads`/`Videos`. Keep the tree reproducible so a later
move to `D:\data\...` only changes the drive letter.

## 3. Install order

qBittorrent → Prowlarr → Sonarr → Radarr → Bazarr → Plex → Seerr → Recyclarr (plus
SABnzbd + FlareSolverr). Services where possible; logon tasks for the rest. See
[`installation.md`](installation.md).

## 4. Configuration — the parts that matter

- **qBittorrent:** save path `C:\data\torrents`; `movies`/`tv` categories; **bind to the
  VPN network interface** (kill-switch); seeding ratio/time limits; cap max active
  downloads; delete torrent on limit (the hardlink keeps the library file).
- **Prowlarr:** add indexers here only; add Sonarr/Radarr as Apps so indexers sync out;
  FlareSolverr for Cloudflare-gated trackers.
- **Sonarr/Radarr:** root folders under `C:\data\media`; **Use Hardlinks instead of
  Copy**; **Minimum Free Space** guard; **1080p cap, remux/BR-DISK excluded** (let
  Recyclarr apply a TRaSH profile); TRaSH naming.
- **Plex:** libraries point at `C:\data\media\{tv,movies}`, **never** at downloads.
  Remote streaming needs Plex Pass / Remote Watch Pass; home viewing is free.
- **Bazarr:** connect to Sonarr/Radarr; set your subtitle language profile.

## 5. Verification test (before anything real)

Grab one episode, let it import, and confirm the log says **"Hardlink created"** (not
copied) and the file exists in both the download and media trees with free space down by
**one** copy. If it copied, stop and fix the volume/root before importing more.

## 6. Known failure modes

| Symptom | Cause |
|---|---|
| Files copied, not hardlinked | Downloads and media not on the same root/volume |
| Windows becomes unstable | OS drive filled — Minimum Free Space not set |
| Import fails silently | Path mismatch between the client's view and the *arr app |
| Indexer offline | Cloudflare challenge — needs FlareSolverr |
| Library grows too fast | 4K profile enabled, or seeding limits not set |

## 7. Phase 2 — migrating to an external drive

Format **NTFS** (not exFAT — exFAT can't hardlink). Fixed drive letter; disable USB
selective suspend. Recreate the identical tree. **Expect hardlinks not to survive the
copy** (Robocopy doesn't preserve them) — so: stop services → copy `media` → update root
folders in Sonarr/Radarr and save paths in qBittorrent → re-check or retire old torrents →
verify (re-run §5) → delete the old root. Buy for **capacity, not speed** (streaming is
low-bandwidth); a single drive is a single point of failure — accept that consciously.

## 8. Out of scope (for now)

Remote access / reverse proxy; 4K and transcoding tuning; Lidarr/Readarr/Tdarr; a backup
strategy for the config folders (worth adding once running).
