#Requires -Version 5.1
<#
.SYNOPSIS
  Codex test: EV Ollama Brain Flask sidecar. Do not touch Command :8080.

.DESCRIPTION
  Winner layout on Blairspc (2026-09-17):
    8080  EV Command Bridge (ev_command_8080.py)  KEEP
    11434 Windows ollama.exe  qwen3:4b             KEEP
    11435 Docker ollama-docker qwen2.5:3b          KEEP
    5056  GEMBot MCP/Flask                         KEEP (two PIDs = conflict, report only)
    5060  RoboShady                                KEEP
    5055  Minerals                                 KEEP
    5432  Postgres                                 KEEP
    8081  Ollama Brain Flask SHOULD listen here
    11436 memory bridge                            currently down

  Broken starter: C:\EV_AI\Ollama\Start-OllamaBrainFlask.ps1
    sets EV_OLLAMA_FLASK_PORT=8080 and Stop-Process on 8080. Do not run it.

  Fast test:
    powershell -NoProfile -ExecutionPolicy Bypass -File .\ev_ollama_brain_flask_codex_test.ps1
#>
$ErrorActionPreference = "Continue"

function Test-Http([string]$Name, [string]$Url, [int]$Sec = 4) {
    try {
        $r = curl.exe -sS -m $Sec -w "`nHTTP %{http_code}" $Url 2>&1
        Write-Host "[$Name] $Url" -ForegroundColor Cyan
        Write-Host $r
    } catch {
        Write-Host "[$Name] FAIL $($_.Exception.Message)" -ForegroundColor Yellow
    }
    Write-Host ""
}

Write-Host "=== DO NOT BIND OR KILL 8080 ===" -ForegroundColor Yellow
Write-Host "Command = 8080. Flask under test = 8081."

Write-Host "`n=== LISTENERS ===" -ForegroundColor Cyan
foreach ($p in 8080, 8081, 11434, 11435, 11436, 5056, 5060, 5055, 5432) {
    $lines = netstat -ano | findstr ":$p"
    if ($lines) { Write-Host "PORT $p"; Write-Host $lines } else { Write-Host "PORT $p  --" }
}

Write-Host "`n=== COMMAND (must stay up) ===" -ForegroundColor Cyan
Test-Http "CMD" "http://127.0.0.1:8080/health" 5

Write-Host "=== OLLAMA ===" -ForegroundColor Cyan
Test-Http "WIN11434" "http://127.0.0.1:11434/api/tags" 5
Test-Http "DK11435" "http://127.0.0.1:11435/api/tags" 5

Write-Host "=== GEMBOT / SHADY / MINERALS ===" -ForegroundColor Cyan
Test-Http "GEMBOT" "http://127.0.0.1:5056/" 3
Test-Http "SHADY" "http://127.0.0.1:5060/" 3
Test-Http "MIN" "http://127.0.0.1:5055/" 3

Write-Host "=== BRAIN FLASK 8081 ===" -ForegroundColor Cyan
Test-Http "FLASK_HEALTH" "http://127.0.0.1:8081/health" 5
Test-Http "FLASK_MODELS" "http://127.0.0.1:8081/models" 5

$ask = '{"prompt":"ping","model":"qwen3:4b"}'
Write-Host "POST /ask (8s, qwen3:4b — may timeout if native generate still hung)"
curl.exe -sS -m 8 -w "`nHTTP %{http_code}`n" -X POST "http://127.0.0.1:8081/ask" -H "Content-Type: application/json" --data-binary $ask
Write-Host ""
$mem = '{"prompt":"ping"}'
Write-Host "POST /memory/ask (5s — 11436 may be down)"
curl.exe -sS -m 5 -w "`nHTTP %{http_code}`n" -X POST "http://127.0.0.1:8081/memory/ask" -H "Content-Type: application/json" --data-binary $mem

Write-Host "`n=== PASS / FAIL ===" -ForegroundColor Cyan
Write-Host "PASS Command: GET :8080/health is 200 and schema still EV Command Bridge"
Write-Host "PASS Flask:   GET :8081/health is 200"
Write-Host "FAIL if :8080 becomes Ollama Brain Flask or Command pid dies"
Write-Host "FAIL if this test started Start-OllamaBrainFlask.ps1 from EV_AI"
Write-Host "GEMBot MCP target is :5056 — Flask should CALL it, not replace it"
