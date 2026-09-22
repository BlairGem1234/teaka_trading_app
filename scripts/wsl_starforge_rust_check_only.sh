#!/usr/bin/env bash
# Check-only: WSL Ubuntu Rust + Nanle StarForge crate. No cargo add, no build, no git writes.
set -euo pipefail
if [[ -f "$HOME/.cargo/env" ]]; then
  # shellcheck source=/dev/null
  source "$HOME/.cargo/env"
fi
REPO="/mnt/c/Users/Blair/EV_Git/_Upstream/StarForge/Blockchain/Nanle-code-StarForge"

echo "=== RUST ==="
command -v rustc
rustc --version
command -v cargo
cargo --version

echo
echo "=== REPO ==="
cd "$REPO"
pwd
git status --short --branch
git remote -v

echo
echo "=== CARGO FILES ==="
ls -lh Cargo.toml Cargo.lock

echo
echo "=== thiserror / migration.up|down ==="
grep -n 'thiserror' Cargo.toml || echo "[thiserror NOT declared]"
grep -nE 'migration\.(up|down)|fn (up|down)\(' src/utils/database.rs | head -30

echo
echo "=== COMPLETE — READ ONLY ==="
echo "Windows 11434 / Docker 11435 / Command 8080. Do not bind WSL Ollama on 11435."
