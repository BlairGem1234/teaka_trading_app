#Requires -Version 5.1
<#
.SYNOPSIS
  Read-only by default. Rebind legacy BlairGem git remotes on BLAIRSPC to BlairGem1234.

.DESCRIPTION
  Covers every known EV/TeAka clone the cloud agent cannot see.
  - NEVER rewrites GEMBot29 (BlairGem1234/GEMBot29 is 404).
  - NEVER deletes clone folders.
  - NEVER rewrites git history, logs, or transcripts.
  - TeAka mirror remotes that still say BlairGem/teaka_trading_app are safe:
    GitHub already 301s them to BlairGem1234/teaka_trading_app.

  Dry-run (default):
    pwsh -NoProfile -File scripts\rebind_pc_git_owner.ps1

  Apply remote URL changes only:
    pwsh -NoProfile -File scripts\rebind_pc_git_owner.ps1 -ApplyRemotes

  Also rewrite text files in each clone (skips GEMBot29 strings):
    pwsh -NoProfile -File scripts\rebind_pc_git_owner.ps1 -ApplyRemotes -ApplyFiles
#>
[CmdletBinding()]
param(
    [switch]$ApplyRemotes,
    [switch]$ApplyFiles
)

$ErrorActionPreference = "Continue"

$LiveTeaka = "C:\Users\Blair\EV_Git\teaka_trading_app"
$Known = @(
    @{ Path = "C:\Users\Blair\EV_Git\Ev";                    Expected = "https://github.com/BlairGem1234/Ev.git"; Skip = $false },
    @{ Path = "C:\Users\Blair\EV_Git\GPT_AI_Workspace";      Expected = "https://github.com/BlairGem1234/GPT_AI_Workspace.git"; Skip = $false },
    @{ Path = "C:\Users\Blair\EV_Git\teaka_trading_app";     Expected = "https://github.com/BlairGem1234/teaka_trading_app.git"; Skip = $false },
    @{ Path = "C:\Users\Blair\EV_Git\MT_GREENLAND";          Expected = "https://github.com/BlairGem1234/MT_GREENLAND.git"; Skip = $false },
    @{ Path = "C:\Users\Blair\EV_Git\Pc-5000-curser-";       Expected = "https://github.com/BlairGem1234/Pc-5000-curser-.git"; Skip = $false },
    @{ Path = "C:\EV_Operator\Cursor";                       Expected = "https://github.com/BlairGem1234/Cursor_Master.git"; Skip = $false },
    @{ Path = "C:\EV_Operator\Clock";                        Expected = "https://github.com/BlairGem1234/EV_Brain_Clock.git"; Skip = $false },
    @{ Path = "C:\Users\Blair\EV_Git\teaka_trading_app_CANONICAL"; Expected = "https://github.com/BlairGem1234/teaka_trading_app.git"; Skip = $false },
    @{ Path = "C:\Users\Blair\EV_Git_tmp_teaka_github_main";  Expected = "https://github.com/BlairGem1234/teaka_trading_app.git"; Skip = $false },
    @{ Path = "C:\Users\Blair\EV_Git\GEMBot29";              Expected = $null; Skip = $true; Reason = "BlairGem1234/GEMBot29 returns 404; do not rebind" }
)

function Get-OriginUrl([string]$Repo) {
    git -C $Repo remote get-url origin 2>$null
}

function Normalize-GitHubUrl([string]$Url) {
    if (-not $Url) { return "" }
    return ($Url -replace '\.git$', '' -replace 'https://github.com/', '' -replace 'git@github.com:', '').Trim()
}

function Test-LegacyOwner([string]$Url) {
    $n = Normalize-GitHubUrl $Url
    return ($n -match '^(BlairGem|blairgem)/' -and $n -notmatch '^BlairGem1234/')
}

Write-Host "=== PC GIT OWNER REBIND ===" -ForegroundColor Cyan
Write-Host ("Mode: remotes={0} files={1}" -f $(if ($ApplyRemotes) {"APPLY"} else {"DRY-RUN"}), $(if ($ApplyFiles) {"APPLY"} else {"DRY-RUN"}))
Write-Host ""

