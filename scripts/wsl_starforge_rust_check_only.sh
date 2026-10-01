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
echo "=== ai_doc_qa mods ==="
commands_mod=0
utils_mod=0
if [[ -f src/commands/mod.rs ]]; then
  commands_mod=$(grep -c 'pub mod ai_doc_qa' src/commands/mod.rs || true)
fi
if [[ -f src/utils/mod.rs ]]; then
  utils_mod=$(grep -c 'pub mod ai_doc_qa' src/utils/mod.rs || true)
fi
echo "src/commands/mod.rs pub mod ai_doc_qa count: ${commands_mod}"
echo "src/utils/mod.rs pub mod ai_doc_qa count: ${utils_mod}"
if [[ "${commands_mod}" -gt 1 ]]; then
  echo "WARN: duplicate pub mod ai_doc_qa in commands/mod.rs — cargo check will fail until one line is removed."
fi

echo
echo "=== CARGO CHECK TARGET ==="
export CARGO_TARGET_DIR=/tmp/starforge-target
mkdir -p "$CARGO_TARGET_DIR"
echo "CARGO_TARGET_DIR=$CARGO_TARGET_DIR"
case "$CARGO_TARGET_DIR" in
  /mnt/c/*|/mnt/d/*|/mnt/e/*)
    echo "REFUSE: target dir is on NTFS 9p. Use /tmp/starforge-target to avoid os error 5."
    exit 2
    ;;
esac

echo
echo "=== cargo check --bin starforge ==="
cargo check --bin starforge

echo
echo "=== COMPLETE — READ ONLY ==="
echo "This is Nanle StarForge, not EV GEMBot."
echo "Windows 11434 / Docker 11435 / Command 8080. Do not bind WSL Ollama on 11435."
echo "Do not start ev-node. Do not live trade. Do not repair D:."
