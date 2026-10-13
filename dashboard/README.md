# Dashboard

A single self-contained HTML page — a "remote control" that links every tool in the stack
on `localhost`, grouped by role (front-of-house: Seerr + Plex; the machinery: Prowlarr,
Sonarr, Radarr, SABnzbd, qBittorrent, Bazarr, FlareSolverr; infrastructure: VPN, Recyclarr).
Bookmark it as the one page you open day to day.

## Safe to publish

The page is **static HTML with only `http://localhost:<port>` links** — no API keys, no
tokens, no personal data. It renders light/dark and works at phone width.

## Included

[`media-stack-remote.html`](media-stack-remote.html) is a ready-made, self-contained page
for this stack — open it in any browser and bookmark it. It's sanitised: only generic
roles (no provider, indexer, tracker or VPN brand names) and only `localhost` links. Edit
the ports/links to match your install.

Why it's worth having: most people juggle a pile of `localhost:PORT` bookmarks or forget
which app lives where. One page that fronts the whole stack — grouped by what each tool
does — turns "which port was Prowlarr again?" into a single click. Cheap to make, used
every day.
