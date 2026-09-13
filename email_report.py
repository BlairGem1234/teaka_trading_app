import os
import smtplib
from email.message import EmailMessage
from generate_summary import generate_summary

def send_email():
    summary = generate_summary()

    recipient = os.environ.get("TEAKA_REPORT_EMAIL_TO", "blairgem@outlook.com")
    sender = os.environ.get("TEAKA_REPORT_EMAIL_FROM", recipient)
    smtp_host = os.environ.get("TEAKA_SMTP_HOST", "smtp-mail.outlook.com")
    smtp_port = int(os.environ.get("TEAKA_SMTP_PORT", "587"))
    smtp_user = os.environ.get("TEAKA_SMTP_USER", sender)
    smtp_password = os.environ.get("TEAKA_SMTP_PASSWORD")

    if not smtp_password:
        print("[Teaka Report] Email not sent: TEAKA_SMTP_PASSWORD not configured. Report generated locally.")
        return

    msg = EmailMessage()
    msg["Subject"] = f"Teaka Trading – Daily Summary Report ({summary['date']})"
    msg["From"] = sender
    msg["To"] = recipient

    text = f"""
🔥 DAILY TRADE SUMMARY – {summary['date']}

📈 Total Trades: {summary['total_trades']}
💰 Win Rate: {summary['win_rate']}%
📊 P&L: +${summary['pnl_usd']} ({summary['pnl_percent']}%)
🏆 Top Symbol: {summary['top_symbol']} (+${summary['top_pnl']})
💣 Worst Symbol: {summary['worst_symbol']} (${summary['worst_pnl']})

📍 Signal Forecast:
"""
    for symbol, bias in summary["forecast"].items():
        text += f"{symbol} → {bias.upper()}\n"

    text += f"\n{summary['notes']}\n\n— Teaka Swarm Core"

    msg.set_content(text)

    with smtplib.SMTP(smtp_host, smtp_port) as smtp:
        smtp.starttls()
        smtp.login(smtp_user, smtp_password)
        smtp.send_message(msg)


if __name__ == "__main__":
    send_email()


