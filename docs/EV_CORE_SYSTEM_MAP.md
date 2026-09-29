# EV Command + C EV brain + EV AI + EV Files + EV core

**EV Command** is the **main system** (operator command plane). **C EV brain** is the masher under it. See `docs/EV_COMMAND_MAIN_SYSTEM.md`.

Your Ev repo **`ev.full_crypto_starforge_vr_system_map.v1`** map (`EV_FULL_CRYPTO_STARFORGE_VR_SYSTEM_MAP_20260811`) describes the **full stack** C EV brain sits on top of — not just TeAka or a single git clone.

## Canonical naming

| Name | Meaning |
|------|---------|
| **C EV brain** | Masher / master index (~5M files), RoboShady + Starforge runtime |
| **`C:\EV_Brain` in the map** | **Path label** for resolver, state map, bridge routing — not a substitute name for “C EV brain” |
| **EV AI** | `C:\EV_AI` — Codex, crypto search reports, tooling |
| **EV Files** | `D:\EV_Files` / `E:\EV_Files` — node, bridge, runtime trees |
| **EV core** | Integrated layers in the map: GEMBot, Firemind, GitRuntime, Drive/Dropbox/OneDrive mirrors, Ollama/API endpoints, Postgres, GeoNode, ev-reth, Starforge vault |

C EV brain **orchestrates** these layers; the system map is the **repair/evidence index** for crypto, GPROOF, Starforge, VR (unproven branch), and ev-node signer — with **`facts_only`** and **no secrets in git**.

## Starforge + Robo in C EV brain

- **Starforge** — vault/runtime/export namespace (`D:\Dropbox\Starforge`, historical OneDrive sync paths in map).
- **RoboShady** — runtime mode probes under `Ev\bridge\live\pc5000\*roboshady*`.
- **VR/game** — map marks **UNPROVEN** until source found in Starforge/Runtime/Tools/Vault.

## Local check (no wallet/seed access)

```powershell
cd C:\Users\blair\EV_Git\teaka_trading_app
git pull
pwsh -NoProfile -File .\scripts\ev_core_system_map_check.ps1
pwsh -NoProfile -File .\scripts\run_cbrain.ps1 -StatusOnly
```

Outputs:

- `scratch\ev_core_system_map_status.json` — map header + which paths exist
- `scratch\cbrain_status.json` — C EV brain + RoboShady + Starforge probes

Optional explicit map file:

```powershell
pwsh -NoProfile -File .\scripts\ev_core_system_map_check.ps1 -MapPath "C:\Users\blair\EV_Git\Ev\brain\evidence\<your_map>.json"
```

## Map status note

Your paste shows **`"clocked": false`** on the system map — align with **`C:\EV_Operator\Config\ev_clock.json`** and Cloak when bringing C EV brain fully live.

Cloud agents: point at the two JSON files under `scratch\`; do not paste genesis addresses or seed material into chat.
