#Requires -Version 5.1
<#
.SYNOPSIS
  Check-only: WSL, Rust, and EV mesh. No starts, stops, or task changes.

.DESCRIPTION
  Blairspc sort:
    Windows Ollama  11434
    Docker Ollama   11435   (do not also run WSL ollama on 11435)
    WSL             Hyper-V VM under Docker Desktop; inspect distros only
    Rust            rustc/cargo/rustup if present

  powershell -NoProfile -ExecutionPolicy Bypass -File C:\EV_Operator\ev_wsl_rust_check_only.ps1
#>
$ErrorActionPreference = "Continue"

function Write-Step([string]$Msg) {
    Write-Host ""
    Write-Host "=== $Msg ===" -ForegroundColor Cyan
}

function Get-Cmd([string]$Name) {
    Get-Command $Name -ErrorAction SilentlyContinue
}

Write-Host "CHECK ONLY — no Disable-ScheduledTask, no Stop-Process, no installs" -ForegroundColor Yellow

Write-Step "RUST"
$rustc = Get-Cmd rustc
$cargo = Get-Cmd cargo
$rustup = Get-Cmd rustup
if ($rustc) {
    Write-Host ("rustc  : {0}" -f (rustc --version 2>&1 | Out-String).Trim())
    Write-Host ("path   : {0}" -f $rustc.Source)
} else {
    Write-Host "rustc  : MISSING"
}
if ($cargo) {
    Write-Host ("cargo  : {0}" -f (cargo --version 2>&1 | Out-String).Trim())
    Write-Host ("path   : {0}" -f $cargo.Source)
} else {
    Write-Host "cargo  : MISSING"
}
if ($rustup) {
    Write-Host ("rustup : {0}" -f (rustup --version 2>&1 | Select-Object -First 1))
    Write-Host "toolchains:"
    rustup toolchain list 2>&1
    Write-Host "default host:"
    rustup show 2>&1 | Select-Object -First 16
} else {
    Write-Host "rustup : MISSING (standalone rustc/cargo still possible)"
}
@(
    "$env:USERPROFILE\.cargo\bin",
    "$env:USERPROFILE\.rustup"
) | ForEach-Object { if (Test-Path $_) { "DIR  $_" } else { "no   $_" } }

Write-Step "WSL DISTROS (sorted)"
$wsl = Get-Cmd wsl.exe
if (-not $wsl) {
    Write-Host "wsl.exe MISSING"
} else {
    Write-Host "wsl --status:"
    wsl.exe --status 2>&1
    Write-Host ""
    Write-Host "wsl -l -v:"
    wsl.exe -l -v 2>&1
    Write-Host ""
    Write-Host "Names (utf16 stripped, sorted):"
    $names = @()
    wsl.exe -l -q 2>$null | ForEach-Object {
        $n = ($_ -replace "`0", "").Trim()
        if ($n) { $names += $n }
    }
    ($names | Sort-Object) | ForEach-Object { Write-Host "  $_" }
    Write-Host "Not entering distros (avoids hang). To check rust/ollama in default WSL later:"
    Write-Host '  wsl.exe -- bash -lc "command -v rustc; rustc --version; command -v ollama; command -v cargo"'
}

Write-Step "DOCKER vs WSL OLLAMA (11435 fight check)"
docker ps --filter name=ollama --format "table {{.Names}}`t{{.Status}}`t{{.Ports}}" 2>&1
$t11435 = Get-ScheduledTask -TaskName "EV_Blair_WSL_Ollama_11435" -ErrorAction SilentlyContinue
$t11434 = Get-ScheduledTask -TaskName "EV_Blair_Ollama_11434" -ErrorAction SilentlyContinue
$tGlobal = Get-ScheduledTask -TaskName "EV_Global_Ollama_11434" -ErrorAction SilentlyContinue
[PSCustomObject]@{
    EV_Blair_Ollama_11434     = if ($t11434) { [string]$t11434.State } else { "missing" }
    EV_Global_Ollama_11434    = if ($tGlobal) { [string]$tGlobal.State } else { "missing" }
    EV_Blair_WSL_Ollama_11435 = if ($t11435) { [string]$t11435.State } else { "missing" }
} | Format-List

Write-Step "MESH LISTENERS"
foreach ($p in 8080, 8081, 11434, 11435, 11436, 5056, 5060, 5055, 5432, 8787) {
    $hit = netstat -ano | findstr ":$p"
    if ($hit) { Write-Host "PORT $p"; Write-Host $hit } else { Write-Host "PORT $p  --" }
}

Write-Step "SORT VERDICT"
Write-Host "Rust:    use Windows rustup/cargo unless a WSL distro is the intended builder."
Write-Host "WSL:     Docker Desktop uses WSL2. Do not also bind Ollama on 11435 inside WSL."
Write-Host "Windows: 11434 = native qwen3:4b. 11435 = docker qwen2.5:3b."
Write-Host "Flask:   8081 only. Command 8080. Cloak 5056 (two python PIDs OK)."
Write-Host "This script changed nothing."
