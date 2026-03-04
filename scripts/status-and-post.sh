#!/usr/bin/env bash
# Run system status and post result to Slack #system-monitor

# Load environment variables from .env if present
if [[ -f "/home/ubuntu/.openclaw/workspace/.env" ]]; then
  set +u
  source /home/ubuntu/.openclaw/workspace/.env
  set -u
fi

OUTPUT=$(/home/ubuntu/.openclaw/workspace/scripts/system-status.sh 2>&1)
echo "$OUTPUT"

# Log to file
LOG_DIR="/home/ubuntu/.openclaw/workspace/logs"
mkdir -p "$LOG_DIR"
echo "$OUTPUT" >> "$LOG_DIR/system-status.log"

# Post to Slack if bot token available (from environment)
BOT_TOKEN="${SLACK_BOT_TOKEN:-}"
CHANNEL_ID="C0AHPT66TV3"
if [[ -n "$BOT_TOKEN" ]]; then
  # Simple JSON without jq
  ESCAPED=$(echo "$OUTPUT" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr -d '\n')
  JSON="{\"channel\":\"${CHANNEL_ID}\",\"text\":\"${ESCAPED}\",\"mrkdwn\":false}"
  curl -s -X POST -H "Authorization: Bearer $BOT_TOKEN" -H "Content-type: application/json" \
    --data "$JSON" https://slack.com/api/chat.postMessage >/dev/null 2>&1 || echo "Slack post failed" >&2
fi
