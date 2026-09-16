# === ev_command_check.ps1 ===
# EV Command = main operator command plane on PC5000 (read-only discovery).
#
#   pwsh -NoProfile -File scripts\ev_command_check.ps1

param(
    [string]$TeakaRoot = "",
    [string]$SaveTo = ""
)

$ErrorActionPreference = "SilentlyContinue"

if (-not $TeakaRoot) {
    $TeakaRoot = Split-Path $PSScriptRoot -Parent
    if (Test-Path "C:\Users\blair\EV_Git\teaka_trading_app") {
        $TeakaRoot = "C:\Users\blair\EV_Git\teaka_trading_app"
    }
}
$scratch = Join-Path $TeakaRoot "scratch"
if (-not (Test-Path $scratch)) { New-Item -ItemType Directory -Path $scratch | Out-Null }
if (-not $SaveTo) { $SaveTo = Join-Path $scratch "ev_command_status.json" }

function Find-CommandScripts {
    $roots = @(
        "C:\EV_Operator",
        "C:\EV_AI",
        "C:\Users\blair\EV_Git\Git_Satellite_Brain",
        "C:\Users\Blair\EV_Git\Git_Satellite_Brain",
        "C:\Users\blair\EV_Git\Ev",
        "C:\Users\blair\EV_Git\GEMBot29",
        "D:\EV_Files\Bridge"
    )
    $names = @(
        "Send-EVCommand.ps1",
        "*EVCommand*",
        "*ev_command*",
        "*Hello*EV*",
        "ev_remote_server*.py"
    )
    $found = @()
    foreach ($root in $roots) {
        if (-not (Test-Path $root)) { continue }
        foreach ($n in $names) {
            Get-ChildItem -LiteralPath $root -Filter $n -Recurse -File -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName -notmatch '\\\.venv\\|site-packages|\.git\\' } |
                Select-Object -First 5 |
                ForEach-Object { $found += $_ }
        }
    }
    $found | Sort-Object FullName -Unique
}

function Test-Port {
    param([int]$Port)
    $hit = netstat -ano 2>$null | Select-String ":$Port\s"
    if (-not $hit) { return @{ listening = $false } }
    $pid = ($hit | ForEach-Object { ($_ -split '\s+')[-1] } | Select-Object -First 1)
    $proc = Get-CimInstance Win32_Process -Filter "ProcessId = $pid" -ErrorAction SilentlyContinue
    return @{
        listening = $true
        pid       = $pid
        name      = $proc.Name
        cmdline   = $proc.CommandLine
    }
}

$scripts = Find-CommandScripts
$sendEv = @($scripts | Where-Object { $_.Name -eq "Send-EVCommand.ps1" })

$out = [ordered]@{
    generated_at = (Get-Date).ToString("o")
    main_system  = "EV Command (operator command plane)"
    stack_order  = @(
        "EV Command",
        "C EV brain (masher)",
        "EV AI",
        "EV Files",
        "EV core (system map)",
        "Starforge / RoboShady / TeAka adapters"
    )
    send_ev_command = @($sendEv | ForEach-Object { $_.FullName })
    command_scripts = @($scripts | Select-Object -First 25 | ForEach-Object {
        @{ path = $_.FullName; name = $_.Name; mtime = $_.LastWriteTime.ToString("o") }
    })
    operator = @{
        ev_operator_exists = Test-Path "C:\EV_Operator"
        clock_json         = Test-Path "C:\EV_Operator\Config\ev_clock.json"
        cloak_py           = Test-Path "C:\EV_Operator\DevToolsRuntime\ev_devtools_cloak.py"
    }
    command_ports = @{
        "8080" = Test-Port 8080
        "5000" = Test-Port 5000
        "5050" = Test-Port 5050
    }
    teaka_handoff = @{
        path   = $TeakaRoot
        note   = "Handoff scripts audit EV Command stack; they do not replace EV Terminal / Send-EVCommand"
        launcher = Join-Path $TeakaRoot "scripts\run_local_handoff.ps1"
    }
}

$out | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $SaveTo -Encoding utf8

Write-Host "=== EV Command (main system) check ===" -ForegroundColor Cyan
Write-Host "Command plane first; C EV brain + EV AI + EV Files sit under it.`n" -ForegroundColor DarkGray
if ($sendEv) {
    foreach ($s in $sendEv) {
        $tag = if ($s.FullName -match '\\EV_AI\\') { "preferred" } elseif ($s.FullName -match 'GEMBot29') { "legacy" } else { "ok" }
        Write-Host "Send-EVCommand [$tag]: $($s.FullName)" -ForegroundColor Green
    }
} else {
    Write-Host "Send-EVCommand.ps1 not found — check Git_Satellite_Brain or GEMBot29." -ForegroundColor Yellow
}
Write-Host "Operator C:\EV_Operator : $(if ($out.operator.ev_operator_exists) { 'OK' } else { 'missing' })" -ForegroundColor Gray
foreach ($p in 8080, 5000, 5050) {
    $st = $out.command_ports["$p"]
    if ($st.listening) { Write-Host "Port $p : listening (PID $($st.pid) $($st.name))" -ForegroundColor Green }
    else { Write-Host "Port $p : off" -ForegroundColor DarkGray }
}
Write-Host "`nSaved: $SaveTo" -ForegroundColor Green
