# 07 - verify the stack: services reachable, indexers synced, delay profile correct.
. "$PSScriptRoot\lib\arr-common.ps1"; Import-DotEnv

function Ping-Svc {
    param($Name, $Base, $Key, $ApiVer = 'v3')
    try {
        $s = Invoke-Arr -BaseUrl $Base -ApiKey $Key -Path "/api/$ApiVer/system/status"
        Write-Host ("  OK   {0,-10} v{1}" -f $Name, $s.version)
    } catch {
        Write-Warning ("  DOWN {0,-10} {1}" -f $Name, $Base)
    }
}

Write-Host 'Services:'
Ping-Svc 'Prowlarr' $env:PROWLARR_URL $env:PROWLARR_API_KEY 'v1'
Ping-Svc 'Sonarr'   $env:SONARR_URL   $env:SONARR_API_KEY
Ping-Svc 'Radarr'   $env:RADARR_URL   $env:RADARR_API_KEY

$apps = @(
    @{ n = 'Sonarr'; u = $env:SONARR_URL; k = $env:SONARR_API_KEY },
    @{ n = 'Radarr'; u = $env:RADARR_URL; k = $env:RADARR_API_KEY })

Write-Host 'Indexers per app:'
foreach ($a in $apps) {
    $idx = Invoke-Arr -BaseUrl $a.u -ApiKey $a.k -Path '/api/v3/indexer'
    Write-Host ("  {0}: {1}" -f $a.n, ((@($idx | ForEach-Object { "$($_.name)/$($_.protocol)" })) -join ', '))
}

Write-Host 'Delay profile (expect preferredProtocol=usenet):'
foreach ($a in $apps) {
    $d = @((Invoke-Arr -BaseUrl $a.u -ApiKey $a.k -Path '/api/v3/delayprofile') | Sort-Object order -Descending)[0]
    Write-Host ("  {0}: proto={1} usenetDelay={2} torrentDelay={3}" -f $a.n, $d.preferredProtocol, $d.usenetDelay, $d.torrentDelay)
}

Write-Host ''
Write-Host 'Reminder: confirm a real grab hardlinks (fsutil hardlink list on an imported file).'
