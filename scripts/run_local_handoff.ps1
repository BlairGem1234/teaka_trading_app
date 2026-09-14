# === run_local_handoff.ps1 ===
# One entry point on Blair PC: pull repo + run handoff / Fing / Codex / Cursor link scripts.
#
# First time (copy entire block into PowerShell):
#   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
#   cd C:\Users\blair\EV_Git\teaka_trading_app
#   git pull
#   pwsh -NoProfile -File .\scripts\run_local_handoff.ps1
#
# Or double-click flow after git is cloned:
#   pwsh -NoProfile -File C:\Users\blair\EV_Git\teaka_trading_app\scripts\run_local_handoff.ps1 -Action all

param(
    [ValidateSet("menu", "all", "pull", "fing", "codex", "cursor", "cursorinstall", "pick", "gitrefs", "gembot", "evlink", "federation", "cbrain", "coremap", "evcommand", "phonebrain", "stack", "help")]
    [string]$Action = "menu",
    [switch]$SkipPull,
    [switch]$OpenAgentLinks
)

$ErrorActionPreference = "Stop"

function Get-RepoRoot {
    if ($env:TEAKA_REPO_ROOT -and (Test-Path (Join-Path $env:TEAKA_REPO_ROOT ".git"))) {
        return (Resolve-Path $env:TEAKA_REPO_ROOT).Path
    }
    $here = $PSScriptRoot
    if ($here) {
        $root = Split-Path $here -Parent
        if (Test-Path (Join-Path $root ".git")) { return (Resolve-Path $root).Path }
    }
    $candidates = @(
        "C:\Users\blair\EV_Git\teaka_trading_app",
        "C:\Users\Blair\EV_Git\teaka_trading_app"
    )
    foreach ($c in $candidates) {
        if (Test-Path (Join-Path $c ".git")) { return $c }
    }
    throw "TeAka repo not found. Clone to C:\Users\blair\EV_Git\teaka_trading_app or set `$env:TEAKA_REPO_ROOT"
}

function Invoke-GitPull {
    param([string]$Root)
    Write-Host "`n>>> git pull (origin, current branch)" -ForegroundColor Cyan
    Push-Location $Root
    try {
        git fetch origin 2>&1 | Write-Host
        git pull 2>&1 | Write-Host
    } finally {
        Pop-Location
    }
}

function Show-Help {
    Write-Host @"

TeAka local handoff launcher
============================
Repo scripts live under:  <repo>\scripts\

Run this file:
  pwsh -NoProfile -File .\scripts\run_local_handoff.ps1
  pwsh -NoProfile -File .\scripts\run_local_handoff.ps1 -Action all
  pwsh -NoProfile -File .\scripts\run_local_handoff.ps1 -Action fing

Actions:
  menu   - pick from list (default)
  pull   - git pull only
  fing   - Fing diagnose -> scratch\fing_diag.txt
  codex  - Codex/Cloak audit -> scratch\codex_audit.txt
  cursor        - Link cloud agents + runtime -> scratch\cursor_cloud_runtime.json
  cursorinstall - Cursor.exe paths, shortcuts, duplicate Codex warning
  pick          - Which Codex/Cloak EV should use (scores running PIDs)
  gitrefs       - Git remotes + tracked EV path docs in this repo only
  gembot        - Find GemBot/EV_Link + Ev repo -> scratch\gembot_repo_check.txt
  evlink        - TeAka + Ev + PC5000 probes -> scratch\ev_teaka_ev_link.json
  federation    - All EV_Git clones + roles (Ev, TeAka, GEMBot29, Starforge…) -> scratch\ev_federation_registry.json
  cbrain        - C EV brain: status or -Start via scripts\run_cbrain.ps1
  coremap       - Ev full crypto/Starforge/VR system map + EV_AI/EV_Files path check
  evcommand     - EV Command main system check -> scratch\ev_command_status.json
  phonebrain    - Cross-device phone brain (:5050 + Cross_device_brain.json)
  stack         - evcommand + cbrain + phonebrain + coremap + evlink
  all           - pull + cursor + codex + fing (in that order)
  help   - this text

If 'pwsh' is missing, use Windows PowerShell 5:
  powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_local_handoff.ps1

"@ -ForegroundColor White
}

$repo = Get-RepoRoot
Write-Host "TeAka repo: $repo" -ForegroundColor Green
Set-Location $repo

if ($Action -eq "help") {
    Show-Help
    exit 0
}

if (-not $SkipPull -and $Action -in @("menu", "all", "fing", "codex", "cursor")) {
    try {
        Invoke-GitPull -Root $repo
    } catch {
        Write-Host "git pull failed (offline or no git?). Continuing with local files..." -ForegroundColor Yellow
    }
}

$scratch = Join-Path $repo "scratch"
if (-not (Test-Path $scratch)) { New-Item -ItemType Directory -Path $scratch | Out-Null }

function Run-Script {
    param([string]$Name, [string[]]$ExtraArgs)
    $path = Join-Path $repo "scripts\$Name"
    if (-not (Test-Path $path)) {
        Write-Host "Missing: $path" -ForegroundColor Red
        return
    }
    Write-Host "`n========== $Name ==========" -ForegroundColor Cyan
    if (Get-Command pwsh -ErrorAction SilentlyContinue) {
        & pwsh -NoProfile -File $path @ExtraArgs
    } else {
        & powershell -NoProfile -ExecutionPolicy Bypass -File $path @ExtraArgs
    }
}

