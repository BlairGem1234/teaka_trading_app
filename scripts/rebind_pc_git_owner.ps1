#Requires -Version 5.1
<#
.SYNOPSIS
  Read-only by default. Rebind live git remotes on BLAIRSPC to BlairGem1234.

.DESCRIPTION
  Covers every known EV/TeAka clone the cloud agent cannot see.

  Verified topology:
    C:\Users\Blair\EV_Git\GEMBot29
      origin        = https://github.com/BlairGem1234/Ev.git
      legacy-origin = https://github.com/blairgem/GEMBot29.git
    D:\Dropbox\Starforge
      origin        = https://github.com/BlairGem1234/Ev.git
      legacy-origin = https://github.com/BlairGem/starforge.git

  GEMBot29 and Starforge are subtree/legacy working copies of Ev.
  Do NOT create BlairGem1234/GEMBot29 or BlairGem1234/starforge.
  Do NOT delete clones. Do NOT rewrite git history, logs, or transcripts.
  Do NOT delete or retarget legacy-origin remotes.

  Dry-run (default):
    pwsh -NoProfile -File scripts\rebind_pc_git_owner.ps1

  Apply live origin URL changes only (never touches legacy-origin):
    pwsh -NoProfile -File scripts\rebind_pc_git_owner.ps1 -ApplyRemotes

  Also rewrite active text-file git destinations (skips legacy-origin lines):
    pwsh -NoProfile -File scripts\rebind_pc_git_owner.ps1 -ApplyRemotes -ApplyFiles
#>
[CmdletBinding()]
param(
    [switch]$ApplyRemotes,
    [switch]$ApplyFiles
)

$ErrorActionPreference = "Continue"

$LiveTeaka = "C:\Users\Blair\EV_Git\teaka_trading_app"
$EvUrl = "https://github.com/BlairGem1234/Ev.git"
$Known = @(
    @{ Path = "C:\Users\Blair\EV_Git\Ev";                         Expected = $EvUrl; LegacyOrigin = $null },
    @{ Path = "C:\Users\Blair\EV_Git\GPT_AI_Workspace";           Expected = "https://github.com/BlairGem1234/GPT_AI_Workspace.git"; LegacyOrigin = $null },
    @{ Path = "C:\Users\Blair\EV_Git\teaka_trading_app";          Expected = "https://github.com/BlairGem1234/teaka_trading_app.git"; LegacyOrigin = $null },
    @{ Path = "C:\Users\Blair\EV_Git\MT_GREENLAND";               Expected = "https://github.com/BlairGem1234/MT_GREENLAND.git"; LegacyOrigin = $null },
    @{ Path = "C:\Users\Blair\EV_Git\Pc-5000-curser-";            Expected = "https://github.com/BlairGem1234/Pc-5000-curser-.git"; LegacyOrigin = $null },
    @{ Path = "C:\EV_Operator\Cursor";                            Expected = "https://github.com/BlairGem1234/Cursor_Master.git"; LegacyOrigin = $null },
    @{ Path = "C:\EV_Operator\Clock";                             Expected = "https://github.com/BlairGem1234/EV_Brain_Clock.git"; LegacyOrigin = $null },
    @{ Path = "C:\Users\Blair\EV_Git\teaka_trading_app_CANONICAL"; Expected = "https://github.com/BlairGem1234/teaka_trading_app.git"; LegacyOrigin = $null },
    @{ Path = "C:\Users\Blair\EV_Git_tmp_teaka_github_main";       Expected = "https://github.com/BlairGem1234/teaka_trading_app.git"; LegacyOrigin = $null },
    @{ Path = "C:\Users\Blair\EV_Git\GEMBot29";                   Expected = $EvUrl; LegacyOrigin = "https://github.com/blairgem/GEMBot29.git" },
    @{ Path = "D:\Dropbox\Starforge";                             Expected = $EvUrl; LegacyOrigin = "https://github.com/BlairGem/starforge.git" }
)

function Get-RemoteUrl([string]$Repo, [string]$Name) {
    git -C $Repo remote get-url $Name 2>$null
}

