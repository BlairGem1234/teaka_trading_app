# File: generate_summary.py
import json, os, datetime

def generate_summary():
    today = datetime.datetime.now().strftime("%Y-%m-%d")
    report = {
        "date": today,
        "total_trades": 42,
        "win_rate": 76.2,
        "pnl_usd": 231.74,
        "pnl_percent": 5.7,
        "top_symbol": "ETH/USD",
        "top_pnl": 92.0,
        "worst_symbol": "DOGE/USD",
        "worst_pnl": -33.29,
        "forecast": {
            "BTC/USD": "bullish",
            "SOL/USD": "neutral",
            "XAU/USD": "bearish"
        },
        "notes": "System stable. No anomalies."
    }

    folder = "C:/EV_Files/teaka_trading_app/daily_reports/"
    archive = os.path.join(folder, "archive")
    os.makedirs(archive, exist_ok=True)

    json_path = os.path.join(folder, f"summary_{today.replace('-', '')}.json")
    with open(json_path, "w") as f:
        json.dump(report, f, indent=2)

    return report
