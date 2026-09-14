# === ev_core_system_map_check.ps1 ===
# Loads Ev repo "full crypto / Starforge / VR" system map (if present) and verifies
# EV AI, EV_Files, EV core paths — read-only, no secrets.
#
#   pwsh -NoProfile -File scripts\ev_core_system_map_check.ps1

param(
    [string]$EvRoot = "",
    [string]$MapPath = "",
    [string]$TeakaRoot = "",
    [string]$SaveTo = ""
)

$ErrorActionPreference = "SilentlyContinue"

function Resolve-EvRoot {
    if ($EvRoot -and (Test-Path $EvRoot)) { return $EvRoot }
    foreach ($p in @("C:\Users\blair\EV_Git\Ev", "C:\Users\Blair\EV_Git\Ev")) {
        if (Test-Path (Join-Path $p ".git")) { return $p }
    }
    return "C:\Users\blair\EV_Git\Ev"
}

function Find-SystemMap {
    param([string]$Root, [string]$Explicit)
    if ($Explicit -and (Test-Path $Explicit)) { return (Resolve-Path $Explicit).Path }
    $patterns = @(
        "*FULL_CRYPTO_STARFORGE*SYSTEM_MAP*",
        "*full_crypto_starforge_vr_system_map*",
        "EV_FULL_CRYPTO_STARFORGE_VR_SYSTEM_MAP*.json"
    )
    foreach ($pat in $patterns) {
        $hit = Get-ChildItem -LiteralPath $Root -Filter $pat -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '\\\.git\\' } |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        if ($hit) { return $hit.FullName }
    }
    $evidence = Join-Path $Root "brain\evidence"
    if (Test-Path $evidence) {
        Get-ChildItem -LiteralPath $evidence -Filter "*.json" -File -ErrorAction SilentlyContinue |
            ForEach-Object {
                $head = Get-Content $_.FullName -TotalCount 5 -Raw -ErrorAction SilentlyContinue
                if ($head -match "ev\.full_crypto_starforge_vr_system_map") { return $_.FullName }
            }
    }
    return $null
}

function Test-PathRow {
    param([string]$Label, [string]$Path)
    $exists = $false
    if ($Path -and (Test-Path -LiteralPath $Path)) { $exists = $true }
    return [ordered]@{ label = $Label; path = $Path; exists = $exists }
}

$ev = Resolve-EvRoot
if (-not $TeakaRoot) {
    $TeakaRoot = Split-Path $PSScriptRoot -Parent
    if (Test-Path "C:\Users\blair\EV_Git\teaka_trading_app") {
        $TeakaRoot = "C:\Users\blair\EV_Git\teaka_trading_app"
    }
}
$scratch = Join-Path $TeakaRoot "scratch"
if (-not (Test-Path $scratch)) { New-Item -ItemType Directory -Path $scratch | Out-Null }
if (-not $SaveTo) { $SaveTo = Join-Path $scratch "ev_core_system_map_status.json" }

$mapFile = Find-SystemMap -Root $ev -Explicit $MapPath
$map = $null
if ($mapFile) {
    try {
        $map = Get-Content -LiteralPath $mapFile -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        $map = @{ parse_error = $_.Exception.Message; file = $mapFile }
    }
}

$corePaths = @(
    (Test-PathRow "C EV brain runtime (Operator)" "C:\EV_Operator"),
    (Test-PathRow "EV AI" "C:\EV_AI"),
    (Test-PathRow "EV Files (D)" "D:\EV_Files"),
    (Test-PathRow "EV Files (E)" "E:\EV_Files"),
    (Test-PathRow "EV Node git" "D:\EV_Files\EV_Node"),
    (Test-PathRow "Starforge (Dropbox)" "D:\Dropbox\Starforge"),
    (Test-PathRow "Starforge (alt)" "C:\Users\Blair\Dropbox\Starforge"),
    (Test-PathRow "Map root_system ev_brain label" "C:\EV_Brain"),
    (Test-PathRow "EV Operator Workspace ev-reth" "C:\EV_Operator_Workspace\EV_Git\_Upstream\evstack_ev-reth")
)

$out = [ordered]@{
    generated_at = (Get-Date).ToString("o")
    naming       = @{
        canonical_brain_name = "C EV brain (masher / master index)"
        map_ev_brain_path    = "C:\EV_Brain in system map = resolver/mirror root label, not the name 'C EV brain'"
        runs                 = @("C EV brain masher", "EV AI (C:\EV_AI)", "EV Files (D/E)", "EV core layers per map", "Starforge vault/runtime", "ev-node (EV_Node)")
    }
    ev_repo      = $ev
    system_map   = @{
        file   = $mapFile
        schema = $map.schema
        map_id = $map.map_id
        status = $map.status
        host   = $map.host
        clocked = $map.clocked
        project = $map.project
    }
    path_checks  = @($corePaths)
    starforge    = @{}
    geo_crypto   = @{}
    ev_reth      = @{}
}

if ($map -and $map.root_system) {
    $out.map_root_system = @{
        ev_brain_path_label = $map.root_system.ev_brain
        role                = $map.root_system.role
        integrated_layers   = @($map.root_system.integrated_layers)
    }
}

if ($map -and $map.starforge) {
    $out.starforge = @{
        status = $map.starforge.status
        verified_prior_local_checkout = $map.starforge.verified_prior_local_checkout
    }
}

if ($map -and $map.ev_reth_blockchain) {
    $out.ev_reth = @{
        project = $map.ev_reth_blockchain.existing_node
        local_checkout = $map.ev_reth_blockchain.local_operator_upstream_checkout
    }
}

if ($map -and $map.gproof_geo_grid_tokenization) {
    $out.geo_crypto = @{
        status = $map.gproof_geo_grid_tokenization.status
        ticker = $map.gproof_geo_grid_tokenization.ticker
        unresolved = $map.gproof_geo_grid_tokenization.unresolved_bridge.status
    }
}

$out | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $SaveTo -Encoding utf8

Write-Host "=== C EV brain + EV core system map check ===" -ForegroundColor Cyan
Write-Host "C EV brain runs with EV AI, EV Files, EV core (per Ev system map)." -ForegroundColor DarkGray
if ($mapFile) {
    Write-Host "Map: $mapFile" -ForegroundColor Green
    Write-Host "  $($map.map_id) [$($map.status)] clocked=$($map.clocked)" -ForegroundColor Gray
} else {
    Write-Host "System map JSON not found under Ev — paste path with -MapPath or add to brain/evidence/" -ForegroundColor Yellow
}
Write-Host "`nPath checks:" -ForegroundColor Yellow
foreach ($row in $corePaths) {
    $mark = if ($row.exists) { "OK" } else { "missing" }
    Write-Host "  [$mark] $($row.label)" -ForegroundColor $(if ($row.exists) { "Green" } else { "DarkGray" })
}
Write-Host "`nSaved: $SaveTo" -ForegroundColor Green
Write-Host "Secrets/wallets: never read SEED_KEY or commit keys — map rules facts_only." -ForegroundColor DarkGray
