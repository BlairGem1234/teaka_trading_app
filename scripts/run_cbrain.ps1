# === run_cbrain.ps1 ===
# Run The Brain (masher) on PC5000 — discovers launchers under Ev + EV_Operator.
# Satellite (Git_Satellite_Brain) is optional add-on via -WithSatellite.
#
#   pwsh -NoProfile -File scripts\run_cbrain.ps1 -StatusOnly
#   pwsh -NoProfile -File scripts\run_cbrain.ps1 -Start
#   pwsh -NoProfile -File scripts\run_cbrain.ps1 -Start -WithCloak -WithSatellite

param(
    [switch]$StatusOnly,
    [switch]$Start,
    [switch]$WithCloak,
    [switch]$WithSatellite,
    [string]$EvRoot = "",
    [string]$SaveTo = ""
)

$ErrorActionPreference = "SilentlyContinue"

function Resolve-EvRoot {
    if ($EvRoot -and (Test-Path $EvRoot)) { return $EvRoot }
    foreach ($p in @(
        "C:\Users\blair\EV_Git\Ev",
        "C:\Users\Blair\EV_Git\Ev",
        "C:\Users\blair\EV_Git\Ev-EVBot-Operator"
    )) {
        if (Test-Path (Join-Path $p ".git")) { return $p }
    }
    return "C:\Users\blair\EV_Git\Ev"
}

function Get-OperatorPython {
    $candidates = @(
        "C:\EV_Operator\DevToolsRuntime\python_env\Scripts\python.exe",
        "C:\EV_Operator\DevToolsRuntime\python_env\Scripts\pythonw.exe"
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }
    return $null
}

function Test-PortListening {
    param([int]$Port)
    return [bool](netstat -ano 2>$null | Select-String ":$Port\s")
}

