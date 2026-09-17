#Requires -Version 5.1
<#
.SYNOPSIS
  Blairspc hardware dump: kernel, system, display adapters, hidden/disabled NVIDIA.

.DESCRIPTION
  nvidia-smi missing does NOT prove there is no NVIDIA card. It may be
  disabled in Device Manager, driver-only leftover, or not on PATH.

  Paste:
    powershell -NoProfile -ExecutionPolicy Bypass -File C:\EV_Operator\ev_pc_gpu_kernel_audit.ps1
#>
$ErrorActionPreference = "Continue"

function Write-Step([string]$Msg) {
    Write-Host ""
    Write-Host "=== $Msg ===" -ForegroundColor Cyan
}

Write-Step "Kernel / OS"
$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$bios = Get-CimInstance Win32_BIOS
[PSCustomObject]@{
    Computer        = $env:COMPUTERNAME
    User            = $env:USERNAME
    Caption         = $os.Caption
    Version         = $os.Version
    Build           = $os.BuildNumber
    KernelNT        = [Environment]::OSVersion.Version.ToString()
    Architecture    = $os.OSArchitecture
    InstallDate     = $os.InstallDate
    LastBoot        = $os.LastBootUpTime
    Manufacturer    = $cs.Manufacturer
    Model           = $cs.Model
    BIOS            = $bios.SMBIOSBIOSVersion
    RAM_GB          = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    FreeRAM_GB      = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    PowerShell      = $PSVersionTable.PSVersion.ToString()
} | Format-List

Write-Step "CPU / kernel scheduler"
Get-CimInstance Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors, MaxClockSpeed, CurrentClockSpeed | Format-List
Write-Host ("HypervisorPresent={0}  TotalCPUs={1}" -f $cs.HypervisorPresent, $cs.NumberOfLogicalProcessors)

Write-Step "Win32_VideoController (Windows display adapters)"
Get-CimInstance Win32_VideoController | Select-Object Name, Status, PNPDeviceID, DriverVersion, DriverDate, VideoProcessor, AdapterRAM, Availability, ConfigManagerErrorCode | Format-List

Write-Step "PnP Display class (present, disabled, hidden)"
try {
    Get-PnpDevice -Class Display -ErrorAction Stop |
        Select-Object Status, Class, FriendlyName, InstanceId, Problem, ProblemDescription |
        Format-Table -AutoSize -Wrap
} catch {
    Write-Host "Get-PnpDevice Display failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Step "Any PnP name matching NVIDIA / GeForce / AMD / Radeon / Intel GPU"
try {
    Get-PnpDevice -ErrorAction Stop |
        Where-Object { $_.FriendlyName -match 'NVIDIA|GeForce|Quadro|Tesla|RTX|GTX|AMD|Radeon|Vega|Intel\(R\) Arc|UHD Graphics|Iris' } |
        Select-Object Status, Class, FriendlyName, InstanceId |
        Format-Table -AutoSize -Wrap
} catch {
    Write-Host "Get-PnpDevice scan failed: $($_.Exception.Message)"
}

Write-Step "pnputil enum Display (includes disconnected)"
& pnputil.exe /enum-devices /class Display 2>&1

Write-Step "PCI devices that look like GPUs"
Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue |
    Where-Object { $_.PNPClass -eq 'Display' -or $_.Name -match 'NVIDIA|GeForce|Radeon|VGA|3D Video|Display' } |
    Select-Object Name, Status, ConfigManagerErrorCode, PNPDeviceID |
    Format-Table -AutoSize -Wrap

Write-Step "nvidia-smi / nvapi leftovers on disk"
$smiHits = @(
    "$env:SystemRoot\System32\nvidia-smi.exe",
    "$env:ProgramFiles\NVIDIA Corporation\NVSMI\nvidia-smi.exe",
    "${env:ProgramFiles(x86)}\NVIDIA Corporation\NVSMI\nvidia-smi.exe"
)
foreach ($p in $smiHits) {
    if (Test-Path -LiteralPath $p) { Write-Host "FOUND $p" -ForegroundColor Green } else { Write-Host "missing $p" }
}
Write-Host "where.exe nvidia-smi:"
& where.exe nvidia-smi 2>&1
Write-Host "where.exe nvcc:"
& where.exe nvcc 2>&1

Write-Step "NVIDIA / AMD program folders"
@(
    "$env:ProgramFiles\NVIDIA Corporation",
    "${env:ProgramFiles(x86)}\NVIDIA Corporation",
    "$env:ProgramFiles\NVIDIA GPU Computing Toolkit",
    "$env:ProgramFiles\AMD",
    "$env:ProgramFiles\AMD\CNext",
    "${env:ProgramFiles(x86)}\AMD"
) | ForEach-Object {
    if (Test-Path -LiteralPath $_) { Write-Host "DIR  $_" -ForegroundColor Green } else { Write-Host "no   $_" }
}

Write-Step "DriverStore NVIDIA infs (hidden driver packages)"
Get-ChildItem "$env:SystemRoot\System32\DriverStore\FileRepository" -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^nv|^amd|^u\d' } |
    Select-Object Name, LastWriteTime |
    Format-Table -AutoSize

Write-Step "Services: nvlddmkm / AMDKMPFD / Ollama / Docker"
Get-Service -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match 'nv|NVIDIA|amdkmpfd|amd-usbc|ollama|com.docker|docker' -or $_.DisplayName -match 'NVIDIA|AMD.*Graphics|Ollama|Docker' } |
    Select-Object Status, StartType, Name, DisplayName |
    Format-Table -AutoSize -Wrap

Write-Step "Registry GPU keys"
foreach ($key in @(
        "HKLM:\SOFTWARE\NVIDIA Corporation",
        "HKLM:\SOFTWARE\WOW6432Node\NVIDIA Corporation",
        "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm",
        "HKLM:\SYSTEM\CurrentControlSet\Services\amdkmdag",
        "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}"
    )) {
    if (Test-Path $key) { Write-Host "KEY  $key" -ForegroundColor Green } else { Write-Host "no   $key" }
}

Write-Step "Disabled devices you can turn back on (needs Admin for Enable)"
try {
    $disabled = Get-PnpDevice -Class Display -ErrorAction Stop | Where-Object { $_.Status -ne 'OK' }
    if ($disabled) {
        $disabled | Format-Table Status, FriendlyName, InstanceId -AutoSize -Wrap
        Write-Host "To enable (Admin PowerShell): Enable-PnpDevice -InstanceId '<InstanceId>' -Confirm:`$false"
    } else {
        Write-Host "All Display-class devices report Status=OK (or none found)."
    }
} catch {
    Write-Host $_.Exception.Message
}

Write-Step "Done"
Write-Host "Copy this whole dump back. If an NVIDIA InstanceId appears with Status=Error/Unknown/Disabled, that is the hidden card."
