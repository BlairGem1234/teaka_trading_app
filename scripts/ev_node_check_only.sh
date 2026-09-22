#!/usr/bin/env bash
# Check-only: Evolve/ev-node / CometBFT RPC. No start, no stop, no tx, no keys.
set -u
if [[ -f "$HOME/.cargo/env" ]]; then
  # rust env is unused here; keep PATH consistent with other WSL checks
  # shellcheck source=/dev/null
  source "$HOME/.cargo/env" 2>/dev/null || true
fi

echo "CHECK ONLY — will not launch the node or containers, and will not submit txs"
echo "This is Evolve ev-node / CometBFT, not EV GEMBot, not Nanle cargo."
echo

echo "=== LISTEN 26657 / 26656 ==="
if command -v ss >/dev/null 2>&1; then
  ss -lptn 2>/dev/null | grep -E ':26657|:26656' || echo "ss: no 26657/26656"
else
  netstat -lptn 2>/dev/null | grep -E ':26657|:26656' || echo "netstat: no 26657/26656"
fi

echo
echo "=== PROCESS ==="
ps -ef | grep -E '[e]v-node|[e]vnode|[c]ometbft|[e]volve' || echo "no matching process"

echo
echo "=== BINARY ==="
command -v ev-node || echo "ev-node not on PATH"
command -v cometbft || echo "cometbft not on PATH"

echo
echo "=== DOCKER ==="
if command -v docker >/dev/null 2>&1; then
  docker ps -a --format '{{.Names}} {{.Status}} {{.Ports}}' 2>/dev/null | grep -Ei 'ev-node|evolve|comet|rollkit' || echo "docker: no ev-node/evolve/comet/rollkit container"
else
  echo "docker not on PATH"
fi

echo
echo "=== GET 127.0.0.1:26657/status ==="
if curl -sS --max-time 3 http://127.0.0.1:26657/status; then
  echo
else
  echo "DOWN"
fi

echo
echo "=== GET 127.0.0.1:26657/health ==="
if curl -sS --max-time 3 http://127.0.0.1:26657/health; then
  echo
else
  echo "HEALTH_DOWN"
fi

echo
echo "=== COMPLETE — READ ONLY ==="
echo "DOWN or missing listener means the node is not up. Do not start it from this script."
echo "Ollama stays 11434 Windows / 11435 Docker. Command 8080. No live trade. No D: repair."
