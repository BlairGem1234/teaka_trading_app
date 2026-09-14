# === ev_federation_git_scan.ps1 ===
# PC5000 / Blair PC: inventory git clones under EV_Git (+ optional Starforge) without dumping venv noise.
#
#   pwsh -NoProfile -File scripts\ev_federation_git_scan.ps1
#   pwsh -NoProfile -File scripts\ev_federation_git_scan.ps1 -SaveTo scratch\ev_federation_registry.json

param(
    [string]$EvGitRoot = "C:\Users\blair\EV_Git",
    [string[]]$ExtraProbeRoots = @("D:\Starforge", "E:\EV_Files", "C:\EV_Operator"),
    [string]$TeakaRoot = "",
    [string]$SaveTo = ""
)

$ErrorActionPreference = "SilentlyContinue"

if (-not $TeakaRoot) {
    $TeakaRoot = Split-Path $PSScriptRoot -Parent
    if (Test-Path "C:\Users\blair\EV_Git\teaka_trading_app\.git") {
        $TeakaRoot = "C:\Users\blair\EV_Git\teaka_trading_app"
    }
}
$scratch = Join-Path $TeakaRoot "scratch"
if (-not (Test-Path $scratch)) { New-Item -ItemType Directory -Path $scratch | Out-Null }
if (-not $SaveTo) { $SaveTo = Join-Path $scratch "ev_federation_registry.json" }

function Get-RepoRole {
    param([string]$Name, [string]$Remote)
    $n = $Name.ToLowerInvariant()
    $r = ($Remote + "").ToLowerInvariant()
    if ($n -eq "ev" -or $r -match "/ev\.git") { return "operator_pc5000_brain_bridge" }
    if ($n -match "teaka") { return "trading_paper_phone_5050" }
    if ($n -match "gembot29|gembot") { return "legacy_gembot_flask_qwen_sidecar" }
    if ($n -match "starforge") { return "vault_spells_starforge" }
    if ($n -match "evstack|ev-node|evstack") { return "ev_blockchain_stack_node" }
    if ($n -match "evbot|operator") { return "evbot_operator_git" }
    if ($r -match "evstack|geo") { return "ev_stack_external" }
    return "other_ev_git"
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
    if ($role -eq "legacy_gembot_flask_qwen_sidecar") {
        $warn += "Old layout: pip/Lib often inside repo — prefer Ev + C:\EV_Operator for operator truth."
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

$roots = [System.Collections.Generic.List[string]]::new()
if (Test-Path $EvGitRoot) {
    Get-ChildItem -LiteralPath $EvGitRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        if (Test-Path (Join-Path $_.FullName ".git")) { [void]$roots.Add($_.FullName) }
    }
}
foreach ($probe in $ExtraProbeRoots) {
    Find-GitRoots -Root $probe -MaxDepth 2 | ForEach-Object { [void]$roots.Add($_) }
}

$uniqueRoots = $roots | Select-Object -Unique | Sort-Object {
    $leaf = Split-Path $_ -Leaf
    switch -Regex ($leaf) {
        "^Ev$" { 0 }
        "teaka" { 1 }
        "GEMBot" { 2 }
        default { 3 }
    }
}, { $_ }

$cards = foreach ($r in $uniqueRoots) { Get-RepoCard -Root $r }

$operatorPy = "C:\EV_Operator\DevToolsRuntime\python_env\Scripts\python.exe"
$brainNote = @{
    ev_operator_python = (Test-Path $operatorPy)
    ev_operator_cloak  = (Test-Path "C:\EV_Operator\DevToolsRuntime\ev_devtools_cloak.py")
    profile_split      = "System/operator brain (Ev, EV_Operator, PC5000 bridge) vs personal GPT/Codex profiles — not one shared AI identity."
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
        operator_git = "C:\Users\blair\EV_Git\Ev"
        trading_git  = "C:\Users\blair\EV_Git\teaka_trading_app"
        legacy_gembot = "C:\Users\blair\EV_Git\GEMBot29 (sidecar history; pip-in-repo)"
        runtime      = "C:\EV_Operator + C:\EV_AI\Codex"
    }
    repos          = @($cards)
    brain_operator = $brainNote
}

$out | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $SaveTo -Encoding utf8

Write-Host "=== EV federation git scan (PC5000 / EV_Git) ===" -ForegroundColor Cyan
foreach ($c in $cards) {
    Write-Host "$($c.name) [$($c.role)]" -ForegroundColor Green
    Write-Host "  $($c.remote)" -ForegroundColor DarkGray
    Write-Host "  $($c.branch) | $($c.head)" -ForegroundColor Gray
    foreach ($w in $c.warnings) { Write-Host "  WARN: $w" -ForegroundColor Yellow }
}
Write-Host "`nSaved: $SaveTo" -ForegroundColor Green
Write-Host "Cloud: scratch\ev_federation_registry.json (+ evlink JSON if you run -Action evlink)" -ForegroundColor DarkGray
