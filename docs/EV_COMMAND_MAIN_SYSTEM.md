# EV Command — main system

**EV Command** is the **main operator system** on PC5000: how you (and RoboShady/Codex/bridge) **issue work** to the stack. Everything else hangs off it.

```text
YOU / EV Terminal / scripts
        │
        ▼
   EV Command  ◄── main system (command plane)
        │
        ├── C EV brain (masher / master index)
        ├── EV AI (C:\EV_AI)
        ├── EV Files (D:\ / E:\EV_Files)
        ├── EV core (GeoNode, ev-reth, crypto map layers, Postgres, …)
        ├── C:\EV_Operator (clock, Cloak, DevTools python)
        ├── Ev git + bridge/live/pc5000
        ├── Starforge vault/runtime
        └── TeAka 5050 (trading bridge — adapter, not the command root)
```

## What counts as EV Command

| Kind | Typical location | Role |
|------|------------------|------|
| **Send-EVCommand.ps1** | `EV_Git\Git_Satellite_Brain\`, legacy GEMBot29 | Satellite **add-on** that forwards into the command plane |
| **EV Terminal / Operator shell** | `C:\EV_Operator`, banner paths | Primary interactive command surface |
| **Bridge HTTP command** | `http://127.0.0.1:8080`, legacy `:5000/ev_remote/command` | Machine-local command injection |
| **Ev repo operator scripts** | `Ev\scripts\`, `Ev\tools\pc5000\` | PC5000 directed checks, bootstrap, RoboShady |
| **TeAka handoff** | `teaka_trading_app\scripts\run_local_handoff.ps1` | Audit/status commands for cloud — **not** a replacement for EV Command |

**C EV brain** merges/indexes; **EV Command** is what you **run**. Satellite brain git only helps **run** C EV brain — it is not the main system.

## Check EV Command (local, read-only)

```powershell
cd C:\Users\blair\EV_Git\teaka_trading_app
git pull
pwsh -NoProfile -File .\scripts\ev_command_check.ps1
```

Or:

```powershell
pwsh -NoProfile -File .\scripts\run_local_handoff.ps1 -Action evcommand -SkipPull
```

Output: **`scratch\ev_command_status.json`**

Full stack (command + C EV brain + system map):

```powershell
pwsh -NoProfile -File .\scripts\run_local_handoff.ps1 -Action stack -SkipPull
```

(`stack` = evcommand + cbrain + coremap)

Cloud agent: point at `scratch\ev_command_status.json` — do not paste secrets or wallet material.
