#Requires -Version 5.1
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$ScriptPath = Join-Path $RepoRoot "scripts\rebind_pc_git_owner.ps1"
$Text = [System.IO.File]::ReadAllText($ScriptPath)

$Forbidden = @(
    "ApplyRemotes",
    "ApplyFiles",
    "remote\s+set-url",
    "remote\s+add",
    "--apply"
)

$Failures = @()
foreach ($Pattern in $Forbidden) {
    if ($Text -match $Pattern) {
        $Failures += $Pattern
    }
}

if ($Failures.Count -gt 0) {
    throw "rebind_pc_git_owner.ps1 still contains prohibited mutation path(s): $($Failures -join ', ')"
}

Write-Host "rebind_pc_git_owner.ps1 contains no prohibited mutation paths."
