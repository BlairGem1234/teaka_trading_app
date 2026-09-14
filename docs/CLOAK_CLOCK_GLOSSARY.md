# Cloak vs clock (“Cloak Clock” on your PC)

On your EV Terminal profile these work **together**; people often say **Cloak Clock** for the pair.

| Piece | What it is | Typical location (your banner) |
|-------|------------|--------------------------------|
| **Cloak** | Running **Python proxy** (`ev_devtools_cloak.py` or similar) between Codex/DevTools and the bridge | Under `C:\EV_Operator\`, `C:\EV_AI\Codex`, or DevTools runtime folders |
| **Clock** | **Config** that throttles / schedules Cloak traffic (`ev_clock.json`, `ev_clock_throttle.js`) | Often `Config\` + `Bridge\` under Operator or EV_AI |
| **Cloak Clock (phrase)** | **Cloak process + clock files** — not a separate app | Same stack |
| **cursor_clock_events.jsonl** | **TeAka handoff script only** — local audit log when you re-run `cursor_cloud_runtime_link.ps1 -AppendClockLog` | `teaka_trading_app\scratch\` — **not** your EV Operator clock |

**Rule of thumb:** Cloak = **process** (should be **0 or 1**, not 4). Clock = **JSON/JS settings** Cloak reads. If the handoff script says “no ev_clock at default paths”, search `C:\EV_AI` and `C:\EV_Operator` (see `scripts\ev_codex_token_audit.ps1`).

**Token burn:** Multiple **Codex.exe** (Stable + Beta) **plus** multiple **Cloak** PIDs multiply background work. Fix Cloak first, then one Codex.

**EV Terminal (your PC):** Use **Stable Codex** under `C:\EV_AI\Codex` — not the Microsoft Store **CodexBeta** app. Cloak script: `C:\EV_Operator\DevToolsRuntime\ev_devtools_cloak.py`. Port **5056** is often Cloak; **5057** on your machine may be **Docker** (`com.docker.backend.exe`), not Codex — do not kill Docker to “fix Codex.”
