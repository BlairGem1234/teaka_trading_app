from flask import Flask, request, jsonify
import json
import os

app = Flask(__name__)

# Memory File Path (supports TEAKA_BRAIN_FILE, C:\EV_Operator, or EV_Files)
ev_operator_brain = r"C:\EV_Operator\teaka_trading_app\ev_virtual_brain.json"
ev_files_dir = os.environ.get("EV_Files", r"C:\EV_Files")
local_brain = os.path.join(os.path.dirname(__file__), "ev_virtual_brain.json")

if os.environ.get("TEAKA_BRAIN_FILE") and os.path.exists(os.environ["TEAKA_BRAIN_FILE"]):
    BRAIN_FILE = os.environ["TEAKA_BRAIN_FILE"]
elif os.path.exists(ev_operator_brain):
    BRAIN_FILE = ev_operator_brain
elif os.path.exists(os.path.join(ev_files_dir, "ev_virtual_brain.json")):
    BRAIN_FILE = os.path.join(ev_files_dir, "ev_virtual_brain.json")
else:
    BRAIN_FILE = local_brain

# Load Brain Memory (if available)
def load_brain():
    if os.path.exists(BRAIN_FILE):
        with open(BRAIN_FILE, "r") as f:
            return json.load(f)
    return {"error": "Brain file missing"}

@app.route("/ev_remote/command", methods=["GET", "POST"])
def remote_command():
    data = request.json or {}
    command = data.get("command", "status_check")

    brain = load_brain()

    response = {
        "ev_status": "online",
        "brain_link": brain,
        "received_command": command
    }
    return jsonify(response)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5050, debug=True)
