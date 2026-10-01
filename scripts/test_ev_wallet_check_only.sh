#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASTE="$ROOT/scripts/PASTE_WSL_EV_WALLET_CHECK.txt"
fail() { echo "FAIL: $*" >&2; exit 1; }
[[ -f "$PASTE" ]] || fail "missing $PASTE"
mapfile -t lines < "$PASTE"
while [[ ${#lines[@]} -gt 0 && -z "${lines[-1]}" ]]; do
  unset 'lines[-1]'
done
[[ ${#lines[@]} -eq 4 ]] || fail "paste must have exactly 4 lines, got ${#lines[@]}"
if printf '%s\n' "${lines[@]}" | grep -q '#'; then
  fail "paste must have no comments"
fi
if printf '%s\n' "${lines[@]}" | grep -qiE 'start ev-node|KEYREGISTRY|private key|mnemonic|genesis.json'; then
  fail "paste must not dump keys"
fi
grep -q 'eth_accounts' "$PASTE" || fail "missing eth_accounts"
grep -q 'eth_coinbase' "$PASTE" || fail "missing eth_coinbase"
grep -q '127.0.0.1:8545' "$PASTE" || fail "missing 8545"
if grep -q '26657' "$PASTE"; then
  fail "must not touch sequencer"
fi
echo "OK: wallet check is 4 lines, read-only eth_accounts/coinbase, no key dump."
