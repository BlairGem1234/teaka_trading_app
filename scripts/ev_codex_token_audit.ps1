# === ev_codex_token_audit.ps1 ===
# Find duplicate EV Cloak / Codex-related processes and common throttle config paths.
# Safe read-only except optional -StopDuplicates (kills extra cloak PIDs, keeps newest).

param(
    [string[]]$SearchRoots = @(
        "C:\EV_Operator",
        "C:\EV_AI",
        "C:\EV_AI\Codex",
        "C:\EV_AI\Cursor",
        "C:\EV_Files",
        "C:\Users\blair\EV_Git\teaka_trading_app",
        "C:\Users\GEMBotSys\EV_Link"
    ),
    [int[]]$WatchPorts = @(5056, 5057),
    [switch]$StopDuplicates,
    [string]$SaveTo = ""
)

$ErrorActionPreference = "SilentlyContinue"

Write-Host "=== EV CODEX / CLOAK TOKEN AUDIT ===" -ForegroundColor Cyan

# 1. Python processes (cloak / codex / ev_devtools)
Write-Host "`n[1] Python processes (cloak / codex / devtools)" -ForegroundColor Yellow
$py = Get-CimInstance Win32_Process -Filter "Name = 'python.exe' OR Name = 'pythonw.exe'" |
    Where-Object { $_.CommandLine -match "cloak|codex|ev_devtools|DevToolsRuntime" }

if ($py) {
    $py | ForEach-Object {
        [PSCustomObject]@{
            PID         = $_.ProcessId
            Name        = $_.Name
            CommandLine = $_.CommandLine
        }
    } | Format-List

    $cloak = @($py | Where-Object { $_.CommandLine -match "ev_devtools_cloak|devtools_cloak" })
    if ($cloak.Count -gt 1 -and $StopDuplicates) {
        $keep = $cloak | Sort-Object CreationDate -Descending | Select-Object -First 1
        $kill = $cloak | Where-Object { $_.ProcessId -ne $keep.ProcessId }
        foreach ($k in $kill) {
            Write-Host "Stopping duplicate Cloak PID $($k.ProcessId)" -ForegroundColor Red
            Stop-Process -Id $k.ProcessId -Force -ErrorAction SilentlyContinue
        }
    } elseif ($cloak.Count -gt 1) {
        Write-Host "WARNING: $($cloak.Count) ev_devtools_cloak-like processes. Re-run with -StopDuplicates to keep newest only." -ForegroundColor Red
    }
} else {
    Write-Host "No matching Python processes (Cloak may be stopped or uses a different launcher)." -ForegroundColor Gray
}

# 2. Port listeners
Write-Host "`n[2] Ports $($WatchPorts -join ', ')" -ForegroundColor Yellow
foreach ($port in $WatchPorts) {
    $lines = netstat -ano | Select-String ":$port\s"
    if ($lines) {
        $pids = $lines | ForEach-Object { ($_ -split '\s+')[-1] } | Select-Object -Unique
        foreach ($procId in $pids) {
            $proc = Get-CimInstance Win32_Process -Filter "ProcessId = $procId" -ErrorAction SilentlyContinue
            Write-Host "Port $port -> PID $procId $($proc.Name)" -ForegroundColor Green
            if ($proc.CommandLine) { Write-Host "  $($proc.CommandLine)" -ForegroundColor DarkGray }
        }
    } else {
        Write-Host "Port $port not listening." -ForegroundColor Gray
    }
}

# 3. Config files
Write-Host "`n[3] Clock / throttle config (first hits)" -ForegroundColor Yellow
$configNames = @("ev_clock.json", "ev_clock_throttle.js", "ev_devtools_cloak.py", "EV_MEMORY.json")
foreach ($root in $SearchRoots) {
    if (-not (Test-Path -LiteralPath $root)) { continue }
    foreach ($cn in $configNames) {
        Get-ChildItem -LiteralPath $root -Filter $cn -Recurse -ErrorAction SilentlyContinue |
            Select-Object -First 3 FullName, Length, LastWriteTime |
            Format-Table -AutoSize
    }
}

# 4. Cursor / Codex token hygiene (informational)
Write-Host "`n[4] Token hygiene (manual)" -ForegroundColor Yellow
Write-Host @"
- Run only ONE Codex profile (Stable OR Beta), not both.
- Avoid pasting full directory trees into Cursor; use scratch\*.txt + path.
- Cloud agents do not use EV Cloak; fix duplicates on Desktop/local PowerShell.
"@ -ForegroundColor DarkGray

$summary = @(
    "Cloak-like Python count: $(@($py | Where-Object { $_.CommandLine -match 'cloak' }).Count)"
    "Codex-like Python count: $(@($py | Where-Object { $_.CommandLine -match 'codex' }).Count)"
    "Ports checked: $($WatchPorts -join ', ')"
)

Write-Host "`n--- SUMMARY ---" -ForegroundColor Cyan
$summary | ForEach-Object { Write-Host $_ }

if ($SaveTo) {
    $outPath = if ([System.IO.Path]::IsPathRooted($SaveTo)) { $SaveTo } else { Join-Path (Get-Location) $SaveTo }
    $dir = Split-Path $outPath -Parent
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    ($summary + "") | Out-File -FilePath $outPath -Encoding utf8
    Write-Host "Saved summary to $outPath" -ForegroundColor Green
}
