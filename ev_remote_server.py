from flask import Flask, request, jsonify
import json
import os

app = Flask(__name__)

# Memory File Path
BRAIN_FILE = "C:\\EV_Files\\ev_virtual_brain.json"
if not os.path.exists(BRAIN_FILE):
    alt = "C:\\EV_Operator\\ev_virtual_brain.json"
    if os.path.exists(alt):
        BRAIN_FILE = alt

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
