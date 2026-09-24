#!/usr/bin/env bash
# Validates the four-line Ubuntu paste file. No cargo, no network.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASTE="$ROOT/scripts/PASTE_WSL_CARGO_CHECK.txt"
SCRIPT="$ROOT/scripts/wsl_starforge_rust_check_only.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }

[[ -f "$PASTE" ]] || fail "missing $PASTE"
[[ -f "$SCRIPT" ]] || fail "missing $SCRIPT"

mapfile -t lines < "$PASTE"
# Drop a possible trailing empty line from the file ending newline.
while [[ ${#lines[@]} -gt 0 && -z "${lines[-1]}" ]]; do
  unset 'lines[-1]'
done
[[ ${#lines[@]} -eq 4 ]] || fail "paste file must have exactly 4 lines, got ${#lines[@]}"

printf '%s\n' "${lines[@]}" | grep -q '#' && fail "paste file must have no comments"
printf '%s\n' "${lines[@]}" | grep -q '```' && fail "paste file must have no markdown fences"
printf '%s\n' "${lines[@]}" | grep -qiE 'you want|stop leftover|finished' && fail "paste file contains chat prose"

[[ "${lines[0]}" == 'source "$HOME/.cargo/env"' ]] || fail "line 1 must source cargo env"
[[ "${lines[1]}" == *Nanle-code-StarForge ]] || fail "line 2 must cd Nanle crate"
[[ "${lines[2]}" == 'export CARGO_TARGET_DIR=/tmp/starforge-target' ]] || fail "line 3 must set /tmp target"
[[ "${lines[3]}" == 'cargo check --bin starforge' ]] || fail "line 4 must be cargo check --bin starforge"

bash -n "$SCRIPT" || fail "wsl_starforge_rust_check_only.sh failed bash -n"
grep -q 'CARGO_TARGET_DIR=/tmp/starforge-target' "$SCRIPT" || fail "script missing /tmp target"
grep -q 'cargo check --bin starforge' "$SCRIPT" || fail "script missing cargo check"
grep -q 'pub mod ai_doc_qa' "$SCRIPT" || fail "script missing ai_doc_qa duplicate check"

echo "OK: paste file is 4 lines, no comments, /tmp target, cargo check only."
