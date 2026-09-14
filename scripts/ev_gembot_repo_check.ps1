# === ev_gembot_repo_check.ps1 ===
# Auto-locate GemBot / EV_Link trees (local + optional git clone under EV_Git), sanity-check, save report.
#
#   pwsh -NoProfile -File scripts\ev_gembot_repo_check.ps1
#   pwsh -NoProfile -File scripts\ev_gembot_repo_check.ps1 -RepoPath "C:\Users\blair\EV_Git\gembot29"
#   pwsh -NoProfile -File scripts\ev_gembot_repo_check.ps1 -SaveTo scratch\gembot_repo_check.txt

param(
    [string]$RepoPath = "",
    [string]$SaveTo = "",
    [switch]$TryClone,
    [string]$CloneUrl = "",
    [string]$EvGitRoot = "C:\Users\blair\EV_Git"
)

$ErrorActionPreference = "SilentlyContinue"

$teakaRoot = Split-Path $PSScriptRoot -Parent
if (Test-Path "C:\Users\blair\EV_Git\teaka_trading_app\.git") {
    $teakaRoot = "C:\Users\blair\EV_Git\teaka_trading_app"
}
$scratch = Join-Path $teakaRoot "scratch"
if (-not (Test-Path $scratch)) { New-Item -ItemType Directory -Path $scratch | Out-Null }
if (-not $SaveTo) { $SaveTo = Join-Path $scratch "gembot_repo_check.txt" }

$lines = [System.Collections.Generic.List[string]]::new()
function Out-Report {
    param([string]$Text, [string]$Color = "White")
    $lines.Add($Text)
    if ($Color -eq "Cyan") { Write-Host $Text -ForegroundColor Cyan }
    elseif ($Color -eq "Yellow") { Write-Host $Text -ForegroundColor Yellow }
    elseif ($Color -eq "Green") { Write-Host $Text -ForegroundColor Green }
    elseif ($Color -eq "Red") { Write-Host $Text -ForegroundColor Red }
    elseif ($Color -eq "Gray" -or $Color -eq "DarkGray") { Write-Host $Text -ForegroundColor DarkGray }
    else { Write-Host $Text }
}

Out-Report "=== GEMBOT / EV_Link REPO CHECK ===" "Cyan"
Out-Report "Time: $(Get-Date -Format o)" "Gray"
Out-Report ""

# Candidate roots: explicit path, EV_Git *gem* / *29*, legacy GEMBotSys EV_Link
$candidates = [System.Collections.Generic.List[string]]::new()
if ($RepoPath -and (Test-Path -LiteralPath $RepoPath)) {
    [void]$candidates.Add((Resolve-Path -LiteralPath $RepoPath).Path)
}

$probeRoots = @(
    $EvGitRoot,
    "C:\Users\Blair\EV_Git",
    "C:\Users\GEMBotSys\EV_Link",
    "C:\Users\GEMBotSys\EV_Link\GemBot",
    "E:\EV_Files",
    "D:\EV_Files"
)

foreach ($root in $probeRoots) {
    if (-not (Test-Path -LiteralPath $root)) { continue }
    if ($root -match "EV_Link\\GemBot$") {
        [void]$candidates.Add($root)
        continue
    }
    Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -match "gembot|gem_bot|GemBot|ev_link|EV_Link|gem.?29|29" -or
            $_.Name -eq "Ev" -or $_.Name -eq "Evolution_AI"
        } |
        ForEach-Object { [void]$candidates.Add($_.FullName) }
}

# Also teaka sibling folders under EV_Link
$evLink = "C:\Users\GEMBotSys\EV_Link"
if (Test-Path $evLink) {
    [void]$candidates.Add($evLink)
    foreach ($sub in @("GemBot", "Bridge", "Platform\Evolution_AI")) {
        $p = Join-Path $evLink $sub
        if (Test-Path $p) { [void]$candidates.Add($p) }
    }
}

$unique = $candidates | Select-Object -Unique | Where-Object { $_ -and (Test-Path $_) }

if (-not $unique -and $TryClone -and $CloneUrl) {
    $dest = Join-Path $EvGitRoot ([IO.Path]::GetFileName($CloneUrl.TrimEnd('/').Replace(".git", "")))
    Out-Report "[Clone] git clone $CloneUrl -> $dest" "Yellow"
    if (-not (Test-Path $EvGitRoot)) { New-Item -ItemType Directory -Path $EvGitRoot | Out-Null }
    Push-Location $EvGitRoot
    git clone $CloneUrl $dest 2>&1 | ForEach-Object { Out-Report $_ "Gray" }
    Pop-Location
    if (Test-Path $dest) { $unique = @((Resolve-Path $dest).Path) }
}

