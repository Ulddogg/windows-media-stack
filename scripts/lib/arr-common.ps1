# arr-common.ps1 — shared helpers for the media-stack API scripts.
# Dot-source it:  . "$PSScriptRoot\lib\arr-common.ps1"
# No secrets live here; keys come from .env or each app's config.xml at runtime.

function Import-DotEnv {
    <#  Load KEY=VALUE lines from a .env file into the process environment. #>
    param([string] $Path = (Join-Path $PSScriptRoot '..\.env'))
    if (-not (Test-Path $Path)) { Write-Warning "no .env at $Path"; return }
    Get-Content $Path | Where-Object { $_ -match '^\s*[^#].*=' } | ForEach-Object {
        $k, $v = $_ -split '=', 2
        [Environment]::SetEnvironmentVariable($k.Trim(), $v.Trim(), 'Process')
    }
}

function Get-ArrApiKey {
    <#  Read <ApiKey> from a Sonarr/Radarr/Prowlarr config.xml. #>
    param([Parameter(Mandatory)][string] $ConfigXmlPath)
    ([xml](Get-Content -Raw $ConfigXmlPath)).Config.ApiKey
}

function Unwrap {
    <#  Defeat the PowerShell 5.1 array-wrapping quirk: return the scalar. #>
    param($Value)
    @($Value)[0]
}

function Invoke-Arr {
    <#  Thin REST wrapper for the *arr APIs.
        Example:
          Invoke-Arr -BaseUrl $env:SONARR_URL -ApiKey $key -Path '/api/v3/qualityprofile'
    #>
    param(
        [Parameter(Mandatory)][string] $BaseUrl,
        [Parameter(Mandatory)][string] $ApiKey,
        [Parameter(Mandatory)][string] $Path,
        [string] $Method = 'Get',
        $Body
    )
    $headers = @{ 'X-Api-Key' = $ApiKey }
    $uri = ($BaseUrl.TrimEnd('/')) + $Path
    if ($null -ne $Body -and $Method -ne 'Get') {
        $json = if ($Body -is [string]) { $Body } else { $Body | ConvertTo-Json -Depth 25 }
        Invoke-RestMethod -Uri $uri -Method $Method -Headers $headers -ContentType 'application/json' -Body $json
    }
    else {
        Invoke-RestMethod -Uri $uri -Method $Method -Headers $headers
    }
}
