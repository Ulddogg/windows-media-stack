# Scripts

PowerShell automation for the API-driven configuration approach. These are the
reproducible alternative to clicking through each app's web UI.

> **Secrets:** scripts read keys from `.env` (via `Import-DotEnv`) or from each app's
> own `config.xml` at runtime (via `Get-ArrApiKey`). Nothing secret is hardcoded. Copy
> `../.env.example` to `../.env` first.

## Files

| File | Purpose | Run as |
|---|---|---|
| `lib/arr-common.ps1` | shared helpers: load `.env`, read an app's API key, `Invoke-Arr` REST wrapper, the array-unwrap helper | dot-sourced |
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
