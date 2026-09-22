# EV Ollama Brain/Memory Flask sidecar.
# Listen:  http://127.0.0.1:8081   (NEVER 8080 -- that is EV Command Bridge)
# Model:   qwen3:4b only by default.

from __future__ import annotations

import json
import os
import uuid
from datetime import datetime, timezone

import requests
from flask import Flask, jsonify, request

app = Flask(__name__)

OLLAMA = os.environ.get("OLLAMA_API", "http://127.0.0.1:11434").rstrip("/")
MEMORY = os.environ.get("EV_MEMORY_BRIDGE", "http://127.0.0.1:11436").rstrip("/")
GEMBOT = os.environ.get("GEMBOT_MCP", "http://127.0.0.1:5056").rstrip("/")
SHADY = os.environ.get("EV_ROBOSHADY", "http://127.0.0.1:5060").rstrip("/")
MINERALS = os.environ.get("EV_MINERALS", "http://127.0.0.1:5055").rstrip("/")
COMMAND = os.environ.get("EV_COMMAND", "http://127.0.0.1:8080").rstrip("/")
DOCKER_OLLAMA = os.environ.get("EV_DOCKER_OLLAMA", "http://127.0.0.1:11435").rstrip("/")
MODEL = os.environ.get("EV_BRAIN_MODEL", "qwen3:4b").casefold()
PORT = int(os.environ.get("EV_OLLAMA_FLASK_PORT", "8081"))
ALLOWED_MODELS = {MODEL, "qwen3:4b"}
MAX_NUM_PREDICT = 256
MAX_NUM_CTX = 4096
TOOL_HUB_CONTEXT = {
    "name": "Windows Quick Command Cheat Sheet - EV (Tool Hub)",
    "drive_id": "1WBce_dHS5JI0n1JMI1GVb7A5fSKt1XLLy9-wzeWxvwQ",
    "link_brain_drive_id": "1G4Ip0-XHCDnLG1FTqbnRFe2_qfvT6Fz39cp0acEKqcw",
    "gpt_task": "Review this notification and report findings to Blair. Do not execute proposed actions without Blair approval.",
}


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def emit_event(event: dict) -> None:
    payload = {
        "schema": "ev.gpt.notification.v1",
        "notification_id": str(uuid.uuid4()),
        "created_utc": utc_now(),
        "source_pr": 19,
        "source_script": "ev_ollama_brain_flask.py",
        "mode": "READ_ONLY_AUDIT",
        "approval_authority": "Blair",
        "approval_state": "NOT_APPROVED",
        "tool_hub": TOOL_HUB_CONTEXT,
        "findings": [event],
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
    print(json.dumps(payload, ensure_ascii=False), flush=True)


def _log(event: dict) -> None:
    emit_event(event)


def validate_port(port: int) -> int:
    if int(port) != 8081:
        raise SystemExit("Refusing to bind non-8081 port -- EV Command Bridge owns 8080 and this sidecar is fixed to 8081")
    return int(port)


PORT = validate_port(PORT)


def bounded_int(value, default: int, minimum: int, maximum: int) -> int:
    try:
        number = int(value)
    except (TypeError, ValueError):
        number = default
    return max(minimum, min(maximum, number))


def validate_generation_request(data: dict) -> tuple[str, dict]:
    model = (data.get("model") or MODEL).strip().casefold()
    if model not in {m.casefold() for m in ALLOWED_MODELS}:
        raise ValueError("model blocked; use qwen3:4b")
    options = {
        "num_predict": bounded_int(data.get("num_predict"), 64, 1, MAX_NUM_PREDICT),
        "num_ctx": bounded_int(data.get("num_ctx"), 2048, 128, MAX_NUM_CTX),
    }
    return model, options


def safe_error(exc: Exception) -> str:
    text = str(exc)
    for marker in ("token=", "key=", "password=", "secret="):
        if marker in text.casefold():
            return "upstream error redacted"
    return text[:240]


def _ping(url: str, timeout: float = 3.0) -> dict:
    try:
        r = requests.get(url, timeout=timeout)
        body = None
        try:
            body = r.json()
        except Exception:
            body = (r.text or "")[:240]
        return {"ok": r.ok, "http": r.status_code, "url": url, "body": body}
    except Exception as e:
        return {"ok": False, "http": 0, "url": url, "error": safe_error(e)}


@app.get("/health")
def health():
    mesh = {
        "command_8080": _ping(f"{COMMAND}/health"),
        "ollama_11434": _ping(f"{OLLAMA}/api/tags", 4),
        "docker_11435": _ping(f"{DOCKER_OLLAMA}/api/tags", 4),
        "gembot_mcp_5056": _ping(f"{GEMBOT}/", 3),
        "roboshady_5060": _ping(f"{SHADY}/", 3),
        "minerals_5055": _ping(f"{MINERALS}/", 3),
        "memory_11436": _ping(f"{MEMORY}/health", 3),
    }
    ollama_ok = bool(mesh["ollama_11434"].get("ok"))
    return jsonify(
        {
            "ok": ollama_ok,
            "service": "ev-ollama-brain-flask",
            "port": PORT,
            "model": MODEL,
            "ollama": OLLAMA,
            "gembot_mcp": GEMBOT,
            "mesh": mesh,
        }
    )


@app.get("/mesh")
def mesh():
    return health()


@app.get("/models")
def models():
    r = requests.get(f"{OLLAMA}/api/tags", timeout=8)
    r.raise_for_status()
    names = [m.get("name") for m in (r.json().get("models") or [])]
    return jsonify({"models": names, "default": MODEL, "allowed": sorted(ALLOWED_MODELS)})


@app.post("/ask")
def ask():
    data = request.get_json(silent=True) or {}
    prompt = (data.get("prompt") or data.get("q") or data.get("message") or "").strip()
    if not prompt:
        return jsonify({"ok": False, "error": "prompt required"}), 400
    try:
        model, options = validate_generation_request(data)
    except ValueError as exc:
        return jsonify({"ok": False, "error": str(exc)}), 400

    body = {
        "model": model,
        "prompt": prompt,
        "stream": False,
        "think": False,
        "options": options,
    }
    try:
        r = requests.post(f"{OLLAMA}/api/generate", json=body, timeout=60)
        r.raise_for_status()
        out = r.json()
        text = out.get("response", "")
        _log({"kind": "ask", "model": model, "prompt_len": len(prompt), "ok": True})
        return jsonify({"ok": True, "model": model, "response": text})
    except Exception as e:
        _log({"kind": "ask", "model": model, "ok": False, "error": safe_error(e)})
        return jsonify({"ok": False, "error": safe_error(e)}), 502


@app.post("/memory/ask")
def memory_ask():
    data = request.get_json(silent=True) or {}
    try:
        r = requests.post(f"{MEMORY}/ask", json=data, timeout=30)
        return jsonify(r.json() if r.content else {"ok": r.ok}), r.status_code
    except Exception as e:
        return jsonify({"ok": False, "error": safe_error(e), "hint": "start memory bridge :11436"}), 502


@app.route("/gembot", defaults={"path": ""}, methods=["GET", "POST"])
@app.route("/gembot/<path:path>", methods=["GET", "POST"])
def gembot_proxy(path: str):
    url = f"{GEMBOT}/{path}".rstrip("/") or GEMBOT
    try:
        if request.method == "POST":
            r = requests.post(url, json=request.get_json(silent=True) or {}, timeout=30)
        else:
            r = requests.get(url, params=request.args, timeout=10)
        try:
            payload = r.json()
        except Exception:
            payload = {"text": (r.text or "")[:2000]}
        return jsonify({"ok": r.ok, "upstream": url, "data": payload}), r.status_code
    except Exception as e:
        return jsonify({"ok": False, "error": safe_error(e), "gembot": GEMBOT}), 502


@app.get("/roboshady")
def roboshady():
    return jsonify(_ping(f"{SHADY}/", 3))


if __name__ == "__main__":
    validate_port(PORT)
    print(f"EV Ollama Brain Flask on :{PORT} model={MODEL} ollama={OLLAMA} gembot={GEMBOT}")
    app.run(host="127.0.0.1", port=PORT, threaded=True)
