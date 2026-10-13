# 06 - import the custom formats into Sonarr and Radarr.
# Scores are applied inside a quality profile afterwards (see docs/custom-formats.md).
. "$PSScriptRoot\lib\arr-common.ps1"; Import-DotEnv
$cfDir = Resolve-Path (Join-Path $PSScriptRoot '..\config\custom-formats')

function Import-CF {
    param($Base, $Key, $JsonPath)
    $name = (Get-Content -Raw $JsonPath | ConvertFrom-Json).name
    $existing = @(Invoke-Arr -BaseUrl $Base -ApiKey $Key -Path '/api/v3/customformat' | Where-Object { $_.name -eq $name })
    if ($existing.Count -gt 0) { Write-Host "  '$name' already exists - skip"; return }
    $new = Invoke-Arr -BaseUrl $Base -ApiKey $Key -Path '/api/v3/customformat' -Method Post -Body (Get-Content -Raw $JsonPath)
    Write-Host "  imported '$name' (id $($new.id))"
}

foreach ($app in @(
        @{ n = 'Sonarr'; u = $env:SONARR_URL; k = $env:SONARR_API_KEY },
        @{ n = 'Radarr'; u = $env:RADARR_URL; k = $env:RADARR_API_KEY })) {
    Write-Host "$($app.n):"
    Import-CF $app.u $app.k (Join-Path $cfDir 'audio-description.json')
    Import-CF $app.u $app.k (Join-Path $cfDir 'danish-audio-tag.json')
    Import-CF $app.u $app.k (Join-Path $cfDir 'danish-audio-language.json')
}

Write-Host ''
Write-Host 'Imported. Now set scores in a quality profile (Settings - Profiles):'
Write-Host '  - Audio Description = -10000 on your normal profile (blocks AD/narration releases)'
Write-Host '  - Danish tag + Danish language = +5000 each, with the profile Minimum Custom'
Write-Host '    Format Score = 5000, to REQUIRE Danish audio (see docs/custom-formats.md).'
