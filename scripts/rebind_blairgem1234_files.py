#!/usr/bin/env python3
"""Read-only BlairGem reference audit.

Prints a GPT notification JSON document describing owner references that
need Blair review. It never rewrites source files.
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import uuid
from datetime import datetime, timezone
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
TOOL_HUB_CONTEXT = {
    "name": "Windows Quick Command Cheat Sheet - EV (Tool Hub)",
    "drive_id": "1WBce_dHS5JI0n1JMI1GVb7A5fSKt1XLLy9-wzeWxvwQ",
    "link_brain_drive_id": "1G4Ip0-XHCDnLG1FTqbnRFe2_qfvT6Fz39cp0acEKqcw",
    "gpt_task": "Review this notification and report findings to Blair. Do not execute proposed actions without Blair approval.",
}

HISTORICAL_RE = re.compile(
    r"legacy-origin|use for history only|old Flask/Qwen bridge",
    re.IGNORECASE,
)
REFERENCE_RE = re.compile(
    r"(https://github\.com/(?:BlairGem(?!1234)|blairgem)/[A-Za-z0-9_.-]+(?:\.git)?"
    r"|git@github\.com:(?:BlairGem(?!1234)|blairgem)/[A-Za-z0-9_.-]+(?:\.git)?"
    r"|(?<![A-Za-z0-9_.-])(?:BlairGem(?!1234)|blairgem)/[A-Za-z0-9_.-]+)",
    re.IGNORECASE,
)
MAIN_SYSTEM_UNVERIFIED_REPOS = {
    "blairgem/gembot29",
}
UNVERIFIED_REPOS = {
    "blairgem/starforge",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def new_notification(source_pr: int, source_script: str) -> dict:
    return {
        "schema": "ev.gpt.notification.v1",
        "notification_id": str(uuid.uuid4()),
        "created_utc": utc_now(),
        "source_pr": source_pr,
        "source_script": source_script,
        "mode": "READ_ONLY_AUDIT",
        "approval_authority": "Blair",
        "approval_state": "NOT_APPROVED",
        "tool_hub": TOOL_HUB_CONTEXT,
        "findings": [],
        "proposed_actions": [],
        "writes_performed": [],
        "notification": {
            "stdout": True,
            "outbox_requested": False,
            "outbox_created": False,
            "outbox_path": None,
            "error": None,
        },
    }


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


def repo_key(reference: str) -> str:
    ref = reference
    ref = re.sub(r"^https://github\.com/", "", ref, flags=re.IGNORECASE)
    ref = re.sub(r"^git@github\.com:", "", ref, flags=re.IGNORECASE)
    ref = re.sub(r"\.git$", "", ref, flags=re.IGNORECASE)
    return ref.lower()


def classify_reference(reference: str, line: str) -> str:
    if HISTORICAL_RE.search(line):
        return "REPORTED"
    if repo_key(reference) in MAIN_SYSTEM_UNVERIFIED_REPOS:
        return "MAIN_SYSTEM_UNVERIFIED_MAPPING"
    if repo_key(reference) in UNVERIFIED_REPOS:
        return "UNVERIFIED"
    return "REPORTED"


def proposed_reference(reference: str) -> str | None:
    if repo_key(reference) in MAIN_SYSTEM_UNVERIFIED_REPOS or repo_key(reference) in UNVERIFIED_REPOS:
        return None
    if reference.startswith("git@github.com:"):
        return re.sub(r"git@github\.com:(?:BlairGem(?!1234)|blairgem)/", "git@github.com:BlairGem1234/", reference, flags=re.IGNORECASE)
    if "github.com/" in reference:
        return re.sub(r"github\.com/(?:BlairGem(?!1234)|blairgem)/", "github.com/BlairGem1234/", reference, flags=re.IGNORECASE)
    return re.sub(r"^(?:BlairGem(?!1234)|blairgem)/", "BlairGem1234/", reference, flags=re.IGNORECASE)


def scan_root(root: Path) -> list[dict]:
    findings: list[dict] = []
    for path in iter_files(root):
        rel = path.relative_to(root).as_posix()
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError as exc:
            findings.append(
                {
                    "type": "file_unreadable",
                    "classification": "UNREADABLE",
                    "file": rel,
                    "line": None,
                    "observed": "non-utf-8 text file",
                    "detail": str(exc),
                }
            )
            continue
        for number, line in enumerate(text.splitlines(), start=1):
            for match in REFERENCE_RE.finditer(line):
                observed = match.group(0)
                classification = classify_reference(observed, line)
                findings.append(
                    {
                        "type": "owner_reference",
                        "classification": classification,
                        "file": rel,
                        "line": number,
                        "observed": observed,
                        "proposed": proposed_reference(observed),
                    }
                )
    return findings


def action_for_finding(finding: dict) -> dict | None:
    if finding.get("type") != "owner_reference":
        return None
    proposed = finding.get("proposed")
    if not proposed:
        if finding["classification"] == "MAIN_SYSTEM_UNVERIFIED_MAPPING":
            proposed = "preserve GEMBot29 main-system route; verify alias/canonical target before any owner change"
        else:
            proposed = "preserve existing route until Blair approves verified alias or canonical target"
    else:
        proposed = f"verify BlairGem compatibility alias; only canonicalize to {proposed} with Blair approval"
    return {
        "status": "PROPOSED_ONLY",
        "operation": "verify_alias_compatibility",
        "target": finding["observed"],
        "proposed": proposed,
        "risk": "Scripts may still rely on BlairGem routes; changing repository ownership references can break access or retarget source control.",
        "evidence": {
            "classification": finding["classification"],
            "file": finding["file"],
            "line": finding["line"],
        },
    }


def append_notification(report: dict, outbox: Path | None) -> dict:
    note = report["notification"]
    if outbox is None:
        return report
    note["outbox_requested"] = True
    note["outbox_path"] = str(outbox)
    try:
        if not outbox.is_absolute():
            raise ValueError("gpt outbox path must be absolute")
        if not outbox.exists() or not outbox.is_dir():
            raise ValueError("gpt outbox path must be an existing directory")
        if outbox.name.casefold() != "outbox":
            raise ValueError("gpt outbox directory name must be outbox")
        filename = f"{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}_{report['notification_id']}.json"
        destination = outbox / filename
        note["outbox_created"] = True
        note["outbox_path"] = str(destination)
        report["writes_performed"].append(
            {
                "type": "append_only_notification",
                "path": str(destination),
                "mode": "CREATE_NEW",
            }
        )
        with open(destination, "x", encoding="utf-8") as handle:
            json.dump(report, handle, indent=2, sort_keys=True)
            handle.write("\n")
    except Exception as exc:
        note["error"] = str(exc)
    return report


def build_report(root: Path, outbox: Path | None) -> dict:
    report = new_notification(13, Path(__file__).name)
    report["findings"] = scan_root(root)
    report["proposed_actions"] = [
        action for finding in report["findings"] if (action := action_for_finding(finding))
    ]
    append_notification(report, outbox)
    return report


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=str(ROOT))
    parser.add_argument("--gpt-outbox-path")
    args = parser.parse_args()
    root = Path(args.root).resolve()
    outbox = Path(args.gpt_outbox_path) if args.gpt_outbox_path else None
    report = build_report(root, outbox)
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
