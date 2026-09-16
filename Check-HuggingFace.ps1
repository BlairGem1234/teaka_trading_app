# Check Hugging Face login, Codex vs Cursor tokens, cache/memory,
# and Blairgem / BlairGem1234 identity mismatch.
#
# DO NOT PASTE THIS FILE INTO THE POWERSHELL PROMPT.
# Pasting pieces causes "Missing closing }" errors.
#
# This file is NOT on E:\ until you download the PR branch or save it.
# Save it to C:\EV_Operator\Check-HuggingFace.ps1 then run:
#   powershell -NoProfile -ExecutionPolicy Bypass -File "C:\EV_Operator\Check-HuggingFace.ps1"
# Or run Get-CheckHuggingFace.ps1 to download it.
# Do not paste this file into the prompt.

[CmdletBinding()]
param(
    [switch]$OpenLogin
)

if (-not $PSCommandPath) {
    Write-Host ''
    Write-Host 'Do not paste this script into the PowerShell prompt.' -ForegroundColor Yellow
    Write-Host 'That is what caused the Missing closing } error.'
    Write-Host 'The file is not on E:\ yet. Save it, then run:'
    Write-Host '  powershell -NoProfile -ExecutionPolicy Bypass -File "C:\EV_Operator\Check-HuggingFace.ps1"'
    return
}

$ErrorActionPreference = 'Continue'

# GitHub on this Teaka repo is BlairGem1234.
# Cursor Hugging Face MCP on the cloud agent was logged in as Blairgem.
$ExpectedGitHub = 'BlairGem1234'
$ExpectedHfCursor = 'Blairgem'
$ExpectedHfAliases = @(
    'Blairgem',
    'BlairGem',
    'Blairgem1234',
    'BlairGem1234',
    'blairgem',
    'blairgem1234'
)

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
}

function Write-Ok {
    param([string]$Message)
    Write-Host "[OK]  $Message" -ForegroundColor Green
}

function Write-WarnLine {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Fail {
    param([string]$Message)
    Write-Host "[FAIL] $Message" -ForegroundColor Red
}

function Get-DirSizeBytes {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }
    $sum = (
        Get-ChildItem -LiteralPath $Path -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { -not $_.PSIsContainer } |
        Measure-Object -Property Length -Sum
    ).Sum
    if ($null -eq $sum) {
        return [int64]0
    }
    return [int64]$sum
}

function Format-Bytes {
    param($Bytes)
    if ($null -eq $Bytes) {
        return 'missing'
    }
    if ($Bytes -ge 1GB) {
        return ('{0:N2} GB' -f ($Bytes / 1GB))
    }
    if ($Bytes -ge 1MB) {
        return ('{0:N2} MB' -f ($Bytes / 1MB))
    }
    if ($Bytes -ge 1KB) {
        return ('{0:N2} KB' -f ($Bytes / 1KB))
    }
    return "$Bytes bytes"
}

function Test-TokenFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Host "Token file missing: $Path"
        return $false
    }
    $item = Get-Item -LiteralPath $Path
    Write-Ok ("Token file present: {0} ({1} bytes). Value not printed." -f $Path, $item.Length)
    return $true
}

function Get-HfProfileStatus {
    param([string]$Username)
    $url = "https://huggingface.co/$Username"
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 20 -MaximumRedirection 0 -ErrorAction Stop
        return @{ Username = $Username; Exists = $true; Status = [int]$response.StatusCode; Url = $url }
    }
    catch {
        $code = $null
        if ($_.Exception.Response) {
            $code = [int]$_.Exception.Response.StatusCode
        }
        $exists = ($code -eq 200 -or $code -eq 301 -or $code -eq 302)
        return @{ Username = $Username; Exists = $exists; Status = $code; Url = $url; Error = $_.Exception.Message }
    }
}

function Get-FirstExistingToken {
    param(
        [string[]]$EnvNames,
        [string[]]$Paths
    )
    foreach ($name in $EnvNames) {
        $value = [Environment]::GetEnvironmentVariable($name)
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return $value.Trim()
        }
        $value = [Environment]::GetEnvironmentVariable($name, 'User')
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return $value.Trim()
        }
        $value = [Environment]::GetEnvironmentVariable($name, 'Machine')
        if (-not [string]::IsNullOrWhiteSpace($value)) {
            return $value.Trim()
        }
    }
    foreach ($path in $Paths) {
        if (Test-Path -LiteralPath $path) {
            $raw = (Get-Content -LiteralPath $path -Raw -ErrorAction SilentlyContinue)
            if (-not [string]::IsNullOrWhiteSpace($raw)) {
                return $raw.Trim()
            }
        }
    }
    return $null
}

