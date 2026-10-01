#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASTE="$ROOT/scripts/PASTE_WSL_EV_TRADE_CHECK.txt"
SH="$ROOT/scripts/ev_trade_check_only.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }

[[ -f "$PASTE" ]] || fail "missing $PASTE"
[[ -f "$SH" ]] || fail "missing $SH"

mapfile -t lines < "$PASTE"
while [[ ${#lines[@]} -gt 0 && -z "${lines[-1]}" ]]; do
  unset 'lines[-1]'
done
[[ ${#lines[@]} -eq 4 ]] || fail "paste file must have exactly 4 lines, got ${#lines[@]}"
if printf '%s\n' "${lines[@]}" | grep -q '#'; then
  fail "paste file must have no comments"
fi
if printf '%s\n' "${lines[@]}" | grep -q '```'; then
  fail "paste file must have no markdown fences"
fi
if printf '%s\n' "${lines[@]}" | grep -qiE 'start ev-node|docker start|cometbft start|init genesis|reset'; then
  fail "paste file must not start or reset the node"
fi

grep -q '127.0.0.1:8545' "$PASTE" || fail "paste missing reth 8545"
grep -q 'NO_TX_IN_SAMPLE' "$PASTE" || fail "paste missing NO_TX_IN_SAMPLE"
grep -q 'DONE_READ_ONLY' "$PASTE" || fail "paste missing DONE_READ_ONLY"
if grep -q '26657' "$PASTE"; then
  fail "trade check must not touch sequencer 26657"
fi

python3 -c "import ast, pathlib; ast.parse(pathlib.Path('$PASTE').read_text().splitlines()[0][len('python3 -c '):].strip('\"'))"

bash -n "$SH" || fail "ev_trade_check_only.sh failed bash -n"
grep -q 'CHECK ONLY' "$SH" || fail "sh missing check-only banner"
if grep -E '^[[:space:]]*(docker[[:space:]]+start|ev-node[[:space:]]+start|systemctl[[:space:]]+start)' "$SH"; then
  fail "sh must not launch the node"
fi

echo "OK: ev trade check pastes are 4 lines, read-only 8545 sample, no start."
