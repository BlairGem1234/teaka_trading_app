# === Launch EVStack: Golden Fleece + Teaka Trading API via Waitress ===

$goldenFleeceModule = "ev_ollama_server:app"
$teakaAPIModule     = "app:app"

Write-Host "Launching Golden Fleece LLM on port 5050..." -ForegroundColor Cyan
Start-Process python -ArgumentList "-m waitress --host=0.0.0.0 --port=5050 $goldenFleeceModule" -WorkingDirectory "C:\EV_Files"

Start-Sleep -Seconds 1

Write-Host "Launching Teaka Trading API on port 5000..." -ForegroundColor Yellow
$teakaAppDir = @(
    "C:\EV_Operator\teaka_trading_app",
    "C:\teaka_trading_app",
    "C:\EV_Files\teaka_trading_app",
    "$PSScriptRoot\.."
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $teakaAppDir) { $teakaAppDir = "C:\EV_Operator\teaka_trading_app" }
Start-Process python -ArgumentList "-m waitress --host=0.0.0.0 --port=5000 $teakaAPIModule" -WorkingDirectory $teakaAppDir

Start-Sleep -Seconds 1

Write-Host "All EVStack components launched." -ForegroundColor Green

