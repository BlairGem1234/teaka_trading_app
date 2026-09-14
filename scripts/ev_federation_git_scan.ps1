# === ev_federation_git_scan.ps1 ===
# PC5000 / Blair PC: inventory git clones under EV_Git (+ optional Starforge) without dumping venv noise.
#
#   pwsh -NoProfile -File scripts\ev_federation_git_scan.ps1
#   pwsh -NoProfile -File scripts\ev_federation_git_scan.ps1 -SaveTo scratch\ev_federation_registry.json

param(
    [string]$EvGitRoot = "",
    [string[]]$ExtraProbeRoots = @(
        "D:\Dropbox\Starforge",
        "D:\Starforge",
        "D:\EV_Files\EV_Node",
        "D:\EV_Files\Git",
        "E:\EV_Files",
        "C:\EV_Operator"
    ),
    [switch]$SkipCloudDriveProbe,
    [string]$TeakaRoot = "",
    [string]$SaveTo = ""
)

$ErrorActionPreference = "SilentlyContinue"

if (-not $EvGitRoot) {
    foreach ($c in @("C:\Users\blair\EV_Git", "C:\Users\Blair\EV_Git")) {
        if (Test-Path $c) { $EvGitRoot = $c; break }
    }
    if (-not $EvGitRoot) { $EvGitRoot = "C:\Users\blair\EV_Git" }
}
if (-not $TeakaRoot) {
    $TeakaRoot = Split-Path $PSScriptRoot -Parent
    if (Test-Path (Join-Path $EvGitRoot "teaka_trading_app\.git")) {
        $TeakaRoot = Join-Path $EvGitRoot "teaka_trading_app"
    }
}
$scratch = Join-Path $TeakaRoot "scratch"
if (-not (Test-Path $scratch)) { New-Item -ItemType Directory -Path $scratch | Out-Null }
if (-not $SaveTo) { $SaveTo = Join-Path $scratch "ev_federation_registry.json" }

function Get-RepoRole {
    param([string]$Name, [string]$Remote)
    $n = $Name.ToLowerInvariant()
    $r = ($Remote + "").ToLowerInvariant()
    if ($n -eq "ev" -and $r -match "/ev\.git") { return "operator_pc5000_primary" }
    if ($r -match "blairgem1234/ev\.git" -and $n -ne "ev") { return "operator_ev_worktree_clone" }
    if ($n -match "teaka" -and $n -match "canonical") { return "trading_teaka_upstream_mirror" }
    if ($n -match "teaka|_tmp_teaka") { return "trading_paper_phone_5050" }
    if ($n -match "gembot29|gembot") { return "legacy_gembot_flask_qwen_sidecar" }
    if ($n -match "gpt_ai_workspace") { return "personal_gpt_workspace_git" }
    if ($n -match "pc-5000-curser|pc5000") { return "pc5000_cursor_ops_git" }
    if ($n -match "mt_greenland|green-earth") { return "geo_minerals_project_git" }
    if ($n -match "starforge" -or $r -match "starforge") { return "vault_spells_starforge" }
    if ($r -match "evstack/ev-node") { return "ev_blockchain_ev_node" }
    if ($n -match "ev-node|evstack") { return "ev_blockchain_stack_node" }
    if ($n -match "evbot|operator") { return "evbot_operator_git" }
    if ($n -eq "clock" -or $r -match "ev_brain_clock") { return "ev_brain_clock_git" }
    if ($n -eq "cursor" -or $r -match "cursor_master") { return "cursor_master_ev_setup_git" }
    if ($n -match "git_satellite_brain") { return "brain_run_addon_git_satellite" }
    if ($n -eq "memories" -or $r -match "codex") { return "codex_memories_baseline_git" }
    return "other_ev_git"
}

