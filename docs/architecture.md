# Architecture

## The signal path

```
┌──────────┐   ┌──────────┐   ┌────────────────┐
│ Request  │──▶│  Find    │──▶│     Grab       │
│ (Seerr)  │   │(Prowlarr)│   │ Sonarr/Radarr  │
└──────────┘   └──────────┘   └───────┬────────┘
                                       │ preferred protocol: Usenet
                        ┌──────────────┴───────────────┐
                        ▼                               ▼
                ┌───────────────┐             ┌──────────────────┐
                │   SABnzbd     │             │   qBittorrent    │
                │  (Usenet)     │             │ (torrent, VPN)   │
                └───────┬───────┘             └────────┬─────────┘
                        └──────────────┬───────────────┘
                                       ▼
                             ┌───────────────────┐
                             │  Import + hardlink │  (+ Bazarr subtitles)
                             │  into C:\data\media│
                             └─────────┬─────────┘
                                       ▼
                                  ┌─────────┐
                                  │  Plex   │
                                  └─────────┘
```

1. **Seerr** is the front door — a Netflix-style UI where you request a title.
2. It hands the request to **Sonarr** (TV) or **Radarr** (movies).
3. Those ask **Prowlarr**, which queries your indexers and returns releases.
4. The release is sent to a download client: **SABnzbd** (Usenet, preferred) or
   **qBittorrent** (torrent, VPN-bound, fallback).
5. On completion the *arr app **imports** the file — **hardlinking** it into the Plex
   library so there is still only one copy on disk.
6. **Bazarr** fetches subtitles; **Plex** serves the finished library.

## Why no Docker

The mainstream way to run this is Docker Compose on Linux. This stack is deliberately
**native Windows** because:

- The target machine is a Windows PC that also does other things — no Linux host, no NAS.
- No desire to run Docker Desktop / WSL2 just to host a few .NET and Python apps that
  already ship native Windows builds.
- It makes Plex hardware transcoding and GPU access trivial (no container passthrough).

The cost is that you do by hand what a `docker-compose.yml` would do for you: install
each app as a service, wire autostart, and work around a couple of Windows-specific
rough edges (see `installation.md` and `usenet.md`). This repo is that missing manual.

## One volume, hardlinks

The single most important design rule: **downloads and the media library live on the
same NTFS volume, under one root** (`C:\data`). That lets the *arr apps import by
**hardlink** instead of copy — the download and the library entry are two directory
entries pointing at the same bytes.

Consequences:
- A grabbed file can be **seeded and in your library at the same time**, at the cost of
  one copy of disk space, not two.
- Deleting the torrent after seeding does **not** delete the library file.
- It only works within one volume. `exFAT` can't do hardlinks — the drive must be NTFS.
- Verify it really hardlinked (don't assume): see the test in `installation.md`.

## The two download paths

| | Usenet (SABnzbd) | Torrent (qBittorrent) |
|---|---|---|
| Preference | **First** (delay profile) | Fallback after a wait |
| Speed | Fast, direct | Depends on seeders |
| Privacy | No VPN needed | **VPN-bound kill-switch** |
| Seeding | None | Yes (ratio/time rules) |
| Import mode | Move (no seeding) | Hardlink (keeps seeding) |
| Availability | Gaps on new / taken-down content | Broad, incl. niche/new |

Routing between them is handled by a Sonarr/Radarr **delay profile**
(`preferredProtocol=usenet`, torrent delayed 60 min). See `configuration.md`.
Because Usenet and torrents complement each other (Usenet fast but gappy, torrents broad
but slower and VPN-gated), keeping **both** is the point — not picking one.
