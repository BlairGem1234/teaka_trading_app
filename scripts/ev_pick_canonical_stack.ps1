# === ev_pick_canonical_stack.ps1 ===
# Which Codex + Cloak should EV use? (local PC — reads paths, not git history)
#   pwsh -NoProfile -File scripts\ev_pick_canonical_stack.ps1 -SaveTo scratch\ev_canonical_choice.json

param(
    [string]$SaveTo = "",
    [string]$PreferredCodexRoot = "C:\EV_AI\Codex",
    [string]$PreferredCloakPy = "C:\EV_Operator\DevToolsRuntime\ev_devtools_cloak.py",
    [string]$ClockJson = "C:\EV_Operator\Config\ev_clock.json"
)

$ErrorActionPreference = "SilentlyContinue"

Write-Host "=== EV CANONICAL STACK PICKER ===" -ForegroundColor Cyan
Write-Host "EV may rewire paths — this scores what is RUNNING vs what your Operator files point at.`n" -ForegroundColor DarkGray

$choices = [System.Collections.Generic.List[object]]::new()

# --- Codex.exe (not Python) ---
Write-Host "[Codex.exe installs]" -ForegroundColor Yellow
$codexProcs = Get-Process -Name "codex" -ErrorAction SilentlyContinue
if (-not $codexProcs) {
    Write-Host "  No codex.exe running. Start Stable from $PreferredCodexRoot when needed." -ForegroundColor Gray
} else {
    foreach ($c in $codexProcs) {
        $path = $c.Path
        $score = 0
        $tags = @()
        if ($path -match [regex]::Escape($PreferredCodexRoot)) { $score += 10; $tags += "matches EV_AI Codex" }
        if ($path -match "WindowsApps\\OpenAI\.CodexBeta") { $score -= 10; $tags += "Store CodexBeta (usually disable for EV)" }
        if ($path -match "OpenAI\\Codex\\bin") { $score += 5; $tags += "OpenAI Codex Stable channel" }
        $row = [PSCustomObject]@{
            Type     = "codex.exe"
            PID      = $c.Id
            Path     = $path
            Score    = $score
            Tags     = ($tags -join "; ")
            Verdict  = if ($score -ge 5) { "PREFERRED for EV" } elseif ($score -le -5) { "AVOID with EV Stable" } else { "REVIEW" }
        }
        $choices.Add($row)
        $row | Format-List
    }
}

# --- Cloak Python ---
Write-Host "`n[Cloak Python]" -ForegroundColor Yellow
$py = Get-CimInstance Win32_Process -Filter "Name = 'python.exe' OR Name = 'pythonw.exe'" |
    Where-Object { $_.CommandLine -match "cloak|ev_devtools" }
if (-not $py) {
    Write-Host "  No Cloak Python running (OK if bridge does not need DevTools right now)." -ForegroundColor Gray
} else {
    foreach ($p in $py) {
        $cmd = $p.CommandLine
        $score = 0
        $tags = @()
        if ($cmd -match [regex]::Escape($PreferredCloakPy)) { $score += 10; $tags += "Operator DevToolsRuntime script" }
        elseif ($cmd -match "ev_devtools_cloak") { $score += 5; $tags += "ev_devtools_cloak (check path)" }
        if ($cmd -match "EV_AI\\Codex") { $score += 2; $tags += "references EV_AI Codex" }
        $row = [PSCustomObject]@{
            Type    = "cloak-python"
            PID     = $p.ProcessId
            Path    = $cmd
            Score   = $score
            Tags    = ($tags -join "; ")
            Verdict = if ($score -ge 8) { "PREFERRED Cloak" } else { "REVIEW — may be duplicate/legacy" }
        }
        $choices.Add($row)
        $row | Format-List
    }
}

# --- Clock file hints ---
Write-Host "`n[Cloak Clock config]" -ForegroundColor Yellow
if (Test-Path -LiteralPath $ClockJson) {
    $clockItem = Get-Item -LiteralPath $ClockJson
    Write-Host "  $ClockJson (modified $($clockItem.LastWriteTime))" -ForegroundColor Green
    try {
        $clock = Get-Content -LiteralPath $ClockJson -Raw | ConvertFrom-Json
        $clock.PSObject.Properties | Select-Object -First 12 Name, Value | Format-Table -AutoSize
    } catch {
        Write-Host "  (JSON present; open locally to inspect ports/endpoints)" -ForegroundColor Gray
    }
} else {
    Write-Host "  Missing: $ClockJson" -ForegroundColor Red
}

# --- Env banner (EV Terminal) ---
Write-Host "`n[Session env (if set)]" -ForegroundColor Yellow
@("EV_AI", "EV_Files", "EV_Operator") | ForEach-Object {
    $v = [Environment]::GetEnvironmentVariable($_)
    if ($v) { Write-Host "  $_=$v" -ForegroundColor DarkGray }
}

# --- Ports (who owns 5056 — not 5057 if Docker) ---
Write-Host "`n[Port 5056 — expected Cloak]" -ForegroundColor Yellow
$lines = netstat -ano | Select-String "127.0.0.1:5056\s"
if ($lines) {
    $lines | ForEach-Object {
        $pid = ($_ -split '\s+')[-1]
        $proc = Get-CimInstance Win32_Process -Filter "ProcessId = $pid"
        Write-Host "  PID $pid $($proc.Name)" -ForegroundColor $(if ($proc.Name -match "python") { "Green" } else { "Yellow" })
        if ($proc.CommandLine) { Write-Host "    $($proc.CommandLine)" -ForegroundColor DarkGray }
    }
} else {
    Write-Host "  5056 not listening — start ONE Cloak via EV Operator when needed." -ForegroundColor Gray
}

# --- Recommendation ---
$bestCodex = $choices | Where-Object { $_.Type -eq "codex.exe" } | Sort-Object Score -Descending | Select-Object -First 1
$bestCloak = $choices | Where-Object { $_.Type -eq "cloak-python" } | Sort-Object Score -Descending | Select-Object -First 1

Write-Host "`n=== RECOMMENDATION ===" -ForegroundColor Cyan
Write-Host @"
Use for EV:
  Codex root : $PreferredCodexRoot (Stable channel — not Store CodexBeta)
  Cloak script: $PreferredCloakPy
  Clock       : C:\EV_Operator\Config\ev_clock.json + Bridge\ev_clock_throttle.js
Keep at most ONE codex.exe (highest score above) and ONE Cloak Python (highest score).
5057 on your PC may be Docker — do not treat it as Codex.
"@ -ForegroundColor White

if ($bestCodex) { Write-Host "Pick Codex: PID $($bestCodex.PID) — $($bestCodex.Verdict)" -ForegroundColor Green }
if ($bestCloak) { Write-Host "Pick Cloak: PID $($bestCloak.PID) — $($bestCloak.Verdict)" -ForegroundColor Green }

$report = @{
    generatedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
    preferred      = @{
        codexRoot  = $PreferredCodexRoot
        cloakPy    = $PreferredCloakPy
        clockJson  = $ClockJson
    }
    candidates     = @($choices)
    recommendation = @{
        codexPid = $bestCodex.PID
        cloakPid = $bestCloak.PID
    }
}

if ($SaveTo) {
    $out = if ([System.IO.Path]::IsPathRooted($SaveTo)) { $SaveTo } else { Join-Path (Get-Location) $SaveTo }
    $dir = Split-Path $out -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $out -Encoding utf8
    Write-Host "`nSaved: $out (share path with cloud agent)" -ForegroundColor Green
}
