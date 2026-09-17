#Requires -Version 5.1
<#
.SYNOPSIS
  Windows bootstrap for C:\EV_Operator — curl.exe + Astral uv.

.DESCRIPTION
  PowerShell's `curl` is an alias for Invoke-WebRequest. That is why:
    curl ... --data '{ ... }'
  dies with "The Data section is missing its statement block"
  and why:
    curl ... | sh
  dies with "sh is not recognized".

  Always call curl.exe. Install uv with the PowerShell installer, never install.sh.

  Save as C:\EV_Operator\ev_operator_win_bootstrap.ps1 then:

    Set-ExecutionPolicy -Scope Process Bypass -Force
    powershell -NoProfile -ExecutionPolicy Bypass -File C:\EV_Operator\ev_operator_win_bootstrap.ps1
#>
[CmdletBinding()]
param(
    [switch]$SkipUv
)

$ErrorActionPreference = "Stop"

function Write-Step([string]$Msg) {
    Write-Host ""
    Write-Host "=== $Msg ===" -ForegroundColor Cyan
}

function Get-CurlExe {
    $candidates = @(
        "$env:SystemRoot\System32\curl.exe",
        "$env:SystemRoot\Sysnative\curl.exe",
        (Get-Command curl.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source)
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

    if ($candidates) { return $candidates[0] }

    $wingetIds = @("cURL.cURL", "curl.curl")
    $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
    if ($winget) {
        foreach ($id in $wingetIds) {
            Write-Host "Trying winget install $id ..."
            & winget.exe install --id $id -e --accept-source-agreements --accept-package-agreements
            $again = Get-Command curl.exe -ErrorAction SilentlyContinue
            if ($again) { return $again.Source }
        }
    }

    throw "curl.exe not found. Windows 10 1803+ ships it at C:\Windows\System32\curl.exe. Do not install via choco unless Chocolatey is already set up."
}

Write-Step "Unalias PowerShell curl"
if (Test-Path Alias:curl) {
    Remove-Item Alias:curl -Force
    Write-Host "Removed session alias curl -> Invoke-WebRequest"
} else {
    Write-Host "No curl alias in this session"
}

Write-Step "Locate curl.exe (do not use PowerShell curl)"
$script:curl = Get-CurlExe
Write-Host "Using $script:curl"
& $script:curl --version | Select-Object -First 1

Write-Step "Safe JSON POST helper (avoids { parser errors)"
function Invoke-CurlJson {
    param(
        [Parameter(Mandatory = $true)][string]$Uri,
        [ValidateSet("GET", "POST", "PUT", "PATCH", "DELETE")][string]$Method = "POST",
        [object]$Body = $null
    )
    $curlArgs = @("-sS", "-X", $Method, $Uri, "-H", "Content-Type: application/json")
    if ($null -ne $Body) {
        if ($Body -is [string]) { $json = $Body }
        else { $json = $Body | ConvertTo-Json -Compress -Depth 8 }
        # --data-binary + variable: PowerShell never parses the JSON braces as a script block
        $curlArgs += @("--data-binary", $json)
    }
    & $script:curl @curlArgs
}

Write-Host @"
Use it like this (braces never go raw on the command line):

  curl.exe -sS -m 5 http://127.0.0.1:8080/
  `$body = '{"command":"status_check"}'
  Invoke-CurlJson -Uri 'http://127.0.0.1:8080/command' -Body `$body

GET / is public. POST belongs on /command (POST / returns 405).
Literal JSON in a PowerShell variable (never raw braces on the line):

  `$body = '{"command":"status_check"}'
  & curl.exe -sS -m 5 -X POST 'http://127.0.0.1:8080/command' -H 'Content-Type: application/json' --data-binary `$body

Never paste:  curl --data '{ ... }'
Never paste:  curl ... | sh
"@

if ($SkipUv) {
    Write-Host "Skipping uv (-SkipUv)."
    return
}

Write-Step "Install Astral uv (Windows PowerShell installer, not install.sh)"
$uvCmd = Get-Command uv -ErrorAction SilentlyContinue
if (-not $uvCmd) {
    $uvExe = @(
        "$env:USERPROFILE\.local\bin\uv.exe",
        "$env:USERPROFILE\.cargo\bin\uv.exe"
    ) | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if ($uvExe) { $uvCmd = Get-Item $uvExe }
}

if ($uvCmd) {
    Write-Host "uv already present: $($uvCmd.Source)"
} else {
    $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
    $installed = $false
    if ($winget) {
        Write-Host "Trying winget id astral-sh.uv ..."
        try {
            & winget.exe install --id astral-sh.uv -e --accept-source-agreements --accept-package-agreements
            if ($LASTEXITCODE -eq 0) { $installed = $true }
        } catch {
            Write-Host "winget uv failed: $($_.Exception.Message)"
        }
    }
    if (-not $installed) {
        Write-Host "Downloading https://astral.sh/uv/install.ps1 ..."
        irm https://astral.sh/uv/install.ps1 | iex
    }
}

$env:Path = "$env:USERPROFILE\.local\bin;$env:USERPROFILE\.cargo\bin;$env:Path"
$uvPath = @(
    (Get-Command uv.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source),
    "$env:USERPROFILE\.local\bin\uv.exe",
    "$env:USERPROFILE\.cargo\bin\uv.exe"
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
if ($uvPath) {
    Write-Host "uv OK: $uvPath"
    & $uvPath --version
} else {
    Write-Host "uv installed but this window may need a restart. Open a new PowerShell and run: uv --version" -ForegroundColor Yellow
}

Write-Step "Done"
Write-Host "From now on in this window: curl.exe   and   uv"
Write-Host "JSON posts: Invoke-CurlJson  or  --data-binary `$json  (never raw '{')"
