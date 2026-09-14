# EV Cloak, Codex, and token burn (local Windows)

Notes recovered from your **web** cloud chat (“Build environment setup”) and **Desktop** threads.  
This cloud agent **cannot** run Cloak on your PC or change Cursor’s billing — it can only document fixes and ship audit scripts in the repo.

## Two different meanings of “cloak”

| Meaning | Where it runs | What it does |
|--------|----------------|--------------|
| **EV Cloak** (`ev_devtools_cloak.py`) | Your Windows box under `C:\EV_Operator\` | Local DevTools / bridge layer between Codex and your EV stack (ports often **5056** / **5057**). Not part of TeAka git. |
| **“Cloak this chat” (Cursor cloud)** | cursor.com agents | **No separate cloak product.** Context = this thread + repo checkout + what you paste. To limit exposure: narrow agent scope, use `.cursorignore`, avoid pasting huge logs, use `scratch/*.txt` + path references. |

Cloud chats (this one included) **do not** attach to EV Cloak automatically. Desktop agent + local PowerShell is the right place to fix duplicate Cloak/Codex processes.

## What we know about Codex using too many tokens

From your prior session (symptoms you described):

1. **Two Cloak processes** — duplicate `ev_devtools_cloak.py` (Stable + Beta or double-start).
2. **Two Codex channels** — Stable and Beta both active → **double** context / API traffic.
3. **Throttle config** — `C:\EV_Operator\Config\ev_clock.json` and `C:\EV_Operator\Bridge\ev_clock_throttle.js` (exact folder names may vary; audit script searches under `EV_Operator`).
4. **Huge pastes into Cursor** — full mirror Downloads listings, DMG trees, etc. burn **Cursor** tokens fast (separate from Codex, same wallet pain).

Beta Codex was **stopped** in that thread; open item was confirming **Stable-only** Cloak wiring and clock throttle values.

## Fix pattern (local, in order)

1. **One Cloak, one Codex path**  
   - Kill duplicate Python processes whose command line contains `ev_devtools_cloak` or `codex`.  
   - Leave **one** listener on **5056** OR **5057**, not both stacks unless you intentionally run two profiles.

2. **Apply clock throttle**  
   - Open `ev_clock.json` — look for interval/ms, max batch, or “throttle” keys.  
   - Ensure `ev_clock_throttle.js` is the file your Stable Codex hook actually loads (not an old copy under GEMBotSys).

3. **Stop context bombs**  
   - Codex/Cursor: send summaries, not full `Get-ChildItem -Recurse` dumps.  
   - Use `scripts\fing_diagnose.ps1 -SaveTo scratch\...` pattern for diagnostics.

4. **Split threads**  
   - **Cloud agent**: TeAka repo, docs, PRs.  
   - **Desktop agent**: `C:\EV_Operator\`, Fing, Cloak, Codex Stable hooks.

## Link cloud chats + runtime on your PC (PowerShell)

This does **not** merge Cursor threads in the cloud. It **registers** agent URLs locally, snapshots Cloak/clock/ports, and writes small JSON you can point agents at.

```powershell
cd C:\Users\blair\EV_Git\teaka_trading_app
git pull
pwsh -File scripts\cursor_cloud_runtime_link.ps1 -AppendClockLog -RunCodexAudit
```

Optional: open both agent pages in the browser:

```powershell
pwsh -File scripts\cursor_cloud_runtime_link.ps1 -OpenLinks
```

Add a **new** cloud run from its URL (`bc-...` id):

```powershell
pwsh -File scripts\cursor_cloud_runtime_link.ps1 -RegisterBcId bc-YOUR-ID-HERE -RegisterName "My thread"
```

Outputs:

| File | Purpose |
|------|---------|
| `scratch/cursor_agent_registry.json` | Your linked agent bcIds + names |
| `scratch/cursor_cloud_runtime.json` | Latest runtime + Cloak count + clock paths |
| `scratch/cursor_clock_events.jsonl` | Append-only “clock” log each run (with `-AppendClockLog`) |
| `bridge/inbox/CURSOR_CLOUD_RUNTIME_*.json` | Copy for TeAka audit |

## Audit on your PC

```powershell
cd C:\Users\blair\EV_Git\teaka_trading_app
git pull
pwsh -File scripts\ev_codex_token_audit.ps1 -SaveTo scratch\codex_audit.txt
```

Paste back **only** the summary section (process count, ports, clock file paths) — not the full file.

## TeAka repo (token-aware context)

| File | Role |
|------|------|
| `evbot/ev_viral_brain.json` | Mentions condensing context for token limits (brain metadata, not Cloak) |
| `docs/EV_LOCAL_SESSION_HANDOFF.md` | Fing + mirror + Cloak pointer |
| `bridge/inbox/` | Drop small JSON diagnostics instead of chat pastes |

## If Cloak files are missing

If audit finds no `ev_devtools_cloak.py` under `C:\EV_Operator\`, check:

- `C:\Users\GEMBotSys\EV_Link\` (legacy EV_Link tree)
- Desktop / Downloads copies from older GEMBot exports

Do **not** commit API keys or Codex tokens into this repo.