function Test-PathMentionsHf {
    param(
        [string]$Path,
        [string]$Label
    )
    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Host "$Label missing: $Path"
        return
    }
    Write-Ok "$Label found: $Path"
    $pattern = 'huggingface|hf_token|HF_TOKEN|Blairgem|BlairGem|codex'
    $hits = Select-String -Path $Path -Pattern $pattern -AllMatches -ErrorAction SilentlyContinue
    if (-not $hits) {
        Write-Host "No Hugging Face / Blairgem / Codex identity strings in $Label."
        return
    }
    $names = $hits | ForEach-Object { $_.Matches } | ForEach-Object { $_.Value } | Sort-Object -Unique
    Write-WarnLine ("{0} mentions: {1}" -f $Label, ($names -join ', '))
}

Write-Section 'Expected identities'
Write-Host "GitHub repo owner expected: $ExpectedGitHub"
Write-Host "Cursor Hugging Face MCP seen as: $ExpectedHfCursor"
Write-Host 'Codex may be using a different Hugging Face token/account on this PC.'
Write-Host 'https://huggingface.co/Blairgem'
Write-Host 'https://huggingface.co/Blairgem1234'
Write-Host 'https://github.com/BlairGem1234'

Write-Section 'Hugging Face CLI'
$hf = Get-Command hf -ErrorAction SilentlyContinue
$legacy = Get-Command huggingface-cli -ErrorAction SilentlyContinue

if ($hf) {
    Write-Ok "Found hf at $($hf.Source)"
    hf version 2>&1 | ForEach-Object { Write-Host $_ }
}
else {
    Write-WarnLine 'hf CLI not found on PATH.'
    Write-Host 'Install: winget install HuggingFace.HuggingFaceCLI'
    Write-Host 'Or: irm https://hf.co/cli/install.ps1 | iex'
}

if ($legacy) {
    Write-Host "Legacy huggingface-cli found at $($legacy.Source)"
}

Write-Section 'Hugging Face login'
$envTokenNames = @('HF_TOKEN', 'HUGGING_FACE_HUB_TOKEN', 'HUGGINGFACEHUB_API_TOKEN')
$envTokenPresent = $false
foreach ($name in $envTokenNames) {
    $processValue = [Environment]::GetEnvironmentVariable($name)
    $userValue = [Environment]::GetEnvironmentVariable($name, 'User')
    $machineValue = [Environment]::GetEnvironmentVariable($name, 'Machine')
    if ([string]::IsNullOrWhiteSpace($processValue) -and [string]::IsNullOrWhiteSpace($userValue) -and [string]::IsNullOrWhiteSpace($machineValue)) {
        Write-Host "$name is not set"
    }
    else {
        $envTokenPresent = $true
        $scopes = @()
        if (-not [string]::IsNullOrWhiteSpace($processValue)) { $scopes += 'process' }
        if (-not [string]::IsNullOrWhiteSpace($userValue)) { $scopes += 'user' }
        if (-not [string]::IsNullOrWhiteSpace($machineValue)) { $scopes += 'machine' }
        Write-Ok ("{0} is set in {1}. Value not printed." -f $name, ($scopes -join ', '))
    }
}

$hfHome = if ($env:HF_HOME) { $env:HF_HOME } else { Join-Path $env:USERPROFILE '.cache\huggingface' }
Write-Host "HF_HOME: $hfHome"

$tokenCandidates = @(
    (Join-Path $hfHome 'token'),
    (Join-Path $env:USERPROFILE '.huggingface\token'),
    (Join-Path $env:USERPROFILE '.cache\huggingface\token')
) | Select-Object -Unique

foreach ($tokenPath in $tokenCandidates) {
    [void](Test-TokenFile -Path $tokenPath)
}

if ($hf) {
    Write-Host ''
    Write-Host 'hf auth whoami:'
    hf auth whoami
    Write-Host ''
    Write-Host 'hf auth list:'
    hf auth list
}

