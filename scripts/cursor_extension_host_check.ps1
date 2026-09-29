# === cursor_extension_host_check.ps1 ===
# What is Cursor doing? Real IDE vs Chrome PWA, extension-host restarts, logs, extensions.
#
#   pwsh -NoProfile -File scripts\cursor_extension_host_check.ps1
#   pwsh -NoProfile -File scripts\cursor_extension_host_check.ps1 -SaveTo scratch\cursor_extension_host_check.txt

param(
    [string]$SaveTo = "",
    [string]$TeakaRoot = "",
    [int]$LogTailLines = 4000
)

$ErrorActionPreference = "SilentlyContinue"

if (-not $TeakaRoot) {
    $TeakaRoot = Split-Path $PSScriptRoot -Parent
    if (Test-Path "C:\Users\blair\EV_Git\teaka_trading_app") {
        $TeakaRoot = "C:\Users\blair\EV_Git\teaka_trading_app"
    }
}
$scratch = Join-Path $TeakaRoot "scratch"
if (-not (Test-Path $scratch)) { New-Item -ItemType Directory -Path $scratch | Out-Null }
if (-not $SaveTo) { $SaveTo = Join-Path $scratch "cursor_extension_host_check.txt" }

$lines = [System.Collections.Generic.List[string]]::new()
function Add-Line { param([string]$s) $lines.Add($s); Write-Host $s }

Add-Line "=== CURSOR EXTENSION / SHORTCUT CHECK ==="
Add-Line "Time: $(Get-Date -Format o)"
Add-Line ""

# --- Real Cursor.exe ---
$cursorExes = @(
    "C:\Program Files\cursor\_\Cursor.exe",
    "C:\Program Files\Cursor\Cursor.exe"
) | Where-Object { Test-Path -LiteralPath $_ }

Add-Line "=== CURSOR DESKTOP APP ==="
if (-not $cursorExes) {
    Add-Line "  Cursor.exe not found under Program Files (install/repair from cursor.com)"
} else {
    foreach ($exe in $cursorExes) {
        $i = Get-Item -LiteralPath $exe
        Add-Line ("  {0}" -f $exe)
        Add-Line ("    Version: {0}  Modified: {1}" -f $i.VersionInfo.ProductVersion, $i.LastWriteTime)
    }
}

Add-Line ""
Add-Line "=== RUNNING PROCESSES (Cursor family) ==="
$procs = Get-CimInstance Win32_Process -Filter "Name='Cursor.exe' OR Name='codex.exe' OR Name='Code.exe'" -ErrorAction SilentlyContinue
if (-not $procs) { Add-Line "  (no Cursor.exe / codex.exe / Code.exe right now)" }
foreach ($p in $procs) {
    $cmd = $p.CommandLine
    if ($cmd.Length -gt 200) { $cmd = $cmd.Substring(0, 200) + "..." }
    Add-Line ("  PID {0} {1}" -f $p.ProcessId, $p.Name)
    Add-Line ("    {0}" -f $cmd)
}

Add-Line ""
Add-Line "=== SHORTCUTS NAMED Cursor (real IDE vs Chrome PWA) ==="
$wsh = New-Object -ComObject WScript.Shell
$fakeChrome = @()
$realIde = @()
Get-ChildItem @(
    "$env:APPDATA\Microsoft\Windows\Start Menu",
    "$env:ProgramData\Microsoft\Windows\Start Menu",
    "$env:USERPROFILE\Desktop"
) -Filter "Cursor*.lnk" -File -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
    $sc = $wsh.CreateShortcut($_.FullName)
    $isChrome = $sc.TargetPath -match "chrome(_proxy)?\.exe" -or $sc.Arguments -match "app-id="
    $row = [ordered]@{
        shortcut = $_.FullName
        target   = $sc.TargetPath
        args     = $sc.Arguments
    }
    if ($isChrome) { $fakeChrome += $row } else { $realIde += $row }
    Add-Line ("  {0}" -f $_.FullName)
    Add-Line ("    Target: {0}" -f $sc.TargetPath)
    if ($sc.Arguments) { Add-Line ("    Args: {0}" -f $sc.Arguments) }
    Add-Line ("    Kind: {0}" -f $(if ($isChrome) { "CHROME PWA (not desktop Cursor IDE)" } else { "Desktop IDE shortcut" }))
}

Add-Line ""
if ($fakeChrome.Count -gt 0) {
    Add-Line "WARNING: $($fakeChrome.Count) shortcut(s) open Chrome app, not Cursor.exe — common at Startup."
    foreach ($f in $fakeChrome) {
        if ($f.shortcut -match "Startup") {
            Add-Line "  Startup fake Cursor: $($f.shortcut)"
        }
    }
}

