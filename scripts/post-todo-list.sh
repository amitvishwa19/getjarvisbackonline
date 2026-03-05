#!/usr/bin/env bash
# Post Formatted Todo List to Slack #daily-planner
# Output matches: [emoji] [Title] ─── [sections with bullet points]

WORKSPACE="/home/ubuntu/.openclaw/workspace"
TODO_FILE="$WORKSPACE/TODO_LIST.md"
SLACK_CHANNEL="C0AH4TSS893"

# Load .env
if [[ -f "$WORKSPACE/.env" ]]; then
  source "$WORKSPACE/.env"
fi

# Build message
TIMESTAMP=$(date '+%Y-%m-%d %H:%M UTC')
{
  echo "👾 Jarvis: Current Todo List (what's next):"
  echo "───"
  
  # If file exists, parse sections
  if [[ -f "$TODO_FILE" ]]; then
    # Read file line by line, format sections
    while IFS= read -r line; do
      if [[ "$line" =~ ^### ]]; then
        # Section header like "### 🔴 High Priority (Pending)"
        # Extract emoji, title
        emoji=$(echo "$line" | grep -oE '🔴|🟡|🟢' || echo '•')
        title=$(echo "$line" | sed 's/^### //')
        echo "$emoji $title"
        echo "───"
      elif [[ "$line" =~ ^\- \[ \] ]]; then
        # Todo item
        echo "$line"
      elif [[ "$line" =~ ^[0-9]+\. ]]; then
        # Numbered item with description
        echo "$line"
      elif [[ -n "$line" ]]; then
        # Continuation or plain text
        echo "$line"
      fi
    done < "$TODO_FILE"
  else
    echo "• No todo file found. Create TODO_LIST.md"
  fi
  
  echo ""
  echo "Main immediate action: Run those 10 diagnostic commands from earlier and tell me output. Slack notification fix is the blocker. 🛠️"
  echo "Kya koi specific task pai rakhna hai?"
} > /tmp/todo_formatted.txt

MESSAGE=$(cat /tmp/todo_formatted.txt)

# Post to Slack
if [[ -n "${SLACK_BOT_TOKEN:-}" ]]; then
  ESCAPED=$(echo "$MESSAGE" | sed 's/\\/\\\\/g; s/"/\\"/g')
  RESPONSE=$(curl -s -X POST -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
    -H "Content-type: application/json" \
    --data "{\"channel\":\"$SLACK_CHANNEL\",\"text\":\"$ESCAPED\",\"mrkdwn\":true}" \
    https://slack.com/api/chat.postMessage)
  
  if echo "$RESPONSE" | grep -q '"ok":true'; then
    echo "Todo list posted successfully to #daily-planner"
  else
    echo "Slack post failed: $RESPONSE" >&2
  fi
else
  echo "SLACK_BOT_TOKEN not set" >&2
fi
