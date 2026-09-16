# Downloads Check-HuggingFace.ps1 onto this PC, then runs it.
# Paste ONLY this small file, or run it with -File. Do not paste the big check script.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\Get-CheckHuggingFace.ps1

$ErrorActionPreference = 'Stop'
$destDir = 'C:\EV_Operator'
$dest = Join-Path $destDir 'Check-HuggingFace.ps1'
$branch = 'cursor/huggingface-powershell-check-a010'
$repo = 'BlairGem1234/teaka_trading_app'
$apiPath = "repos/$repo/contents/Check-HuggingFace.ps1?ref=$branch"
$browserUrl = "https://github.com/$repo/blob/$branch/Check-HuggingFace.ps1"

New-Item -ItemType Directory -Force -Path $destDir | Out-Null

$downloaded = $false
$gh = Get-Command gh -ErrorAction SilentlyContinue
if ($gh) {
    Write-Host "Downloading with gh to $dest"
    & gh api $apiPath -H 'Accept: application/vnd.github.raw' --output $dest
    if ((Test-Path -LiteralPath $dest) -and ((Get-Item -LiteralPath $dest).Length -gt 0)) {
        $downloaded = $true
    }
}

if (-not $downloaded) {
    Write-Host 'gh download failed or gh is not installed.'
    Write-Host "Open this page, click Raw, then Save As:"
    Write-Host "  $browserUrl"
    Write-Host "Save to:"
    Write-Host "  $dest"
    Write-Host 'Then run:'
    Write-Host "  powershell -NoProfile -ExecutionPolicy Bypass -File `"$dest`""
    Start-Process $browserUrl
    return
}

Write-Host "Saved $dest"
powershell -NoProfile -ExecutionPolicy Bypass -File $dest
