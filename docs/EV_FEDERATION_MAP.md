# EV federation map (PC5000 / `C:\Users\blair\EV_Git`)

You track **one machine (PC5000 / Blair PC)** through **many git roots**. They are **not** one AI profile: **system masher (The Brain)** vs **personal** Codex/GPT workspaces.

**Naming:** **The Brain = masher** (merge/runtime authority). **`EV_Brain` folders/repos**, `ev_*_brain.json`, and **`Ev` git** are **not** interchangeable with “the brain” — see `docs/EV_MASHER_BRAIN_GLOSSARY.md`.

## Git remotes (your PC5000 inventory)

| Path | Remote | Role |
|------|--------|------|
| `C:\Users\Blair\EV_Git\Ev` | BlairGem1234/Ev | **Primary operator / PC5000** |
| `...\Ev-EVBot-Operator`, `...\Ev-fuzzy-on-main` | same Ev remote | Extra worktrees — pick one primary |
| `...\teaka_trading_app` | BlairGem1234/teaka_trading_app | Recovery fork + handoff scripts |
| `...\teaka_trading_app_CANONICAL`, `\_tmp_teaka_github_main` | BlairGem/teaka_trading_app | Upstream mirrors |
| `...\GEMBot29` | blairgem/GEMBot29 | Legacy sidecar |
| `...\GPT_AI_Workspace` | BlairGem1234/GPT_AI_Workspace | Personal GPT workspace git |
| `...\Pc-5000-curser-` | BlairGem1234/Pc-5000-curser- | PC5000 + Cursor ops |
| `...\MT_GREENLAND`, Green-Earth demo | geo repos | Minerals / demo |
| `D:\EV_Files\EV_Node` | evstack/ev-node | EV blockchain node |
| `D:\Dropbox\Starforge` | BlairGem/starforge | Starforge vault git |
| `...\Clock` | BlairGem1234/EV_Brain_Clock | Cloak/clock git (timezone deps) |
| `...\Cursor` | BlairGem1234/Cursor_Master | Cursor EV automation / shell rules |
| `...\Git_Satellite_Brain` | (local) | GitHub Operator **satellite** (feeds masher stack — not the masher) |
| `...\memories` | Codex git baseline | Personal Codex memories — not operator Ev |

## Google Drive / OneDrive / Dropbox

| Layer | Mapped? | How |
|-------|---------|-----|
| **Local git federation** | Yes | `ev_federation_git_scan.ps1` → `scratch\ev_federation_registry.json` |
| **Google Drive (cloud)** | Not automatic | Cloud agents need **Google Drive MCP** in Cursor, or Ev node `EV_GOOGLE_DRIVE_LAUNCHER_BRIDGE_*.json` on disk |
| **Local Drive mount** | Shallow probe | Same script searches `Google Drive`, DriveFS root, OneDrive, Dropbox for `EV_Brain`, `EV_CloudProject`, `*pc5000*` (depth-limited) |
| **Handoff folder id** | Reference only | `15kPq7T_iarOY4FCkeGptje8c4fwu5LxC` — index in Drive MCP when authenticated |

Drive is a **sync/index plane**, not a git remote. Tie-break order: **Ev `bridge/live/pc5000`** (live) → **EV_Operator** (runtime) → **Drive exports** (archive) → **GEMBot29** (legacy).

## Canonical vs legacy (from your scan)

| Layer | Where | Role |
|-------|--------|------|
| **Operator + PC5000** | `EV_Git\Ev` | Brain evidence, `bridge/live/pc5000/*`, Hello EV operator, RoboShady probes — **git truth for control plane** |
| **Trading / phone** | `EV_Git\teaka_trading_app` | Paper broker, `connect_python` **5050**, handoff scripts, cloud agent drops in `scratch\` |
| **Runtime (not git)** | `C:\EV_Operator`, `C:\EV_AI\Codex` | Cloak **5056**, clock JSON/JS, Stable Codex — **PROVEN_LIVE** in Ev evidence |
| **Legacy sidecar** | `EV_Git\GEMBot29` | Old Flask/Qwen bridge (`blairgem/GEMBot29`); **pip/Lib inside repo** — ignore pip diff noise; use for history only |
| **Vault / chain / node** | `D:\Starforge`, external **evstack/ev-node** | Spells/vault, GeoBlockchain EV stack — integrate via adapters, not TeAka monorepo |

Ev’s own **pip env** under `C:\EV_Operator\DevToolsRuntime\python_env` runs Cloak/brain tooling — separate from GEMBot29’s committed `Lib\`.

## Port snapshot (your latest run)

| Port | Your machine | Meaning |
|------|----------------|---------|
| **5056** | off after `-StopDuplicates` | Expected until you start **one** Cloak from EV Operator |
| **5057** | Docker | Not Codex |
| **5055** | python | EV auxiliary service |
| **8080** | python | Terminal/bridge |
| **11434** | ollama | Local models (5056 sidecar when Cloak up) |
| **5000** | off | Legacy GEMBot Flask label in TeAka `status_report.yaml` — not required if stack moved |

## Architecture rule (from Ev evidence)

**5056 = GEMBot/Qwen sidecar only** — not authoritative Brain/Git/filesystem queries. Cursor/cloud should use **index-first** + **Ev bridge JSON**, not treat 5056 as full brain bind.

## One-shot local commands

```powershell
cd C:\Users\blair\EV_Git\teaka_trading_app
git pull
pwsh -NoProfile -File .\scripts\run_local_handoff.ps1 -Action federation -SkipPull
pwsh -NoProfile -File .\scripts\run_local_handoff.ps1 -Action evlink -SkipPull
```

Cloud agent paths: `scratch\ev_federation_registry.json`, `scratch\ev_teaka_ev_link.json`.

## After killing duplicate Cloaks

Restart **one** lane:

```powershell
# From EV Terminal / Operator launcher you normally use, or:
& "C:\EV_Operator\DevToolsRuntime\python_env\Scripts\python.exe" "C:\EV_Operator\DevToolsRuntime\ev_devtools_cloak.py"
```

Then re-run codex audit; **5056** should show one python listener.
