# 04 - sync TRaSH quality profiles into Sonarr/Radarr with Recyclarr.
# The committed recyclarr configs read their api key from the environment
# (api_key: !env_var SONARR_API_KEY), so nothing secret is stored.
. "$PSScriptRoot\lib\arr-common.ps1"; Import-DotEnv

$recyclarr = 'recyclarr'    # or the full path to recyclarr.exe
$cfgDir = Resolve-Path (Join-Path $PSScriptRoot '..\config\recyclarr')

foreach ($c in 'web-1080p.yml', 'hd-bluray-web.yml') {
    $path = Join-Path $cfgDir $c
    Write-Host "recyclarr sync -c $path"
    & $recyclarr sync -c $path
}

# Note: recyclarr needs a real console; if it errors with an invalid-handle message,
# run it in a normal terminal rather than a redirected/automation shell.
