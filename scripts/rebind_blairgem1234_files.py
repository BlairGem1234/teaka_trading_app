#!/usr/bin/env python3
"""Rewrite live BlairGem owner refs to BlairGem1234 in a checkout.

Does NOT rewrite:
  - GEMBot29 / blairgem/GEMBot29 (destination unproven)
  - TeAkaTrader/* (unrelated upstream)
  - already-correct BlairGem1234/*
  - git history, logs, transcripts

Usage:
  python3 scripts/rebind_blairgem1234_files.py           # dry-run
  python3 scripts/rebind_blairgem1234_files.py --apply
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SKIP_DIR_NAMES = {
    ".git",
    "node_modules",
    "venv",
    ".venv",
    "__pycache__",
    "dist",
    "build",
}
SKIP_FILE_NAMES = {
    "rebind_blairgem1234_files.py",
    "rebind_pc_git_owner.ps1",
}
TEXT_SUFFIXES = {
    ".md",
    ".py",
    ".js",
    ".ts",
    ".tsx",
    ".json",
    ".yml",
    ".yaml",
    ".ps1",
    ".sh",
    ".txt",
    ".toml",
    ".html",
    ".css",
}
# Lines mentioning these stay untouched (destination not proven).
SKIP_LINE_RE = re.compile(r"GEMBot29", re.IGNORECASE)
# Owner/repo form: BlairGem/foo but not BlairGem1234/foo
OWNER_SLASH_RE = re.compile(r"(?<![A-Za-z0-9])BlairGem(?!1234)/")
GITHUB_OWNER_RE = re.compile(r"github\.com/BlairGem(?!1234)/", re.IGNORECASE)
GIT_SSH_RE = re.compile(r"github\.com:BlairGem(?!1234)/")


def transform_line(line: str) -> str:
    if SKIP_LINE_RE.search(line):
        return line
    line = GITHUB_OWNER_RE.sub("github.com/BlairGem1234/", line)
    line = GIT_SSH_RE.sub("github.com:BlairGem1234/", line)
    line = OWNER_SLASH_RE.sub("BlairGem1234/", line)
    return line


def transform_text(text: str) -> str:
    return "".join(transform_line(line) for line in text.splitlines(keepends=True))


def iter_files(root: Path):
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        if any(part in SKIP_DIR_NAMES for part in path.parts):
            continue
        if path.name in SKIP_FILE_NAMES:
            continue
        if path.suffix.lower() not in TEXT_SUFFIXES:
            continue
        yield path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--root", default=str(ROOT))
    args = parser.parse_args()
    root = Path(args.root).resolve()
    changed = []
    for path in iter_files(root):
        original = path.read_text(encoding="utf-8", errors="replace")
        updated = transform_text(original)
        if updated == original:
            continue
        rel = path.relative_to(root)
        changed.append(rel)
        print(f"{'WRITE' if args.apply else 'DRY '} {rel}")
        if args.apply:
            path.write_text(updated, encoding="utf-8")
    print(f"{len(changed)} file(s) {'updated' if args.apply else 'would change'}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