if (-not $unique) {
    Out-Report "No GemBot folder found automatically." "Red"
    Out-Report @"

Set -RepoPath to your gembot 29 checkout, e.g.:
  pwsh -NoProfile -File scripts\ev_gembot_repo_check.ps1 -RepoPath "C:\Users\blair\EV_Git\<your-gembot-repo>"

Or clone (private URL — replace):
  pwsh -NoProfile -File scripts\ev_gembot_repo_check.ps1 -TryClone -CloneUrl "https://github.com/BlairGem1234/<gembot29>.git"

Known legacy layout (not always git):
  C:\Users\GEMBotSys\EV_Link\GemBot\
"@ "Gray"
    $lines | Set-Content -LiteralPath $SaveTo -Encoding utf8
    Out-Report "`nSaved: $SaveTo" "Green"
    exit 1
}

$keyFiles = @(
    "ev_remote_server.py",
    "gem_bot.py",
    "ev_bot.py",
    "ev_flask_server.py",
    "status_report.yaml",
    "ev_virtual_brain.json",
    "ev_brain_state.json"
)

foreach ($dir in $unique) {
    Out-Report "`n----------------------------------------" "Cyan"
    Out-Report "ROOT: $dir" "Yellow"

    $gitDir = Join-Path $dir ".git"
    if (Test-Path $gitDir) {
        Push-Location $dir
        Out-Report "[Git remote]" "Yellow"
        git remote -v 2>&1 | ForEach-Object { Out-Report "  $_" }
        Out-Report "[Git branch] $(git branch --show-current 2>&1)" "Yellow"
        $st = git status -sb 2>&1 | Out-String
        Out-Report "[Git status]`n$st" "Gray"
        Out-Report "[Recent commit]" "Yellow"
        git log -1 --oneline 2>&1 | ForEach-Object { Out-Report "  $_" }
        Pop-Location
    } else {
        Out-Report "(Not a git repo — folder scan only)" "Gray"
    }

    Out-Report "[Key files]" "Yellow"
    foreach ($kf in $keyFiles) {
        $hits = Get-ChildItem -LiteralPath $dir -Filter $kf -Recurse -ErrorAction SilentlyContinue | Select-Object -First 5
        if ($hits) {
            foreach ($h in $hits) {
                Out-Report "  OK $($h.FullName) ($($h.Length) bytes, $($h.LastWriteTime))" "Green"
            }
        }
    }

    Out-Report "[EV / Codex / Cloak refs in *.py, *.md, *.json (sample)]" "Yellow"
    Get-ChildItem -LiteralPath $dir -Include *.py, *.md, *.json, *.yaml, *.ps1 -Recurse -ErrorAction SilentlyContinue |
        Select-Object -First 400 |
        ForEach-Object {
            Select-String -LiteralPath $_.FullName -Pattern "EV_Operator|EV_AI|ev_devtools_cloak|Codex|5056|5000|Flask" -ErrorAction SilentlyContinue
        } |
        Select-Object -First 20 |
        ForEach-Object { Out-Report "  $($_.Path):$($_.LineNumber) $($_.Line.Trim())" "DarkGray" }

    $gemBotSub = Join-Path $dir "GemBot"
    if (Test-Path $gemBotSub) {
        Out-Report "[GemBot subfolder]" "Yellow"
        Get-ChildItem -LiteralPath $gemBotSub -File -ErrorAction SilentlyContinue | Select-Object -First 15 Name, Length |
            ForEach-Object { Out-Report "  $($_.Name) $($_.Length)" }
    }
}

Out-Report "`n[Ports — GemBot bridge often Flask :5000]" "Yellow"
foreach ($port in @(5000, 5055, 5056, 8080, 11434)) {
    $hit = netstat -ano 2>$null | Select-String ":$port\s"
    if ($hit) {
        $pids = $hit | ForEach-Object { ($_ -split '\s+')[-1] } | Select-Object -Unique
        foreach ($procId in $pids) {
            $proc = Get-CimInstance Win32_Process -Filter "ProcessId = $procId" -ErrorAction SilentlyContinue
            Out-Report "  Port $port -> PID $procId $($proc.Name)" "Green"
        }
    } else {
        Out-Report "  Port $port not listening." "Gray"
    }
}

Out-Report "`n[TeAka cross-check]" "Yellow"
Out-Report "  This handoff repo: $teakaRoot" "Gray"
Out-Report "  Run pick + codex after GemBot check:" "Gray"
Out-Report "    pwsh -NoProfile -File scripts\run_local_handoff.ps1 -Action pick -SkipPull" "Gray"
Out-Report "    pwsh -NoProfile -File scripts\run_local_handoff.ps1 -Action codex -SkipPull" "Gray"

$lines | Set-Content -LiteralPath $SaveTo -Encoding utf8
Out-Report "`nSaved: $SaveTo" "Green"
Out-Report "Paste path to cloud agent: scratch\gembot_repo_check.txt" "DarkGray"
