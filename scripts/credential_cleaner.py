#!/usr/bin/env python3
"""Report-first credential cleaner for TeAka.

Default mode only reports likely committed credentials. It does not print secret
values and it does not change files. Redaction requires both --apply and
--approve Blair.

Protected EV Brain artifacts are skipped by default: .zip, .exe, and paths that
look like Brain/runtime archives. This cleaner is for credentials in text files,
not EV Brain cleanup.
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

CREDENTIAL_NAMES = (
    "API_KEY",
    "SECRET_KEY",
    "PASSPHRASE",
    "TOKEN",
    "WEBHOOK_URL",
    "PASSWORD",
)

DEFAULT_SCAN_PATHS = (
    ".env.example",
    "SECRETS.md",
    "README.md",
    "api clients/telegram_api.txt",
    "scripts/credential_vault.py",
)

PROTECTED_SUFFIXES = {".exe", ".zip"}
PROTECTED_PATH_MARKERS = ("brain", "ev_brain", "ev_ai", "ollama", "gembot")
ASSIGNMENT_RE = re.compile(
    r"(?P<name>[A-Z0-9_]*(?:API_KEY|SECRET_KEY|PASSPHRASE|TOKEN|WEBHOOK_URL|PASSWORD)[A-Z0-9_]*)"
    r"(?P<sep>\s*[:=]\s*)"
    r"(?P<quote>['\"]?)"
    r"(?P<value>[^'\"\s`|]+)"
    r"(?P=quote)",
)
BULLET_SECRET_RE = re.compile(
    r"(?P<label>[-*]\s*(?:API Key|Secret|Passphrase|Token)\s*:\s*)`?(?P<value>[^`\s]+)`?",
    re.IGNORECASE,
)


@dataclass
class Finding:
    path: Path
    line_number: int
    label: str


def is_protected_path(path: Path) -> bool:
    lowered = str(path).replace("\\", "/").lower()
    if path.suffix.lower() in PROTECTED_SUFFIXES:
        return True
    return any(marker in lowered for marker in PROTECTED_PATH_MARKERS)


def should_redact_value(value: str) -> bool:
    if not value or value in {"", "<value>", "<token>", "<kucoin-api-key>"}:
        return False
    if value.startswith("$") or value.startswith("<"):
        return False
    return len(value) >= 6


def redact_line(line: str) -> tuple[str, list[str]]:
    labels: list[str] = []

    def replace_assignment(match: re.Match[str]) -> str:
        name = match.group("name")
        value = match.group("value")
        if not should_redact_value(value):
            return match.group(0)
        labels.append(name)
        quote = match.group("quote")
        return f"{name}{match.group('sep')}{quote}{quote}"

    line = ASSIGNMENT_RE.sub(replace_assignment, line)

    def replace_bullet(match: re.Match[str]) -> str:
        value = match.group("value")
        if not should_redact_value(value):
            return match.group(0)
        labels.append(match.group("label").strip())
        return f"{match.group('label')}<redacted>"

    line = BULLET_SECRET_RE.sub(replace_bullet, line)
    return line, labels


def scan_file(path: Path, apply: bool) -> list[Finding]:
    try:
        original = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return []
    except OSError:
        return []

    findings: list[Finding] = []
    output_lines: list[str] = []
    changed = False
    for idx, line in enumerate(original.splitlines(keepends=True), start=1):
        new_line, labels = redact_line(line)
        for label in labels:
            findings.append(Finding(path, idx, label))
        if new_line != line:
            changed = True
        output_lines.append(new_line)

    if apply and changed:
        path.write_text("".join(output_lines), encoding="utf-8")
    return findings


def iter_paths(args: argparse.Namespace) -> list[Path]:
    if args.paths:
        raw = args.paths
    else:
        raw = list(DEFAULT_SCAN_PATHS)
    paths: list[Path] = []
    for item in raw:
        path = Path(item)
        if path.is_dir():
            paths.extend(p for p in path.rglob("*") if p.is_file())
        else:
            paths.append(path)
    return paths


def main() -> int:
    parser = argparse.ArgumentParser(description="Report-first credential cleaner")
    parser.add_argument("paths", nargs="*", help="Files or folders to scan")
    parser.add_argument("--apply", action="store_true", help="Write redactions")
    parser.add_argument("--approve", default="", help="Required value: Blair")
    parser.add_argument(
        "--include-brain-artifacts",
        action="store_true",
        help="Allow scanning protected Brain/archive/runtime paths",
    )
    args = parser.parse_args()

    if args.apply and args.approve != "Blair":
        print("REFUSED: --apply requires --approve Blair", file=sys.stderr)
        return 2

    mode = "APPLY" if args.apply else "REPORT_ONLY"
    print(f"MODE={mode}")
    all_findings: list[Finding] = []
    skipped: list[Path] = []

    for path in iter_paths(args):
        if not path.exists():
            continue
        if is_protected_path(path) and not args.include_brain_artifacts:
            skipped.append(path)
            continue
        findings = scan_file(path, args.apply)
        all_findings.extend(findings)

    for finding in all_findings:
        print(f"FINDING file={finding.path} line={finding.line_number} label={finding.label}")
    for path in skipped:
        print(f"SKIPPED_PROTECTED file={path}")

    print(f"FINDINGS_TOTAL={len(all_findings)}")
    print(f"SKIPPED_PROTECTED_TOTAL={len(skipped)}")
    if not args.apply:
        print("NO_CHANGES_WRITTEN=true")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
