# Creates C: folders, makes sure Check-HuggingFace.ps1 is on disk, then runs it.
# Do not paste the big check script. Run this file:
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\Get-CheckHuggingFace.ps1

$ErrorActionPreference = 'Continue'

$operatorDir = 'C:\EV_Operator'
$teakaDir = 'C:\EV_Files\teaka_trading_app'
$evFilesDir = 'C:\EV_Files'
$dest = Join-Path $operatorDir 'Check-HuggingFace.ps1'
$teakaDest = Join-Path $teakaDir 'Check-HuggingFace.ps1'
$branch = 'cursor/huggingface-powershell-check-a010'
$repo = 'BlairGem1234/teaka_trading_app'
$apiPath = "repos/$repo/contents/Check-HuggingFace.ps1?ref=$branch"
$browserUrl = "https://github.com/$repo/blob/$branch/Check-HuggingFace.ps1"

$folders = @(
    $operatorDir,
    $evFilesDir,
    $teakaDir,
    (Join-Path $evFilesDir 'Bridge'),
    (Join-Path $evFilesDir 'Logs'),
    (Join-Path $evFilesDir 'Tools'),
    (Join-Path $teakaDir 'daily_reports'),
    (Join-Path $teakaDir 'sql_teaka_dashboard')
)

Write-Host '=== Create C: folders ===' -ForegroundColor Cyan
foreach ($folder in $folders) {
    New-Item -ItemType Directory -Force -Path $folder | Out-Null
    if (Test-Path -LiteralPath $folder) {
        Write-Host "[OK]  $folder"
    }
    else {
        Write-Host "[FAIL] could not create $folder" -ForegroundColor Red
    }
}

function Copy-IfPresent {
    param(
        [string]$From,
        [string]$To
    )
    if (-not (Test-Path -LiteralPath $From)) {
        return $false
    }
    $toDir = Split-Path -Parent $To
    if ($toDir) {
        New-Item -ItemType Directory -Force -Path $toDir | Out-Null
    }
    Copy-Item -LiteralPath $From -Destination $To -Force
    return (Test-Path -LiteralPath $To)
}

function Test-UsableScript {
    param([string]$Path)
    return ((Test-Path -LiteralPath $Path) -and ((Get-Item -LiteralPath $Path).Length -gt 200))
}

Write-Host ''
Write-Host '=== Place Check-HuggingFace.ps1 ===' -ForegroundColor Cyan

$found = $null
$search = @(
    (Join-Path $PSScriptRoot 'Check-HuggingFace.ps1'),
    $dest,
    $teakaDest,
    (Join-Path $operatorDir 'teaka_trading_app\Check-HuggingFace.ps1')
) | Where-Object { $_ } | Select-Object -Unique

foreach ($path in $search) {
    if (Test-UsableScript $path) {
        $found = $path
        Write-Host "[OK]  found $path"
        break
    }
}

if (-not $found) {
    $gh = Get-Command gh -ErrorAction SilentlyContinue
    if ($gh) {
        Write-Host "Downloading with gh to $dest"
        New-Item -ItemType Directory -Force -Path $operatorDir | Out-Null
        & gh api $apiPath -H 'Accept: application/vnd.github.raw' --output $dest
        if (Test-UsableScript $dest) {
            $found = $dest
            Write-Host "[OK]  downloaded $dest"
        }
        else {
            Write-Host '[WARN] gh download did not create a usable script' -ForegroundColor Yellow
        }
    }
    else {
        Write-Host '[WARN] gh is not installed' -ForegroundColor Yellow
    }
}

if (-not $found) {
    $git = Get-Command git -ErrorAction SilentlyContinue
    if ($git) {
        $cloneDir = Join-Path $operatorDir 'teaka_trading_app'
        if (-not (Test-Path -LiteralPath (Join-Path $cloneDir '.git'))) {
            Write-Host "Cloning $repo into $cloneDir"
            git clone --branch $branch "https://github.com/$repo.git" $cloneDir
        }
        $clonedScript = Join-Path $cloneDir 'Check-HuggingFace.ps1'
        if (Test-UsableScript $clonedScript) {
            $found = $clonedScript
            Write-Host "[OK]  cloned $clonedScript"
        }
    }
}

if ($found) {
    [void](Copy-IfPresent -From $found -To $dest)
    [void](Copy-IfPresent -From $found -To $teakaDest)
}

$helpers = @(
    'Get-CheckHuggingFace.ps1',
    'Check-HuggingFace.cmd',
    'ev_virtual_brain.json'
)
if ($PSScriptRoot) {
    foreach ($name in $helpers) {
        $from = Join-Path $PSScriptRoot $name
        if (Test-Path -LiteralPath $from) {
            [void](Copy-IfPresent -From $from -To (Join-Path $operatorDir $name))
            if ($name -eq 'ev_virtual_brain.json') {
                [void](Copy-IfPresent -From $from -To (Join-Path $evFilesDir $name))
                [void](Copy-IfPresent -From $from -To (Join-Path $teakaDir $name))
            }
            else {
                [void](Copy-IfPresent -From $from -To (Join-Path $teakaDir $name))
            }
        }
    }
}

Write-Host ''
Write-Host '=== Verify files ===' -ForegroundColor Cyan
$required = @(
    $dest,
    $teakaDest,
    (Join-Path $evFilesDir 'ev_virtual_brain.json')
)
$missing = @()
foreach ($path in $required) {
    if (Test-Path -LiteralPath $path) {
        $len = (Get-Item -LiteralPath $path).Length
        Write-Host "[OK]  $path ($len bytes)"
    }
    else {
        Write-Host "[MISSING] $path" -ForegroundColor Yellow
        $missing += $path
    }
}

if (-not (Test-UsableScript $dest)) {
    Write-Host ''
    Write-Host 'Check-HuggingFace.ps1 is still not on this PC.' -ForegroundColor Red
    Write-Host 'Open this page, click Raw, then Save As:'
    Write-Host "  $browserUrl"
    Write-Host 'Save to both:'
    Write-Host "  $dest"
    Write-Host "  $teakaDest"
    Write-Host 'Then run:'
    Write-Host "  powershell -NoProfile -ExecutionPolicy Bypass -File `"$dest`""
    Start-Process $browserUrl
    return
}

Write-Host ''
Write-Host "Running $dest"
powershell -NoProfile -ExecutionPolicy Bypass -File $dest