$tokenForApi = Get-FirstExistingToken -EnvNames $envTokenNames -Paths $tokenCandidates
$whoami = $null
$whoamiUrl = 'https://huggingface.co/api/whoami-v2'
Write-Host ''
Write-Host "API check: $whoamiUrl"
try {
    $headers = @{ Accept = 'application/json' }
    if ($tokenForApi) {
        $headers['Authorization'] = "Bearer $tokenForApi"
    }
    $whoami = Invoke-RestMethod -Uri $whoamiUrl -Headers $headers -TimeoutSec 20
    if ($whoami.name) {
        Write-Ok "This PC Hugging Face login is $($whoami.name) ($($whoami.type))"
        if ($whoami.auth.accessToken.displayName) {
            Write-Host "Token name: $($whoami.auth.accessToken.displayName)"
        }
        if ($whoami.auth.accessToken.role) {
            Write-Host "Token role: $($whoami.auth.accessToken.role)"
        }
        if ($whoami.email) {
            Write-Host "Email: $($whoami.email)"
        }
        $orgs = @($whoami.orgs)
        if ($orgs.Count -gt 0) {
            $orgNames = @($orgs | ForEach-Object { $_.name })
            Write-Host ("Orgs: {0}" -f ($orgNames -join ', '))
        }
        else {
            Write-Host 'Orgs: none visible'
        }
    }
    else {
        Write-Host ($whoami | ConvertTo-Json -Depth 6)
    }
}
catch {
    Write-Fail "whoami API failed: $($_.Exception.Message)"
    Write-Host 'Open this login page: https://huggingface.co/mcp?login'
    Write-Host 'Create a token at: https://huggingface.co/settings/tokens'
}

Write-Section 'Blairgem vs BlairGem1234'
$profiles = @(
    (Get-HfProfileStatus -Username 'Blairgem'),
    (Get-HfProfileStatus -Username 'BlairGem'),
    (Get-HfProfileStatus -Username 'Blairgem1234'),
    (Get-HfProfileStatus -Username 'BlairGem1234')
)
foreach ($profile in $profiles) {
    if ($profile.Exists) {
        Write-Ok ("HF user {0} exists  {1}" -f $profile.Username, $profile.Url)
    }
    else {
        Write-WarnLine ("HF user {0} not found (HTTP {1})  {2}" -f $profile.Username, $profile.Status, $profile.Url)
    }
}

$loggedIn = $null
if ($whoami -and $whoami.name) {
    $loggedIn = [string]$whoami.name
}

if ($loggedIn) {
    if ($loggedIn -ceq $ExpectedGitHub) {
        Write-Ok "Hugging Face login matches GitHub owner $ExpectedGitHub."
    }
    elseif ($loggedIn -ieq $ExpectedGitHub) {
        Write-WarnLine "Hugging Face login $loggedIn matches GitHub $ExpectedGitHub except for letter case."
    }
    elseif ($loggedIn -ieq $ExpectedHfCursor) {
        Write-WarnLine "DISCREPANCY: Hugging Face is $loggedIn, GitHub repo is $ExpectedGitHub."
        Write-Host 'Cursor MCP is on Blairgem. Codex on this PC may still be on a different HF user/token.'
        Write-Host 'Models, Spaces, and private memory under BlairGem1234 will not show up on Blairgem, and the reverse is also true.'
    }
    else {
        Write-Fail "DISCREPANCY: Hugging Face login is $loggedIn, not Blairgem and not BlairGem1234."
    }
}
else {
    Write-WarnLine 'Could not read a Hugging Face username from the local token. Cannot compare Blairgem vs BlairGem1234 yet.'
}

Write-Section 'Codex vs Cursor Hugging Face setup'
$codexDir = Join-Path $env:USERPROFILE '.codex'
$cursorDir = Join-Path $env:USERPROFILE '.cursor'
$codexFiles = @(
    @{ Label = 'Codex auth'; Path = Join-Path $codexDir 'auth.json' },
    @{ Label = 'Codex config'; Path = Join-Path $codexDir 'config.toml' },
    @{ Label = 'Codex config.yaml'; Path = Join-Path $codexDir 'config.yaml' },
    @{ Label = 'Cursor mcp.json'; Path = Join-Path $cursorDir 'mcp.json' },
    @{ Label = 'Cursor mcp.json (User)'; Path = Join-Path $env:APPDATA 'Cursor\User\globalStorage\cursor.mcp\mcp.json' }
)

if (Test-Path -LiteralPath $codexDir) {
    Write-Ok "Codex folder found: $codexDir"
    Write-Host 'Hugging Face on this machine is likely the Codex login/token, not the Cursor cloud MCP login.'
}
else {
    Write-WarnLine "No Codex folder at $codexDir"
}

if (Test-Path -LiteralPath $cursorDir) {
    Write-Ok "Cursor folder found: $cursorDir"
}
else {
    Write-Host "No Cursor folder at $cursorDir"
}

