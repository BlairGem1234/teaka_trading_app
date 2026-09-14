# EV / TeAka local session handoff

Continuity notes from Desktop + web cloud-agent threads (Sep 2026).  
Safe paths and inventory only — no secrets.

## Where this chat picks up

| Thread | Status |
|--------|--------|
| **Fing (Windows)** | Canonical exe confirmed: `C:\Program Files\Fing\Fing.exe`. Desktop shortcut fixed. Launch with `-Verb RunAs` waits on **UAC**. Process often **exits immediately** — needs console exit code + `main.log` (see below). |
| **Mirror Downloads** | Inspected `OneDriveMirror\Downloads` — **Fing.dmg** / **Fing (1).dmg** only (macOS); **no** Windows Fing installer there. |
| **ChatGPT.dmg in mirror** | Extracted tree shows **ChatGPT.app** + **LicensePlist** (`*.plist` under `com.mono0926.LicensePlist/`). Swift packages (swift-markdown, LiveKitWebRTC, Sentry, etc.) are **normal OpenAI macOS app dependencies**, not TeAka/Fing malware. |
| **Codex / Cloak Clock** | **Cloak** = Python proxy process; **Clock** = `ev_clock.json` / throttle JS. Your banner: `C:\EV_AI\Codex`, `C:\EV_Operator`. **4 Cloak PIDs = fix now.** Glossary: **`docs/CLOAK_CLOCK_GLOSSARY.md`**. Scripts: `ev_codex_token_audit.ps1 -StopDuplicates`. |
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

## Fing — next diagnostic (PowerShell)

When `-Verb RunAs` shows no process, **UAC may be blocking** or the app **exits cleanly**. Run **without** elevation first to capture exit code.

**From repo (recommended):**

```powershell
cd C:\Users\blair\EV_Git\teaka_trading_app
pwsh -File scripts\fing_diagnose.ps1 -SaveTo scratch\fing_diag.txt
```

Then paste **only** `ExitCode`, stderr, and `main.log` tail into Cursor (or tell the agent: `scratch\fing_diag.txt`). The script clears stale locks/GPU cache, checks `Get-Service *fing*`, lists `C:\Program Files\Fing\*.exe`, runs a synchronous launch, and optionally saves output to avoid **HTTP 500** on huge pastes.

**What those Swift `.plist` files in the mirror were:** LicensePlist entries inside extracted **ChatGPT.app** (macOS), not Fing or TeAka — see table above.

## Run git scripts locally (PowerShell) — start here

Scripts in the repo are **not** run by the cloud agent on your PC. Use **one launcher**:

**Copy this whole block into PowerShell (first time + every run):**

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
cd C:\Users\blair\EV_Git\teaka_trading_app
git pull
pwsh -NoProfile -File .\scripts\run_local_handoff.ps1
```

Menu picks **cursor** / **codex** / **fing** / **all**. No `pwsh` installed? Use:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\run_local_handoff.ps1 -Action all
```

From repo root you can also run: `.\Run-LocalHandoff.ps1 -Action all`

| `-Action` | Runs |
|-----------|------|
| `cursor` | `cursor_cloud_runtime_link.ps1` (+ clock log) |
| `codex` | `ev_codex_token_audit.ps1` |
| `fing` | `fing_diagnose.ps1` |
| `all` | all three after `git pull` |

Outputs go to **`scratch\`** (gitignored). Point the cloud agent at those files, not huge pastes.

## Link this cloud chat to the EV / Codex thread (local)

Cursor keeps **one transcript per agent URL**. To **continue the same thread**, open that run in the browser — do not start a brand-new agent if you want history.

```powershell
cd C:\Users\blair\EV_Git\teaka_trading_app
git pull
pwsh -File scripts\cursor_cloud_runtime_link.ps1 -AppendClockLog -OpenLinks
```

| Thread | URL |
|--------|-----|
| Fing + handoff (this line of work) | https://cursor.com/agents/bc-70aa0aeb-0d8a-4d84-9114-c299b5fe8248 |
| EV / Codex / Cloak | https://cursor.com/agents/bc-b9fdc66e-2374-47ba-9788-073c9a6bf902 |

Then tell any agent: “read `scratch\cursor_cloud_runtime.json`” instead of pasting long logs.

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
2. EV Cloak: run `ev_codex_token_audit.ps1`; confirm Stable-only + throttle files (see `EV_CODEX_CLOAK_AND_TOKENS.md`)  
3. Google Drive: index `EV_Brain` / log JSON once Drive MCP authenticated  
4. Mirror: optionally copy `downloaded-logs-*.json` into `bridge/inbox/` for TeAka audit (scrub secrets first)
