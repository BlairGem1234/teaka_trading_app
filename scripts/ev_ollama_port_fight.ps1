#Requires -Version 5.1
<#
.SYNOPSIS
  Read-only Ollama port ownership audit for Blair/GPT notification.
#>
[CmdletBinding()]
param([string]$GptOutboxPath)

$ErrorActionPreference = "Continue"
. (Join-Path $PSScriptRoot "Write-EvGptNotification.ps1")

function Get-ListenLines([int]$Port) {
    @(Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
        Select-Object LocalAddress, LocalPort, OwningProcess, State)
}

$Report = New-EvNotification -SourcePr 19 -SourceScript (Split-Path -Leaf $PSCommandPath)
$ports = foreach ($port in 11434, 11435, 8080, 8081, 5056, 5060, 5055, 5432) {
    [ordered]@{ port = $port; listeners = Get-ListenLines $port }
}

Add-EvFinding $Report ([ordered]@{
    type = "port_inventory"
    classification = "REPORTED"
    ports = $ports
})

$svc = Get-Service Ollama -ErrorAction SilentlyContinue
Add-EvFinding $Report ([ordered]@{
    type = "ollama_service"
    classification = "REPORTED"
    service = $(if ($svc) { $svc | Select-Object Status, StartType, Name, DisplayName } else { $null })
})

$tasks = @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
    $_.TaskName -match 'Ollama|11434|11435|EV_Blair|GEMBot'
})
Add-EvFinding $Report ([ordered]@{
    type = "scheduled_task_inventory"
    classification = "REPORTED"
    tasks = @($tasks | Select-Object TaskName, TaskPath, State)
})

Add-EvProposal $Report ([ordered]@{
    operation = "review_port_owner_conflict"
    target = "Windows Ollama 11434"
    proposed = "Choose a single owner only after Blair approval; this audit does not prefer service or task ownership."
    risk = "Changing scheduled tasks or services can break the established EV port layout."
    evidence = [ordered]@{ service_present = [bool]$svc; task_count = $tasks.Count }
})

Write-EvNotification $Report $GptOutboxPath
