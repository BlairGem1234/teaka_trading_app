#Requires -Version 5.1
<#
.SYNOPSIS
  Read-only AMD/Ollama split audit for Blair/GPT notification.
#>
[CmdletBinding()]
param([string]$GptOutboxPath)

$ErrorActionPreference = "Continue"
. (Join-Path $PSScriptRoot "Write-EvGptNotification.ps1")

$Report = New-EvNotification -SourcePr 19 -SourceScript (Split-Path -Leaf $PSCommandPath)

Add-EvFinding $Report ([ordered]@{
    type = "machine_profile"
    classification = "REPORTED"
    video = @(Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue | Select-Object Name, DriverVersion, AdapterRAM)
    memory = @(Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue | Select-Object TotalVisibleMemorySize, FreePhysicalMemory)
})

Add-EvFinding $Report ([ordered]@{
    type = "ollama_processes"
    classification = "REPORTED"
    processes = @(Get-Process -Name ollama -ErrorAction SilentlyContinue | Select-Object Id, ProcessName, CPU, WorkingSet64)
})

$listeners = @()
foreach ($port in 11434, 11435, 8080, 8081) {
    $connections = @(Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction SilentlyContinue |
        Select-Object LocalAddress, LocalPort, OwningProcess, State)
    $listeners += [ordered]@{ port = $port; connections = $connections }
}
Add-EvFinding $Report ([ordered]@{
    type = "listeners"
    classification = "REPORTED"
    listeners = $listeners
})

Add-EvProposal $Report ([ordered]@{
    operation = "review_ollama_restart_plan"
    target = "Windows Ollama lane 11434"
    proposed = "If Blair approves, use a separate bounded change to restart only the chosen Ollama owner after recording before-state evidence."
    risk = "Restarting processes can interrupt existing EV services and model work."
    evidence = [ordered]@{ ports = @(11434, 11435); command_port_preserved = 8080 }
})

Write-EvNotification $Report $GptOutboxPath
