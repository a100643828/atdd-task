#!/bin/bash
# Start/stop the Slack bot with proper cleanup
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
PIDFILE="$DIR/.bot.pid"

stop() {
  if [ -f "$PIDFILE" ]; then
    pid=$(cat "$PIDFILE")
    if kill -0 "$pid" 2>/dev/null; then
      echo "Stopping bot (PID $pid)..."
      kill "$pid"  # SIGTERM for graceful WebSocket close
      sleep 3
      kill -0 "$pid" 2>/dev/null && kill -9 "$pid"
    fi
    rm -f "$PIDFILE"
  fi
}

case "${1:-start}" in
  start)
    stop
    sleep 2
    source "$DIR/.venv/bin/activate"
    python -u "$DIR/app.py" > /tmp/slack-bot.log 2>&1 &
    echo $! > "$PIDFILE"
    echo "Bot started (PID $!). Log: /tmp/slack-bot.log"
    sleep 3
    grep -a "running\|ERROR" /tmp/slack-bot.log || true
    ;;
  stop)
    stop
    echo "Bot stopped."
    ;;
  restart)
    stop
    sleep 3
    exec "$0" start
    ;;
  *)
    echo "Usage: $0 {start|stop|restart}"
    ;;
esac