function Start-CloakIfRequested {
    if (-not $WithCloak) { return }
    if (Test-PortListening 5056) {
        Write-Host "Cloak lane 5056 already listening." -ForegroundColor Green
        return
    }
    $py = Get-OperatorPython
    $cloak = "C:\EV_Operator\DevToolsRuntime\ev_devtools_cloak.py"
    if (-not ($py -and (Test-Path $cloak))) {
        Write-Host "Cannot start Cloak: missing Operator python or ev_devtools_cloak.py" -ForegroundColor Red
        return
    }
    Write-Host "Starting ONE Cloak (masher sidecar lane 5056)..." -ForegroundColor Cyan
    Start-Process -FilePath $py -ArgumentList "`"$cloak`"" -WindowStyle Minimized
    Start-Sleep -Seconds 2
}

function Invoke-SatelliteAddon {
    if (-not $WithSatellite) { return }
    $satRoot = "C:\Users\blair\EV_Git\Git_Satellite_Brain"
    if (-not (Test-Path $satRoot)) { $satRoot = "C:\Users\Blair\EV_Git\Git_Satellite_Brain" }
    Write-Host "Satellite add-on (run-brain helper): $satRoot" -ForegroundColor Yellow
    $send = Join-Path $satRoot "Send-EVCommand.ps1"
    if (Test-Path $send) {
        Write-Host "Running Send-EVCommand.ps1 ..." -ForegroundColor Cyan
        & pwsh -NoProfile -File $send
        return
    }
    Get-ChildItem -LiteralPath $satRoot -Filter "*.ps1" -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match "Run|Start|Operator|Brain" } |
        Select-Object -First 1 |
        ForEach-Object {
            Write-Host "Running satellite: $($_.FullName)" -ForegroundColor Cyan
            & pwsh -NoProfile -File $_.FullName
        }
}

function Find-CBrainLaunchers {
    param([string]$Root)
    $patterns = @(
        "*masher*",
        "*cbrain*",
        "*CBrain*",
        "*Hello*EV*",
        "*hello*ev*operator*",
        "*pc5000*brain*",
        "*Run*Brain*",
        "*Start*Brain*"
    )
    $found = @()
    foreach ($pat in $patterns) {
        Get-ChildItem -LiteralPath $Root -Include $pat -Recurse -File -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Extension -in @(".ps1", ".py", ".bat", ".cmd") -and
                $_.FullName -notmatch '\\\.venv\\|\\Lib\\site-packages\\|node_modules'
            } |
            ForEach-Object { $found += $_ }
    }
    # Known Ev PC5000 tools (from your tree)
    foreach ($rel in @(
        "tools\pc5000\Get-PC5000EVLiveBrainStatus.ps1",
        "scripts\pc5000_ev_google_drive_brain_bootstrap.ps1",
        "scripts\Run-RoboShady-FullHistoricalCSV.ps1"
    )) {
        $p = Join-Path $Root $rel
        if (Test-Path $p) { $found += Get-Item $p }
    }
    $found | Sort-Object FullName -Unique
}

$ev = Resolve-EvRoot
$teakaRoot = Split-Path $PSScriptRoot -Parent
if (Test-Path "C:\Users\blair\EV_Git\teaka_trading_app") {
    $teakaRoot = "C:\Users\blair\EV_Git\teaka_trading_app"
}
$scratch = Join-Path $teakaRoot "scratch"
if (-not (Test-Path $scratch)) { New-Item -ItemType Directory -Path $scratch | Out-Null }
if (-not $SaveTo) { $SaveTo = Join-Path $scratch "cbrain_run_log.txt" }

Write-Host "=== C Brain (masher) ===" -ForegroundColor Cyan
Write-Host "Ev root: $ev" -ForegroundColor DarkGray
Write-Host "The Brain = masher. Satellite = optional add-on only.`n" -ForegroundColor DarkGray

$launchers = Find-CBrainLaunchers -Root $ev
$statusTool = Join-Path $ev "tools\pc5000\Get-PC5000EVLiveBrainStatus.ps1"
$bootstrap = Join-Path $ev "scripts\pc5000_ev_google_drive_brain_bootstrap.ps1"

$log = [System.Collections.Generic.List[string]]::new()
function Log-Line { param([string]$t) $log.Add($t); Write-Host $t }

Log-Line "Time: $(Get-Date -Format o)"

if (Test-Path $statusTool) {
    Log-Line "`n--- PC5000 live brain status ---"
    & pwsh -NoProfile -File $statusTool 2>&1 | ForEach-Object { Log-Line $_ }
} else {
    Log-Line "Status tool not found: $statusTool"
}

Log-Line "`n--- Ports (masher stack hints) ---"
foreach ($port in @(8080, 5050, 5056, 5000, 11434)) {
    if (Test-PortListening $port) { Log-Line "  Port $port : listening" }
    else { Log-Line "  Port $port : off" }
}

if ($StatusOnly -and -not $Start) {
    Log-Line "`nDiscovered launchers under Ev:"
    if (-not $launchers) { Log-Line "  (none — add entry script path to Ev or set in scratch\cbrain_launcher.txt)" }
    foreach ($l in $launchers) { Log-Line "  $($l.FullName)" }
    $log | Set-Content -LiteralPath $SaveTo -Encoding utf8
    Log-Line "`nSaved: $SaveTo"
    exit 0
}

if (-not $Start) {
    Write-Host @"

Usage:
  pwsh -NoProfile -File scripts\run_cbrain.ps1 -StatusOnly
  pwsh -NoProfile -File scripts\run_cbrain.ps1 -Start
  pwsh -NoProfile -File scripts\run_cbrain.ps1 -Start -WithCloak -WithSatellite

"@ -ForegroundColor White
    exit 0
}

Start-CloakIfRequested
Invoke-SatelliteAddon

Log-Line "`n--- Start masher (bootstrap if present) ---"
if (Test-Path $bootstrap) {
    Log-Line "Running: $bootstrap"
    & pwsh -NoProfile -File $bootstrap 2>&1 | ForEach-Object { Log-Line $_ }
} else {
    Log-Line "Bootstrap not found: $bootstrap"
}

$startCandidates = $launchers | Where-Object {
    $_.Name -match "bootstrap|Run|Start|hello" -and
    $_.Name -notmatch "Get-PC5000|Status|RoboShady"
} | Select-Object -First 1

if ($startCandidates) {
    Log-Line "Running launcher: $($startCandidates.FullName)"
    if ($startCandidates.Extension -eq ".ps1") {
        & pwsh -NoProfile -File $startCandidates.FullName 2>&1 | ForEach-Object { Log-Line $_ }
    } elseif ($startCandidates.Extension -eq ".py") {
        $py = Get-OperatorPython
        if ($py) { & $py $startCandidates.FullName 2>&1 | ForEach-Object { Log-Line $_ } }
    }
} elseif (-not (Test-Path $bootstrap)) {
    Log-Line @"

No masher start script auto-found. Pin your entry point (one line, full path):
  Set-Content -Path scratch\cbrain_launcher.txt -Value 'C:\path\to\your_masher_start.ps1'
Then re-run -Start.

"@ 
    $pin = Join-Path $scratch "cbrain_launcher.txt"
    if (Test-Path $pin) {
        $cmd = (Get-Content $pin -Raw).Trim()
        Log-Line "Pinned launcher: $cmd"
        if ($cmd -match '\.ps1$') { & pwsh -NoProfile -File $cmd }
        elseif ($cmd -match '\.py$') { $py = Get-OperatorPython; if ($py) { & $py $cmd } }
        else { Invoke-Expression $cmd }
    }
}

if (Test-Path $statusTool) {
    Log-Line "`n--- Status after start ---"
    & pwsh -NoProfile -File $statusTool 2>&1 | ForEach-Object { Log-Line $_ }
}

$log | Set-Content -LiteralPath $SaveTo -Encoding utf8
Write-Host "`nSaved: $SaveTo" -ForegroundColor Green
