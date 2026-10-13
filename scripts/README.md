# Scripts

PowerShell automation for the API-driven configuration approach. These are the
reproducible alternative to clicking through each app's web UI.

> **Secrets:** scripts read keys from `.env` (via `Import-DotEnv`) or from each app's
> own `config.xml` at runtime (via `Get-ArrApiKey`). Nothing secret is hardcoded. Copy
> `../.env.example` to `../.env` first.

## Files

Run the numbered scripts **in order** after copying `.env.example` → `.env`.

| File | Purpose | Run as |
|---|---|---|
| `lib/arr-common.ps1` | shared helpers: load `.env`, read an app's API key, `Invoke-Arr` REST wrapper, the array-unwrap helper | dot-sourced |
| `01-create-folders.ps1` | create the `C:\data` tree + prove hardlinks work on the volume | user |
| `02-download-clients.ps1` | add qBittorrent + SABnzbd to Sonarr & Radarr (skips existing) | user |
| `03-indexers.ps1` | pattern for adding indexers in Prowlarr + trigger app sync (bring-your-own) | user |
| `04-quality-profiles.ps1` | sync TRaSH quality profiles with Recyclarr | real terminal |
| `05-delay-profiles.ps1` | set the Usenet-first delay profile on both apps | user |
| `06-custom-formats.ps1` | import the custom formats (Danish audio, AD blocker) | user |
| `07-verify.ps1` | health check: services, indexer sync, delay profile | user |
| `register-autostart.ps1` | register logon scheduled tasks for Bazarr / Seerr / FlareSolverr / SABnzbd | **elevated** |
| `sabnzbd/start-sabnzbd.vbs` | hidden launcher for SABnzbd's console exe (the working Windows approach) | called by the task |

## Pattern

```powershell
. "$PSScriptRoot\lib\arr-common.ps1"
Import-DotEnv

$key  = $env:SONARR_API_KEY            # or: Get-ArrApiKey 'C:\ProgramData\Sonarr\config.xml'
$base = $env:SONARR_URL

# read
$profiles = Invoke-Arr -BaseUrl $base -ApiKey $key -Path '/api/v3/qualityprofile'

# write (build JSON bodies explicitly — see the array-wrapping note below)
Invoke-Arr -BaseUrl $base -ApiKey $key -Path '/api/v3/delayprofile/1' -Method Put -Body $profile
```

**Always remember the PowerShell 5.1 array-wrapping quirk:** a scalar property off an
`Invoke-RestMethod` object can come back as `System.Object[]`. Use `Unwrap` /
`[int]"$(@($x.id)[0])"`, and build JSON fields explicitly (e.g.
`languages = @(@{ id = 6; name = 'Danish' })`) or writes 500 on serialization.

> These are deliberately small building blocks, not a one-click installer — the point is
> that each configuration step is legible and reviewable. Open the repo in Claude Code and
> it can drive them against your live stack (see [`../CLAUDE.md`](../CLAUDE.md)).
