from __future__ import annotations

import importlib
import io
import json
import os
import sys
import tempfile
import unittest
import types
from contextlib import redirect_stdout
from pathlib import Path
from unittest import mock


MODULE_NAME = "evbot.ev_ollama_brain_flask"


def import_brain_with_log_dir(path: Path):
    sys.modules.pop(MODULE_NAME, None)
    fake_requests = types.SimpleNamespace(get=lambda *a, **k: None, post=lambda *a, **k: None)

    class FakeFlask:
        def __init__(self, name: str):
            self.name = name

        def get(self, _rule: str):
            return lambda func: func

        def post(self, _rule: str):
            return lambda func: func

        def route(self, *_args, **_kwargs):
            return lambda func: func

        def run(self, *_args, **_kwargs):
            return None

    fake_flask = types.SimpleNamespace(
        Flask=FakeFlask,
        jsonify=lambda *args, **kwargs: args[0] if args else kwargs,
        request=types.SimpleNamespace(
            get_json=lambda silent=True: {},
            method="GET",
            args={},
        ),
    )
    fake_modules = {
        "requests": fake_requests,
        "flask": fake_flask,
    }
    with mock.patch.dict(sys.modules, fake_modules), mock.patch.dict(os.environ, {"EVBOT_LOG_DIR": str(path)}, clear=False):
        return importlib.import_module(MODULE_NAME)


class OllamaBrainFlaskTests(unittest.TestCase):
    def test_import_does_not_create_missing_log_directory(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            missing = Path(td) / "missing_logs"

            import_brain_with_log_dir(missing)

            self.assertFalse(missing.exists())

    def test_log_emits_common_schema_event_to_stdout(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            module = import_brain_with_log_dir(Path(td) / "missing_logs")
            stream = io.StringIO()

            with redirect_stdout(stream):
                module._log({"kind": "ask", "ok": True})

            event = json.loads(stream.getvalue())
            self.assertEqual(event["schema"], "ev.gpt.notification.v1")
            self.assertEqual(event["approval_state"], "NOT_APPROVED")
            self.assertEqual(event["source_script"], "ev_ollama_brain_flask.py")
            self.assertEqual(event["tool_hub"]["link_brain_drive_id"], "1G4Ip0-XHCDnLG1FTqbnRFe2_qfvT6Fz39cp0acEKqcw")
            self.assertIn("report findings to Blair", event["tool_hub"]["gpt_task"])
            self.assertEqual(event["findings"][0]["kind"], "ask")

    def test_port_8080_refusal_can_be_checked_without_starting_server(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            module = import_brain_with_log_dir(Path(td) / "missing_logs")

            with self.assertRaises(SystemExit):
                module.validate_port(8080)
            self.assertEqual(module.validate_port(8081), 8081)

    def test_generation_options_are_bounded_and_model_is_case_insensitive(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            module = import_brain_with_log_dir(Path(td) / "missing_logs")

            model, options = module.validate_generation_request(
                {"model": "QWEN3:4B", "num_ctx": "999999", "num_predict": "999999"}
            )

            self.assertEqual(model, "qwen3:4b")
            self.assertLessEqual(options["num_ctx"], module.MAX_NUM_CTX)
            self.assertLessEqual(options["num_predict"], module.MAX_NUM_PREDICT)
            with self.assertRaises(ValueError):
                module.validate_generation_request({"model": "qwen3-coder:30b"})


if __name__ == "__main__":
    unittest.main()
