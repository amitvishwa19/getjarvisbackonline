#!/bin/bash

# Instagram Verification Script
# Checks recent posts on Instagram Business Account

# Load .env file
if [ -f "/home/ubuntu/.openclaw/workspace/.env" ]; then
    source <(grep -v '^#' /home/ubuntu/.openclaw/workspace/.env | grep -v '^$')
else
    echo "ERROR: .env file not found"
    exit 1
fi

# Check credentials
if [ -z "$INSTAGRAM_BUSINESS_ACCOUNT_ID" ] || [ -z "$FACEBOOK_ACCESS_TOKEN" ]; then
    echo "ERROR: Missing INSTAGRAM_BUSINESS_ACCOUNT_ID or FACEBOOK_ACCESS_TOKEN"
    exit 1
fi

echo "=== Instagram Verification ==="
echo "Account ID: $INSTAGRAM_BUSINESS_ACCOUNT_ID"

# Get recent media (last 10)
echo -e "\nFetching recent media..."
RESPONSE=$(curl -s "https://graph.facebook.com/v18.0/${INSTAGRAM_BUSINESS_ACCOUNT_ID}/media?fields=id,caption,media_type,media_url,permalink,timestamp&limit=10&access_token=${FACEBOOK_ACCESS_TOKEN}")

ERROR=$(echo "$RESPONSE" | jq -r '.error.message // empty')
if [ -n "$ERROR" ]; then
    echo "API Error: $ERROR"
    echo "Full response: $RESPONSE"
    exit 1
fi

# Parse media
echo -e "\nRecent Media Posts:"
echo "==================================="

echo "$RESPONSE" | jq -r '.data[]? | "\(.id) | \(.timestamp) | \(.media_type) | \(.caption // "No caption")"' | while IFS='|' read -r id timestamp type capt; do
    echo "-----------------------------------"
    echo "ID: $id"
    echo "Time: $timestamp"
    echo "Type: $type"
    echo "Caption: ${capt:0:50}..."
    echo "$RESPONSE" | jq -r ".data[]? | select(.id==\"$id\") | .permalink" | while read -r link; do
        [ -n "$link" ] && echo "Link: $link"
    done
done

# Check if our test post is present
TEST_CAPTION="Jarvis test post from OpenClaw"
FOUND=$(echo "$RESPONSE" | jq --arg test "$TEST_CAPTION" '.data[]? | select(.caption | contains($test)) | .id')

if [ -n "$FOUND" ]; then
    echo -e "\n✅ FOUND! Test post is on Instagram."
    echo "$RESPONSE" | jq -r --arg id "$FOUND" '.data[]? | select(.id==$id) | "Post ID: \(.id)\nPermalink: \(.permalink // "Not available")\nCaption: \(.caption)\nType: \(.media_type)\nTime: \(.timestamp)"'
else
    echo -e "\n⚠️  Test post NOT found in recent media."
    echo "Possible reasons:"
    echo "- Post still processing (Instagram can take 5-10 minutes)"
    echo "- Rate limiting or API permissions issue"
    echo "- Wrong account being checked"
fi
