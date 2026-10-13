# Usenet (SABnzbd on Windows)

> Your Usenet **provider** and **indexers** are bring-your-own. Enter the provider's
> server, username and password in the SABnzbd web UI (not in any file here); add
> Newznab indexers in Prowlarr. Nothing secret belongs in this repo.

## The Windows service problem (and the fix)

SABnzbd 5.x's **native Windows service is broken** (it ships without the
`pythonservice.exe` helper), and wrapping `SABnzbd.exe` with NSSM fails too because the
exe force-triggers its own service dispatcher (error 1063).

**Working approach:** run the **console** executable from a hidden launcher at logon.

`scripts/sabnzbd/start-sabnzbd.vbs`:

```vbscript
CreateObject("WScript.Shell").Run _
  """C:\Program Files\SABnzbd\SABnzbd-console.exe"" -f ""C:\ProgramData\SABnzbd\sabnzbd.ini"" -s 127.0.0.1:8085 -b 0", 0, False
```

Register it as a **logon scheduled task** (`RunLevel Highest`) via
`scripts/register-autostart.ps1`. It's reboot-safe and windowless. Confirm it's listening
on its port after a reboot.

## Categories → folders under the data root

Create `tv` and `movies` categories in SABnzbd whose folders resolve under `C:\data`
(e.g. complete dir `C:\data\usenet\complete`, category dir `tv` → `…\complete\tv`). This
keeps completed Usenet downloads on the same volume as the library so Sonarr/Radarr can
import them cleanly. Point Sonarr's SABnzbd client at category `tv`, Radarr's at `movies`.

## The single-provider reality

SABnzbd is set to abort jobs it can't complete (`fail_hopeless_jobs=1`,
`req_completion_rate≈100`), so a job with missing articles fails within seconds rather
than downloading garbage. With **one** provider you'll hit this on:

- **Brand-new releases** — articles not fully propagated yet.
- **Popular/older titles** — articles removed by DMCA takedown.

When it happens, every NZB for that title fails the same way (they all point at the same
missing articles on that backbone), and the *arr app falls back to a torrent. This is
**expected on a single provider**, not a misconfiguration. The real remedy is a second
provider on a **different backbone** added as a *backup* server in SABnzbd — it fills the
missing articles from the other source. Don't "fix" it by lowering the completion
requirement; that just produces broken, unpack-failing files.

Rule of thumb: Usenet is fast and clean for well-propagated content; torrents are the
safety net for brand-new and taken-down titles. Keeping both is the design.
