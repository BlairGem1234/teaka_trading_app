# === ev_git_repos_check.ps1 ===
# Git-only: what THIS repo knows about EV (cannot see C:\ or private repos unless cloned).
#   pwsh -NoProfile -File scripts\ev_git_repos_check.ps1

$ErrorActionPreference = "SilentlyContinue"
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if (Test-Path "C:\Users\blair\EV_Git\teaka_trading_app\.git") {
    $repoRoot = "C:\Users\blair\EV_Git\teaka_trading_app"
}
Set-Location $repoRoot

Write-Host "=== GIT / REPO EV REFERENCES ===" -ForegroundColor Cyan
Write-Host "Repo: $repoRoot`n" -ForegroundColor DarkGray

Write-Host "[Remotes]" -ForegroundColor Yellow
git remote -v

Write-Host "`n[Branch]" -ForegroundColor Yellow
git branch --show-current

Write-Host "`n[Tracked files mentioning EV paths (sample)]" -ForegroundColor Yellow
git grep -l "EV_Operator\|EV_AI\|ev_devtools_cloak\|Codex" -- "*.md" "*.ps1" "*.json" "*.yaml" "*.txt" 2>$null |
    Select-Object -First 25

Write-Host "`n[Private EV repo note]" -ForegroundColor Yellow
Write-Host @"
TeAka README says full EV control may live in a sibling repo (e.g. BlairGem/Ev) — not in this fork.
This script cannot read other GitHub repos until you:
  git clone https://github.com/BlairGem1234/<repo>.git C:\Users\blair\EV_Git\<repo>
Cloud agents only see repos checked out in their VM unless you paste output.

For WHICH Codex/Cloak to run on PC, use:
  pwsh -NoProfile -File scripts\ev_pick_canonical_stack.ps1 -SaveTo scratch\ev_canonical_choice.json
"@ -ForegroundColor DarkGray