foreach ($file in $codexFiles) {
    Test-PathMentionsHf -Path $file.Path -Label $file.Label
}

Write-Section 'Git identity on this repo'
$git = Get-Command git -ErrorAction SilentlyContinue
if ($git) {
    $remote = git remote get-url origin 2>$null
    $gitName = git config user.name 2>$null
    $gitEmail = git config user.email 2>$null
    if ($remote) {
        Write-Host "git remote: $remote"
        if ($remote -match 'BlairGem1234') {
            Write-Ok "Git remote uses $ExpectedGitHub."
        }
        elseif ($remote -match 'Blairgem') {
            Write-WarnLine "Git remote uses a Blairgem spelling, not $ExpectedGitHub."
        }
        else {
            Write-WarnLine 'Git remote does not mention BlairGem1234 or Blairgem.'
        }
    }
    if ($gitName) { Write-Host "git user.name: $gitName" }
    if ($gitEmail) { Write-Host "git user.email: $gitEmail" }
}
else {
    Write-Host 'git not found on PATH.'
}

Write-Section 'Hugging Face MCP'
$mcpLogin = 'https://huggingface.co/mcp?login'
Write-Host "MCP login URL: $mcpLogin"
try {
    $mcp = Invoke-WebRequest -Uri 'https://huggingface.co/mcp' -UseBasicParsing -TimeoutSec 20
    Write-Ok "MCP endpoint reachable. HTTP $($mcp.StatusCode)"
}
catch {
    Write-Fail "MCP endpoint check failed: $($_.Exception.Message)"
}
if ($OpenLogin) {
    Start-Process $mcpLogin
    Write-Host 'Opened Hugging Face MCP login in your browser.'
}

Write-Section 'Hugging Face memory / cache'
$hubCache = if ($env:HUGGINGFACE_HUB_CACHE) { $env:HUGGINGFACE_HUB_CACHE } else { Join-Path $hfHome 'hub' }
$xetCache = Join-Path $hfHome 'xet'
$transformersCache = if ($env:TRANSFORMERS_CACHE) { $env:TRANSFORMERS_CACHE } else { Join-Path $hfHome 'transformers' }
$datasetsCache = if ($env:HF_DATASETS_CACHE) { $env:HF_DATASETS_CACHE } else { Join-Path $hfHome 'datasets' }
$modulesCache = Join-Path $hfHome 'modules'

$cacheDirs = @(
    @{ Name = 'HF home'; Path = $hfHome },
    @{ Name = 'Hub model/dataset memory'; Path = $hubCache },
    @{ Name = 'Xet cache'; Path = $xetCache },
    @{ Name = 'Transformers cache'; Path = $transformersCache },
    @{ Name = 'Datasets cache'; Path = $datasetsCache },
    @{ Name = 'Modules cache'; Path = $modulesCache }
)

foreach ($dir in $cacheDirs) {
    if (Test-Path -LiteralPath $dir.Path) {
        $size = Format-Bytes (Get-DirSizeBytes -Path $dir.Path)
        Write-Ok ("{0}: {1} ({2})" -f $dir.Name, $dir.Path, $size)
    }
    else {
        Write-Host "$($dir.Name) missing: $($dir.Path)"
    }
}

if ($hf) {
    Write-Host ''
    Write-Host 'hf cache list:'
    hf cache list --format human
}

Write-Section 'Summary'
Write-Host 'CLI present: ' -NoNewline
if ($hf) { Write-Ok 'yes' } else { Write-Fail 'no' }
Write-Host 'Env token present: ' -NoNewline
if ($envTokenPresent) { Write-Ok 'yes' } else { Write-WarnLine 'no' }
Write-Host 'Logged in Hugging Face user: ' -NoNewline
if ($loggedIn) { Write-Host $loggedIn } else { Write-WarnLine 'unknown' }
Write-Host 'GitHub owner expected: ' -NoNewline
Write-Host $ExpectedGitHub
Write-Host 'Local cache/memory folder: ' -NoNewline
if (Test-Path -LiteralPath $hfHome) { Write-Ok $hfHome } else { Write-WarnLine "not created yet ($hfHome)" }
Write-Host ''
Write-Host 'If Codex and Cursor disagree, log Hugging Face in on the same user you want for Teaka:'
Write-Host "  expected GitHub: $ExpectedGitHub"
Write-Host "  Cursor MCP currently: $ExpectedHfCursor"
Write-Host '  hf auth login'
Write-Host "  $mcpLogin"
Write-Host 'Then rerun this script and confirm whoami matches the account that owns the models/memory you need.'
