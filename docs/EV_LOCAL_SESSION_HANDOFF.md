# EV / TeAka local session handoff

Continuity notes from Desktop + web cloud-agent threads (Sep 2026).  
Safe paths and inventory only — no secrets.

## Where this chat picks up

| Thread | Status |
|--------|--------|
| **Fing (Windows)** | Canonical exe confirmed: `C:\Program Files\Fing\Fing.exe`. Desktop shortcut fixed. Launch with `-Verb RunAs` waits on **UAC**. Process often **exits immediately** — needs console exit code + `main.log` (see below). |
| **Mirror Downloads** | Inspected `OneDriveMirror\Downloads` — **Fing.dmg** / **Fing (1).dmg** only (macOS); **no** Windows Fing installer there. |
| **ChatGPT.dmg in mirror** | Extracted tree shows **ChatGPT.app** + **LicensePlist** (`*.plist` under `com.mono0926.LicensePlist/`). Swift packages (swift-markdown, LiveKitWebRTC, Sentry, etc.) are **normal OpenAI macOS app dependencies**, not TeAka/Fing malware. |
| **Codex / EV Cloak** | Separate thread: duplicate `ev_devtools_cloak.py`, Stable+Beta Codex, ports **5056/5057**, clock files `C:\EV_Operator\Config\ev_clock.json` + `Bridge\ev_clock_throttle.js`. Beta killed; Cloak→Stable wiring still to confirm. |
| **TeAka cloud** | Paper bridge: `connect_python.py` on **5050**; `main` @ BoltBuddy+phone merge. |
| **Google Drive EV logs** | Referenced in open PR work (EV_Brain / bridge sync). Folder id from agent notes: `15kPq7T_iarOY4FCkeGptje8c4fwu5LxC` — link Drive MCP in Cursor to index from cloud. |

## Mirror / “hidden” filesystem (OneDrive ↔ Dropbox audit)

**Root (Blair profile):**

```text
C:\Users\blair\OneDrive\OneDrive\Imports\blairgem@outlook.com - Dropbox\Mirror_Audit\OneDriveMirror\Downloads
```

**What it is:** A **point-in-time mirror** of old Downloads (Nov 2024 batch + later merges). Not a live sync root — useful for **forensics and recovery**, not for “which Fing to run.”

**TeAka / EV-relevant items spotted in mirror listing (non-exhaustive):**

| Artifact | Notes |
|----------|--------|
| `downloaded-logs-20240818-*.json` | Cloud/runtime log exports — candidate for TeAka/EV timeline reconstruction |
| `AIPRM-export-chatgpt-thread_*.md` | Archived GPT threads (GEM/prospectivity context) |
| `install nmap.log` | Network tooling install trace |
| `scripts.zip_openai` / `ChatGPT Installer.exe` | OpenAI desktop tooling |
| `ChatGPT.dmg` + extracted `.app` | macOS client only |
| `.HFS+ Private Directory Data` / `[HFS+ Private Data]` | Normal **DMG mount residue** on Windows when images were opened |
| `Open Notebook.onetoc2` (many) | OneNote section index files |
| GIS / GEM / Mergin (`*.gpkg`, `.mergin`, Barrytown/Ngakawau) | Field geology — parallel to GEM prospectivity work, not trading engine |
| `C27EB4BA.DROPBOX_xbfy0k16fey96!App` | Dropbox placeholder namespace |

**Canonical Windows Fing (ignore duplicate DMGs):**

```text
C:\Program Files\Fing\Fing.exe
C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Fing.lnk
C:\Users\Blair\Desktop\Fing.lnk  → should target Program Files exe
```

## Fing — next diagnostic (paste in PowerShell)

When `-Verb RunAs` shows no process, **UAC may be blocking** or the app **exits cleanly**. Run **without** elevation first to capture exit code:

```powershell
Write-Host "=== FING CONSOLE EXIT CODE ===" -ForegroundColor Cyan
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "C:\Program Files\Fing\Fing.exe"
$psi.Arguments = "--enable-logging --v=1 --disable-gpu"
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$p = [System.Diagnostics.Process]::Start($psi)
$out = $p.StandardOutput.ReadToEnd()
$err = $p.StandardError.ReadToEnd()
$p.WaitForExit(15000)
Write-Host "ExitCode: $($p.ExitCode)" -ForegroundColor $(if ($p.ExitCode -eq 0){"Green"}else{"Red"})
if ($out) { Write-Host "--- stdout ---"; $out }
if ($err) { Write-Host "--- stderr ---"; $err }
$log = "$env:APPDATA\Fing\logs\main.log"
if (Test-Path $log) { Write-Host "--- main.log tail ---"; Get-Content $log -Tail 20 }
Get-ChildItem "C:\Program Files\Fing" -Filter "*.exe" | Format-Table Name, Length, LastWriteTime -AutoSize
```

Paste **only** `ExitCode`, stderr, and `main.log` tail back here (small chunk — avoids Cursor **HTTP 500** on huge pastes).

**Also check:** `Get-Service *fing*` and `%APPDATA%\Fing\` lock files (already in prior scripts).

## Cursor HTTP 500 when pasting

Usually **Cursor server error** on large messages, not TeAka port 5000. Mitigations:

- Paste **ExitCode + last 20 log lines** instead of full directory dumps
- Save big output to `C:\Users\blair\EV_Git\teaka_trading_app\scratch\fing_diag.txt` and tell the agent the path
- Continue heavy local threads in **Desktop agent**; use **cloud agent** for repo/docs

## Repo pointers (TeAka)

| Item | Path |
|------|------|
| Paper bridge | `connect_python.py` (:5050) |
| PC5000 git diagnostic drop | `bridge/inbox/PC5000_GIT_ACCESS_DIAGNOSTIC_001.json` |
| GEMBot paths | `docs/GEMBotSys_path_map.txt` |
| Brain (cloud copy) | `ev_virtual_brain.json` (local canonical paths in flight — PR #8 C: drive sync) |

## Open follow-ups

1. Fing: exit code + service + `main.log` crash reason  
2. EV Cloak: which Codex build Stable uses + clock throttle values  
3. Google Drive: index `EV_Brain` / log JSON once Drive MCP authenticated  
4. Mirror: optionally copy `downloaded-logs-*.json` into `bridge/inbox/` for TeAka audit (scrub secrets first)