function Get-CloudDriveProbe {
    $candidates = [System.Collections.Generic.List[string]]::new()
    foreach ($p in @(
        "$env:USERPROFILE\Google Drive",
        "$env:USERPROFILE\My Drive",
        "G:\My Drive",
        "G:\",
        "$env:USERPROFILE\OneDrive",
        "C:\Users\blair\OneDrive",
        "C:\Users\Blair\OneDrive",
        "D:\Dropbox",
        "C:\Users\blair\OneDrive\OneDrive\Imports\blairgem@outlook.com - Dropbox\Mirror_Audit"
    )) {
        if ($p -and (Test-Path -LiteralPath $p)) { [void]$candidates.Add((Resolve-Path -LiteralPath $p).Path) }
    }
    # DriveFS mount (common on Win11)
    $dfs = Join-Path $env:LOCALAPPDATA "Google\DriveFS\root"
    if (Test-Path $dfs) { [void]$candidates.Add((Resolve-Path $dfs).Path) }

    $evNamePatterns = @("EV_Brain", "EV Brain", "EV_CloudProject", "EV_Link", "ev_brain", "bridge")
    $hits = @()
    foreach ($root in ($candidates | Select-Object -Unique)) {
        $row = [ordered]@{ root = $root; ev_like_paths = @(); sample_files = @() }
        foreach ($pat in $evNamePatterns) {
            Get-ChildItem -LiteralPath $root -Directory -Filter $pat -Recurse -Depth 3 -ErrorAction SilentlyContinue |
                Select-Object -First 5 |
                ForEach-Object { [void]$row.ev_like_paths.Add($_.FullName) }
        }
        Get-ChildItem -LiteralPath $root -Include "*EV_GOOGLE_DRIVE*", "*ev_brain*", "*pc5000*" -Recurse -Depth 4 -File -ErrorAction SilentlyContinue |
            Select-Object -First 8 |
            ForEach-Object { [void]$row.sample_files.Add(@{ path = $_.FullName; bytes = $_.Length; mtime = $_.LastWriteTime.ToString("o") }) }
        if ($row.ev_like_paths.Count -gt 0 -or $row.sample_files.Count -gt 0) {
            $hits += $row
        }
    }
    return @{
        probed              = @($candidates | Select-Object -Unique)
        ev_hits             = $hits
        google_drive_folder_id_note = "15kPq7T_iarOY4FCkeGptje8c4fwu5LxC (from handoff — use Cursor Google Drive MCP to index cloud-side; this probe is local mount only)"
        cloud_agent_indexed = $false
    }
}

function Find-GitRoots {
    param([string]$Root, [int]$MaxDepth = 2)
    $found = @()
    if (-not (Test-Path -LiteralPath $Root)) { return $found }
    if (Test-Path (Join-Path $Root ".git")) { return @((Resolve-Path $Root).Path) }
    if ($MaxDepth -le 0) { return $found }
    Get-ChildItem -LiteralPath $Root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $found += Find-GitRoots -Root $_.FullName -MaxDepth ($MaxDepth - 1)
    }
    return $found
}

function Get-RepoCard {
    param([string]$Root)
    Push-Location $Root
    $remote = git remote get-url origin 2>$null
    $branch = git branch --show-current 2>$null
    $head = git log -1 --oneline 2>$null
    $sb = (git status -sb 2>$null | Select-Object -First 1)
    $untracked = @(git status -sb --untracked-files=no 2>$null | Select-String "^\?\?" ).Count
    $modified = @(git status -sb --untracked-files=no 2>$null | Select-String "^\s*[MADRCU]" ).Count
    Pop-Location
    $name = Split-Path $Root -Leaf
    $role = Get-RepoRole -Name $name -Remote $remote
    $warn = @()
    if ($role -eq "operator_ev_worktree_clone") {
        $warn += "Second Ev checkout — same remote as Ev; use one primary working copy for PC5000 bridge commits."
    }
    if ($role -eq "legacy_gembot_flask_qwen_sidecar") {
        $warn += "Old layout: pip/Lib often inside repo — prefer Ev + C:\EV_Operator for operator truth."
    }
    if ($role -eq "trading_teaka_upstream_mirror" -or $name -match "_tmp_") {
        $warn += "Extra TeAka clone — handoff scripts default to teaka_trading_app (BlairGem1234 fork)."
    }
    if (Test-Path (Join-Path $Root "Lib\site-packages\pip")) {
        $warn += "Contains Lib/site-packages (venv-in-repo); do not treat pip diff as EV source changes."
    }
    $pc5000Live = Join-Path $Root "bridge\live\pc5000"
    $liveCount = 0
    if (Test-Path $pc5000Live) {
        $liveCount = @(Get-ChildItem -LiteralPath $pc5000Live -File -ErrorAction SilentlyContinue).Count
    }
    return [ordered]@{
        path           = $Root
        name           = $name
        role           = $role
        remote         = $remote
        branch         = $branch
        head           = $head
        status_line    = $sb
        modified_count = $modified
        untracked_hint = $untracked
        pc5000_live_files = $liveCount
        warnings       = @($warn)
    }
}

function Add-GitChildren {
    param([string]$Root)
    if (-not (Test-Path -LiteralPath $Root)) { return }
    Get-ChildItem -LiteralPath $Root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        if (Test-Path (Join-Path $_.FullName ".git")) { [void]$roots.Add($_.FullName) }
    }
}

$roots = [System.Collections.Generic.List[string]]::new()
Add-GitChildren -Root $EvGitRoot
Add-GitChildren -Root "D:\EV_Files\Git"
foreach ($probe in $ExtraProbeRoots) {
    Find-GitRoots -Root $probe -MaxDepth 2 | ForEach-Object { [void]$roots.Add($_) }
}

