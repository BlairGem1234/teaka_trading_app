# === cursor_install_check.ps1 ===
# Summarize Cursor + Codex install on Blair PC (matches manual "location check" paste).
#   pwsh -File scripts\cursor_install_check.ps1
#   pwsh -File scripts\cursor_install_check.ps1 -SaveTo scratch\cursor_install_check.txt

param(
    [string]$SaveTo = "",
    [string]$Project = "C:\Users\blair\EV_Git\teaka_trading_app"
)

$ErrorActionPreference = "SilentlyContinue"
$lines = [System.Collections.Generic.List[string]]::new()

function Add-Line { param([string]$s) $lines.Add($s); Write-Host $s }

Add-Line "=== CURSOR + CODEX INSTALL CHECK ==="
Add-Line "Time: $(Get-Date -Format o)"
Add-Line "User: $env:USERDOMAIN\$env:USERNAME"
Add-Line ""

$canonicalPaths = @(
    "C:\Program Files\cursor\_\Cursor.exe",
    "C:\Program Files\Cursor\Cursor.exe",
    "C:\Program Files\Cursor\_\Cursor.exe"
)
Add-Line "=== CURSOR.EXE PATHS ==="
foreach ($p in $canonicalPaths) {
    $ok = Test-Path -LiteralPath $p
    Add-Line ("  [{0}] {1}" -f $(if ($ok) { "OK" } else { "--" }), $p)
    if ($ok) {
        $i = Get-Item -LiteralPath $p
        Add-Line ("       Version: {0}  SizeMB: {1}" -f $i.VersionInfo.ProductVersion, [math]::Round($i.Length / 1MB, 1))
    }
}

Add-Line ""
Add-Line "=== RUNNING: Cursor / Code / codex (token burn if 2+ codex) ==="
Get-Process Cursor, Code, codex, codex-code-mode-host -ErrorAction SilentlyContinue |
    Select-Object Id, ProcessName, @{ N = "Path"; E = { $_.Path } }, StartTime |
    ForEach-Object { Add-Line ("  PID {0} {1}`n    {2}" -f $_.Id, $_.ProcessName, $_.Path) }

$codexCount = @(Get-Process codex -ErrorAction SilentlyContinue).Count
if ($codexCount -gt 1) {
    Add-Line ""
    Add-Line "WARNING: $codexCount codex.exe processes (Stable + Beta = extra tokens). Close Codex Beta from Task Manager."
}

Add-Line ""
Add-Line "=== START MENU CURSOR SHORTCUTS ==="
$wsh = New-Object -ComObject WScript.Shell
Get-ChildItem @(
    "$env:APPDATA\Microsoft\Windows\Start Menu",
    "$env:ProgramData\Microsoft\Windows\Start Menu",
    "$env:USERPROFILE\Desktop"
) -Filter "Cursor*.lnk" -File -Recurse -ErrorAction SilentlyContinue |
    ForEach-Object {
        $sc = $wsh.CreateShortcut($_.FullName)
        Add-Line ("  {0}" -f $_.FullName)
        Add-Line ("    Target: {0}  Exists: {1}" -f $sc.TargetPath, (Test-Path -LiteralPath $sc.TargetPath))
        if ($sc.Arguments) { Add-Line ("    Args: {0}" -f $sc.Arguments) }
    }

Add-Line ""
Add-Line "=== RECOMMENDED LAUNCH (Anysphere IDE, not Chrome PWA) ==="
$launch = "C:\Program Files\cursor\_\Cursor.exe"
if (Test-Path -LiteralPath $launch) {
    Add-Line "  Start-Process -FilePath '$launch' -ArgumentList '\`"$Project\`"'"
} else {
    Add-Line "  Install/repair Cursor from https://cursor.com — exe not at expected path."
}

if ($SaveTo) {
    $out = if ([System.IO.Path]::IsPathRooted($SaveTo)) { $SaveTo } else { Join-Path (Get-Location) $SaveTo }
    $dir = Split-Path $out -Parent
    if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $lines -join "`n" | Set-Content -LiteralPath $out -Encoding utf8
    Add-Line ""
    Add-Line "Saved: $out"
}
