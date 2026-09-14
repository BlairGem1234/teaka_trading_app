# C EV brain (naming)

Use this so TeAka / Cursor / PC5000 docs do not talk past each other.

## **C EV brain** (canonical name)

**C EV brain** is The Brain on PC5000 — the **masher / master index** (~**5 million** tracked files in the RoboShady + Starforge plane). Say **C EV brain**, not “EV_Brain folder” and not “Ev git repo.”

| Say | Meaning |
|-----|---------|
| **C EV brain** | Live masher / master index + RoboShady runtime; drives **EV AI**, **EV Files**, **EV core** per `ev.full_crypto_starforge_vr_system_map.v1` |
| **masher / master** | Same thing — merge + index mechanics |
| **`EV_Brain` on Drive** | Sync/archive label — **not** C EV brain |
| **`Ev` git** | Operator + PC5000 bridge — feeds C EV brain, is not the brain |

**RoboShady** runtime probes under `Ev\bridge\live\pc5000\*roboshady*` describe how that index runs. **Starforge** (`D:\Dropbox\Starforge`, vault spells) feeds the Robo/masher stack — checked by `run_cbrain.ps1` without walking every file.

When someone says “run the brain,” they mean **C EV brain** (masher + operator runtime), not “open any file called ev_brain.”

## Not the Brain (common mislabels)

| Name | What it actually is |
|------|---------------------|
| **`EV_Brain` (Drive / folders)** | Sync / archive / launcher paths (e.g. Google Drive exports, `EV_GOOGLE_DRIVE_LAUNCHER_BRIDGE_*.json`) — **mirror envs**, not separate mashers |
| **Ignis7 (`C:\EV_Brain\Ignis7`)** | Battery cycle **sim/project** EV built — **not** C EV brain |
| **Google / Dropbox / OneDrive “brain”** | Per-env **mirrors and indexes** feeding the masher — see `EV_BRAIN_ENV_LAYERS.md` |
| **`ev_virtual_brain.json` / `ev_brain_state.json` (TeAka or Ev copies)** | Snapshots or inputs the masher (or operator) may read — **not** the masher itself |
| **`Ev` git repo** | Operator + PC5000 bridge + evidence — **control plane git**, not the masher |
| **`Git_Satellite_Brain` git** | **Add-on** to help **run C EV brain** — GitHub Operator helper, not a second brain |
| **`EV_Brain_Clock` (`Clock` repo)** | Clock / timezone / throttle **git** — couples to Cloak, not brain authority |
| **5056 / GEMBot sidecar** | Qwen/Ollama advisory lane — **explicitly not** authoritative Brain queries (see Ev `CURSOR_BRAIN_BINDING` evidence) |
| **Codex / GPT `memories` repo** | Personal profile baseline — separate from system masher |

## Satellite = add-on to run C EV brain

**Git_Satellite_Brain** is **not** C EV brain. It is an **optional add-on** to **run / support C EV brain** (git mailbox, GitHub Operator, etc.).

## Practical rule on PC5000

1. **Authority for “what is true now”** → **C EV brain** + **`Ev\bridge\live\pc5000\`** + **`C:\EV_Operator`** runtime.  
2. **“Brain” in a folder name** → usually artifact or sync (`EV_Brain` on Drive), not the masher.  
3. **“Satellite”** → add-on to run the brain, not brain authority.  
4. **TeAka** → trading + `5050` + handoff `scratch\`; it **consumes** operator/masher signals, it is not the masher.

Handoff scripts (`federation`, `evlink`) map **git and ports**; they do not replace masher logic.

**Run / check C EV brain on PC:**

```powershell
cd C:\Users\blair\EV_Git\teaka_trading_app
git pull
pwsh -NoProfile -File .\scripts\run_cbrain.ps1 -StatusOnly
pwsh -NoProfile -File .\scripts\run_cbrain.ps1 -Start -WithCloak
```

Log: `scratch\cbrain_run_log.txt`. Pin a custom entry: one line in `scratch\cbrain_launcher.txt`.
