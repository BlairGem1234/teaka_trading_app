# === check_system_now.ps1 ===
# Fresh PC5000 snapshot (this moment) — not old log sessions.
#
#   pwsh -NoProfile -File scripts\check_system_now.ps1

param(
    [switch]$SkipPull,
    [string]$TeakaRoot = ""
)

$ErrorActionPreference = "Continue"

if (-not $TeakaRoot) {
    $TeakaRoot = Split-Path $PSScriptRoot -Parent
    if (Test-Path "C:\Users\blair\EV_Git\teaka_trading_app") {
        $TeakaRoot = "C:\Users\blair\EV_Git\teaka_trading_app"
    }
}
$scratch = Join-Path $TeakaRoot "scratch"
$scripts = Join-Path $TeakaRoot "scripts"
if (-not (Test-Path $scratch)) { New-Item -ItemType Directory -Path $scratch | Out-Null }

$stamp = Get-Date
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  EV / TeAka SYSTEM CHECK — NOW" -ForegroundColor Cyan
Write-Host "  $($stamp.ToString('o'))" -ForegroundColor White
Write-Host "========================================`n" -ForegroundColor Cyan

Set-Location $TeakaRoot

if (-not $SkipPull) {
    Write-Host ">>> git pull (current branch)" -ForegroundColor Yellow
    & git fetch origin 2>$null
    & git pull 2>$null
}

$branch = git branch --show-current 2>$null
$commit = git log -1 --oneline 2>$null

function Test-ListenPort {
    param([int]$Port)
    $hit = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty OwningProcess -Unique
    if (-not $hit) { return @{ port = $Port; listening = $false; pids = @() } }
    $procs = @($hit | ForEach-Object {
        $p = Get-Process -Id $_ -ErrorAction SilentlyContinue
        @{ pid = $_; name = $p.ProcessName }
    })
    return @{ port = $Port; listening = $true; pids = $procs }
}

$ports = @(8080, 5000, 5050, 5056, 8545, 5057) | ForEach-Object { Test-ListenPort $_ }
$codex = @(Get-Process codex -ErrorAction SilentlyContinue)
$cursor = @(Get-Process Cursor -ErrorAction SilentlyContinue)
$dockerOk = $false
if (Get-Command docker -ErrorAction SilentlyContinue) {
    docker info 2>$null | Out-Null
    $dockerOk = ($LASTEXITCODE -eq 0)
}

Write-Host "Git: $branch @ $commit" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Ports:" -ForegroundColor Yellow
foreach ($p in $ports) {
    if ($p.listening) {
        $who = ($p.pids | ForEach-Object { "$($_.pid) $($_.name)" }) -join ", "
        Write-Host "  $($p.port) ON  ($who)" -ForegroundColor Green
    } else {
        Write-Host "  $($p.port) off" -ForegroundColor DarkGray
    }
}
Write-Host ""
Write-Host "Processes:" -ForegroundColor Yellow
Write-Host "  codex.exe count: $($codex.Count) $(if ($codex.Count -gt 1) { '(WARN: close Codex Beta duplicate)' } else { '' })" -ForegroundColor $(if ($codex.Count -gt 1) { "Yellow" } else { "Gray" })
Write-Host "  Cursor.exe count: $($cursor.Count)" -ForegroundColor Gray
Write-Host "  Docker engine: $(if ($dockerOk) { 'ready' } else { 'not ready / CLI missing' })" -ForegroundColor $(if ($dockerOk) { "Green" } else { "DarkGray" })
Write-Host ""

$steps = @(
    @{ n = "ev_command_check.ps1"; out = "ev_command_status.json" },
    @{ n = "ev_docker_stack_check.ps1"; out = "ev_docker_stack_status.json" },
    @{ n = "cursor_extension_host_check.ps1"; out = "cursor_extension_host_check.txt"; extra = @("-LogTailLines", "800") }
)

$i = 0
foreach ($s in $steps) {
    $i++
    $path = Join-Path $scripts $s.n
    Write-Host ">>> [$i/$($steps.Count)] $($s.n)" -ForegroundColor Cyan
    if (-not (Test-Path $path)) {
        Write-Host "  MISSING — git pull handoff branch" -ForegroundColor Red
        continue
    }
    $save = Join-Path $scratch $s.out
    $args = @("-SaveTo", $save) + @($s.extra)
    & pwsh -NoProfile -File $path @args
}

$summaryPath = Join-Path $scratch "system_check_now.json"
$summary = [ordered]@{
    generated_at = $stamp.ToString("o")
    teaka_root   = $TeakaRoot
    git_branch   = $branch
    git_commit   = $commit
    ports        = $ports
    codex_count  = $codex.Count
    cursor_count = $cursor.Count
    docker_engine_ok = $dockerOk
    scratch_files = @($steps | ForEach-Object {
        $p = Join-Path $scratch $_.out
        if (Test-Path $p) {
            $f = Get-Item $p
            @{ name = $_.out; mtime = $f.LastWriteTime.ToString("o"); bytes = $f.Length }
        }
    } | Where-Object { $_ })
    note = "Fresh run — compare generated_at to old Sep handoff pastes"
}
$summary | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $summaryPath -Encoding utf8

Write-Host ""
Write-Host "Done. Fresh index: scratch\system_check_now.json" -ForegroundColor Green
Write-Host "Paste that JSON (or cursorext tail + ev_command JSON) to cloud agent.`n" -ForegroundColor DarkGray
