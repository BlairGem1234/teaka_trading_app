#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASTE="$ROOT/scripts/PASTE_WSL_EV_HIDDEN_TOKEN_CHECK.txt"

fail() { echo "FAIL: $*" >&2; exit 1; }

[[ -f "$PASTE" ]] || fail "missing $PASTE"
mapfile -t lines < "$PASTE"
while [[ ${#lines[@]} -gt 0 && -z "${lines[-1]}" ]]; do
  unset 'lines[-1]'
done
[[ ${#lines[@]} -eq 4 ]] || fail "paste file must have exactly 4 lines, got ${#lines[@]}"
if printf '%s\n' "${lines[@]}" | grep -q '#'; then
  fail "paste file must have no comments"
fi
if printf '%s\n' "${lines[@]}" | grep -qiE 'start ev-node|docker start|KEYREGISTRY|private key|mnemonic'; then
  fail "paste must not start node or dump keys"
fi
grep -q '127.0.0.1:8545' "$PASTE" || fail "paste missing 8545"
grep -q 'NO_TRANSFER_LOGS' "$PASTE" || fail "paste missing NO_TRANSFER_LOGS"
grep -q 'ddf252ad' "$PASTE" || fail "paste missing ERC20 Transfer topic"
if grep -q '26657' "$PASTE"; then
  fail "must not touch sequencer 26657"
fi
python3 -c "import ast, pathlib; ast.parse(pathlib.Path('$PASTE').read_text().splitlines()[0][len('python3 -c '):].strip('\"'))"
echo "OK: hidden-token check is 4 lines, read-only 8545 ERC20 Transfer scan, no key dump."
