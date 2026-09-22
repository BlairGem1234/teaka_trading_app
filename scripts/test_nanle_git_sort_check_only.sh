#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GB="$ROOT/scripts/PASTE_GITBASH_NANLE_GIT_SORT.txt"
WSL="$ROOT/scripts/PASTE_WSL_NANLE_GIT_SORT.txt"
SH="$ROOT/scripts/nanle_git_sort_check_only.sh"

fail() { echo "FAIL: $*" >&2; exit 1; }

count4() {
  local f="$1"
  mapfile -t lines < "$f"
  while [[ ${#lines[@]} -gt 0 && -z "${lines[-1]}" ]]; do
    unset 'lines[-1]'
  done
  [[ ${#lines[@]} -eq 4 ]] || fail "$f must have exactly 4 lines, got ${#lines[@]}"
  if printf '%s\n' "${lines[@]}" | grep -q '#'; then
    fail "$f must have no comments"
  fi
  if printf '%s\n' "${lines[@]}" | grep -qiE 'set-url|git push|git commit'; then
    fail "$f must not write git"
  fi
}

count4 "$GB"
count4 "$WSL"
grep -q '/c/Users/Blair/' "$GB" || fail "gitbash paste must cd /c/Users/Blair"
grep -q '/mnt/c/Users/Blair/' "$WSL" || fail "wsl paste must cd /mnt/c"
bash -n "$SH" || fail "nanle_git_sort_check_only.sh failed bash -n"
grep -q 'will not change remotes' "$SH" || fail "sh missing check-only banner"
if grep -E '^[[:space:]]*git (push|commit|remote set-url)' "$SH"; then
  fail "sh must not write git"
fi

COMMIT_WSL="$ROOT/scripts/PASTE_WSL_NANLE_GIT_COMMIT_LOCAL.txt"
COMMIT_GB="$ROOT/scripts/PASTE_GITBASH_NANLE_GIT_COMMIT_LOCAL.txt"
[[ -f "$COMMIT_WSL" ]] || fail "missing $COMMIT_WSL"
[[ -f "$COMMIT_GB" ]] || fail "missing $COMMIT_GB"
grep -q 'git checkout -b local/cargo-check-fixes' "$COMMIT_WSL" || fail "wsl commit paste missing local branch"
if grep -q 'git push' "$COMMIT_WSL"; then
  fail "commit paste must not push"
fi
grep -q 'git add Cargo.toml Cargo.lock src/commands/mod.rs src/utils/database.rs src/utils/mod.rs' "$COMMIT_WSL" || fail "commit paste must add only the five compile-fix files"

echo "OK: Nanle git sort pastes are 4 lines, check-only, Git Bash + WSL."
echo "OK: local commit pastes do not push to Nanle origin."
