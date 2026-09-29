# === fing_diagnose.ps1 ===
# Diagnose Fing desktop (Windows) immediate exit, stale locks, and service state.
# Run from repo:  pwsh -File scripts\fing_diagnose.ps1
# Optional:      pwsh -File scripts\fing_diagnose.ps1 -SaveTo scratch\fing_diag.txt

param(
    [string]$FingExe = "C:\Program Files\Fing\Fing.exe",
    [string]$SaveTo = ""
)

$ErrorActionPreference = "SilentlyContinue"

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " FING DIAGNOSTIC (TeAka handoff)" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

# 1. Stop zombie Fing processes
Get-Process *fing* -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

# 2. AppData locks and GPU cache
$fingAppData = Join-Path $env:APPDATA "Fing"
if (Test-Path -LiteralPath $fingAppData) {
    Write-Host "[+] Cleaning stale lock files under $fingAppData" -ForegroundColor Yellow
    Get-ChildItem -LiteralPath $fingAppData -Filter "*lock*" -Recurse -ErrorAction SilentlyContinue |
        Remove-Item -Force -ErrorAction SilentlyContinue
    $gpuCache = Join-Path $fingAppData "GPUCache"
    if (Test-Path -LiteralPath $gpuCache) {
        Remove-Item -LiteralPath $gpuCache -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "    Removed GPUCache" -ForegroundColor DarkGray
    }
} else {
    Write-Host "[-] No $fingAppData (first run or different user profile)" -ForegroundColor Gray
}

# 3. Windows services
Write-Host "`n[+] Fing-related services" -ForegroundColor Yellow
Get-Service -Name "*fing*" -ErrorAction SilentlyContinue |
    Select-Object Name, DisplayName, Status, StartType | Format-Table -AutoSize
$svc = Get-Service -Name "*fing*" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($svc -and $svc.Status -ne "Running") {
    Write-Host "    Attempting Start-Service $($svc.Name)..." -ForegroundColor Yellow
    Start-Service -Name $svc.Name -ErrorAction SilentlyContinue
}

# 4. Installed exes
Write-Host "[+] Executables in $(Split-Path $FingExe -Parent)" -ForegroundColor Yellow
$installDir = Split-Path $FingExe -Parent
if (Test-Path -LiteralPath $installDir) {
    Get-ChildItem -LiteralPath $installDir -Filter "*.exe" |
        Select-Object Name, Length, LastWriteTime | Format-Table -AutoSize
} else {
    Write-Host "    Install folder not found: $installDir" -ForegroundColor Red
}

# 5. Logs
Write-Host "[+] Recent log files" -ForegroundColor Yellow
$logDir = Join-Path $fingAppData "logs"
if (Test-Path -LiteralPath $logDir) {
    Get-ChildItem -LiteralPath $logDir | Sort-Object LastWriteTime -Descending |
        Select-Object -First 5 Name, Length, LastWriteTime | Format-Table -AutoSize
    $mainLog = Join-Path $logDir "main.log"
    if (Test-Path -LiteralPath $mainLog) {
        Write-Host "--- main.log (last 20 lines) ---" -ForegroundColor Cyan
        Get-Content -LiteralPath $mainLog -Tail 20
    }
} else {
    Write-Host "    No log directory: $logDir" -ForegroundColor Gray
}

# 6. Synchronous launch (capture exit code)
Write-Host "`n[+] Console launch (no UAC): $FingExe" -ForegroundColor Green
if (-not (Test-Path -LiteralPath $FingExe)) {
    Write-Host "    Fing.exe missing at configured path." -ForegroundColor Red
    exit 1
}

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $FingExe
$psi.Arguments = "--enable-logging --v=1 --disable-gpu --no-sandbox"
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$psi.WorkingDirectory = Split-Path $FingExe -Parent

$p = [System.Diagnostics.Process]::Start($psi)
$stdout = $p.StandardOutput.ReadToEnd()
$stderr = $p.StandardError.ReadToEnd()
$null = $p.WaitForExit(15000)

$exitColor = if ($p.ExitCode -eq 0) { "Green" } else { "Red" }
Write-Host "ExitCode: $($p.ExitCode)" -ForegroundColor $exitColor
if ($stdout.Trim()) {
    Write-Host "--- stdout ---" -ForegroundColor Yellow
    Write-Output $stdout
}
if ($stderr.Trim()) {
    Write-Host "--- stderr ---" -ForegroundColor Red
    Write-Output $stderr
}

Start-Sleep -Seconds 2
$running = Get-Process *fing* -ErrorAction SilentlyContinue
if ($running) {
    Write-Host "`n[+] Fing process still running after launch:" -ForegroundColor Green
    $running | Select-Object Id, ProcessName, MainWindowTitle, Path | Format-Table -AutoSize
} else {
    Write-Host "`n[-] No Fing process after launch (exited or never started UI)." -ForegroundColor Yellow
    Get-WinEvent -FilterHashtable @{ LogName = "Application"; ProviderName = "Application Error" } -MaxEvents 5 -ErrorAction SilentlyContinue |
        Where-Object { $_.Message -like "*Fing*" } |
        Select-Object TimeCreated, Message | Format-List
}

if ($SaveTo) {
    $outPath = if ([System.IO.Path]::IsPathRooted($SaveTo)) { $SaveTo } else { Join-Path (Get-Location) $SaveTo }
    $dir = Split-Path $outPath -Parent
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    @(
        "ExitCode: $($p.ExitCode)"
        "stdout:"
        $stdout
        "stderr:"
        $stderr
        "main.log tail:"
        if (Test-Path -LiteralPath (Join-Path $logDir "main.log")) {
            Get-Content -LiteralPath (Join-Path $logDir "main.log") -Tail 30
        }
    ) | Out-File -FilePath $outPath -Encoding utf8
    Write-Host "`n[+] Saved summary to $outPath (paste path to Cursor, not full file)" -ForegroundColor Green
}

Write-Host "`nTip: If UI needs admin, run Desktop shortcut after UAC Yes, or:" -ForegroundColor DarkGray
Write-Host "  Start-Process '$FingExe' -Verb RunAs" -ForegroundColor DarkGray
