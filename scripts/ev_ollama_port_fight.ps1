#Requires -Version 5.1
<#
.SYNOPSIS
  Find scheduled-task / service / extra-serve conflicts on Ollama 11434 vs Docker 11435.

.DESCRIPTION
  Docker is 11435. Windows is 11434. They do not share a port.
  Conflict = two Windows starters both claiming 11434:
    service Ollama + task EV_Blair_Ollama_11434 + extra ollama.exe serve

  Paste:
    powershell -NoProfile -ExecutionPolicy Bypass -File C:\EV_Operator\ev_ollama_port_fight.ps1
#>
$ErrorActionPreference = "Continue"
$conflicts = New-Object System.Collections.Generic.List[string]

function Write-Step([string]$Msg) {
    Write-Host ""
    Write-Host "=== $Msg ===" -ForegroundColor Cyan
}

function Get-ListenPids([string]$Port) {
    netstat -ano | Select-String "[:.]$Port\s+.*LISTENING" | ForEach-Object {
        ($_ -split '\s+')[-1]
    } | Where-Object { $_ -match '^\d+$' } | Sort-Object -Unique
}

Write-Step "LISTENERS"
$p34 = @(Get-ListenPids "11434")
$p35 = @(Get-ListenPids "11435")
Write-Host "11434 PIDs: $($p34 -join ', ')"
Write-Host "11435 PIDs: $($p35 -join ', ')"
netstat -ano | findstr ":11434"
netstat -ano | findstr ":11435"

if ($p34.Count -eq 0) { $conflicts.Add("NO listener on 11434 - Windows Ollama is down") }
if ($p34.Count -gt 1) { $conflicts.Add("MULTIPLE listeners on 11434: PIDs $($p34 -join ', ')") }
if ($p35.Count -eq 0) { $conflicts.Add("NO listener on 11435 - Docker Ollama is down") }

Write-Step "PID COMMAND LINES"
foreach ($procId in @($p34 + $p35 | Sort-Object -Unique)) {
    Get-CimInstance Win32_Process -Filter "ProcessId=$procId" |
        Select-Object ProcessId, Name, CommandLine | Format-List
}

Write-Step "ALL ollama.exe (even not listening)"
$ollamaProcs = @(Get-Process -Name ollama -ErrorAction SilentlyContinue)
$ollamaProcs | Format-Table Id, ProcessName, CPU, @{ n = "MB"; e = { [int]($_.WorkingSet64 / 1MB) } } -AutoSize
if ($ollamaProcs.Count -gt 1) {
    $conflicts.Add("MULTIPLE ollama.exe processes: $($ollamaProcs.Id -join ', ')")
}

Write-Step "WINDOWS SERVICE Ollama"
$svc = Get-Service Ollama -ErrorAction SilentlyContinue
if ($svc) {
    $svc | Format-List Status, StartType, Name, DisplayName
} else {
    Write-Host "No Windows service named Ollama"
}

Write-Step "SCHEDULED TASKS (Ollama / 11434 / 11435 / EV_Blair / EV Codex)"
$taskFilter = 'Ollama|11434|11435|EV_Blair|EV Codex|GEMBot|GenesisKernel|Retriever|Cursor_Master'
$tasks = @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
        $_.TaskName -match $taskFilter -or $_.TaskPath -match '\\EV'
    })
if (-not $tasks) {
    Write-Host "Get-ScheduledTask returned none. Falling back to schtasks.exe ..."
    schtasks.exe /Query /FO LIST /V | Select-String -Pattern "Ollama|11434|EV_Blair|TaskName" -Context 0,0
}

$rows = foreach ($t in $tasks) {
    $info = $t | Get-ScheduledTaskInfo
    $actions = ($t.Actions | ForEach-Object { "$($_.Execute) $($_.Arguments)".Trim() }) -join " | "
    $triggers = ($t.Triggers | ForEach-Object { $_.CimClass.CimClassName + " enabled=" + $_.Enabled }) -join " | "
    $looks11434 = ($t.TaskName -match '11434|Ollama' -or $actions -match '11434|ollama')
    $looks11435 = ($t.TaskName -match '11435' -or $actions -match '11435')
    [PSCustomObject]@{
        Task       = $t.TaskPath + $t.TaskName
        State      = [string]$t.State
        LastRun    = $info.LastRunTime
        LastResult = $info.LastTaskResult
        NextRun    = $info.NextRunTime
        Actions    = $actions
        Triggers   = $triggers
        PortHint   = $(if ($looks11434) { "11434" } elseif ($looks11435) { "11435" } else { "" })
    }
}
$rows | Format-List

$ollamaTasks = @($rows | Where-Object { $_.PortHint -eq "11434" -or $_.Task -match 'Ollama' })
$runningOllamaTasks = @($ollamaTasks | Where-Object { $_.State -match 'Running' })
$readyOllamaTasks = @($ollamaTasks | Where-Object { $_.State -match 'Ready' })
if ($runningOllamaTasks.Count -gt 0 -and $svc -and $svc.Status -eq "Running") {
    $conflicts.Add("SERVICE Ollama is Running AND task(s) also Running: $($runningOllamaTasks.Task -join ', ')")
}
if ($ollamaTasks.Count -gt 1) {
    $conflicts.Add("More than one scheduled task targets Windows Ollama/11434: $($ollamaTasks.Task -join ' ; ')")
}
if ($svc -and $svc.Status -eq "Running" -and $readyOllamaTasks.Count -gt 0) {
    $conflicts.Add("SERVICE Ollama Running while task is Ready (will relaunch and fight): $($readyOllamaTasks.Task -join ', ')")
}
if ($svc -and $svc.StartType -eq "Automatic" -and $readyOllamaTasks.Count -gt 0) {
    $conflicts.Add("SERVICE Ollama Automatic + EV Ollama task both exist (boot race on 11434)")
}
foreach ($r in $ollamaTasks) {
    if ($r.LastResult -notin @(0, 267009, 267011, $null)) {
        # 0=ok, 267009=still running, 267011=not yet run
        $conflicts.Add("Task $($r.Task) last result=$($r.LastResult) (not success)")
    }
}

Write-Step "DOCKER"
docker ps -a --filter name=ollama --format "table {{.Names}}`t{{.Status}}`t{{.Ports}}" 2>&1

Write-Step "CONFLICT VERDICT"
if ($conflicts.Count -eq 0) {
    Write-Host "No scheduled-task vs service vs extra-serve clash detected on 11434." -ForegroundColor Green
    Write-Host "Docker 11435 is a different port. If generate still hangs, that is the AMD/Vulkan hang, not a port fight."
} else {
    Write-Host "CONFLICTS FOUND:" -ForegroundColor Red
    $conflicts | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    Write-Host ""
    Write-Host "Do NOT stop Docker / 11435 / 8080."
    Write-Host "To disable the extra Windows Ollama task (Admin, after you confirm the name):"
    Write-Host '  Disable-ScheduledTask -TaskName "EV_Blair_Ollama_11434"'
}

Write-Host ""
Write-Host "Copy this whole dump back."
