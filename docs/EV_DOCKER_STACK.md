# Docker + EV stack (PC5000)

**Docker is not C EV brain.** It runs **EV core** pieces (often **ev-reth** / **ev-node**) from your system map. Port **5057** is usually **Docker backend** — do not confuse with Codex **5056**.

## Quick start

1. **Open Docker Desktop**

```powershell
pwsh -NoProfile -File .\scripts\ev_docker_stack_check.ps1 -StartDesktop
```

Wait until the whale icon is steady (~30–60s).

2. **Check engine + containers + compose files**

```powershell
pwsh -NoProfile -File .\scripts\ev_docker_stack_check.ps1
```

Output: `scratch\ev_docker_stack_status.json`

3. **Start compose stack** (if a compose file is found under `D:\EV_Files\EV_Node` or Ev)

```powershell
pwsh -NoProfile -File .\scripts\ev_docker_stack_check.ps1 -ComposeUp
```

Or manually from your ev-reth / EV_Node folder:

```powershell
cd D:\EV_Files\EV_Node
docker compose up -d
docker ps
```

4. **Then run operator stack** (EV Command + C EV brain — not inside Docker)

```powershell
pwsh -NoProfile -File .\scripts\run_stack.ps1
```

## Map references (from your Ev evidence)

| Item | Typical value |
|------|----------------|
| EV Node git | `D:\EV_Files\EV_Node` → `evstack/ev-node` |
| Docker network | `evolveevm_evolve-network` |
| ev-reth RPC | `http://127.0.0.1:8545` (when container is up) |
| Prior chain id evidence | `0x4d2` (chat/audit — re-verify live) |

## Order of operations

```text
Docker Desktop up  →  ev-reth/ev-node containers  →  EV Command  →  C EV brain (masher)
TeAka :5050        →  cross-device phone brain      (parallel, not in Docker)
```

Cloud agent: `scratch\ev_docker_stack_status.json` + `scratch\cbrain_status.json`.
