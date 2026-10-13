# Security

## No secrets in this repository

This repo contains **no** API keys, tokens, provider or tracker credentials, Plex tokens,
IP addresses, or other secrets. Everything configurable is templated in
[`.env.example`](.env.example); the real `.env` is git-ignored and never committed.

A CI job ([gitleaks](.github/workflows/ci.yml)) scans every push and pull request —
including full history — for accidentally committed secrets.

If you fork or adapt this:

- Keep your real values in a local `.env` only.
- **Never** put a private tracker's name, URL, or key anywhere that could be committed —
  most trackers ban members for public exposure.
- Rotate any credential you think may have been exposed, immediately.

## Reporting

Found a secret that slipped through, or a security issue in the scripts? Please open a
private report via GitHub Security Advisories (Security tab → "Report a vulnerability")
rather than a public issue.
