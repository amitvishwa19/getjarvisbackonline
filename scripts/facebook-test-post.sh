#!/bin/bash

# Facebook Test Post Script
# Uses cURL to directly call Facebook Graph API

# Load .env file
if [ -f "/home/ubuntu/.openclaw/workspace/.env" ]; then
    source <(grep -v '^#' /home/ubuntu/.openclaw/workspace/.env | grep -v '^$')
else
    echo "ERROR: .env file not found"
    exit 1
fi

# Check credentials
if [ -z "$FACEBOOK_PAGE_ID" ] || [ -z "$FACEBOOK_ACCESS_TOKEN" ]; then
    echo "ERROR: Missing FACEBOOK_PAGE_ID or FACEBOOK_ACCESS_TOKEN in .env"
    exit 1
fi

echo "=== Facebook API Test ==="
echo "Page ID: $FACEBOOK_PAGE_ID"
echo "Token: ${FACEBOOK_ACCESS_TOKEN:0:20}..."

# 1. Test token validity
echo -e "\n[1] Testing token validity via /me endpoint..."
ME_RESPONSE=$(curl -s -X GET "https://graph.facebook.com/v18.0/me?access_token=$FACEBOOK_ACCESS_TOKEN")
ME_ERROR=$(echo "$ME_RESPONSE" | jq -r '.error.message // empty')

if [ -n "$ME_ERROR" ]; then
    echo "Token invalid: $ME_ERROR"
    echo "Full response: $ME_RESPONSE"
    exit 1
else
    ME_ID=$(echo "$ME_RESPONSE" | jq -r '.id')
    echo "Token valid. User ID: $ME_ID"
fi

# 2. Test page access
echo -e "\n[2] Testing page access..."
PAGE_RESPONSE=$(curl -s -X GET "https://graph.facebook.com/v18.0/$FACEBOOK_PAGE_ID?fields=id,name&access_token=$FACEBOOK_ACCESS_TOKEN")
PAGE_ERROR=$(echo "$PAGE_RESPONSE" | jq -r '.error.message // empty')

if [ -n "$PAGE_ERROR" ]; then
    echo "Page access failed: $PAGE_ERROR"
    echo "Full response: $PAGE_RESPONSE"
    exit 1
else
    PAGE_NAME=$(echo "$PAGE_RESPONSE" | jq -r '.name')
    echo "Page accessible: $PAGE_NAME (ID: $FACEBOOK_PAGE_ID)"
fi

# 3. Post to feed
echo -e "\n[3] Posting test message to page feed..."
TEST_MESSAGE="Jarvis test post from OpenClaw 🤖 #devlomatix"

POST_RESPONSE=$(curl -s -X POST \
    "https://graph.facebook.com/v18.0/$FACEBOOK_PAGE_ID/feed" \
    -d "message=$TEST_MESSAGE" \
    -d "access_token=$FACEBOOK_ACCESS_TOKEN")

POST_ERROR=$(echo "$POST_RESPONSE" | jq -r '.error.message // empty')
POST_ID=$(echo "$POST_RESPONSE" | jq -r '.id // empty')

if [ -n "$POST_ERROR" ]; then
    echo "Post failed: $POST_ERROR"
    echo "Full response: $POST_RESPONSE"
    echo "\nPossible reasons:"
    echo "- Token lacks 'pages_manage_posts' permission"
    echo "- Page ID incorrect or access not granted"
    echo "- Token expired (need to regenerate)"
    exit 1
else
    echo "✅ Post successful!"
    echo "Post ID: $POST_ID"
    POST_URL="https://www.facebook.com/$FACEBOOK_PAGE_ID/posts/$POST_ID"
    echo "View: $POST_URL"

    # Send Slack notification if configured
    if [ -n "$SLACK_BOT_TOKEN" ] && [ -n "$SLACK_CHANNEL_ID" ]; then
        echo -e "\n[4] Sending Slack notification..."
        SLACK_MSG="📢 *New Post Published*\n*Platform:* Facebook\n*Content:* $TEST_MESSAGE\n*Link:* $POST_URL\n*ID:* $POST_ID\n*Time:* $(date -Iseconds)"
        SLACK_RESP=$(curl -s -X POST "https://slack.com/api/chat.postMessage" \
          -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
          -H "Content-type: application/json; charset=utf-8" \
          --data "{\"channel\":\"$SLACK_CHANNEL_ID\",\"text\":\"${SLACK_MSG//\"/\\\"}\"}")
        SLACK_OK=$(echo "$SLACK_RESP" | jq -r '.ok // false')
        if [ "$SLACK_OK" = "true" ]; then
            echo "✅ Slack notification sent"
        else
            SLACK_ERR=$(echo "$SLACK_RESP" | jq -r '.error // "unknown"')
            echo "❌ Slack notification failed: $SLACK_ERR"
        fi
    else
        echo -e "\n[4] Slack notification skipped (SLACK_BOT_TOKEN or SLACK_CHANNEL_ID not set)"
    fi
fi
