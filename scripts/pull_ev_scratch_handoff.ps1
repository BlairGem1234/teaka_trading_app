# === pull_ev_scratch_handoff.ps1 ===
# Pull teaka handoff branch + run stack + verify scratch JSON for cloud agent.
#
#   pwsh -NoProfile -File scripts\pull_ev_scratch_handoff.ps1
#   pwsh -NoProfile -File scripts\pull_ev_scratch_handoff.ps1 -SkipGitPull
#   pwsh -NoProfile -File scripts\pull_ev_scratch_handoff.ps1 -AlsoFederation

param(
    [switch]$SkipGitPull,
    [switch]$AlsoFederation,
    [string]$RepoRoot = ""
)

$ErrorActionPreference = "Continue"

function Resolve-TeakaRoot {
    if ($RepoRoot -and (Test-Path (Join-Path $RepoRoot ".git"))) {
        return (Resolve-Path $RepoRoot).Path
    }
    foreach ($c in @(
        "C:\Users\blair\EV_Git\teaka_trading_app",
        "C:\Users\Blair\EV_Git\teaka_trading_app"
    )) {
        if (Test-Path (Join-Path $c ".git")) { return $c }
    }
    throw "TeAka repo not found under EV_Git\teaka_trading_app"
}

$root = Resolve-TeakaRoot
$scratch = Join-Path $root "scratch"
$scripts = Join-Path $root "scripts"
if (-not (Test-Path $scratch)) { New-Item -ItemType Directory -Path $scratch | Out-Null }

Write-Host "=== Pull + load EV scratch handoff ===" -ForegroundColor Cyan
Write-Host "Repo: $root`n" -ForegroundColor DarkGray

Set-Location $root

$handoffBranch = "cursor/local-handoff-notes-8248"
if (-not $SkipGitPull) {
    Write-Host ">>> git fetch + pull ($handoffBranch)" -ForegroundColor Yellow
    & git fetch origin $handoffBranch
    if ($LASTEXITCODE -ne 0) { Write-Host "git fetch warning exit $LASTEXITCODE" -ForegroundColor Yellow }
    $cur = git branch --show-current 2>$null
    if ($cur -ne $handoffBranch) {
        Write-Host "Current branch '$cur' — checking out $handoffBranch" -ForegroundColor Yellow
        & git checkout $handoffBranch
    }
    & git pull origin $handoffBranch
    if ($LASTEXITCODE -ne 0) {
        Write-Host "git pull warning exit $LASTEXITCODE — trying plain git pull" -ForegroundColor Yellow
        & git pull
    }
}

$handoff = Join-Path $root "scripts\run_local_handoff.ps1"
if (-not (Test-Path $handoff)) {
    Write-Host "Missing $handoff — are you on cursor/local-handoff-notes-8248?" -ForegroundColor Red
    exit 1
}

Write-Host "`n>>> run_stack.ps1 (all handoff JSON)" -ForegroundColor Yellow
$stackScript = Join-Path $root "scripts\run_stack.ps1"
if (Test-Path $stackScript) {
    & $stackScript
} else {
    & pwsh -NoProfile -File $handoff -Action stack -SkipPull
}

if ($AlsoFederation) {
    Write-Host "`n>>> run_local_handoff -Action federation" -ForegroundColor Yellow
    & pwsh -NoProfile -File $handoff -Action federation -SkipPull
}

$expected = @(
    "ev_command_status.json",
    "cbrain_status.json",
    "cross_device_brain_status.json",
    "ev_core_system_map_status.json",
    "ev_teaka_ev_link.json",
    "ev_federation_registry.json"
)

Write-Host "`n>>> scratch files" -ForegroundColor Yellow
$manifest = [System.Collections.Generic.List[object]]::new()
foreach ($name in $expected) {
    $path = Join-Path $scratch $name
    if (Test-Path $path) {
        $item = Get-Item $path
        $manifest.Add([ordered]@{
            name   = $name
            path   = $path
            bytes  = $item.Length
            mtime  = $item.LastWriteTime.ToString("o")
            loaded = $true
        })
        Write-Host "  OK  $name ($($item.Length) bytes)" -ForegroundColor Green
    } else {
        $manifest.Add([ordered]@{ name = $name; path = $path; loaded = $false })
        Write-Host "  --  $name (not created — optional or step skipped)" -ForegroundColor DarkGray
    }
}

# One small index file for cloud (paths + sizes, not full merge — keeps secrets out)
$indexPath = Join-Path $scratch "cloud_handoff_index.json"
$index = [ordered]@{
    generated_at = (Get-Date).ToString("o")
    repo         = $root
    branch       = (git branch --show-current 2>$null)
    tell_cloud_agent = @(
        "scratch\ev_teaka_ev_link.json",
        "scratch\ev_command_status.json",
        "scratch\cbrain_status.json",
        "scratch\cross_device_brain_status.json",
        "scratch\ev_core_system_map_status.json",
        "scratch\ev_federation_registry.json",
        "scratch\cloud_handoff_index.json"
    )
    files = @($manifest)
    hierarchy_reminder = "EV Command -> C EV brain (master) -> cross-device phone brain -> mirrors/nodes"
}
$index | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $indexPath -Encoding utf8

Write-Host "`nIndex: scratch\cloud_handoff_index.json" -ForegroundColor Green
Write-Host @"

Tell Cursor cloud agent (paste once):

  Read these under teaka_trading_app\scratch\:
  cloud_handoff_index.json, ev_teaka_ev_link.json, cbrain_status.json,
  cross_device_brain_status.json, ev_command_status.json

Or open folder:
  $scratch

"@ -ForegroundColor DarkGray
