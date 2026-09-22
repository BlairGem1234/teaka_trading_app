#Requires -Version 5.1
<#
.SYNOPSIS
  Check-only: Evolve/ev-node and CometBFT :26657. No start, stop, or tx.

.DESCRIPTION
  Blairspc sort:
    Windows Ollama  11434
    Docker Ollama   11435
    Command         8080
    ev-node RPC     26657   (this script only GETs status/health)
    ev-node P2P     26656

  powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\ev_node_check_only.ps1
#>
$ErrorActionPreference = "Continue"

function Write-Step([string]$Msg) {
    Write-Host ""
    Write-Host "=== $Msg ===" -ForegroundColor Cyan
}

Write-Host "CHECK ONLY — inspect listeners and GET status only. No launch. No txs." -ForegroundColor Yellow
Write-Host "This is Evolve ev-node / CometBFT, not EV GEMBot, not Nanle cargo."

Write-Step "LISTEN 26657 / 26656"
foreach ($p in 26657, 26656, 1317, 9090) {
    $hit = netstat -ano | findstr ":$p"
    if ($hit) { Write-Host "PORT $p"; Write-Host $hit } else { Write-Host "PORT $p  --" }
}

Write-Step "PROCESS"
$procs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -match '(?i)ev-node|evnode|cometbft' -or
    ($_.CommandLine -and $_.CommandLine -match '(?i)ev-node|evnode[^\w]|cometbft')
}
if ($procs) {
    $procs | Select-Object ProcessId, Name, CommandLine | Format-List
} else {
    Write-Host "no matching Windows process"
}

Write-Step "BINARY ON PATH"
foreach ($n in @("ev-node", "evnode", "cometbft")) {
    $c = Get-Command $n -ErrorAction SilentlyContinue
    if ($c) { Write-Host "$n : $($c.Source)" } else { Write-Host "$n : missing" }
}

Write-Step "DOCKER"
if (Get-Command docker -ErrorAction SilentlyContinue) {
    docker ps -a --format "table {{.Names}}`t{{.Status}}`t{{.Ports}}" 2>&1
} else {
    Write-Host "docker missing"
}

Write-Step "GET 127.0.0.1:26657/status"
if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
    curl.exe -sS -m 3 http://127.0.0.1:26657/status
    if ($LASTEXITCODE -ne 0) { Write-Host "DOWN" }
    Write-Host ""
    Write-Host "GET /health"
    curl.exe -sS -m 3 http://127.0.0.1:26657/health
    if ($LASTEXITCODE -ne 0) { Write-Host "HEALTH_DOWN" }
} else {
    try {
        Invoke-WebRequest -Uri "http://127.0.0.1:26657/status" -UseBasicParsing -TimeoutSec 3 | Select-Object -ExpandProperty Content
    } catch {
        Write-Host "DOWN"
        Write-Host $_.Exception.Message
    }
}

Write-Step "SORT VERDICT"
Write-Host "If 26657 is -- and status is DOWN, ev-node is not live. Leave it down."
Write-Host "Do not start ev-node from this chat. No live trade. No D: repair."
Write-Host "Ollama 11434 / 11435. Command 8080. This script changed nothing."
