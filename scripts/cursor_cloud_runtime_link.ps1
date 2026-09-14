# === cursor_cloud_runtime_link.ps1 ===
# Link Cursor cloud agent runs to local EV runtime + clock log (see what Cloak/Codex sees).
#
# Usage (from repo root on Blair PC):
#   git pull
#   pwsh -File scripts\cursor_cloud_runtime_link.ps1
#   pwsh -File scripts\cursor_cloud_runtime_link.ps1 -OpenLinks
#   pwsh -File scripts\cursor_cloud_runtime_link.ps1 -RegisterBcId bc-NEW-ID -RegisterName "My agent"
#
# Paste agent id from URL: https://cursor.com/agents/bc-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

param(
    [string]$RepoRoot = "",
    [string]$RegisterBcId = "",
    [string]$RegisterName = "",
    [string]$RegisterSource = "desktop",
    [switch]$OpenLinks,
    [switch]$RunCodexAudit,
    [switch]$AppendClockLog,
    [string]$EvOperatorRoot = "C:\EV_Operator",
    [string[]]$EvSearchRoots = @(
        "C:\EV_Operator",
        "C:\EV_AI",
        "C:\EV_AI\Codex",
        "C:\EV_AI\Cursor",
        "C:\EV_Files"
    )
)

$ErrorActionPreference = "SilentlyContinue"

if (-not $RepoRoot) {
    if (Test-Path -LiteralPath "C:\Users\blair\EV_Git\teaka_trading_app\.git") {
        $RepoRoot = "C:\Users\blair\EV_Git\teaka_trading_app"
    } else {
        $RepoRoot = Split-Path $PSScriptRoot -Parent
    }
}

$scratchDir = Join-Path $RepoRoot "scratch"
$registryPath = Join-Path $scratchDir "cursor_agent_registry.json"
$runtimePath = Join-Path $scratchDir "cursor_cloud_runtime.json"
$clockLogPath = Join-Path $scratchDir "cursor_clock_events.jsonl"
$inboxDir = Join-Path $RepoRoot "bridge\inbox"

if (-not (Test-Path -LiteralPath $scratchDir)) {
    New-Item -ItemType Directory -Path $scratchDir -Force | Out-Null
}

# Default linked threads (TeAka repo — update via -RegisterBcId)
$defaultAgents = @(
    @{
        name   = "Trading app status (Fing + handoff)"
        bcId   = "bc-70aa0aeb-0d8a-4d84-9114-c299b5fe8248"
        source = "desktop"
        role   = "teaka_handoff"
    },
    @{
        name   = "Build environment setup (EV / Codex / Cloak)"
        bcId   = "bc-b9fdc66e-2374-47ba-9788-073c9a6bf902"
        source = "web"
        role   = "ev_codex_cloak"
    }
)

function Get-AgentRegistry {
    if (Test-Path -LiteralPath $registryPath) {
        $raw = Get-Content -LiteralPath $registryPath -Raw | ConvertFrom-Json
        if ($raw.agents) { return @($raw.agents) }
    }
    return @()
}

function Save-AgentRegistry {
    param([array]$Agents)
    $payload = @{
        updatedAt = (Get-Date).ToUniversalTime().ToString("o")
        agents    = $Agents
    }
    $payload | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $registryPath -Encoding utf8
}

$agents = Get-AgentRegistry
if ($agents.Count -eq 0) {
    $agents = $defaultAgents
    Save-AgentRegistry -Agents $agents
}

