# TeAka Trading App — Secrets & Credentials

All credentials are loaded from **environment variables only**.
Copy `.env.example` to `.env` and fill in your local values. Never commit `.env`.

---

## Cleaner Rule

Credential cleanup is report-first by default.

Use `scripts/credential_cleaner.py` to inspect files for committed-looking credentials. It does not change files unless both of these are present:

```bash
python scripts/credential_cleaner.py --apply --approve Blair <paths>
```

Protected EV Brain artifacts are skipped by default, including `.zip`, `.exe`, and paths containing `brain`, `ev_brain`, or `ev_ai`. The cleaner is for credentials and small text config files, not Brain archives or runtime binaries.

---

## Required for Telegram Alerts

| Variable | Where to get it | Used by |
|----------|----------------|---------|
| `TELEGRAM_BOT_TOKEN` | @BotFather -> `/newbot` | `alert_routes.py.py`, `public/ev_alert_api.py`, `trading_stack/messaging.py` |
| `TELEGRAM_CHAT_ID` | `curl https://api.telegram.org/bot<TOKEN>/getUpdates` | Same as above |

If a token was ever committed to Git history, rotate it via @BotFather before use.

---

## Required for Live Trading (paper mode needs none of these)

### Crypto Exchanges

| Variable | Service | Used by |
|----------|---------|---------|
| `KUCOIN_API_KEY` | KuCoin (primary) | `broker_apis.py`, `ccxt_integration.py`, `futures_trading.py` |
| `KUCOIN_SECRET_KEY` | KuCoin | Same |
| `KUCOIN_PASSPHRASE` | KuCoin | Same |
| `BINANCE_API_KEY` | Binance (backup) | `ccxt_integration.py` |
| `BINANCE_SECRET_KEY` | Binance | Same |

`ccxt_integration.py` supports 10 exchanges total. Optional ones can be configured with env vars when needed.

Exchanges without credentials still work for public data such as prices, OHLCV, and order books.

### Forex

| Variable | Service | Used by |
|----------|---------|---------|
| `OANDA_API_KEY` | OANDA forex | `broker_apis.py` |
| `OANDA_ACCOUNT_ID` | OANDA forex | Same |

### Stocks

| Variable | Service | Used by |
|----------|---------|---------|
| `IB_API_KEY` | Interactive Brokers | `broker_apis.py` |
| `IB_ACCOUNT_ID` | Interactive Brokers | Same |
| `ALPACA_API_KEY` | Alpaca | `alpaca_integration.py`, `config.py` |
| `ALPACA_SECRET_KEY` | Alpaca | Same |
| `ALPACA_BASE_URL` | Alpaca paper/live base URL | Same |

---

## Optional

| Variable | Purpose | Used by |
|----------|---------|---------|
| `DISCORD_WEBHOOK_URL` | Discord alert channel | `trading_stack/messaging.py` |
| `TEAKA_BIND_HOST` | Bridge bind address | `connect_python.py` |
| `TEAKA_BIND_PORT` | Bridge port | `connect_python.py` |
| `TEAKA_BRAIN_FILE` | Custom brain JSON path | `connect_python.py` |

---

## Safety Gates

Live trading requires all three to be set:

```text
TEAKA_MODE=live
LIVE_TRADING_ENABLED=true
PRIVATE_EXCHANGE_API_ENABLED=true
```

Paper mode (default) needs no exchange credentials.

---

## Cursor Cloud Agent Secrets

If running as a Cursor Cloud Agent, add secrets at:
**Cursor Dashboard -> Cloud Agents -> Secrets**

Required for this repo:
- `TELEGRAM_BOT_TOKEN`
- `TELEGRAM_CHAT_ID`
