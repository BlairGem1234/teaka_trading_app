from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCANNER = ROOT / "scripts" / "rebind_blairgem1234_files.py"


def run_scanner(*args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        [sys.executable, str(SCANNER), *args],
        cwd=str(ROOT),
        text=True,
        capture_output=True,
        check=False,
    )


def load_stdout_json(result: subprocess.CompletedProcess[str]) -> dict:
    assert result.returncode == 0, result.stderr
    return json.loads(result.stdout)


class SafeNotificationTests(unittest.TestCase):
    def test_default_scan_does_not_modify_source(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            target = root / "README.md"
            target.write_text("https://github.com/BlairGem/Ev\n", encoding="utf-8")
            before = target.read_bytes()

            result = run_scanner("--root", str(root))

            self.assertEqual(target.read_bytes(), before)
            report = load_stdout_json(result)
            self.assertEqual(report["schema"], "ev.gpt.notification.v1")
            self.assertEqual(report["approval_state"], "NOT_APPROVED")
            self.assertEqual(report["mode"], "READ_ONLY_AUDIT")
            self.assertEqual(report["tool_hub"]["link_brain_drive_id"], "1G4Ip0-XHCDnLG1FTqbnRFe2_qfvT6Fz39cp0acEKqcw")
            self.assertIn("report findings to Blair", report["tool_hub"]["gpt_task"])
            self.assertEqual(report["proposed_actions"][0]["status"], "PROPOSED_ONLY")
            self.assertEqual(report["writes_performed"], [])

    def test_invalid_outbox_path_is_reported_without_creating_files(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            target = root / "README.md"
            target.write_text("https://github.com/BlairGem/Ev\n", encoding="utf-8")
            relative_outbox = "outbox"

            result = run_scanner("--root", str(root), "--gpt-outbox-path", relative_outbox)

            report = load_stdout_json(result)
            self.assertTrue(report["notification"]["outbox_requested"])
            self.assertFalse(report["notification"]["outbox_created"])
            self.assertTrue(report["notification"]["error"])
            self.assertFalse((ROOT / relative_outbox).exists())

    def test_valid_outbox_creates_one_new_notification_without_overwrite(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            target = root / "README.md"
            target.write_text("https://github.com/BlairGem/Ev\n", encoding="utf-8")
            outbox = root / "outbox"
            outbox.mkdir()

            first = load_stdout_json(run_scanner("--root", str(root), "--gpt-outbox-path", str(outbox)))
            files_after_first = sorted(outbox.iterdir())
            second = load_stdout_json(run_scanner("--root", str(root), "--gpt-outbox-path", str(outbox)))
            files_after_second = sorted(outbox.iterdir())

            self.assertTrue(first["notification"]["outbox_created"])
            self.assertTrue(second["notification"]["outbox_created"])
            self.assertEqual(len(files_after_first), 1)
            self.assertEqual(len(files_after_second), 2)
            stored = json.loads(files_after_first[0].read_text(encoding="utf-8"))
            self.assertTrue(stored["notification"]["outbox_created"])
            self.assertEqual(stored["writes_performed"][0]["mode"], "CREATE_NEW")

    def test_unreadable_text_file_is_reported_not_rewritten(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            target = root / "bad.md"
            target.write_bytes(b"https://github.com/BlairGem/Ev\xff\n")
            before = target.read_bytes()

            report = load_stdout_json(run_scanner("--root", str(root)))

            self.assertEqual(target.read_bytes(), before)
            self.assertTrue(
                any(
                    finding["classification"] == "UNREADABLE"
                    and finding["file"].endswith("bad.md")
                    for finding in report["findings"]
                )
            )

    def test_gembot29_is_preserved_main_system_and_starforge_mappings_are_unverified(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            target = root / "repos.md"
            target.write_text(
                "https://github.com/blairgem/GEMBot29\n"
                "https://github.com/BlairGem/starforge\n",
                encoding="utf-8",
            )

            report = load_stdout_json(run_scanner("--root", str(root)))

            observed = {
                action["target"]: action["evidence"]["classification"]
                for action in report["proposed_actions"]
            }
            self.assertEqual(observed["https://github.com/blairgem/GEMBot29"], "MAIN_SYSTEM_UNVERIFIED_MAPPING")
            self.assertEqual(observed["https://github.com/BlairGem/starforge"], "UNVERIFIED")


if __name__ == "__main__":
    unittest.main()
