#!/usr/bin/env bash
# Check-only: Nanle StarForge git identity for the crypto crate.
# No remote set-url, no commit, no push, no ev-node start, no GEMBot29 rebind.
set -u

echo "CHECK ONLY — will not change remotes, commit, push, or start ev-node"
echo "This is Nanle-code/StarForge git, not EV GEMBot, not Teaka, not Evolve ev-node."
echo

REPO=""
for d in \
  "/c/Users/Blair/EV_Git/_Upstream/StarForge/Blockchain/Nanle-code-StarForge" \
  "/mnt/c/Users/Blair/EV_Git/_Upstream/StarForge/Blockchain/Nanle-code-StarForge"
 do
  if [[ -d "$d/.git" || -f "$d/.git" ]]; then
    REPO="$d"
    break
  fi
done

if [[ -z "$REPO" ]]; then
  echo "Nanle crate path not found. Run this from Git Bash or WSL Ubuntu."
  echo "Git Bash: /c/Users/Blair/EV_Git/_Upstream/StarForge/Blockchain/Nanle-code-StarForge"
  echo "WSL:      /mnt/c/Users/Blair/EV_Git/_Upstream/StarForge/Blockchain/Nanle-code-StarForge"
  exit 1
fi

cd "$REPO" || exit 1
echo "=== REPO ==="
pwd
git rev-parse --show-toplevel
git rev-parse --abbrev-ref HEAD

echo
echo "=== REMOTES ==="
git remote -v
ORIGIN=$(git config --get remote.origin.url || true)
echo "origin.url=$ORIGIN"
EXPECT="https://github.com/Nanle-code/StarForge.git"
if [[ "$ORIGIN" == "$EXPECT" || "$ORIGIN" == "git@github.com:Nanle-code/StarForge.git" ]]; then
  echo "SORT: origin is Nanle-code/StarForge"
else
  echo "SORT: origin is NOT Nanle-code/StarForge"
  echo "Expected: $EXPECT"
  echo "Do not invent a StarForge GitHub repo. Do not set-url unless asked."
fi

echo
echo "=== STATUS ==="
git status -sb

echo
echo "=== BRANCH ==="
git branch -vv

echo
echo "=== LOG ==="
git log -5 --oneline --decorate

echo
echo "=== NOT THIS REPO ==="
echo "Teaka:    BlairGem1234/teaka_trading_app"
echo "GEMBot29: do not rebind remotes unless asked"
echo "ev-node:  leave down, do not start"
echo "Ollama:   11434 Windows / 11435 Docker"

echo
echo "=== COMPLETE — READ ONLY ==="
echo "This script changed nothing."
