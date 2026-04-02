"""Slack bot PoC: thread conversation + Block Kit formatting."""

import logging
import os
import re
from pathlib import Path

from dotenv import load_dotenv
from slack_bolt import App
from slack_bolt.adapter.socket_mode import SocketModeHandler

logging.basicConfig(level=logging.INFO)

load_dotenv(Path(__file__).resolve().parents[2] / ".env")

app = App(token=os.environ["SLACK_BOT_TOKEN"])

# In-memory conversation state (MVP: replace with session persistence later)
conversations = {}


def _strip_mention(text: str) -> str:
    return re.sub(r"<@[\\w]+>\\s*", "", text).strip()


@app.event("app_mention")
def handle_mention(event, say, client):
    """PM @mentions bot to start a task — bot replies in thread with Block Kit."""
    user = event["user"]
    text = _strip_mention(event.get("text", ""))
    channel = event["channel"]
    thread_ts = event.get("thread_ts") or event["ts"]

    # Check if this is a reply in an existing thread
    if thread_ts in conversations:
        handle_thread_reply(user, text, channel, thread_ts, say)
        return

    # New conversation: simulate specist asking clarification
    conversations[thread_ts] = {
        "user": user,
        "step": 1,
        "description": text,
    }

    # Block Kit formatted response
    blocks = [
        {
            "type": "header",
            "text": {"type": "plain_text", "text": "New Task Received"}
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": f"*Description:* {text}"
            }
        },
        {"type": "divider"},
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "I have a few questions before proceeding:\n\n"
                        "*Q1:* What is the expected behavior when this feature is complete?"
            }
        },
        {
            "type": "context",
            "elements": [
                {"type": "mrkdwn", "text": "Reply in this thread to continue the conversation."}
            ]
        }
    ]

    say(blocks=blocks, text="New task received", thread_ts=thread_ts)


def handle_thread_reply(user, text, channel, thread_ts, say):
    """Handle follow-up replies in a thread (multi-turn conversation)."""
    conv = conversations[thread_ts]
    step = conv["step"]

    if step == 1:
        conv["expected_behavior"] = text
        conv["step"] = 2

        blocks = [
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"Got it.\n\n*Q2:* Are there any edge cases or error scenarios to consider?"
                }
            }
        ]
        say(blocks=blocks, text="Follow-up question", thread_ts=thread_ts)

    elif step == 2:
        conv["edge_cases"] = text
        conv["step"] = 3

        # Final summary with action buttons
        blocks = [
            {
                "type": "header",
                "text": {"type": "plain_text", "text": "Requirement Summary"}
            },
            {
                "type": "section",
                "fields": [
                    {"type": "mrkdwn", "text": f"*Description:*\n{conv['description']}"},
                    {"type": "mrkdwn", "text": f"*Expected Behavior:*\n{conv['expected_behavior']}"},
                ]
            },
            {
                "type": "section",
                "fields": [
                    {"type": "mrkdwn", "text": f"*Edge Cases:*\n{conv['edge_cases']}"},
                ]
            },
            {"type": "divider"},
            {
                "type": "actions",
                "elements": [
                    {
                        "type": "button",
                        "text": {"type": "plain_text", "text": "Confirm"},
                        "style": "primary",
                        "action_id": "task_confirm",
                        "value": thread_ts,
                    },
                    {
                        "type": "button",
                        "text": {"type": "plain_text", "text": "Revise"},
                        "action_id": "task_revise",
                        "value": thread_ts,
                    },
                    {
                        "type": "button",
                        "text": {"type": "plain_text", "text": "Cancel"},
                        "style": "danger",
                        "action_id": "task_cancel",
                        "value": thread_ts,
                    },
                ]
            }
        ]
        say(blocks=blocks, text="Requirement summary", thread_ts=thread_ts)

    else:
        say(text="This conversation is already complete.", thread_ts=thread_ts)


@app.action("task_confirm")
def handle_confirm(ack, body, say):
    ack()
    thread_ts = body["actions"][0]["value"]
    channel = body["channel"]["id"]
    conv = conversations.get(thread_ts, {})

    say(
        text=f"Task confirmed! Creating task for: *{conv.get('description', '?')}*",
        thread_ts=thread_ts,
        channel=channel,
    )
    conversations.pop(thread_ts, None)


@app.action("task_revise")
def handle_revise(ack, body, say):
    ack()
    thread_ts = body["actions"][0]["value"]
    channel = body["channel"]["id"]
    conv = conversations.get(thread_ts, {})
    conv["step"] = 1

    say(
        text="OK, let's start over. What is the task description?",
        thread_ts=thread_ts,
        channel=channel,
    )


@app.action("task_cancel")
def handle_cancel(ack, body, say):
    ack()
    thread_ts = body["actions"][0]["value"]
    channel = body["channel"]["id"]

    say(text="Task cancelled.", thread_ts=thread_ts, channel=channel)
    conversations.pop(thread_ts, None)


@app.event("message")
def handle_message(event, say, logger):
    """Handle DMs and thread replies."""
    logger.info(f"=== MESSAGE EVENT: text={event.get('text', '')}, thread_ts={event.get('thread_ts')}, bot_id={event.get('bot_id')}, channel_type={event.get('channel_type')}")

    # Skip bot messages
    if event.get("bot_id"):
        return

    # Thread reply in a channel — route to conversation handler
    thread_ts = event.get("thread_ts")
    if thread_ts:
        logger.info(f"=== THREAD REPLY: thread_ts={thread_ts}, in conversations={thread_ts in conversations}, keys={list(conversations.keys())}")
        if thread_ts in conversations:
            handle_thread_reply(
                event["user"], event.get("text", ""),
                event["channel"], thread_ts, say,
            )
            return
        else:
            logger.info(f"=== THREAD NOT FOUND in conversations")
            return

    # Skip non-thread channel messages (handled by app_mention)
    if event.get("channel_type") != "im":
        return

    # DM echo (keep for testing)
    say(f"Echo: {event.get('text', '')}")


if __name__ == "__main__":
    handler = SocketModeHandler(app, os.environ["SLACK_APP_TOKEN"])
    print("Bot is running. Press Ctrl+C to stop.")
    handler.start()