switch ($Action) {
    "pull" { exit 0 }
    "fing" {
        Run-Script "fing_diagnose.ps1" @("-SaveTo", (Join-Path $scratch "fing_diag.txt"))
    }
    "codex" {
        Run-Script "ev_codex_token_audit.ps1" @("-SaveTo", (Join-Path $scratch "codex_audit.txt"))
    }
    "cursor" {
        $cursorArgs = @("-AppendClockLog", "-RunCodexAudit")
        if ($OpenAgentLinks) { $cursorArgs += "-OpenLinks" }
        Run-Script "cursor_cloud_runtime_link.ps1" $cursorArgs
    }
    "cursorinstall" {
        Run-Script "cursor_install_check.ps1" @("-SaveTo", (Join-Path $scratch "cursor_install_check.txt"))
    }
    "pick" {
        Run-Script "ev_pick_canonical_stack.ps1" @("-SaveTo", (Join-Path $scratch "ev_canonical_choice.json"))
    }
    "gitrefs" {
        Run-Script "ev_git_repos_check.ps1" @()
    }
    "gembot" {
        Run-Script "ev_gembot_repo_check.ps1" @("-SaveTo", (Join-Path $scratch "gembot_repo_check.txt"))
    }
    "evlink" {
        Run-Script "ev_teaka_ev_bridge_summary.ps1" @("-SaveTo", (Join-Path $scratch "ev_teaka_ev_link.json"))
    }
    "federation" {
        Run-Script "ev_federation_git_scan.ps1" @("-SaveTo", (Join-Path $scratch "ev_federation_registry.json"))
    }
    "cbrain" {
        Run-Script "run_cbrain.ps1" @(
            "-StatusOnly",
            "-SaveTo", (Join-Path $scratch "cbrain_run_log.txt"),
            "-JsonSaveTo", (Join-Path $scratch "cbrain_status.json")
        )
    }
    "coremap" {
        Run-Script "ev_core_system_map_check.ps1" @("-SaveTo", (Join-Path $scratch "ev_core_system_map_status.json"))
    }
    "evcommand" {
        Run-Script "ev_command_check.ps1" @("-SaveTo", (Join-Path $scratch "ev_command_status.json"))
    }
    "phonebrain" {
        Run-Script "cross_device_brain_check.ps1" @("-SaveTo", (Join-Path $scratch "cross_device_brain_status.json"))
    }
    "stack" {
        Write-Host "`n>>> [1/5] EV Command (main system)" -ForegroundColor Cyan
        Run-Script "ev_command_check.ps1" @("-SaveTo", (Join-Path $scratch "ev_command_status.json"))
        Write-Host "`n>>> [2/5] C EV brain (master masher)" -ForegroundColor Cyan
        Run-Script "run_cbrain.ps1" @(
            "-StatusOnly",
            "-SaveTo", (Join-Path $scratch "cbrain_run_log.txt"),
            "-JsonSaveTo", (Join-Path $scratch "cbrain_status.json")
        )
        Write-Host "`n>>> [3/5] Cross-device phone brain (:5050)" -ForegroundColor Cyan
        Run-Script "cross_device_brain_check.ps1" @("-SaveTo", (Join-Path $scratch "cross_device_brain_status.json"))
        Write-Host "`n>>> [4/5] EV core / Starforge system map" -ForegroundColor Cyan
        Run-Script "ev_core_system_map_check.ps1" @("-SaveTo", (Join-Path $scratch "ev_core_system_map_status.json"))
        Write-Host "`n>>> [5/5] TeAka + Ev evlink" -ForegroundColor Cyan
        Run-Script "ev_teaka_ev_bridge_summary.ps1" @("-SaveTo", (Join-Path $scratch "ev_teaka_ev_link.json"))
        Write-Host "`nStack done. Cloud paths under scratch\:" -ForegroundColor Green
        Write-Host "  ev_command_status.json, cbrain_status.json, cross_device_brain_status.json"
        Write-Host "  ev_core_system_map_status.json, ev_teaka_ev_link.json"
    }
    "all" {
        $cursorArgs = @("-AppendClockLog")
        if ($OpenAgentLinks) { $cursorArgs += "-OpenLinks" }
        Run-Script "cursor_cloud_runtime_link.ps1" $cursorArgs
        Run-Script "ev_codex_token_audit.ps1" @("-SaveTo", (Join-Path $scratch "codex_audit.txt"))
        Run-Script "fing_diagnose.ps1" @("-SaveTo", (Join-Path $scratch "fing_diag.txt"))
    }
    default {
        Show-Help
        Write-Host "Choose action (pull is done automatically unless -SkipPull):" -ForegroundColor Yellow
        Write-Host "  1) cursor        - Cloud agent link + runtime clock log"
        Write-Host "  2) codex         - Cloak/Codex token audit"
        Write-Host "  3) fing          - Fing launch diagnose"
        Write-Host "  4) cursorinstall - Cursor paths + duplicate Codex check"
        Write-Host "  5) all           - Run 1+2+3"
        Write-Host "  6) pull          - Git pull only"
        Write-Host "  7) gembot        - GemBot / EV_Link auto check"
        Write-Host "  h) help"
        $choice = Read-Host "Enter 1-7 or h"
        switch ($choice) {
            "1" { & $PSCommandPath -Action cursor -SkipPull }
            "2" { & $PSCommandPath -Action codex -SkipPull }
            "3" { & $PSCommandPath -Action fing -SkipPull }
            "4" { & $PSCommandPath -Action cursorinstall -SkipPull }
            "5" { & $PSCommandPath -Action all -SkipPull }
            "6" { Invoke-GitPull -Root $repo }
            "7" { & $PSCommandPath -Action gembot -SkipPull }
            default { Show-Help }
        }
    }
}

Write-Host "`nDone. Small results are under: $scratch" -ForegroundColor Green
Write-Host "Tell Cursor cloud agent: scratch\cursor_cloud_runtime.json (or fing_diag.txt)" -ForegroundColor DarkGray
