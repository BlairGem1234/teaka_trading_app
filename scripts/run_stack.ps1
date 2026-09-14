# === run_stack.ps1 ===
# Full operator stack in one process (no nested pwsh). Same as handoff -Action stack.
#
#   pwsh -NoProfile -File scripts\run_stack.ps1

$ErrorActionPreference = "Continue"
$repo = Split-Path $PSScriptRoot -Parent
if (Test-Path "C:\Users\blair\EV_Git\teaka_trading_app") { $repo = "C:\Users\blair\EV_Git\teaka_trading_app" }
$scratch = Join-Path $repo "scratch"
if (-not (Test-Path $scratch)) { New-Item -ItemType Directory -Path $scratch | Out-Null }

Write-Host "=== EV stack (single process) ===" -ForegroundColor Cyan
Write-Host "Repo: $repo`n" -ForegroundColor DarkGray

Write-Host "Tip: Docker EV chain first — scripts\ev_docker_stack_check.ps1 -StartDesktop then -ComposeUp`n" -ForegroundColor DarkGray

$steps = @(
    @{ n = "ev_docker_stack_check.ps1"; a = @("-SaveTo", (Join-Path $scratch "ev_docker_stack_status.json")) },
    @{ n = "ev_command_check.ps1"; a = @("-SaveTo", (Join-Path $scratch "ev_command_status.json")) },
    @{ n = "run_cbrain.ps1"; a = @("-StatusOnly", "-SaveTo", (Join-Path $scratch "cbrain_run_log.txt"), "-JsonSaveTo", (Join-Path $scratch "cbrain_status.json")) },
    @{ n = "cross_device_brain_check.ps1"; a = @("-SaveTo", (Join-Path $scratch "cross_device_brain_status.json")) },
    @{ n = "ev_core_system_map_check.ps1"; a = @("-SaveTo", (Join-Path $scratch "ev_core_system_map_status.json")) },
    @{ n = "ev_teaka_ev_bridge_summary.ps1"; a = @("-SaveTo", (Join-Path $scratch "ev_teaka_ev_link.json")) }
)

$i = 0
foreach ($s in $steps) {
    $i++
    $path = Join-Path $repo "scripts\$($s.n)"
    Write-Host "`n>>> [$i/$($steps.Count)] $($s.n)" -ForegroundColor Cyan
    if (-not (Test-Path $path)) {
        Write-Host "Missing $path" -ForegroundColor Red
        continue
    }
    & $path @($s.a)
}

Write-Host "`nStack finished. scratch\:" -ForegroundColor Green
Get-ChildItem $scratch -Filter "*.json" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 12 Name, Length, LastWriteTime |
    Format-Table -AutoSize
