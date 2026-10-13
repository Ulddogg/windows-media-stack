# 05 - make the catch-all delay profile Usenet-first on Sonarr and Radarr.
# NZBs grab immediately; torrents wait 60 min for Usenet to land first.
. "$PSScriptRoot\lib\arr-common.ps1"; Import-DotEnv

function Set-UsenetFirst {
    param($Base, $Key)
    $profs = Invoke-Arr -BaseUrl $Base -ApiKey $Key -Path '/api/v3/delayprofile'
    $def = @($profs | Sort-Object order -Descending)[0]    # catch-all = highest order
    $def | Add-Member preferredProtocol 'usenet' -Force
    $def | Add-Member usenetDelay 0 -Force
    $def | Add-Member torrentDelay 60 -Force
    $def | Add-Member bypassIfHighestQuality $false -Force
    Invoke-Arr -BaseUrl $Base -ApiKey $Key -Path "/api/v3/delayprofile/$($def.id)" -Method Put -Body $def | Out-Null
    # read back - don't assume
    $chk = @((Invoke-Arr -BaseUrl $Base -ApiKey $Key -Path '/api/v3/delayprofile') | Where-Object { $_.id -eq $def.id })[0]
    Write-Host ("  proto={0} usenetDelay={1} torrentDelay={2} bypassHiQ={3}" -f `
        $chk.preferredProtocol, $chk.usenetDelay, $chk.torrentDelay, $chk.bypassIfHighestQuality)
}

Write-Host 'Sonarr:'; Set-UsenetFirst $env:SONARR_URL $env:SONARR_API_KEY
Write-Host 'Radarr:'; Set-UsenetFirst $env:RADARR_URL $env:RADARR_API_KEY