# --- 1. Remotes ---
Write-Host "[1] Remotes" -ForegroundColor Yellow
foreach ($item in $Known) {
    $p = $item.Path
    if (-not (Test-Path -LiteralPath (Join-Path $p ".git"))) {
        Write-Host ("  MISSING  {0}" -f $p) -ForegroundColor DarkGray
        continue
    }
    $url = Get-OriginUrl $p
    if ($item.Skip) {
        Write-Host ("  LEAVE    {0}" -f $p) -ForegroundColor Magenta
        Write-Host ("           origin={0}" -f $url)
        Write-Host ("           {0}" -f $item.Reason)
        continue
    }
    $legacy = Test-LegacyOwner $url
    $mark = if ($legacy) { "LEGACY" } else { "OK    " }
    Write-Host ("  {0}  {1}" -f $mark, $p)
    Write-Host ("           origin={0}" -f $url)
    if ($legacy -and $item.Expected) {
        Write-Host ("           proposed={0}" -f $item.Expected) -ForegroundColor Green
        if ($ApplyRemotes) {
            git -C $p remote set-url origin $item.Expected
            Write-Host ("           SET origin -> {0}" -f (Get-OriginUrl $p)) -ForegroundColor Green
        }
    }
}

# --- 2. TeAka mirror uniqueness (read-only) ---
Write-Host "`n[2] TeAka mirror uniqueness vs live clone" -ForegroundColor Yellow
$mirrors = @(
    "C:\Users\Blair\EV_Git\teaka_trading_app_CANONICAL",
    "C:\Users\Blair\EV_Git_tmp_teaka_github_main"
)
if (Test-Path -LiteralPath (Join-Path $LiveTeaka ".git")) {
    $liveHead = git -C $LiveTeaka rev-parse HEAD
    $liveBranch = git -C $LiveTeaka branch --show-current
    Write-Host ("  LIVE {0}" -f $LiveTeaka)
    Write-Host ("       branch={0} HEAD={1}" -f $liveBranch, $liveHead)
    foreach ($m in $mirrors) {
        if (-not (Test-Path -LiteralPath (Join-Path $m ".git"))) {
            Write-Host ("  MISSING {0}" -f $m) -ForegroundColor DarkGray
            continue
        }
        $head = git -C $m rev-parse HEAD
        $branch = git -C $m branch --show-current
        $status = git -C $m status --porcelain
        $ahead = git -C $m rev-list --count "$liveHead..HEAD" 2>$null
        $behind = git -C $m rev-list --count "HEAD..$liveHead" 2>$null
        Write-Host ("  MIRROR {0}" -f $m)
        Write-Host ("         branch={0} HEAD={1}" -f $branch, $head)
        Write-Host ("         vs live: ahead={0} behind={1} dirty_lines={2}" -f $ahead, $behind, @($status).Count)
        if ($status) { $status | Select-Object -First 20 | ForEach-Object { Write-Host ("         {0}" -f $_) } }
        if ($head -eq $liveHead -and -not $status) {
            Write-Host "         duplicate/mirror of live HEAD (no unique commits/files)" -ForegroundColor Green
        } else {
            Write-Host "         NOT a clean duplicate — keep this folder, do not delete" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "  Live TeAka clone not found; skip uniqueness." -ForegroundColor DarkGray
}

# --- 3. File scan / optional rewrite ---
Write-Host "`n[3] Text-file owner refs (skip GEMBot29 lines)" -ForegroundColor Yellow
$fileScript = Join-Path $PSScriptRoot "rebind_blairgem1234_files.py"
$scanRoots = @(
    "C:\Users\Blair\EV_Git\GPT_AI_Workspace",
    "C:\Users\Blair\EV_Git\Ev",
    "C:\Users\Blair\EV_Git\teaka_trading_app",
    "C:\Users\Blair\EV_Git\teaka_trading_app_CANONICAL",
    "C:\Users\Blair\EV_Git_tmp_teaka_github_main",
    "C:\Users\Blair\EV_Git\MT_GREENLAND",
    "C:\Users\Blair\EV_Git\Pc-5000-curser-",
    "C:\EV_Operator\Cursor",
    "C:\EV_Operator\Clock"
)
foreach ($root in $scanRoots) {
    if (-not (Test-Path -LiteralPath $root)) {
        Write-Host ("  MISSING  {0}" -f $root) -ForegroundColor DarkGray
        continue
    }
    Write-Host ("  SCAN {0}" -f $root) -ForegroundColor Cyan
    if (Test-Path -LiteralPath $fileScript) {
        $pyArgs = @("--root", $root)
        if ($ApplyFiles) { $pyArgs += "--apply" }
        python $fileScript @pyArgs
    } else {
        git -C $root grep -n -I -E "BlairGem/|github.com/BlairGem[^1]" -- "*.md" "*.py" "*.js" "*.json" "*.ps1" 2>$null |
            Where-Object { $_ -notmatch "GEMBot29" } |
            Select-Object -First 40
    }
}

Write-Host "`n[4] GEMBot29 left untouched on purpose" -ForegroundColor Magenta
Write-Host "    Prove the real destination repo before any rewrite."
Write-Host "`nDone. Clones were not deleted. History/logs were not rewritten."
