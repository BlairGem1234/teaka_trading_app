# Teaka Swarm – Daily Summary Task Scheduler
$taskName = "TeakaDailySummary"
$candidatePaths = @(
    "C:\EV_Operator\teaka_trading_app\email_report.py",
    "C:\EV_Files\teaka_trading_app\email_report.py",
    "$PSScriptRoot\..\email_report.py"
)
$scriptPath = $candidatePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $scriptPath) { $scriptPath = "C:\EV_Operator\teaka_trading_app\email_report.py" }

$trigger = New-ScheduledTaskTrigger -Daily -At 00:01AM
$action = New-ScheduledTaskAction -Execute "python.exe" -Argument "`"$scriptPath`""

Register-ScheduledTask -TaskName $taskName `
  -Action $action `
  -Trigger $trigger `
  -Description "Sends daily trade summary email from Teaka Swarm" `
  -User "SYSTEM" `
  -RunLevel Highest