$uniqueRoots = $roots | ForEach-Object {
    try { (Get-Item -LiteralPath $_).FullName.ToLowerInvariant() } catch { $_.ToLowerInvariant() }
} | Select-Object -Unique | ForEach-Object {
    # restore original casing from first matching root
    $roots | Where-Object { ((Get-Item -LiteralPath $_).FullName.ToLowerInvariant()) -eq $_ } | Select-Object -First 1
} | Sort-Object {
    $leaf = Split-Path $_ -Leaf
    switch -Regex ($leaf) {
        "^Ev$" { 0 }
        "^EV_Node$" { 1 }
        "Starforge" { 2 }
        "teaka_trading_app$" { 3 }
        "GEMBot" { 4 }
        default { 5 }
    }
}, { $_ }

$cards = foreach ($r in $uniqueRoots) { Get-RepoCard -Root $r }

$operatorPy = "C:\EV_Operator\DevToolsRuntime\python_env\Scripts\python.exe"
$brainNote = @{
    ev_operator_python = (Test-Path $operatorPy)
    ev_operator_cloak  = (Test-Path "C:\EV_Operator\DevToolsRuntime\ev_devtools_cloak.py")
    profile_split      = "C EV brain = masher/master index (~5M, RoboShady+Starforge). Git_Satellite_Brain = add-on to RUN C EV brain. Ev/EV_Operator = operator plane. EV_Brain* folders / ev_*_brain.json = artifacts — not C EV brain. Personal Codex/GPT = separate profile."
    port_roles         = @{
        "5000"  = "GEMBot Flask (legacy); often off if sidecar moved"
        "5050"  = "TeAka connect_python paper bridge"
        "5055"  = "EV minerals / auxiliary python (your scan)"
        "5056"  = "Cloak / GEMBot Qwen sidecar — restart ONE cloak after duplicate kill"
        "8080"  = "EV terminal / bridge python"
        "11434" = "Ollama local models"
        "5057"  = "Often Docker — not Codex"
    }
}

$out = [ordered]@{
    generated_at   = (Get-Date).ToString("o")
    machine        = $env:COMPUTERNAME
    ev_git_root    = $EvGitRoot
    teaka_handoff  = $TeakaRoot
    canonical_hint = @{
        operator_git   = Join-Path $EvGitRoot "Ev"
        ev_node_git    = "D:\EV_Files\EV_Node -> evstack/ev-node"
        starforge_git  = "D:\Dropbox\Starforge -> BlairGem/starforge"
        trading_git    = Join-Path $EvGitRoot "teaka_trading_app"
        gpt_workspace  = Join-Path $EvGitRoot "GPT_AI_Workspace"
        ev_brain_clock = Join-Path $EvGitRoot "Clock"
        cursor_master  = Join-Path $EvGitRoot "Cursor"
        git_satellite  = Join-Path $EvGitRoot "Git_Satellite_Brain"
        legacy_gembot  = Join-Path $EvGitRoot "GEMBot29"
        handoff_branch = "teaka_trading_app on cursor/local-handoff-notes-8248 until PR merge"
        runtime        = "C:\EV_Operator + C:\EV_AI\Codex"
    }
    repos          = @($cards)
    brain_operator = $brainNote
    cloud_drives   = if ($SkipCloudDriveProbe) { @{ skipped = $true } } else { Get-CloudDriveProbe }
}

$out | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $SaveTo -Encoding utf8

Write-Host "=== EV federation git scan (PC5000 / EV_Git) ===" -ForegroundColor Cyan
foreach ($c in $cards) {
    Write-Host "$($c.name) [$($c.role)]" -ForegroundColor Green
    Write-Host "  $($c.remote)" -ForegroundColor DarkGray
    Write-Host "  $($c.branch) | $($c.head)" -ForegroundColor Gray
    foreach ($w in $c.warnings) { Write-Host "  WARN: $w" -ForegroundColor Yellow }
}
if ($out.cloud_drives.probed) {
    Write-Host "`n[Cloud drive local mounts probed]" -ForegroundColor Cyan
    $out.cloud_drives.probed | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
    if ($out.cloud_drives.ev_hits.Count -eq 0) {
        Write-Host "  No EV_Brain/bridge hits in shallow scan — Drive may be online-only or different letter." -ForegroundColor Yellow
    }
}
Write-Host "`nSaved: $SaveTo" -ForegroundColor Green
Write-Host "Git map: scratch\ev_federation_registry.json | Google cloud index: Drive MCP (not auto from this script)" -ForegroundColor DarkGray
