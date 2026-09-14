# TeAka + Ev — why both exist (two-repo map)

You are not imagining a split: **trading / paper / dashboard** live mainly in **TeAka**, while **operator, PC5000 bridge, GemBot stack, RoboShady runtime** live in private **`Ev`**. They talk through **bridge JSON**, **Flask ports**, and shared **brain** files — not one monorepo.

## Roles

| Repo | Local path (yours) | Job |
|------|-------------------|-----|
| **teaka_trading_app** | `C:\Users\blair\EV_Git\teaka_trading_app` | Paper broker, `connect_python.py` (**5050**), BoltBuddy merge target, EV *stubs* (`ev_*.py`, `ev_virtual_brain.json`, `status_report.yaml`), handoff scripts in `scripts/`. |
| **Ev** | `C:\Users\blair\EV_Git\Ev` | Hello EV operator, **PC5000** live bridge (`bridge/live/pc5000/`), GemBot stack probes, Codex handoff drops, brain nodes, reconstruction evidence. |

Deep-diving TeAka alone shows **how trading and the phone bridge work**. Deep-diving **Ev** shows **why EV “works” on the PC** (runtime mode, GemBot stack, cross-device brain). Together they explain the full loop.

## How they connect (conceptual)

```text
Phone / LAN  ──►  TeAka connect_python :5050  ──►  paper_trading / brain candidates
                           │
                           ▼
              bridge/brain (Cross_device_brain.json)
                           │
     Ev repo  ◄── bridge/live/pc5000/*.json  ──►  PC5000 / Codex / GemBot probes
                           │
              C:\EV_Operator (Cloak/Clock) + C:\EV_AI\Codex (Stable)
                           │
              status_report.yaml (TeAka copy): Flask :5000 EV Cloud ↔ GEMBot
```

- **TeAka** `connect_python.py` loads brain from `bridge/brain/`, repo `ev_virtual_brain.json`, or `E:\EV_Files\ev_virtual_brain.json`.
- **Ev** untracked `bridge/live/pc5000/pc5000_brain_gembot_stack_probe_*.json` is your **live stack truth** on the machine (newer than git).
- **GEMBotSys** `EV_Link\GemBot\` is legacy layout; **`EV_Git\Ev`** is the git-backed operator repo you found.

## What to run locally (one small file for cloud)

```powershell
cd C:\Users\blair\EV_Git\teaka_trading_app
git pull
pwsh -NoProfile -File .\scripts\ev_teaka_ev_bridge_summary.ps1
```

Output: **`scratch\ev_teaka_ev_link.json`** — tell the cloud agent that path only.

## Cloud agent limits

This VM can read **teaka_trading_app** on GitHub. **`BlairGem1234/Ev` is private** — the agent only sees Ev when you drop summaries under `teaka_trading_app\scratch\` or commit sanitized bridge excerpts.
