# === ensure_handoff_scripts.ps1 ===
# Verify handoff branch scripts exist; optional git fetch/checkout.
#
#   pwsh -NoProfile -File scripts\ensure_handoff_scripts.ps1
#   pwsh -NoProfile -File scripts\ensure_handoff_scripts.ps1 -FixGit

param(
    [switch]$FixGit,
    [string]$HandoffBranch = "cursor/local-handoff-notes-8248"
)

$ErrorActionPreference = "Continue"

function Resolve-TeakaRoot {
    foreach ($c in @(
        "C:\Users\blair\EV_Git\teaka_trading_app",
        "C:\Users\Blair\EV_Git\teaka_trading_app",
        $PSScriptRoot | ForEach-Object { Split-Path $_ -Parent }
    )) {
        if ($c -and (Test-Path (Join-Path $c ".git"))) { return (Resolve-Path $c).Path }
    }
    throw "TeAka repo not found"
}

$required = @(
    "run_local_handoff.ps1",
    "run_stack.ps1",
    "ev_docker_stack_check.ps1",
    "ev_command_check.ps1",
    "run_cbrain.ps1",
    "cross_device_brain_check.ps1",
    "ev_core_system_map_check.ps1",
    "ev_teaka_ev_bridge_summary.ps1",
    "pull_ev_scratch_handoff.ps1"
)

$root = Resolve-TeakaRoot
Set-Location $root
$branch = (git branch --show-current 2>$null)
Write-Host "=== Handoff script check ===" -ForegroundColor Cyan
Write-Host "Repo: $root"
Write-Host "Branch: $branch`n" -ForegroundColor DarkGray

if ($FixGit) {
    Write-Host ">>> git fetch + checkout $HandoffBranch" -ForegroundColor Yellow
    & git fetch origin $HandoffBranch
    & git checkout $HandoffBranch
    & git pull origin $HandoffBranch
}

$missing = @()
foreach ($n in $required) {
    $p = Join-Path $root "scripts\$n"
    if (Test-Path $p) {
        Write-Host "  OK  scripts\$n" -ForegroundColor Green
    } else {
        Write-Host "  MISS scripts\$n" -ForegroundColor Red
        $missing += $n
    }
}

if ($missing.Count -eq 0) {
    Write-Host "`nAll handoff scripts present. Run:" -ForegroundColor Green
    Write-Host "  pwsh -NoProfile -File .\scripts\run_stack.ps1" -ForegroundColor White
    exit 0
}

Write-Host "`nMissing $($missing.Count) file(s). Run with -FixGit or:" -ForegroundColor Yellow
Write-Host @"
  cd $root
  git fetch origin $HandoffBranch
  git checkout $HandoffBranch
  git pull origin $HandoffBranch
"@ -ForegroundColor White
exit 1
