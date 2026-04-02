# Slack Echo Bot PoC

Minimal Slack Bolt (Python) bot that echoes messages via Socket Mode.

## Prerequisites

1. A Slack app with **Socket Mode** enabled.
2. Bot token scopes: `app_mentions:read`, `chat:write`, `im:history`.
3. Event subscriptions: `app_mention`, `message.im`.
4. Tokens in `/Users/liu/atdd-task/.env`:

```
SLACK_APP_TOKEN=xapp-...
SLACK_BOT_TOKEN=xoxb-...
SLACK_SIGNING_SECRET=...
```

## Setup

```bash
cd poc/slack-bot
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Run

```bash
python app.py
```

The bot connects via WebSocket — no public URL or ngrok needed.

## Behaviour

- **@mention in a channel** — echoes the message text (minus the mention).
- **DM** — echoes the message text as-is.
