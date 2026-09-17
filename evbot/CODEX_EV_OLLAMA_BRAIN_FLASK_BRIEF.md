# Codex brief: EV Ollama Brain Flask (Blairspc 2026-09-17)

Give this whole file to Codex. Do not recurse `C:\Users\Blair\EV_Git\Ev`. Do not `Stop-Process` on 8080, 11434, 11435, 5060, 5432, or DevTools cloak PIDs.

## What was wrong

The live file `C:\EV_AI\Ollama\ev_ollama_brain_flask.py` and `Start-OllamaBrainFlask.ps1`:

- Default listen **8080** — that port is **EV Command Bridge** (`ev_command_8080.py`, PID 3852).
- Starter **kills whatever owns 8080** then starts Flask there. That is how Command dies.
- Extra `ollama.exe serve` if 11434 is down — third Windows Ollama starter (fights `EV_Blair_Ollama_11434`).
- No GEMBot / DevTools / RoboShady / Minerals / Command client URLs.
- `/health` mixed Ollama errors into the memory field.
- `/ask` used 180s timeout and no `think: false` — `qwen3:4b` generate already hung on this AMD 5700U.

`BlairGem1234/Ev` git (PC: `C:\Users\Blair\EV_Git\Ev`) does **not** contain a live `ev_ollama_brain_flask.py`. Tracked flask/gembot py is only under `brain/recovery/...` (snapshot). **Do not treat recovery as production.** Canonical sidecar to patch is EV_AI (and the copy in teaka `evbot/ev_ollama_brain_flask.py`).

## Winner ports (leave running)

| Port | Service | Notes |
|------|---------|--------|
| **8080** | EV Command Bridge | GET `/health` must stay Command. Flask must **never** bind or kill this. |
| **8081** | Ollama Brain Flask | **This** process listens here. |
| **11434** | Windows `ollama.exe` | `qwen3:4b` (also gemma3:4b, phi4-mini). Never autoload `qwen2.5:32b` / `qwen3-coder:30b`. |
| **11435** | Docker `ollama-docker` | `127.0.0.1:11435->11434/tcp` — `qwen2.5:3b` only. |
| **5056** | **EV DevTools Cloak** | `ev_devtools_cloak.py`. JSON: `service: EV DevTools Cloak`. **Not** `gembot_qwen_flask.py`. May use **two Python PIDs** (parent/worker). **Do not kill the non-listener.** Restart only via `C:\EV_Operator\DevToolsRuntime\Start-EVDevToolsCloak.ps1`. |
| **5060** | RoboShady | LISTENING |
| **5055** | Minerals | LISTENING |
| **5432** | Postgres | LISTENING — Flask talks via memory bridge, not raw password in source |
| **8787** | Codex | Bound **`192.168.1.20:8787`**, not 127.0.0.1 |
| **11436** | Memory/postgres bridge | **Down** — `/memory/ask` may 502; that is OK |

Scheduled tasks: keep `EV_Blair_Ollama_11434`. Keep `EV_Blair_EV_Command_8080_Start`. **Disabled:** `EV_Global_Ollama_11434`, `EV_Blair_WSL_Ollama_11435`. **Disable** `EV_Ollama_Brain_Flask` until it no longer uses 8080.

Hardware: HP 15s-eq2xxx, Ryzen 7 5700U, **AMD iGPU only — no NVIDIA**. Native generate can still timeout; Flask bind can still be PASS.

## What to add to the Flask (env + routes)

Listen **8081**. Refuse to start if `PORT==8080`.

```text
EV_OLLAMA_FLASK_PORT=8081
OLLAMA_API=http://127.0.0.1:11434
EV_BRAIN_MODEL=qwen3:4b
OLLAMA_MODELS=D:\OllamaModels
EV_DOCKER_OLLAMA=http://127.0.0.1:11435
GEMBOT_MCP=http://127.0.0.1:5056          # DevTools Cloak (name is historical)
EV_ROBOSHADY=http://127.0.0.1:5060
EV_MINERALS=http://127.0.0.1:5055
EV_COMMAND=http://127.0.0.1:8080          # client GET only
EV_MEMORY_BRIDGE=http://127.0.0.1:11436
EV_POSTGRES_HOST=127.0.0.1
EV_POSTGRES_PORT=5432
EV_CODEX=http://192.168.1.20:8787
```

Keep existing routes: `GET /health`, `GET /models`, `POST /ask`, `POST /memory/ask`.

Add:

- `GET /health` (or `/mesh`) pings Command, 11434, 11435, 5056, 5060, 5055, 11436 separately (do not overwrite fields).
- `GET|POST /gembot` and `/gembot/<path>` proxy to `GEMBOT_MCP` (5056 Cloak). Do not bind 5056.
- `GET /roboshady` ping 5060.
- `/ask`: block `30b`/`32b`; `think: false`; shorter `num_predict`/`num_ctx`; timeout ~60s.
- Start-OllamaBrainFlask.ps1: **remove** `Stop-Process` on 8080; **remove** extra `ollama serve`; set port 8081.

Reference implementation already in teaka PR: `evbot/ev_ollama_brain_flask.py`  
Test script: `scripts/ev_ollama_brain_flask_codex_test.ps1`

Copy patched py to `C:\EV_AI\Ollama\ev_ollama_brain_flask.py` then:

```powershell
$env:EV_OLLAMA_FLASK_PORT='8081'
# ... other env from table ...
python C:\EV_AI\Ollama\ev_ollama_brain_flask.py
```

Working directory `C:\EV_AI\Ollama`.

## Codex pass / fail

PASS:

- `GET http://127.0.0.1:8080/health` still EV Command Bridge (not Brain Flask).
- Flask listening **8081**; `GET /health` 200 with mesh keys.
- `GET http://127.0.0.1:5056/health` Cloak ONLINE (one or two python PIDs OK).
- No new `ollama.exe serve` spawned by Flask.

FAIL:

- Anything binds or kills 8080.
- Flask default port 8080.
- Killing DevTools cloak “duplicate” PID and 5056 going down.
- Loading 30b/32b.
- Editing Ev `brain/recovery/**` as if it were live Flask.

`/ask` timeout on 11434 is **not** a Flask bind fail on this 5700U.

## Do not confuse

- TeAka git `BlairGem1234/teaka_trading_app` ≠ Ev git `BlairGem1234/Ev`. Same owner, two repos.
- 5056 = DevTools Cloak, not GEMBot recovery flask.
- Docker 11435 and Windows 11434 are different ports; WSL Ollama task on 11435 was disabled so it would not fight Docker.
