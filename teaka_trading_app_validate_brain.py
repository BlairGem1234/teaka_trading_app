import json
import os
import sys

path = r"C:\EV_Files\ev_virtual_brain.json"
os_fallback = r"C:\EV_Operator\ev_virtual_brain.json"
if not os.path.exists(path) and os.path.exists(os_fallback):
    path = os_fallback

try:
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    print("✅ JSON is valid. Top‐level keys:", list(data.keys())[:5])
except Exception as e:
    print("❌ JSON parse error:", e)
    sys.exit(1)
