#Requires -Version 5.1
<#
.SYNOPSIS
  Blairspc: AMD iGPU + native Ollama 11434 vs Docker 2.5 on 11435.

.DESCRIPTION
  This PC has NO NVIDIA card (nvidia-smi missing). GPU is AMD Radeon(TM)
  Graphics. Windows AdapterRAM often shows 512 MB; extra "VRAM" is system RAM
  assigned to the iGPU (UMA). You cannot script GDDR into existence.

  Docker qwen2.5:3b on :11435 already generates (CPU in the container).
  Native :11434 listing works but generate hangs if ollama.exe is stuck in
  GPU/Vulkan discovery. This script kills only native ollama.exe, then
  restarts serve with Vulkan off so qwen3:4b can run on CPU like Docker.

  AMD Adrenalin (manual, not this script):
    Performance -> Tuning / GPU Memory  — raise iGPU memory from system RAM
  BIOS:
    iGPU / UMA Frame Buffer Size

  Usage (EV Terminal):
    powershell -NoProfile -ExecutionPolicy Bypass -File C:\EV_Operator\ev_amd_ollama_split.ps1
    powershell -NoProfile -ExecutionPolicy Bypass -File C:\EV_Operator\ev_amd_ollama_split.ps1 -VulkanIgpu
#>
[CmdletBinding()]
param(
    [switch]$VulkanIgpu,
    [switch]$SkipRestart,
    [switch]$SkipPing
)

$ErrorActionPreference = "Continue"
$OllamaExe = "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe"
$Models = "D:\OllamaModels"
$NativeHost = "127.0.0.1:11434"
$DockerHost = "127.0.0.1:11435"

function Write-Step([string]$Msg) {
    Write-Host ""
    Write-Host "=== $Msg ===" -ForegroundColor Cyan
}

Write-Step "GPU / RAM (cannot convert RAM into discrete VRAM)"
Get-CimInstance Win32_VideoController | Select-Object Name, DriverVersion, @{
    n = "AdapterRAM_MB"
    e = { if ($_.AdapterRAM -gt 0) { [int]($_.AdapterRAM / 1MB) } else { 0 } }
} | Format-List
Get-CimInstance Win32_OperatingSystem | Select-Object @{
    n = "RAM_GB"; e = { [math]::Round($_.TotalVisibleMemorySize / 1MB, 1) }
}, @{
    n = "FreeRAM_GB"; e = { [math]::Round($_.FreePhysicalMemory / 1MB, 1) }
} | Format-List
$smi = Get-Command nvidia-smi.exe -ErrorAction SilentlyContinue
if ($smi) { Write-Host "NVIDIA CLI: $($smi.Source)" } else { Write-Host "NVIDIA: none (expected on this APU)" -ForegroundColor Yellow }

Write-Host @"

Split this machine actually has:
  Docker 11435  qwen2.5:3b   ~12 GB container RAM cap (working)
  Native 11434  qwen3:4b     rest of system RAM / AMD iGPU shared
  Leave on disk              qwen2.5:32b  qwen3-coder:30b
"@

if (-not $SkipRestart) {
    Write-Step "Restart native ollama.exe only (do not touch Docker / 8080)"
    Get-Process -Name ollama -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "Stopping PID $($_.Id)"
        Stop-Process -Id $_.Id -Force
    }
    Start-Sleep 2
    if (-not (Test-Path -LiteralPath $OllamaExe)) { throw "Missing $OllamaExe" }

    $env:OLLAMA_MODELS = $Models
    $env:OLLAMA_HOST = $NativeHost
    $env:CUDA_VISIBLE_DEVICES = "-1"
    if ($VulkanIgpu) {
        $env:OLLAMA_VULKAN = "1"
        $env:OLLAMA_IGPU_ENABLE = "1"
        Write-Host "Mode: AMD iGPU Vulkan (shared RAM as graphics memory)"
    } else {
        $env:OLLAMA_VULKAN = "0"
        $env:OLLAMA_IGPU_ENABLE = "0"
        Write-Host "Mode: CPU only (unstick hung GPU discovery)"
    }

    Start-Process -FilePath $OllamaExe -ArgumentList "serve" -WindowStyle Hidden
    Start-Sleep 5
}

if ($SkipPing) { return }

Write-Step "Ping both lanes"
curl.exe -sS -m 8 -w "`nNATIVE_TAGS %{http_code}`n" "http://$NativeHost/api/tags" | Select-Object -Last 5
curl.exe -sS -m 8 -w "`nDOCKER_TAGS %{http_code}`n" "http://$DockerHost/api/tags" | Select-Object -Last 3

$body = '{"model":"qwen3:4b","prompt":"hi","stream":false,"think":false,"options":{"num_gpu":0,"num_predict":8,"num_ctx":512}}'
Write-Host "Native generate qwen3:4b (CPU, 90s) ..."
curl.exe -sS -m 90 -w "`nQ3 %{http_code}`n" -X POST "http://$NativeHost/api/generate" -H "Content-Type: application/json" --data-binary $body

Write-Step "Done"
Write-Host "If Q3 000 again: native runner is still wedged. Reboot or check D:\EV_AI\logs"
Write-Host "If Q3 200: keep Docker on 2.5; Windows 3/4 is CPU until you raise iGPU memory in Adrenalin and rerun -VulkanIgpu"
