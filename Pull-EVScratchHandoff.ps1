# Wrapper — double-click or:
#   pwsh -NoProfile -File Pull-EVScratchHandoff.ps1
$here = $PSScriptRoot
& pwsh -NoProfile -File (Join-Path $here "scripts\pull_ev_scratch_handoff.ps1") @args
