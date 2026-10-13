# Installation (native Windows)

> No Docker, no WSL2. Each app is installed from its official Windows build and set to
> start on boot. Do the prerequisites yourself — **do not paste credentials into an
> agent or a chat; enter them in each app's own web UI.**

## Prerequisites

- An NTFS volume with real free space (video is large; see `build-spec.md §1`).
- Accounts for your indexers/trackers and Usenet provider, and a Plex account.
- A VPN subscription with a Windows client installed (for the torrent path).

## Folder layout (create first)

```
C:\data\
├── torrents\{movies,tv}
├── usenet\{incomplete,complete}
└── media\{movies,tv}
```

Keep it exactly reproducible — a later move to another drive just changes the letter.

## Install order

Install in this order; each step assumes the previous is reachable:

1. **qBittorrent** (download client) — enable the Web UI, set save path to
   `C:\data\torrents`, create `movies`/`tv` categories, and **bind it to the VPN
   network interface** (Options → Advanced → Network Interface). See `vpn-killswitch.md`.
2. **Prowlarr** (9696) — official installer, runs as a service.
3. **Sonarr** (8989) — if the silent installer skips the service, create it by hand
   (mirror Radarr's service with `sc.exe` pointing at `Sonarr.Console.exe`).
4. **Radarr** (7878) — official installer, service.
5. **Bazarr** (6767) — note it re-execs to **base Python**, not its venv; its binary
   deps (numpy, lxml, pywin32, webrtcvad) must be in base Python. Autostart via a hidden
   launcher at logon (see `scripts/`).
6. **SABnzbd** (8085) — install, then run via `SABnzbd-console.exe` from a hidden VBS +
   logon task, because the native 5.x Windows service is broken. See `usenet.md`.
7. **Plex** (32400) — point libraries at `C:\data\media\{tv,movies}`, never at downloads.
8. **Seerr** (5055) — request front-end (successor to Overseerr/Jellyseerr).
9. **Recyclarr** — CLI, used on demand to sync TRaSH quality profiles.

Grant the service accounts (e.g. `NT AUTHORITY\LocalService`) Modify on `C:\data`.

## Autostart

The services survive reboot on their own. Bazarr, SABnzbd, Seerr and FlareSolverr run as
**logon scheduled tasks** — register them with
[`scripts/register-autostart.ps1`](../scripts/register-autostart.ps1) **from an elevated
PowerShell** (the SABnzbd task needs `RunLevel Highest`).

> Environment note: on some setups, scheduled-task registration and files under
> `%APPDATA%\Roaming` are per-user and must be created by *you* running the script, not
> by an automation sandbox. Config written to `C:\ProgramData` / `C:\` via PowerShell is
> the shared, real state the apps read.

## Verify hardlinks BEFORE importing anything real

This is the make-or-break test. In Sonarr, add one show and let it grab a single
episode. When it imports, confirm the hardlink actually happened:

```powershell
# After an import, the file should exist in both the download and media trees
# with on-disk link count 2 (two names, one copy of the bytes):
fsutil hardlink list "C:\data\media\tv\<Show>\Season 01\<file>.mkv"
```

If `fsutil hardlink list` shows **two paths** (one under `media`, one under `torrents`),
hardlinking works. If the Sonarr log says "copied" or free space dropped by two copies,
**stop and fix it** before importing anything else — almost always the download and
media folders are not on the same volume/root.

(Note: Usenet imports are a *move*, not a hardlink — SABnzbd downloads don't seed, so
there's nothing to keep the original for. That's expected, not a fault.)
