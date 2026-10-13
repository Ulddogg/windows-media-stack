# Contributing

Thanks for taking a look. This is a personal reference setup shared in the hope it's
useful to others running the *arr stack **natively on Windows, without Docker**.

## Ground rules

1. **Never commit secrets.** API keys, provider/tracker credentials, Plex tokens, real
   IPs, personal paths. Keep them in your local `.env` (git-ignored). CI runs gitleaks.
2. **Never name a private tracker** in any file that could be committed.
3. Keep it **Windows-native** — the whole point of this repo is the no-Docker path. If
   you want a Docker version, there are many excellent ones already (see the README).

## Running the scripts

```powershell
Copy-Item .env.example .env       # then fill in your own values
. .\scripts\lib\arr-common.ps1    # dot-source the helpers
Import-DotEnv
```

The scripts call each app's REST API and are intentionally small, legible building
blocks. Mind the PowerShell 5.1 array-wrapping quirk documented in
[`CLAUDE.md`](CLAUDE.md) and [`scripts/README.md`](scripts/README.md).

## Pull requests

- Keep changes focused and explain the "why".
- Run PSScriptAnalyzer on any PowerShell you touch.
- Documentation-only improvements (clarity, more Windows gotchas, other providers) are
  very welcome.
