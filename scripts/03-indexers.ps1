# 03 - add indexers in Prowlarr, then sync them out to Sonarr/Radarr.
#
# Indexers are BRING-YOUR-OWN. This script shows the pattern and triggers the sync;
# it does NOT hardcode any indexer name or key. Read keys from your .env, and NEVER
# put a private tracker's name or key in a committed file.
. "$PSScriptRoot\lib\arr-common.ps1"; Import-DotEnv
$prow = $env:PROWLARR_URL; $pk = $env:PROWLARR_API_KEY

function Add-Indexer {
    param([string]$DefinitionMatch, [hashtable]$FieldValues)
    $appProfileId = [int]"$(@((Invoke-Arr -BaseUrl $prow -ApiKey $pk -Path '/api/v1/appprofile')[0]).id)"
    $schema = Invoke-Arr -BaseUrl $prow -ApiKey $pk -Path '/api/v1/indexer/schema'
    $tpl = @($schema | Where-Object { $_.name -match $DefinitionMatch })[0]
    if (-not $tpl) { Write-Warning "no definition matches '$DefinitionMatch'"; return }

    # Some Cardigann defs resolve baseUrl via a provider action rather than inline options:
    if (@($tpl.fields | Where-Object { $_.name -eq 'baseUrl' -and -not $_.selectOptions })) {
        $urls = Invoke-Arr -BaseUrl $prow -ApiKey $pk -Path '/api/v1/indexer/action/getUrls' -Method Post -Body ($tpl | ConvertTo-Json -Depth 25)
        $opts = if ($urls.options) { $urls.options } else { $urls }
        $FieldValues['baseUrl'] = "$(@($opts)[0].value)"
    }
    foreach ($f in $tpl.fields) { if ($FieldValues.ContainsKey($f.name)) { $f | Add-Member value $FieldValues[$f.name] -Force } }
    $tpl | Add-Member appProfileId $appProfileId -Force
    $tpl | Add-Member enable $true -Force
    $tpl | Add-Member tags @() -Force
    $body = $tpl | ConvertTo-Json -Depth 25
    Invoke-Arr -BaseUrl $prow -ApiKey $pk -Path '/api/v1/indexer/test' -Method Post -Body $body | Out-Null
    $new = Invoke-Arr -BaseUrl $prow -ApiKey $pk -Path '/api/v1/indexer' -Method Post -Body $body
    Write-Host "added indexer '$($new.name)' (id $($new.id))"
}

# --- examples: uncomment and adapt with YOUR definition name + key (from .env) ---
#   A Newznab/Usenet indexer:
# Add-Indexer 'YourUsenetIndexerName' @{ apikey = $env:USENET_INDEXER_KEY }
#   A private tracker (keep its name/key in .env ONLY, never here):
# Add-Indexer $env:PRIVATE_TRACKER_DEF @{ apikey = $env:PRIVATE_TRACKER_KEY }

# Push whatever indexers exist out to Sonarr/Radarr:
Invoke-Arr -BaseUrl $prow -ApiKey $pk -Path '/api/v1/command' -Method Post -Body '{"name":"ApplicationIndexerSync"}' | Out-Null
Write-Host 'ApplicationIndexerSync triggered.'
