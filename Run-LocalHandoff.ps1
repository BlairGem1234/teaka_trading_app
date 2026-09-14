# Double-click or run from anywhere — forwards to scripts\run_local_handoff.ps1
$root = $PSScriptRoot
$launcher = Join-Path $root "scripts\run_local_handoff.ps1"
if (-not (Test-Path $launcher)) {
    Write-Error "Not found: $launcher"
    exit 1
}
if (Get-Command pwsh -ErrorAction SilentlyContinue) {
    & pwsh -NoProfile -File $launcher @args
} else {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $launcher @args
}
