#Requires -Version 5.1
<#
.SYNOPSIS
  Read-only Windows operator tool audit for Blair/GPT notification.
#>
[CmdletBinding()]
param([string]$GptOutboxPath)

$ErrorActionPreference = "Continue"
. (Join-Path $PSScriptRoot "Write-EvGptNotification.ps1")

$Report = New-EvNotification -SourcePr 19 -SourceScript (Split-Path -Leaf $PSCommandPath)

$curl = Get-Command curl.exe -ErrorAction SilentlyContinue
$uv = Get-Command uv.exe -ErrorAction SilentlyContinue

Add-EvFinding $Report ([ordered]@{
    type = "operator_tool_inventory"
    classification = "REPORTED"
    powershell_version = $PSVersionTable.PSVersion.ToString()
    curl_exe = $(if ($curl) { $curl.Source } else { $null })
    uv_exe = $(if ($uv) { $uv.Source } else { $null })
    curl_alias_present = [bool](Test-Path Alias:curl)
})

if (-not $curl) {
    Add-EvProposal $Report ([ordered]@{
        operation = "install_tool"
        target = "curl.exe"
        proposed = "Install or repair curl.exe only after Blair approval; Windows normally provides it in System32."
        risk = "Package installation can change system state and PATH."
        evidence = [ordered]@{ current = "not found" }
    })
}

if (-not $uv) {
    Add-EvProposal $Report ([ordered]@{
        operation = "install_tool"
        target = "uv.exe"
        proposed = "Install uv only after Blair approval using a separately reviewed installer command."
        risk = "Installer execution can alter user profile tools and PATH."
        evidence = [ordered]@{ current = "not found" }
    })
}

Write-EvNotification $Report $GptOutboxPath
