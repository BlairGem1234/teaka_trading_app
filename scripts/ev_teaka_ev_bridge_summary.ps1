# === ev_teaka_ev_bridge_summary.ps1 ===
# Merge TeAka + Ev repo facts + latest PC5000 bridge probes -> one small JSON for cloud agents.
#
#   pwsh -NoProfile -File scripts\ev_teaka_ev_bridge_summary.ps1

param(
    [string]$TeakaRoot = "",
    [string]$EvRoot = "C:\Users\blair\EV_Git\Ev",
    [string]$SaveTo = ""
)

$ErrorActionPreference = "SilentlyContinue"

if (-not $TeakaRoot) {
    $TeakaRoot = Split-Path $PSScriptRoot -Parent
    if (Test-Path "C:\Users\blair\EV_Git\teaka_trading_app\.git") {
        $TeakaRoot = "C:\Users\blair\EV_Git\teaka_trading_app"
    }
}
$scratch = Join-Path $TeakaRoot "scratch"
if (-not (Test-Path $scratch)) { New-Item -ItemType Directory -Path $scratch | Out-Null }
if (-not $SaveTo) { $SaveTo = Join-Path $scratch "ev_teaka_ev_link.json" }

function Get-GitMini {
    param([string]$Root)
    if (-not (Test-Path (Join-Path $Root ".git"))) {
        return @{ path = $Root; git = $false }
    }
    Push-Location $Root
    $o = @{
        path    = $Root
        git     = $true
        remote  = (git remote get-url origin 2>$null)
        branch  = (git branch --show-current 2>$null)
        ahead   = $null
        commit  = (git log -1 --oneline 2>$null)
    }
    $sb = git status -sb 2>$null
    if ($sb -match '\[ahead (\d+)\]') { $o.ahead = [int]$Matches[1] }
    Pop-Location
    return $o
}

function Get-JsonTopKeys {
    param([string]$FilePath, [int]$MaxKeys = 12)
    try {
        $j = Get-Content -LiteralPath $FilePath -Raw -Encoding UTF8 | ConvertFrom-Json
        $props = $j.PSObject.Properties.Name | Select-Object -First $MaxKeys
        return @{
            file = $FilePath
            keys = @($props)
            schema = $j.schema
            command_id = $j.command_id
            created = $j.created_utc
            mode = $j.mode
        }
    } catch {
        return @{ file = $FilePath; error = $_.Exception.Message }
    }
}

$summary = [ordered]@{
    generated_at = (Get-Date).ToString("o")
    main_system  = "EV Command (command plane) -> C EV brain (masher) -> EV AI / EV Files / EV core"
    teaka        = Get-GitMini -Root $TeakaRoot
    ev           = Get-GitMini -Root $EvRoot
    teaka_signals = @{}
    ev_bridge_live = @{}
    ports        = @{}
    note         = "Tell cloud agent: scratch\ev_teaka_ev_link.json (+ ev_command_status.json, cbrain_status.json after stack action)"
}

# TeAka: status_report + connect_python presence
$statusYaml = Join-Path $TeakaRoot "status_report.yaml"
if (Test-Path $statusYaml) {
    $summary.teaka_signals.status_report = (Get-Content $statusYaml -TotalCount 15) -join "`n"
}
foreach ($rel in @("connect_python.py", "ev_virtual_brain.json", "bridge\brain\Cross_device_brain.json")) {
    $p = Join-Path $TeakaRoot $rel
    if (Test-Path $p) {
        $summary.teaka_signals[$rel.Replace('\', '/')] = @{
            exists = $true
            bytes  = (Get-Item $p).Length
            mtime  = (Get-Item $p).LastWriteTime.ToString("o")
        }
    }
}

# Ev: latest PC5000 probes (untracked OK)
$liveDir = Join-Path $EvRoot "bridge\live\pc5000"
if (Test-Path $liveDir) {
    $patterns = @(
        "*gembot_stack_probe*",
        "*runtime_mode_roboshady*",
        "*codex_chat_handoff*",
        "*connection_stack_test*"
    )
    foreach ($pat in $patterns) {
        $latest = Get-ChildItem -LiteralPath $liveDir -Filter $pat -File -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        if ($latest) {
            $summary.ev_bridge_live[$pat.Trim('*')] = Get-JsonTopKeys -FilePath $latest.FullName
            $summary.ev_bridge_live[$pat.Trim('*')].last_write = $latest.LastWriteTime.ToString("o")
        }
    }
}

foreach ($port in @(5000, 5050, 5056, 8080, 11434)) {
    $hit = netstat -ano 2>$null | Select-String ":$port\s"
    if ($hit) {
        $pid = ($hit | ForEach-Object { ($_ -split '\s+')[-1] } | Select-Object -First 1)
        $proc = Get-CimInstance Win32_Process -Filter "ProcessId = $pid" -ErrorAction SilentlyContinue
        $summary.ports["$port"] = @{ listening = $true; pid = $pid; name = $proc.Name }
    } else {
        $summary.ports["$port"] = @{ listening = $false }
    }
}

$json = $summary | ConvertTo-Json -Depth 6
$json | Set-Content -LiteralPath $SaveTo -Encoding utf8

Write-Host "=== TeAka + Ev bridge summary ===" -ForegroundColor Cyan
Write-Host "TeAka: $($summary.teaka.path) [$($summary.teaka.branch)]" -ForegroundColor Green
Write-Host "Ev:    $($summary.ev.path) [$($summary.ev.branch)]" -ForegroundColor Green
if ($summary.ev.ahead) {
    Write-Host "Ev branch is ahead $($summary.ev.ahead) commits (local-only until push)." -ForegroundColor Yellow
}
Write-Host "Saved: $SaveTo" -ForegroundColor Green
Write-Host "Tell cloud agent: scratch\ev_teaka_ev_link.json" -ForegroundColor DarkGray