# --- Logs: extension host exits ---
Add-Line ""
Add-Line "=== EXTENSION HOST RESTARTS (from Cursor logs) ==="
Add-Line "  code 0 = clean exit (host replaced — often extensions/reload/agents, not a crash)"

$logRoots = @(
    Join-Path $env:APPDATA "Cursor\logs"
    Join-Path $env:APPDATA "cursor\logs"
)
$mainLogs = @()
foreach ($root in $logRoots) {
    if (-not (Test-Path $root)) { continue }
    Get-ChildItem -LiteralPath $root -Filter "main.log" -Recurse -File -ErrorAction SilentlyContinue |
        ForEach-Object { $mainLogs += $_ }
    $main = Join-Path $root "main.log"
    if (Test-Path $main) { $mainLogs += Get-Item $main }
}
$mainLogs = $mainLogs | Sort-Object LastWriteTime -Descending | Select-Object -Unique -First 3

if (-not $mainLogs) {
    Add-Line "  No main.log found under %APPDATA%\Cursor\logs (open Cursor once, then re-run)."
} else {
    foreach ($ml in $mainLogs) {
        Add-Line ("  Log: {0} ({1})" -f $ml.FullName, $ml.LastWriteTime)
        $tail = Get-Content -LiteralPath $ml.FullName -Tail $LogTailLines -ErrorAction SilentlyContinue
        $exits = @($tail | Select-String "Extension host with pid \d+ exited")
        Add-Line ("    In last {0} lines: {1} extension-host exit line(s)" -f $LogTailLines, $exits.Count)
        if ($exits.Count -gt 0) {
            Add-Line "    Last 5:"
            $exits | Select-Object -Last 5 | ForEach-Object { Add-Line ("      $($_.Line.Trim())") }
        }
        $updates = @($tail | Select-String "update#setState")
        if ($updates) {
            Add-Line ("    Update state lines (last 3):")
            $updates | Select-Object -Last 3 | ForEach-Object { Add-Line ("      $($_.Line.Trim())") }
        }
        $traceFail = @($tail | Select-String "TracingService: failed")
        if ($traceFail) {
            Add-Line ("    Tracing errors: $($traceFail.Count) in tail (telemetry — usually harmless)")
        }
    }
}

# --- Installed extensions (top by folder size) ---
Add-Line ""
Add-Line "=== INSTALLED EXTENSIONS (largest folders — suspects if host loops) ==="
$extRoots = @(
    Join-Path $env:USERPROFILE ".cursor\extensions"
    Join-Path $env:USERPROFILE ".vscode\extensions"
)
foreach ($er in $extRoots) {
    if (-not (Test-Path $er)) { continue }
    Add-Line "  Root: $er"
    Get-ChildItem -LiteralPath $er -Directory -ErrorAction SilentlyContinue |
        ForEach-Object {
            $sizeMb = [math]::Round((Get-ChildItem $_.FullName -Recurse -File -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum).Sum / 1MB, 1)
            [PSCustomObject]@{ Name = $_.Name; SizeMB = $sizeMb; Modified = $_.LastWriteTime }
        } |
        Sort-Object SizeMB -Descending |
        Select-Object -First 12 |
        ForEach-Object { Add-Line ("    {0} MB  {1}" -f $_.SizeMB, $_.Name) }
}

Add-Line ""
Add-Line "=== INTERPRETATION ==="
Add-Line @"
  • Many 'Extension host exited code 0' + editor still works → reload churn (extensions, agents, window reload).
  • Chrome PWA in Startup → not the IDE; use Program Files\cursor\_\Cursor.exe for TeAka repo.
  • Test without extensions:
      & 'C:\Program Files\cursor\_\Cursor.exe' --disable-extensions `"$TeakaRoot`"
  • If restarts stop → re-enable extensions in Cursor until one triggers it (Help → Developer Tools → Console).
"@

Add-Line ""
Add-Line "=== QUICK COMMANDS ==="
Add-Line "  pwsh -NoProfile -File `"$TeakaRoot\scripts\cursor_install_check.ps1`" -SaveTo `"$scratch\cursor_install_check.txt`""

$outPath = if ([System.IO.Path]::IsPathRooted($SaveTo)) { $SaveTo } else { Join-Path $TeakaRoot $SaveTo }
$dir = Split-Path $outPath -Parent
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
$lines -join "`n" | Set-Content -LiteralPath $outPath -Encoding utf8
Add-Line ""
Add-Line "Saved: $outPath"
