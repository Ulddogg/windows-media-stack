# Custom formats

Importable custom-format definitions for Sonarr/Radarr. They contain scoring rules only —
no secrets. See [`../../docs/custom-formats.md`](../../docs/custom-formats.md) for the full
how-and-why.

| File | What it matches | Suggested score |
|---|---|---|
| `danish-audio-tag.json` | `NORDiC` / `DANiSH` in the release title | **+5000** |
| `danish-audio-language.json` | audio the app parsed as Danish (language id 6) | **+5000** |
| `audio-description.json` | "with Audio Description" / narration-track releases | **−10000** |

## Import

- **UI:** Settings → Custom Formats → **Import** → paste a file's contents (one per file).
- **API:** `POST {app}/api/v3/customformat` with the file as the body.

## Apply in a quality profile

- **Require Danish audio:** put *both* Danish formats in a dedicated profile, score each
  **+5000**, and set the profile's **Minimum Custom Format Score = 5000**. Only releases
  carrying a Danish signal then qualify.
- **Block Audio Description:** add `audio-description.json` to your normal profile at
  **−10000** (with the profile minimum at 0, AD releases go negative and are rejected).

## Adapt to another language

`danish-audio-tag.json` and `danish-audio-language.json` are a template. Swap the regex
words (e.g. `german|deutsch`) and the language id — get ids from `GET {app}/api/v3/language`.
