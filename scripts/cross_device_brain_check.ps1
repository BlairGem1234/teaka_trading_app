# === cross_device_brain_check.ps1 ===
# Cross-device phone brain: TeAka connect_python :5050 + bridge/brain/Cross_device_brain.json
# Master index remains C EV brain (masher on PC5000).
#
#   pwsh -NoProfile -File scripts\cross_device_brain_check.ps1

param(
    [string]$TeakaRoot = "",
    [int]$BridgePort = 5050,
    [string]$SaveTo = ""
)

$ErrorActionPreference = "SilentlyContinue"

if (-not $TeakaRoot) {
    $TeakaRoot = Split-Path $PSScriptRoot -Parent
    if (Test-Path "C:\Users\blair\EV_Git\teaka_trading_app") {
        $TeakaRoot = "C:\Users\blair\EV_Git\teaka_trading_app"
    }
}
$scratch = Join-Path $TeakaRoot "scratch"
if (-not (Test-Path $scratch)) { New-Item -ItemType Directory -Path $scratch | Out-Null }
if (-not $SaveTo) { $SaveTo = Join-Path $scratch "cross_device_brain_status.json" }

$brainPath = Join-Path $TeakaRoot "bridge\brain\Cross_device_brain.json"
$connectPy = Join-Path $TeakaRoot "connect_python.py"

function Get-BrainFileSummary {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        return @{ exists = $false; path = $Path }
    }
    try {
        $j = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
        return @{
            exists   = $true
            path     = $Path
            bytes    = (Get-Item $Path).Length
            mtime    = (Get-Item $Path).LastWriteTime.ToString("o")
            phase    = $j.phase
            linked   = $j.linked
            evbot    = $j.evbot
            identity = $j.ev_identity
        }
    } catch {
        return @{ exists = $true; path = $Path; parse_error = $_.Exception.Message }
    }
}

$portUp = [bool](netstat -ano 2>$null | Select-String ":$BridgePort\s")
$api = @{
    phone_status = $null
    phone_brain  = $null
    error        = $null
}

if ($portUp) {
    try {
        $api.phone_status = Invoke-RestMethod -Uri "http://127.0.0.1:$BridgePort/api/phone/status" -TimeoutSec 4
    } catch {
        $api.error = "status: $($_.Exception.Message)"
    }
    try {
        $api.phone_brain = Invoke-RestMethod -Uri "http://127.0.0.1:$BridgePort/api/phone/brain" -TimeoutSec 4
    } catch {
        if (-not $api.error) { $api.error = "brain GET: $($_.Exception.Message)" }
    }
}

$out = [ordered]@{
    generated_at = (Get-Date).ToString("o")
    hierarchy    = @{
        master_brain = "C EV brain (masher) on PC5000 / EV_Operator / Ev bridge"
        phone_brain  = "Cross-device phone brain — sync lane via TeAka :5050; not a second masher"
        relationship = "Phone pushes/pulls Cross_device_brain.json; PC masher remains authority for full index"
    }
    teaka_root   = $TeakaRoot
    connect_py   = @{ path = $connectPy; exists = (Test-Path $connectPy) }
    brain_file   = Get-BrainFileSummary -Path $brainPath
    bridge_port  = @{
        port      = $BridgePort
        listening = $portUp
    }
    api_probe    = $api
    phone_sources = @{
        pythonista = Join-Path $TeakaRoot "phone\pythonista_boot.py"
        scriptable = Join-Path $TeakaRoot "phone\Scriptable_EVBot_Lore.js"
        sync_route = "/api/phone/brain/sync"
    }
}

$out | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $SaveTo -Encoding utf8

Write-Host "=== Cross-device phone brain ===" -ForegroundColor Cyan
Write-Host "Master: C EV brain (masher). Phone: Cross_device_brain.json + :5050 API." -ForegroundColor DarkGray
Write-Host "File: $brainPath -> $(if ($out.brain_file.exists) { 'OK' } else { 'missing' })" -ForegroundColor $(if ($out.brain_file.exists) { "Green" } else { "Yellow" })
Write-Host "Port $BridgePort : $(if ($portUp) { 'listening' } else { 'off — start connect_python.py for phone sync' })" -ForegroundColor $(if ($portUp) { "Green" } else { "Yellow" })
if ($api.phone_status) {
    Write-Host "API status: mode=$($api.phone_status.mode) cross_device=$($api.phone_status.cross_device_brain_present)" -ForegroundColor Gray
}
Write-Host "`nSaved: $SaveTo" -ForegroundColor Green
