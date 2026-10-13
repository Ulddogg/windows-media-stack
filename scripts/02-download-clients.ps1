# 02 - add qBittorrent (torrent) and SABnzbd (Usenet) to Sonarr and Radarr.
# Leaves any existing client in place; skips a client that's already configured.
. "$PSScriptRoot\lib\arr-common.ps1"; Import-DotEnv

$qbHost = '127.0.0.1'; $qbPort = 8081       # your qBittorrent Web UI
$sabHost = '127.0.0.1'; $sabPort = 8085     # your SABnzbd

function Add-Client {
    param($Base, $Key, $Impl, $Name, [hashtable]$Fields, $Priority = 1)
    $existing = Invoke-Arr -BaseUrl $Base -ApiKey $Key -Path '/api/v3/downloadclient'
    if (@($existing | Where-Object { $_.implementation -eq $Impl }).Count -gt 0) {
        Write-Host "  $Name already present - skip"; return
    }
    $schema = Invoke-Arr -BaseUrl $Base -ApiKey $Key -Path '/api/v3/downloadclient/schema'
    $tpl = @($schema | Where-Object { $_.implementation -eq $Impl })[0]
    foreach ($f in $tpl.fields) { if ($Fields.ContainsKey($f.name)) { $f | Add-Member value $Fields[$f.name] -Force } }
    $tpl | Add-Member name $Name -Force
    $tpl | Add-Member enable $true -Force
    $tpl | Add-Member priority $Priority -Force
    $tpl | Add-Member tags @() -Force
    $body = $tpl | ConvertTo-Json -Depth 20
    Invoke-Arr -BaseUrl $Base -ApiKey $Key -Path '/api/v3/downloadclient/test' -Method Post -Body $body | Out-Null
    $new = Invoke-Arr -BaseUrl $Base -ApiKey $Key -Path '/api/v3/downloadclient' -Method Post -Body $body
    Write-Host "  added $Name (id $($new.id))"
}

Write-Host 'Sonarr:'
Add-Client $env:SONARR_URL $env:SONARR_API_KEY 'QBittorrent' 'qBittorrent' @{ host = $qbHost; port = $qbPort; tvCategory = 'tv'; useSsl = $false }
Add-Client $env:SONARR_URL $env:SONARR_API_KEY 'Sabnzbd' 'SABnzbd' @{ host = $sabHost; port = $sabPort; apiKey = $env:SABNZBD_API_KEY; tvCategory = 'tv'; useSsl = $false }

Write-Host 'Radarr:'
Add-Client $env:RADARR_URL $env:RADARR_API_KEY 'QBittorrent' 'qBittorrent' @{ host = $qbHost; port = $qbPort; movieCategory = 'movies'; useSsl = $false }
Add-Client $env:RADARR_URL $env:RADARR_API_KEY 'Sabnzbd' 'SABnzbd' @{ host = $sabHost; port = $sabPort; apiKey = $env:SABNZBD_API_KEY; movieCategory = 'movies'; useSsl = $false }

# If you did NOT enable "Bypass auth for localhost" in qBittorrent, add
#   username = $env:QBITTORRENT_USER; password = $env:QBITTORRENT_PASS
# to the qBittorrent @{ ... } field hashtables above.
