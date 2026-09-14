# === run_cbrain.ps1 ===
# Run The Brain (masher) on PC5000 — discovers launchers under Ev + EV_Operator.
# Satellite (Git_Satellite_Brain) is optional add-on via -WithSatellite.
#
#   pwsh -NoProfile -File scripts\run_cbrain.ps1 -StatusOnly
#   pwsh -NoProfile -File scripts\run_cbrain.ps1 -Start
#   pwsh -NoProfile -File scripts\run_cbrain.ps1 -Start -WithCloak -WithSatellite
#
# Status includes RoboShady + Starforge (no full 5M-file walk — reads probe JSON only).

param(
    [switch]$StatusOnly,
    [switch]$Start,
    [switch]$WithCloak,
    [switch]$WithSatellite,
    [switch]$SkipRoboShadyCheck,
    [switch]$SkipStarforgeCheck,
    [string]$EvRoot = "",
    [string]$StarforgeRoot = "",
    [string]$SaveTo = "",
    [string]$JsonSaveTo = ""
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

function Get-LatestProbe {
    param([string]$Dir, [string]$Filter)
    if (-not (Test-Path $Dir)) { return $null }
    Get-ChildItem -LiteralPath $Dir -Filter $Filter -File -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
}

function Get-ProbeSummary {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) { return @{ file = $FilePath; missing = $true } }
    try {
        $j = Get-Content -LiteralPath $FilePath -Raw -Encoding UTF8 | ConvertFrom-Json
        $o = [ordered]@{
            file       = $FilePath
            last_write = (Get-Item $FilePath).LastWriteTime.ToString("o")
            schema     = $j.schema
            mode       = $j.mode
            command_id = $j.command_id
        }
        foreach ($key in @(
            "file_count", "total_files", "indexed_files", "brain_file_count",
            "files_indexed", "million", "starforge", "roboshady", "runtime_mode", "status"
        )) {
            if ($j.PSObject.Properties.Name -contains $key) { $o[$key] = $j.$key }
        }
        # nested common shapes
        if ($j.brain) {
            foreach ($k in @("file_count", "total_files", "indexed_files")) {
                if ($j.brain.PSObject.Properties.Name -contains $k) { $o["brain_$k"] = $j.brain.$k }
            }
        }
        if ($j.index) {
            foreach ($k in @("file_count", "total_files", "count")) {
                if ($j.index.PSObject.Properties.Name -contains $k) { $o["index_$k"] = $j.index.$k }
            }
        }
        return $o
    } catch {
        return @{ file = $FilePath; parse_error = $_.Exception.Message }
    }
}

function Get-RoboShadyStarforgeStatus {
    param([string]$Ev, [string]$Starforge)
    $live = Join-Path $Ev "bridge\live\pc5000"
    $rob = @{
        latest_runtime = Get-ProbeSummary -FilePath ((Get-LatestProbe -Dir $live -Filter "*runtime_mode_roboshady*").FullName)
        latest_schema  = Get-ProbeSummary -FilePath ((Get-LatestProbe -Dir $live -Filter "*roboshady_chat_schema*").FullName)
        latest_stack   = Get-ProbeSummary -FilePath ((Get-LatestProbe -Dir $live -Filter "*brain_gembot_stack_probe*").FullName)
        latest_greenland = Get-ProbeSummary -FilePath ((Get-LatestProbe -Dir $live -Filter "*mt_greenland_roboshady*").FullName)
    }
    $sf = @{ path = $Starforge; git = $false }
    if ($Starforge -and (Test-Path $Starforge)) {
        $sf.path = (Resolve-Path $Starforge).Path
        if (Test-Path (Join-Path $Starforge ".git")) {
            Push-Location $Starforge
            $sf.git = $true
            $sf.remote = git remote get-url origin 2>$null
            $sf.branch = git branch --show-current 2>$null
            Pop-Location
        }
        $vault = Join-Path $Starforge "Vault"
        $sf.vault_path = $vault
        $sf.vault_exists = Test-Path $vault
        if ($sf.vault_exists) {
            # Shallow sample only — brain index ~5M is NOT enumerated here
            $sf.vault_top_entries = @(Get-ChildItem -LiteralPath $vault -ErrorAction SilentlyContinue | Select-Object -First 12 Name)
        }
    }
    # Recorded index size hint (from probes or convention — no full scan)
    $fiveM = 5000000
    $recorded = $null
    foreach ($p in @($rob.latest_runtime, $rob.latest_stack, $rob.latest_schema)) {
        if (-not $p) { continue }
        foreach ($k in @("file_count", "total_files", "indexed_files", "brain_file_count", "index_count", "brain_total_files")) {
            if ($p.Contains($k) -and $p[$k]) { $recorded = [int64]$p[$k]; break }
        }
        if ($recorded) { break }
    }
    return [ordered]@{
        roboshady   = $rob
        starforge   = $sf
        brain_index = @{
            recorded_file_count = $recorded
            design_note         = "Masher/master brain index may be ~5M files in RoboShady/Starforge plane — this script never walks all files."
            expected_order_of_magnitude = $fiveM
        }
    }
}

