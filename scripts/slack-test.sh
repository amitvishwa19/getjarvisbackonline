#!/bin/bash

# Test Slack bot token and channel access

source <(grep -v '^#' /home/ubuntu/.openclaw/workspace/.env | grep -v '^$')

echo "=== Slack Token Test ==="
echo "Token: ${SLACK_BOT_TOKEN:0:20}..."
echo "Channel: ${SLACK_CHANNEL_ID:-not set}"

# 1. Auth test
echo -e "\n[1] Testing token with auth.test..."
AUTH_RESP=$(curl -s -X POST "https://slack.com/api/auth.test" \
  -H "Authorization: Bearer ${SLACK_BOT_TOKEN}")
echo "$AUTH_RESP" | jq .

# 2. Try posting to channel (dry run if no channel set)
if [ -n "$SLACK_CHANNEL_ID" ]; then
  echo -e "\n[2] Attempting to post to channel ${SLACK_CHANNEL_ID}..."
  MSG="Test message from Jarvis at $(date -Iseconds)"
  POST_RESP=$(curl -s -X POST "https://slack.com/api/chat.postMessage" \
    -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
    -H "Content-type: application/json; charset=utf-8" \
    --data "{\"channel\":\"${SLACK_CHANNEL_ID}\",\"text\":\"${MSG}\"}")
  echo "$POST_RESP" | jq .
else
  echo -e "\n[2] SLACK_CHANNEL_ID not set, skipping post test"
fi

# 3. List channels bot can access (if channels:read)
echo -e "\n[3] Checking channels list (requires channels:read)..."
CH_RESP=$(curl -s -X GET "https://slack.com/api/conversations.list?exclude_archived=true&limit=10" \
  -H "Authorization: Bearer ${SLACK_BOT_TOKEN}")
# echo "$CH_RESP" | jq '.channels[]? | {id, name, is_member}' 2>/dev/null || echo "$CH_RESP" | jq .
# Just show summary
echo "$CH_RESP" | jq -r '.ok // false, if .ok then "Channels fetched: \(.channels | length)" else "Error: \(.error)" end'
