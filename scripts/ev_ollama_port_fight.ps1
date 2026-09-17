#Requires -Version 5.1
<#
.SYNOPSIS
  Show who owns 11434 vs 11435 and which EV/Ollama tasks are fighting.

.DESCRIPTION
  Docker ollama-docker is 11435. Native Windows Ollama is 11434.
  They do not share a port. 11434 can still fight itself:
    Windows service "Ollama"
    scheduled task EV_Blair_Ollama_11434
    extra ollama.exe serve from EV Terminal
#>
$ErrorActionPreference = "Continue"

Write-Host "`n=== LISTENERS 11434 / 11435 ===" -ForegroundColor Cyan
netstat -ano | findstr ":11434"
netstat -ano | findstr ":11435"

Write-Host "`n=== PID COMMAND LINES ===" -ForegroundColor Cyan
$pids = netstat -ano | Select-String ":1143[45].*LISTENING" | ForEach-Object {
    ($_ -split '\s+')[-1]
} | Sort-Object -Unique
foreach ($procId in $pids) {
    Get-CimInstance Win32_Process -Filter "ProcessId=$procId" |
        Select-Object ProcessId, Name, CommandLine | Format-List
}

Write-Host "`n=== SERVICE Ollama ===" -ForegroundColor Cyan
Get-Service Ollama -ErrorAction SilentlyContinue | Format-List Status, StartType, Name, DisplayName

Write-Host "`n=== TASKS Ollama / EV_Blair / 11434 ===" -ForegroundColor Cyan
Get-ScheduledTask -ErrorAction SilentlyContinue |
    Where-Object { $_.TaskName -match 'Ollama|11434|EV_Blair' -or $_.TaskPath -match 'EV' } |
    Select-Object TaskPath, TaskName, State |
    Format-Table -AutoSize -Wrap

Get-ScheduledTask -ErrorAction SilentlyContinue |
    Where-Object { $_.TaskName -match 'Ollama|11434|EV_Blair' } |
    ForEach-Object {
        $i = $_ | Get-ScheduledTaskInfo
        [PSCustomObject]@{
            Task     = $_.TaskName
            State    = $_.State
            LastRun  = $i.LastRunTime
            LastResult = $i.LastTaskResult
            NextRun  = $i.NextRunTime
            Actions  = ($_.Actions | ForEach-Object { "$($_.Execute) $($_.Arguments)" }) -join ' | '
        }
    } | Format-List

Write-Host "`n=== docker ports ===" -ForegroundColor Cyan
docker ps --filter name=ollama --format "table {{.Names}}`t{{.Status}}`t{{.Ports}}"

Write-Host "`n11434 = Windows. 11435 = Docker. Disable extra 11434 tasks, do not stop Docker."
