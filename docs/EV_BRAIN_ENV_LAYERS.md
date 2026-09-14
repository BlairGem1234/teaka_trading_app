# How “brain” names fit together (honest map)

You are not wrong to be unsure — the word **brain** is used for **different layers**. Only one layer is **C EV brain** (the masher). The rest are **mirrors, nodes, or project artifacts**.

## One sentence

**EV Command** runs the stack → **C EV brain (masher)** merges truth from **nodes + git + PC5000 bridge** → **Drive / Dropbox / OneDrive “brains”** are mostly **sync/resolver copies and indexes**, not separate thinking engines → **Starforge / EV stack** are **runtime + vault + chain** → things like **Ignis7** are **domain projects** stored under the `C:\EV_Brain\…` **folder tree**, not the main brain.

## Layer table

| Name you hear | What it usually is | Main brain? |
|---------------|-------------------|-------------|
| **C EV brain** | Masher / master index (~5M file index, RoboShady runtime) | **Yes — this is the one** |
| **EV Command** | Main operator command plane (Terminal, Send-EVCommand, bridges) | **Main system you run** (feeds C EV brain) |
| **`C:\EV_Brain\…` path** | Filesystem root for resolver, manifests, exports (Ignis7, Sovereign_Core, …) | **Path label**, not a second masher |
| **Google Drive “brain”** | DriveFS mirror, Cello/SQLite metrics, `EV_Brain` cloud folder | **Mirror / archive / index source** → feeds masher |
| **Dropbox “brain”** | e.g. Starforge checkout, mirror paths | **Mirror + vault git** → feeds masher |
| **OneDrive “brain”** | Legacy Starforge vault sync, old runtime sync | **Legacy mirror** → feeds masher |
| **Ev `brain/nodes/*.json`** | Config/evidence **nodes** (Geo, crypto, launcher bridges) | **Nodes into C EV brain**, not brains themselves |
| **Git_Satellite_Brain** | Add-on to **run** C EV brain (GitHub Operator) | **No** |
| **`ev_*_brain.json` snapshots** | State snapshots TeAka/Ev/Starforge may read | **Artifacts**, not the masher |
| **Ignis7** | Battery cycle **simulation / test project** under `EV_Brain\Ignis7` | **No** — product experiment, not C EV brain |
| **Starforge** | Vault, Runtime, Tools, spells, export namespace | **Runtime vault** wired **into** Robo/masher stack |
| **EV stack** (ev-node, ev-reth, GeoNode, GPROOF map) | Chain, geo-crypto, minerals evidence | **Core layers** under system map — adapters into operator |

## Do you have “a brain in every env”?

**Almost — but not as multiple mashing minds.**

```text
                    ┌─────────────────────┐
                    │     EV Command      │  ← you run this
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │   C EV brain        │  ← ONE masher / master index
                    │   (masher)          │
                    └──────────┬──────────┘
           ┌───────────────────┼───────────────────┐
           │                   │                   │
    ┌──────▼──────┐    ┌───────▼───────┐   ┌──────▼──────┐
    │ Ev git      │    │ PC5000 bridge │   │ EV_Operator │
    │ nodes +     │    │ live JSON     │   │ clock/cloak │
    │ evidence    │    │ RoboShady     │   │ python      │
    └──────┬──────┘    └───────────────┘   └─────────────┘
           │
    ┌──────▼──────────────────────────────────────────┐
    │  Mirrors (each env has a *copy/index*, not      │
    │  a second masher):                              │
    │  Google Drive │ Dropbox │ OneDrive │ local C:\  │
    └──────┬──────────────────────────────────────────┘
           │
    ┌──────▼──────┐     ┌─────────────┐     ┌──────────┐
    │ Starforge   │     │ EV AI       │     │ EV Files │
    │ vault/runtime     │ C:\EV_AI    │     │ D/E:\    │
    └─────────────┘     └─────────────┘     └──────────┘
           │
    ┌──────▼──────┐
    │ Ignis7,     │  ← projects / sims / evidence folders
    │ minerals,   │     under EV_Brain path or repos
    │ crypto map  │
    └─────────────┘
```

So: **every env can hold brain-related files**; **C EV brain** is where they get **resolved and merged** for “what’s true on PC5000 now.” Cloud-only agents do **not** see Drive/Dropbox unless MCP/sync or you drop JSON in `scratch\`.

## What to run when you’re confused (PC5000)

```powershell
cd C:\Users\blair\EV_Git\teaka_trading_app
git pull
pwsh -NoProfile -File .\scripts\run_local_handoff.ps1 -Action stack -SkipPull
```

| Output | Tells you |
|--------|-----------|
| `scratch\ev_command_status.json` | EV Command entry points |
| `scratch\cbrain_status.json` | C EV brain + RoboShady + Starforge probes |
| `scratch\ev_core_system_map_status.json` | EV AI, EV Files, crypto/Starforge map header |
| `scratch\ev_federation_registry.json` | All EV_Git clones + local Drive mount probe |
| `scratch\ev_teaka_ev_link.json` | TeAka ↔ Ev bridge |

Tell the cloud agent those paths (or paste the JSON files once).

## Ignis7 (your note)

**Ignis7 = battery project EV created** (cycle sim, CSV vs Tesla). It lives under **`C:\EV_Brain\Ignis7`** because that’s the **export tree name**, not because Ignis7 **is** C EV brain. Keep sim outputs as **Ignis7 evidence**, not operator truth.

## Related docs

- `EV_MASHER_BRAIN_GLOSSARY.md` — C EV brain vs mislabels  
- `EV_COMMAND_MAIN_SYSTEM.md` — EV Command first  
- `EV_CORE_SYSTEM_MAP.md` — full crypto / Starforge / VR map  
- `EV_FEDERATION_MAP.md` — git remotes on PC5000  