function Find-CBrainLaunchers {
    param([string]$Root)
    $patterns = @(
        "*masher*",
        "*master*",
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
if (-not $JsonSaveTo) { $JsonSaveTo = Join-Path $scratch "cbrain_status.json" }
if (-not $StarforgeRoot) {
    foreach ($s in @("D:\Dropbox\Starforge", "D:\Starforge")) {
        if (Test-Path $s) { $StarforgeRoot = $s; break }
    }
}

Write-Host "=== C Brain (masher / master index) ===" -ForegroundColor Cyan
Write-Host "Ev root: $ev" -ForegroundColor DarkGray
Write-Host "The Brain = masher (master file index). RoboShady + Starforge checked in status.`n" -ForegroundColor DarkGray

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

$statusJson = [ordered]@{
    generated_at = (Get-Date).ToString("o")
    ev_root      = $ev
    starforge_root = $StarforgeRoot
    ports        = @{}
}
foreach ($port in @(8080, 5050, 5056, 5000, 11434)) {
    $statusJson.ports["$port"] = Test-PortListening $port
}

if (-not $SkipRoboShadyCheck -or -not $SkipStarforgeCheck) {
    Log-Line "`n--- RoboShady + Starforge (probe JSON only) ---"
    $rs = Get-RoboShadyStarforgeStatus -Ev $ev -Starforge $(if ($SkipStarforgeCheck) { "" } else { $StarforgeRoot })
    $statusJson.roboshady_starforge = $rs
    if ($rs.brain_index.recorded_file_count) {
        Log-Line "  Brain index (from probe): $($rs.brain_index.recorded_file_count) files"
    } else {
        Log-Line "  Brain index: ~5M files (design) — no count field in latest RoboShady probe; not scanning disk."
    }
    foreach ($k in @("latest_runtime", "latest_stack", "latest_schema", "latest_greenland")) {
        $p = $rs.roboshady[$k]
        if ($p -and $p.file -and -not $p.missing) {
            Log-Line "  RoboShady $k : $(Split-Path $p.file -Leaf)"
        }
    }
    if ($rs.starforge.path) {
        Log-Line "  Starforge: $($rs.starforge.path) git=$($rs.starforge.git) vault=$($rs.starforge.vault_exists)"
    }
}

if ($StatusOnly -and -not $Start) {
    Log-Line "`nDiscovered launchers under Ev:"
    if (-not $launchers) { Log-Line "  (none — add entry script path to Ev or set in scratch\cbrain_launcher.txt)" }
    foreach ($l in $launchers) { Log-Line "  $($l.FullName)" }
    $statusJson.launchers = @($launchers | ForEach-Object { $_.FullName })
    $statusJson | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $JsonSaveTo -Encoding utf8
    $log | Set-Content -LiteralPath $SaveTo -Encoding utf8
    Log-Line "`nSaved: $SaveTo"
    Log-Line "JSON: $JsonSaveTo"
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

if (-not $SkipRoboShadyCheck) {
    $statusJson.roboshady_starforge = Get-RoboShadyStarforgeStatus -Ev $ev -Starforge $StarforgeRoot
}
$statusJson | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $JsonSaveTo -Encoding utf8
$log | Set-Content -LiteralPath $SaveTo -Encoding utf8
Write-Host "`nSaved: $SaveTo" -ForegroundColor Green
Write-Host "JSON: $JsonSaveTo" -ForegroundColor DarkGray