if ($RegisterBcId) {
    $url = "https://cursor.com/agents/$RegisterBcId"
    $name = if ($RegisterName) { $RegisterName } else { "Registered $(Get-Date -Format 'yyyy-MM-dd HH:mm')" }
    $agents = @($agents | Where-Object { $_.bcId -ne $RegisterBcId })
    $agents += @{
        name      = $name
        bcId      = $RegisterBcId
        source    = $RegisterSource
        role      = "custom"
        url       = $url
        linkedAt  = (Get-Date).ToUniversalTime().ToString("o")
    }
    Save-AgentRegistry -Agents $agents
    Write-Host "[+] Registered cloud agent: $name -> $url" -ForegroundColor Green
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " CURSOR CLOUD + EV RUNTIME LINK" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Repo: $RepoRoot" -ForegroundColor DarkGray

Write-Host "`n[1] Linked Cursor cloud threads (open to continue SAME chat)" -ForegroundColor Yellow
foreach ($a in $agents) {
    $u = if ($a.url) { $a.url } else { "https://cursor.com/agents/$($a.bcId)" }
    Write-Host "  - $($a.name)" -ForegroundColor Green
    Write-Host "    $u" -ForegroundColor DarkGray
    if ($OpenLinks) { Start-Process $u }
}

# Local runtime snapshot
Write-Host "`n[2] Local runtime snapshot" -ForegroundColor Yellow
$cursorProcs = Get-Process -Name "Cursor" -ErrorAction SilentlyContinue
if ($cursorProcs) {
    $cursorProcs | Select-Object Id, ProcessName, @{N = "MB"; E = { [math]::Round($_.WorkingSet64 / 1MB, 1) } } | Format-Table -AutoSize
} else {
    Write-Host "  Cursor.exe not running (OK if you only use web agents)." -ForegroundColor Gray
}

$pyCloak = Get-CimInstance Win32_Process -Filter "Name = 'python.exe' OR Name = 'pythonw.exe'" |
    Where-Object { $_.CommandLine -match "ev_devtools_cloak|devtools_cloak" }
$cloakCount = @($pyCloak).Count
Write-Host "  Cloak Python processes: $cloakCount (want 0 or 1 — see docs/CLOAK_CLOCK_GLOSSARY.md)" -ForegroundColor $(if ($cloakCount -gt 1) { "Red" } else { "Green" })
if ($cloakCount -gt 0) {
    $pyCloak | ForEach-Object {
        $cmd = (Get-CimInstance Win32_Process -Filter "ProcessId = $($_.ProcessId)").CommandLine
        Write-Host "    PID $($_.ProcessId): $cmd" -ForegroundColor DarkGray
    }
}

# EV clock files (Cloak Clock = clock config + cloak process)
Write-Host "`n[3] Cloak Clock — throttle files (ev_clock*.json / ev_clock_throttle.js)" -ForegroundColor Yellow
$clockCandidates = @()
foreach ($root in $EvSearchRoots) {
    if (-not (Test-Path -LiteralPath $root)) { continue }
    $clockCandidates += Join-Path $root "Config\ev_clock.json"
    $clockCandidates += Join-Path $root "Bridge\ev_clock_throttle.js"
}
$clockCandidates += @(
    Join-Path $EvOperatorRoot "Config\ev_clock.json",
    Join-Path $EvOperatorRoot "Bridge\ev_clock_throttle.js"
)
$clockFound = @()
foreach ($c in ($clockCandidates | Select-Object -Unique)) {
    if (Test-Path -LiteralPath $c) {
        if ($clockFound -notcontains $c) { $clockFound += $c }
        Write-Host "  [found] $c" -ForegroundColor Green
        if ($c -like "*.json") {
            try {
                Get-Content -LiteralPath $c -Raw | ConvertFrom-Json | ConvertTo-Json -Compress | Write-Host -ForegroundColor DarkGray
            } catch {
                Write-Host "  (could not parse JSON)" -ForegroundColor Yellow
            }
        } else {
            Get-Content -LiteralPath $c -TotalCount 8 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
        }
    }
}
if ($clockFound.Count -eq 0) {
    Write-Host "  No clock files at usual Config/Bridge paths — searching EV_AI + EV_Operator ..." -ForegroundColor Yellow
    foreach ($root in $EvSearchRoots) {
        if (-not (Test-Path -LiteralPath $root)) { continue }
        Get-ChildItem -LiteralPath $root -Include "ev_clock.json", "ev_clock_throttle.js", "*devtools*cloak*.py" -Recurse -ErrorAction SilentlyContinue |
            Select-Object -First 6 FullName, LastWriteTime |
            Format-Table -AutoSize
    }
}

# Ports (Cloak listeners)
Write-Host "`n[4] Cloak ports 5056 / 5057" -ForegroundColor Yellow
foreach ($port in @(5056, 5057)) {
    $hit = netstat -ano | Select-String ":$port\s"
    if ($hit) { Write-Host "  Port $port IN USE" -ForegroundColor Green; $hit | Select-Object -First 2 } else { Write-Host "  Port $port idle" -ForegroundColor Gray }
}

$runtime = @{
    recordedAtUtc = (Get-Date).ToUniversalTime().ToString("o")
    machine       = $env:COMPUTERNAME
    user          = $env:USERNAME
    repoRoot      = $RepoRoot
    linkedAgents  = $agents
    cloakCount    = @($pyCloak).Count
    clockFiles    = $clockFound
    cursorPidCount = @($cursorProcs).Count
    note          = "Local registry links cloud threads; does not merge Cursor transcripts. Use agent URLs to continue each thread."
}

$runtime | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $runtimePath -Encoding utf8
Write-Host "`n[+] Wrote $runtimePath" -ForegroundColor Green

if ($AppendClockLog) {
    $line = @{
        t      = $runtime.recordedAtUtc
        event  = "cursor_cloud_runtime_link"
        cloak  = $runtime.cloakCount
        agents = ($agents | ForEach-Object { $_.bcId }) -join ","
    } | ConvertTo-Json -Compress
    Add-Content -LiteralPath $clockLogPath -Value $line -Encoding utf8
    Write-Host "[+] Appended clock event log: $clockLogPath" -ForegroundColor Green
    Write-Host "    (Watch this file grow when you re-run the script — 'clocks' chat/runtime checks.)" -ForegroundColor DarkGray
}

$inboxFile = Join-Path $inboxDir ("CURSOR_CLOUD_RUNTIME_{0:yyyyMMdd_HHmmss}.json" -f (Get-Date))
if (Test-Path -LiteralPath $inboxDir) {
    Copy-Item -LiteralPath $runtimePath -Destination $inboxFile -Force
    Write-Host "[+] Copied snapshot to $inboxFile (TeAka bridge inbox)" -ForegroundColor Green
}

if ($RunCodexAudit) {
    $audit = Join-Path $RepoRoot "scripts\ev_codex_token_audit.ps1"
    if (Test-Path -LiteralPath $audit) {
        Write-Host "`n[5] Running ev_codex_token_audit.ps1 ..." -ForegroundColor Yellow
        & $audit -SaveTo (Join-Path $scratchDir "codex_audit.txt")
    }
}

Write-Host "`n--- Next steps ---" -ForegroundColor Cyan
Write-Host "1. Continue EV/Codex thread: open Build environment setup URL above." -ForegroundColor White
Write-Host "2. Continue this handoff thread: open Trading app status URL above." -ForegroundColor White
Write-Host "3. Re-run with -AppendClockLog to append timestamped lines to cursor_clock_events.jsonl." -ForegroundColor White
Write-Host "4. Tell cloud agent: scratch\cursor_cloud_runtime.json (small file, not a huge paste)." -ForegroundColor White
