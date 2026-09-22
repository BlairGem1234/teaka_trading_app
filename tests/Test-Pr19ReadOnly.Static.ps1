#Requires -Version 5.1
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$ProductionScripts = @(
    "scripts\ev_amd_ollama_split.ps1",
    "scripts\ev_operator_win_bootstrap.ps1",
    "scripts\ev_ollama_port_fight.ps1",
    "scripts\ev_ollama_brain_flask_codex_test.ps1"
)
$Forbidden = @(
    "Stop-Process",
    "Start-Process",
    "winget(?:\.exe)?\s+install",
    "\birm\b.*\|\s*iex",
    "Invoke-RestMethod.*\|\s*Invoke-Expression",
    "Invoke-Expression",
    "\biex\b",
    "Disable-ScheduledTask",
    "ollama\s+pull",
    "\$env:Path\s*=",
    "\$env:OLLAMA_"
)

$Failures = @()
foreach ($Relative in $ProductionScripts) {
    $Path = Join-Path $RepoRoot $Relative
    $Text = [System.IO.File]::ReadAllText($Path)
    foreach ($Pattern in $Forbidden) {
        if ($Text -match $Pattern) {
            $Failures += "$Relative :: $Pattern"
        }
    }
}

if ($Failures.Count -gt 0) {
    throw "PR19 script(s) still contain prohibited mutation path(s): $($Failures -join '; ')"
}

Write-Host "PR19 scripts contain no prohibited mutation paths."
