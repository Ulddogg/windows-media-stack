# Custom formats

Two opinionated custom formats ship here as importable JSON in
[`../config/custom-formats/`](../config/custom-formats/). Both are plain scoring rules —
no secrets. Import via each app's **Settings → Custom Formats → Import**, or POST to
`/api/v3/customformat`, then set their scores inside a quality profile.

## 1. Audio-language requirement (example: Danish)

Goal: only grab releases that actually contain a specific **audio language** — useful for
kids' content that needs a local-language dub. Two cooperating formats:

- **`*-danish-audio` (title tag)** — ReleaseTitle regex `(?i)\b(danish|nordic)\b`. Catches
  the `NORDiC` / `DANiSH` tags Nordic dub packs use.
- **`*-danish-language` (parsed)** — a Language specification = Danish (language id `6`).
  Catches what the app actually parsed as Danish audio.

Put both in a dedicated quality profile, score each **+5000**, and set the profile's
**Minimum Custom Format Score to 5000**. Now a release only qualifies if it carries a
Danish signal; everything else falls below the minimum and is rejected. Select that
profile per-request in the request front-end when you want a local-language copy.

**Known limitation:** a `NORDiC` pack doesn't *always* include Danish (sometimes just
Norwegian/Swedish/Finnish). The parsed-language format is the accurate signal; the title
tag is a broad helper. If a non-matching pack slips through, blocklist that release and
re-grab. (You can instead make parsed-language the sole qualifier and demote the title
tag to a hint — stricter, at the cost of missing releases the parser can't read.)

> This is a **template for any language** — swap the regex words and the language id for
> German, French, etc. Language ids come from `GET /api/v3/language`.

## 2. Audio Description blocker

Goal: never grab the "with Audio Description" / narration-track versions (the extra voice
that describes on-screen action for accessibility — annoying if you don't want it).

- **`*-audio-description`** — ReleaseTitle regex
  `(?i)(audio[ ._-]?description|[ ._-]ad[ ._-])`, scored **−10000** in your profile.

With the profile's minimum at 0, any AD release scores negative and is rejected. The
regex matches "Audio Description" and a bounded `AD` tag without false-matching words like
"ADDICTION". Verify a format matches what you expect with `GET /api/v3/parse?title=...`
before relying on it — it returns the custom formats a given release name would hit.
