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

## If you see EXT4 / `iget: checksum invalid` in Docker logs

That output is from **inside Docker Desktop’s WSL2 VM** (`docker-desktop` / `nbd0` / `sdf` ~1 TiB virtual disk). It means the **Docker Linux disk image is corrupted or was mounted `noload` while tools (`find`, `python3`, `du`) scanned it**. It is **not** C EV brain, not TeAka, not `C:\EV_Brain` on Windows NTFS.

**Normal noise (ignore):** `hvc0` / securetty, `FS-Cache: Duplicate cookie`, `tmpfs: Unknown parameter 'noswap'`, `Pacific/Auckland tzdata`, `CheckConnection: v4 succeeded`, docker0/cni0 veth up/down when containers restart.

**Do not** stay logged in at `docker-desktop login: root` for EV work — use **Windows PowerShell** + `docker` CLI.

### Fix order (Windows host)

1. **Stop scanning the broken mount** — close anything running `find`/`du` over Docker’s internal ext4 from WSL.

2. **Restart WSL + Docker**

```powershell
wsl --shutdown
# Start Docker Desktop from the tray / Start menu; wait until Engine running
docker info
docker ps -a
```

3. **If `docker info` fails or containers keep dying** — Docker Desktop → **Settings → Troubleshoot** → **Restart Docker Desktop**. If still broken: **Clean / Purge data** or **Reset to factory defaults** (removes local images/containers — git repos on `C:\` / `D:\EV_Files` are untouched).

4. **Recreate EV stack** after engine is healthy:

```powershell
cd D:\EV_Files\EV_Node   # if that is your compose tree
docker compose down
docker compose up -d
```

5. **Run operator stack on Windows** (always):

```powershell
cd C:\Users\blair\EV_Git\teaka_trading_app
pwsh -NoProfile -File .\scripts\run_stack.ps1
```

### Do not run `e2fsck` inside `docker-desktop` unless Docker support/docs say so

Manual fsck on Docker’s internal VHDX can make things worse. Prefer **WSL shutdown + Docker reset** or **move disk image** (Settings → Resources → Advanced) after backup of anything you still need from containers.

Until the disk is clean, treat **Docker EV chain (8545)** as **untrusted**; **C EV brain / EV Command on `C:\`** can still be checked with `run_stack.ps1`.
