# 01 - create the data tree and prove hardlinks work on this volume.
# Run first. Idempotent.
. "$PSScriptRoot\lib\arr-common.ps1"; Import-DotEnv

$root = if ($env:DATA_ROOT) { $env:DATA_ROOT } else { 'C:\data' }
$dirs = 'torrents\movies', 'torrents\tv',
        'usenet\incomplete', 'usenet\complete\tv', 'usenet\complete\movies',
        'media\movies', 'media\tv'
foreach ($d in $dirs) { New-Item -ItemType Directory -Force -Path (Join-Path $root $d) | Out-Null }
Write-Host "Created the data tree under $root"

# Hardlink smoke test: a link across torrents <-> media must succeed (one NTFS volume).
$src = Join-Path $root 'torrents\tv\.hltest'
$dst = Join-Path $root 'media\tv\.hltest'
Remove-Item $dst -ErrorAction SilentlyContinue
Set-Content -Path $src -Value 'hardlink test'
New-Item -ItemType HardLink -Path $dst -Target $src -ErrorAction SilentlyContinue | Out-Null
$links = @(fsutil hardlink list $src).Count
Remove-Item $src, $dst -ErrorAction SilentlyContinue

if ($links -ge 2) {
    Write-Host "HARDLINKS OK (link count $links) - downloads and media share one volume."
} else {
    Write-Warning "Hardlink test failed - make sure the whole tree is on ONE NTFS volume (not exFAT)."
}
