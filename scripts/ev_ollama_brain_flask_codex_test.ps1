#Requires -Version 5.1
<#
.SYNOPSIS
  Read-only health audit for EV Ollama Brain Flask sidecar.
#>
[CmdletBinding()]
param([string]$GptOutboxPath)

$ErrorActionPreference = "Continue"
. (Join-Path $PSScriptRoot "Write-EvGptNotification.ps1")

function Test-HttpGet {
    param([string]$Name, [string]$Url, [int]$Seconds = 4)
    try {
        $result = curl.exe -sS -m $Seconds -w "`nHTTP %{http_code}" $Url 2>&1
        [ordered]@{ name = $Name; url = $Url; ok = $true; result = @($result) }
    } catch {
        [ordered]@{ name = $Name; url = $Url; ok = $false; error = $_.Exception.Message }
    }
}

$Report = New-EvNotification -SourcePr 19 -SourceScript (Split-Path -Leaf $PSCommandPath)
$checks = @(
    Test-HttpGet "command_8080" "http://127.0.0.1:8080/health" 5
    Test-HttpGet "flask_8081_health" "http://127.0.0.1:8081/health" 5
    Test-HttpGet "flask_8081_models" "http://127.0.0.1:8081/models" 5
    Test-HttpGet "ollama_11434" "http://127.0.0.1:11434/api/tags" 5
    Test-HttpGet "docker_11435" "http://127.0.0.1:11435/api/tags" 5
)

Add-EvFinding $Report ([ordered]@{
    type = "http_health_checks"
    classification = "REPORTED"
    checks = $checks
    command_port_reserved = 8080
    flask_expected_port = 8081
})

Write-EvNotification $Report $GptOutboxPath