function Normalize-GitHubUrl([string]$Url) {
    if (-not $Url) { return "" }
    return ($Url -replace '\.git$', '' -replace 'https://github.com/', '' -replace 'git@github.com:', '').Trim()
}

function Test-UrlsEqual([string]$A, [string]$B) {
    return (Normalize-GitHubUrl $A).ToLowerInvariant() -eq (Normalize-GitHubUrl $B).ToLowerInvariant()
}

Write-Host "=== PC GIT OWNER REBIND ===" -ForegroundColor Cyan
Write-Host ("Mode: remotes={0} files={1}" -f $(if ($ApplyRemotes) {"APPLY"} else {"DRY-RUN"}), $(if ($ApplyFiles) {"APPLY"} else {"DRY-RUN"}))
Write-Host "GEMBot29/Starforge active origin = BlairGem1234/Ev; legacy-origin preserved."
Write-Host ""

# --- 1. Remotes ---
Write-Host "[1] Remotes" -ForegroundColor Yellow
foreach ($item in $Known) {
    $p = $item.Path
    if (-not (Test-Path -LiteralPath (Join-Path $p ".git"))) {
        Write-Host ("  MISSING  {0}" -f $p) -ForegroundColor DarkGray
        continue
    }
    $origin = Get-RemoteUrl $p "origin"
    $legacy = Get-RemoteUrl $p "legacy-origin"
    $originOk = Test-UrlsEqual $origin $item.Expected
    Write-Host ("  {0}  {1}" -f $(if ($originOk) {"OK    "} else {"REBIND"}), $p)
    Write-Host ("           origin={0}" -f $origin)
    if ($item.LegacyOrigin) {
        $legacyOk = Test-UrlsEqual $legacy $item.LegacyOrigin
        Write-Host ("           legacy-origin={0} ({1})" -f $(if ($legacy) { $legacy } else { "<missing>" }), $(if ($legacyOk) {"preserve"} else {"expected $($item.LegacyOrigin)"}))
        if ($ApplyRemotes -and -not $legacy) {
            git -C $p remote add legacy-origin $item.LegacyOrigin
            Write-Host "           ADDED missing legacy-origin (historical remote only)" -ForegroundColor Yellow
        }
    }
    if (-not $originOk) {
        Write-Host ("           proposed origin={0}" -f $item.Expected) -ForegroundColor Green
        if ($ApplyRemotes) {
            git -C $p remote set-url origin $item.Expected
            Write-Host ("           SET origin -> {0}" -f (Get-RemoteUrl $p "origin")) -ForegroundColor Green
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
Write-Host "`n[3] Text-file owner refs (legacy-origin / history-only lines kept)" -ForegroundColor Yellow
$fileScript = Join-Path $PSScriptRoot "rebind_blairgem1234_files.py"
$scanRoots = @(
    "C:\Users\Blair\EV_Git\GPT_AI_Workspace",
    "C:\Users\Blair\EV_Git\Ev",
    "C:\Users\Blair\EV_Git\teaka_trading_app",
    "C:\Users\Blair\EV_Git\teaka_trading_app_CANONICAL",
    "C:\Users\Blair\EV_Git_tmp_teaka_github_main",
    "C:\Users\Blair\EV_Git\MT_GREENLAND",
    "C:\Users\Blair\EV_Git\Pc-5000-curser-",
    "C:\Users\Blair\EV_Git\GEMBot29",
    "D:\Dropbox\Starforge",
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
        git -C $root grep -n -I -E "BlairGem/|blairgem/GEMBot29|github.com/BlairGem[^1]" -- "*.md" "*.py" "*.js" "*.json" "*.ps1" 2>$null |
            Select-Object -First 40
    }
}

Write-Host "`n[4] Forbidden destinations (do not create)" -ForegroundColor Magenta
Write-Host "    BlairGem1234/GEMBot29"
Write-Host "    BlairGem1234/starforge"
Write-Host "    Active git for those working copies is BlairGem1234/Ev."
Write-Host "`nDone. Clones were not deleted. History/logs/legacy-origin were not rewritten."
