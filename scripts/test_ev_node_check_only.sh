#!/usr/bin/env bash
# Validates ev-node check-only paste/scripts. No network, no node start.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASTE="$ROOT/scripts/PASTE_WSL_EV_NODE_CHECK.txt"
SH="$ROOT/scripts/ev_node_check_only.sh"
PS1="$ROOT/scripts/ev_node_check_only.ps1"

fail() { echo "FAIL: $*" >&2; exit 1; }

[[ -f "$PASTE" ]] || fail "missing $PASTE"
[[ -f "$SH" ]] || fail "missing $SH"
[[ -f "$PS1" ]] || fail "missing $PS1"

mapfile -t lines < "$PASTE"
while [[ ${#lines[@]} -gt 0 && -z "${lines[-1]}" ]]; do
  unset 'lines[-1]'
done
[[ ${#lines[@]} -eq 4 ]] || fail "paste file must have exactly 4 lines, got ${#lines[@]}"
printf '%s\n' "${lines[@]}" | grep -q '#' && fail "paste file must have no comments"
printf '%s\n' "${lines[@]}" | grep -q '```' && fail "paste file must have no markdown fences"
printf '%s\n' "${lines[@]}" | grep -qiE 'start ev-node|docker start|cometbft start' && fail "paste file must not start the node"

grep -q '26657' "$PASTE" || fail "paste missing 26657"
grep -q '/status' "$PASTE" || fail "paste missing /status"

bash -n "$SH" || fail "ev_node_check_only.sh failed bash -n"
grep -q 'CHECK ONLY' "$SH" || fail "sh missing check-only banner"
if grep -E '^[[:space:]]*(docker[[:space:]]+start|ev-node[[:space:]]+start|systemctl[[:space:]]+start)' "$SH"; then
  fail "sh must not launch the node"
fi
if grep -E '^[[:space:]]*(Start-Process|docker[[:space:]]+start|ev-node[[:space:]]+start)' "$PS1"; then
  fail "ps1 must not launch the node"
fi
grep -q 'CHECK ONLY' "$PS1" || fail "ps1 missing CHECK ONLY"

echo "OK: ev-node check scripts are check-only, 26657 GET, no start."
