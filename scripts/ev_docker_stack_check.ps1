# === ev_docker_stack_check.ps1 ===
# Open/check Docker + EV stack containers (ev-node / ev-reth per system map).
#
#   pwsh -NoProfile -File scripts\ev_docker_stack_check.ps1
#   pwsh -NoProfile -File scripts\ev_docker_stack_check.ps1 -StartDesktop
#   pwsh -NoProfile -File scripts\ev_docker_stack_check.ps1 -ComposeUp

param(
    [switch]$StartDesktop,
    [switch]$ComposeUp,
    [string]$SaveTo = "",
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
if (-not (Test-Path $scratch)) { New-Item -ItemType Directory -Path $scratch | Out-Null }
if (-not $SaveTo) { $SaveTo = Join-Path $scratch "ev_docker_stack_status.json" }

$dockerDesktop = @(
    "${env:ProgramFiles}\Docker\Docker\Docker Desktop.exe",
    "$env:LOCALAPPDATA\Docker\Docker Desktop.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

function Find-ComposeFiles {
    $roots = @(
        "D:\EV_Files\EV_Node",
        "D:\EV_Files",
        "C:\EV_Operator_Workspace",
        "C:\Users\blair\EV_Git\Ev"
    )
    $found = @()
    foreach ($r in $roots) {
        if (-not (Test-Path $r)) { continue }
        Get-ChildItem -LiteralPath $r -Filter "docker-compose*.yml" -Recurse -Depth 4 -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '\\\.git\\' } |
            ForEach-Object { $found += $_ }
        Get-ChildItem -LiteralPath $r -Filter "compose*.yaml" -Recurse -Depth 4 -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '\\\.git\\' } |
            ForEach-Object { $found += $_ }
    }
    $found | Sort-Object FullName -Unique
}

if ($StartDesktop -and $dockerDesktop) {
    Write-Host "Starting Docker Desktop..." -ForegroundColor Cyan
    Start-Process -FilePath $dockerDesktop
    Write-Host "Wait ~30–60s for Docker engine before -ComposeUp." -ForegroundColor Yellow
}

$dockerCli = Get-Command docker -ErrorAction SilentlyContinue
$out = [ordered]@{
    generated_at   = (Get-Date).ToString("o")
    docker_desktop = $dockerDesktop
    docker_cli     = [bool]$dockerCli
    engine_ok      = $false
    containers     = @()
    networks       = @()
    compose_files  = @()
    rpc_8545       = @{ listening = $false }
    notes          = @(
        "5057 on PC5000 is often com.docker.backend — not Codex",
        "System map: network evolveevm_evolve-network, ev-reth RPC http://127.0.0.1:8545 (prior evidence)"
    )
}

if ($dockerCli) {
    docker info 2>$null | Out-Null
    $out.engine_ok = ($LASTEXITCODE -eq 0)
    if ($out.engine_ok) {
        $ps = docker ps -a --format "{{.Names}}|{{.Status}}|{{.Ports}}" 2>$null
        if ($ps) {
            $out.containers = @($ps | ForEach-Object {
                $p = $_ -split '\|', 3
                @{ name = $p[0]; status = $p[1]; ports = $p[2] }
            })
        }
        $nets = docker network ls --format "{{.Name}}|{{.Driver}}" 2>$null
        if ($nets) {
            $out.networks = @($nets | ForEach-Object {
                $p = $_ -split '\|', 2
                @{ name = $p[0]; driver = $p[1] }
            })
        }
    }
}

$out.rpc_8545.listening = [bool](netstat -ano 2>$null | Select-String ":8545\s")

$composes = Find-ComposeFiles
$out.compose_files = @($composes | ForEach-Object { $_.FullName })

if ($ComposeUp -and $dockerCli -and $out.engine_ok -and $composes.Count -gt 0) {
    $primary = $composes | Where-Object { $_.FullName -match 'EV_Node|ev-reth|evolve' } | Select-Object -First 1
    if (-not $primary) { $primary = $composes | Select-Object -First 1 }
    $dir = $primary.DirectoryName
    Write-Host "docker compose up -d in $dir" -ForegroundColor Cyan
    Push-Location $dir
    docker compose up -d 2>&1 | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0) {
        docker-compose up -d 2>&1 | ForEach-Object { Write-Host $_ }
    }
    Pop-Location
    $out.compose_up_dir = $dir
}

$out | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $SaveTo -Encoding utf8

Write-Host "=== EV Docker stack ===" -ForegroundColor Cyan
Write-Host "Docker CLI: $(if ($out.docker_cli) { 'yes' } else { 'missing' })" -ForegroundColor Gray
Write-Host "Engine ready: $(if ($out.engine_ok) { 'yes' } else { 'no — run with -StartDesktop' })" -ForegroundColor $(if ($out.engine_ok) { "Green" } else { "Yellow" })
Write-Host "8545 (ev-reth RPC): $(if ($out.rpc_8545.listening) { 'listening' } else { 'off' })" -ForegroundColor Gray
if ($out.compose_files.Count -gt 0) {
    Write-Host "Compose files found:" -ForegroundColor Yellow
    $out.compose_files | Select-Object -First 5 | ForEach-Object { Write-Host "  $_" }
} else {
    Write-Host "No docker-compose found under EV_Node/EV_Files/Ev — start stack manually from your ev-reth checkout." -ForegroundColor Yellow
}
Write-Host "`nSaved: $SaveTo" -ForegroundColor Green
