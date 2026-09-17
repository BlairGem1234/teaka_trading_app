# EV Ollama Brain/Memory Flask — sidecar only (does not steer Cursor chat).
# Listen:  http://127.0.0.1:8081   (NEVER 8080 — that is EV Command Bridge)
# Model:   qwen3:4b (never 30b/32b)
# Clients: Windows Ollama :11434, GEMBot MCP :5056, RoboShady :5060,
#          Minerals :5055, memory/postgres bridge :11436, Command :8080 (GET only)

from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from pathlib import Path

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
MODEL = os.environ.get("EV_BRAIN_MODEL", "qwen3:4b")
PORT = int(os.environ.get("EV_OLLAMA_FLASK_PORT", "8081"))
LOG_DIR = Path(os.environ.get("EVBOT_LOG_DIR", r"D:\EV_AI\logs"))
LOG_DIR.mkdir(parents=True, exist_ok=True)
BRAIN_LOG = LOG_DIR / "ev_ollama_brain_flask.jsonl"


def _log(event: dict) -> None:
    event["time"] = datetime.now(timezone.utc).isoformat()
    with BRAIN_LOG.open("a", encoding="utf-8") as f:
        f.write(json.dumps(event, ensure_ascii=False) + "\n")


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
        return {"ok": False, "http": 0, "url": url, "error": str(e)}


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
    return jsonify({"models": names, "default": MODEL})


@app.post("/ask")
def ask():
    data = request.get_json(silent=True) or {}
    prompt = (data.get("prompt") or data.get("q") or data.get("message") or "").strip()
    model = (data.get("model") or MODEL).strip()
    if "30b" in model or "32b" in model:
        return jsonify({"ok": False, "error": "large models blocked; use qwen3:4b"}), 400
    if not prompt:
        return jsonify({"ok": False, "error": "prompt required"}), 400

    body = {
        "model": model,
        "prompt": prompt,
        "stream": False,
        "think": False,
        "options": {
            "num_predict": int(data.get("num_predict", 64)),
            "num_ctx": int(data.get("num_ctx", 2048)),
        },
    }
    try:
        r = requests.post(f"{OLLAMA}/api/generate", json=body, timeout=60)
        r.raise_for_status()
        out = r.json()
        text = out.get("response", "")
        _log({"kind": "ask", "model": model, "prompt_len": len(prompt), "ok": True})
        return jsonify({"ok": True, "model": model, "response": text})
    except Exception as e:
        _log({"kind": "ask", "model": model, "ok": False, "error": str(e)})
        return jsonify({"ok": False, "error": str(e)}), 502


@app.post("/memory/ask")
def memory_ask():
    """Forward to postgres memory bridge :11436 when available."""
    data = request.get_json(silent=True) or {}
    try:
        r = requests.post(f"{MEMORY}/ask", json=data, timeout=30)
        return jsonify(r.json() if r.content else {"ok": r.ok}), r.status_code
    except Exception as e:
        return jsonify({"ok": False, "error": str(e), "hint": "start memory bridge :11436"}), 502


@app.route("/gembot", defaults={"path": ""}, methods=["GET", "POST"])
@app.route("/gembot/<path:path>", methods=["GET", "POST"])
def gembot_proxy(path: str):
    """Proxy to GEMBot MCP/Flask on :5056. Does not bind 5056."""
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
        return jsonify({"ok": False, "error": str(e), "gembot": GEMBOT}), 502


@app.get("/roboshady")
def roboshady():
    return jsonify(_ping(f"{SHADY}/", 3))


if __name__ == "__main__":
    if PORT == 8080:
        raise SystemExit("Refusing to bind :8080 — that is EV Command Bridge. Use EV_OLLAMA_FLASK_PORT=8081")
    print(
        f"EV Ollama Brain Flask on :{PORT} model={MODEL} ollama={OLLAMA} gembot={GEMBOT}"
    )
    app.run(host="127.0.0.1", port=PORT, threaded=True)
