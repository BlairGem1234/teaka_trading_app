#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASTE="$ROOT/scripts/PASTE_GITBASH_EV_STACK_PLACES.txt"
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
if printf '%s\n' "${lines[@]}" | grep -qiE 'cat |KEYREGISTRY|private key|mnemonic'; then
  fail "paste must not dump secrets"
fi
grep -q '/c/EV_Files' "$PASTE" || fail "must check C:/EV_Files"
if grep -q '/e/EV_Files' "$PASTE"; then
  fail "paste must not use E:/EV_Files"
fi
grep -q '/c/EV_Brain' "$PASTE" || fail "must check C:/EV_Brain"
grep -qF '0x[a-fA-F0-9]{40}' "$PASTE" || fail "must search public 0x addresses only"
echo "OK: EV stack places paste is 4 lines, names and 0x addresses only."
