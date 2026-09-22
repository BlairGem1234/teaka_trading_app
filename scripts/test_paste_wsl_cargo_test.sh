#!/usr/bin/env bash
# Validates the four-line Ubuntu cargo test paste. No cargo, no network.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASTE="$ROOT/scripts/PASTE_WSL_CARGO_TEST.txt"

fail() { echo "FAIL: $*" >&2; exit 1; }

[[ -f "$PASTE" ]] || fail "missing $PASTE"

mapfile -t lines < "$PASTE"
while [[ ${#lines[@]} -gt 0 && -z "${lines[-1]}" ]]; do
  unset 'lines[-1]'
done
[[ ${#lines[@]} -eq 4 ]] || fail "paste file must have exactly 4 lines, got ${#lines[@]}"

printf '%s\n' "${lines[@]}" | grep -q '#' && fail "paste file must have no comments"
printf '%s\n' "${lines[@]}" | grep -q '```' && fail "paste file must have no markdown fences"
printf '%s\n' "${lines[@]}" | grep -qiE 'ev-node start|cargo build --release' && fail "paste must not start node or release-build"

[[ "${lines[0]}" == 'source "$HOME/.cargo/env"' ]] || fail "line 1 must source cargo env"
[[ "${lines[1]}" == *Nanle-code-StarForge ]] || fail "line 2 must cd Nanle crate"
[[ "${lines[2]}" == 'export CARGO_TARGET_DIR=/tmp/starforge-target' ]] || fail "line 3 must set /tmp target"
[[ "${lines[3]}" == 'cargo test --test deployment_preparation_e2e --test deployment_error_handling -- --test-threads=1' ]] || fail "line 4 must be targeted cargo test"

LIST="$ROOT/scripts/PASTE_WSL_CARGO_TEST_LIST.txt"
[[ -f "$LIST" ]] || fail "missing $LIST"
mapfile -t list_lines < "$LIST"
while [[ ${#list_lines[@]} -gt 0 && -z "${list_lines[-1]}" ]]; do
  unset 'list_lines[-1]'
done
[[ ${#list_lines[@]} -eq 4 ]] || fail "list paste must have exactly 4 lines, got ${#list_lines[@]}"
[[ "${list_lines[3]}" == 'cargo test --test deployment_error_handling --test deployment_preparation_e2e -- --list ; echo EXIT:$?' ]] || fail "list paste line 4 mismatch"

HARNESS="$ROOT/scripts/PASTE_WSL_CARGO_TEST_HARNESS.txt"
[[ -f "$HARNESS" ]] || fail "missing $HARNESS"
mapfile -t harness_lines < "$HARNESS"
while [[ ${#harness_lines[@]} -gt 0 && -z "${harness_lines[-1]}" ]]; do
  unset 'harness_lines[-1]'
done
[[ ${#harness_lines[@]} -eq 4 ]] || fail "harness paste must have exactly 4 lines, got ${#harness_lines[@]}"
[[ "${harness_lines[1]}" == 'grep -n harness Cargo.toml' ]] || fail "harness paste line 2 mismatch"

HEADP="$ROOT/scripts/PASTE_WSL_CARGO_TEST_HEAD.txt"
[[ -f "$HEADP" ]] || fail "missing $HEADP"
mapfile -t head_lines < "$HEADP"
while [[ ${#head_lines[@]} -gt 0 && -z "${head_lines[-1]}" ]]; do
  unset 'head_lines[-1]'
done
[[ ${#head_lines[@]} -eq 4 ]] || fail "head paste must have exactly 4 lines, got ${#head_lines[@]}"
[[ "${head_lines[1]}" == 'ls -l tests' ]] || fail "head paste line 2 mismatch"

echo "OK: cargo test paste is 4 lines, /tmp target, two Nanle test bins only."
echo "OK: cargo test --list paste captures EXIT."
echo "OK: cargo test harness grep paste is 4 lines."
echo "OK: cargo test head paste is 4 lines."
