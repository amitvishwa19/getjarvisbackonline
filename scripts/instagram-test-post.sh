#!/bin/bash

# Instagram Test Post Script
# Uses cURL to call Instagram Graph API

# Load .env file
if [ -f "/home/ubuntu/.openclaw/workspace/.env" ]; then
    source <(grep -v '^#' /home/ubuntu/.openclaw/workspace/.env | grep -v '^$')
else
    echo "ERROR: .env file not found"
    exit 1
fi

# Check credentials
if [ -z "$INSTAGRAM_BUSINESS_ACCOUNT_ID" ] || [ -z "$FACEBOOK_ACCESS_TOKEN" ]; then
    echo "ERROR: Missing INSTAGRAM_BUSINESS_ACCOUNT_ID or FACEBOOK_ACCESS_TOKEN in .env"
    exit 1
fi

echo "=== Instagram API Test ==="
echo "Instagram Business Account ID: $INSTAGRAM_BUSINESS_ACCOUNT_ID"
echo "Token: ${FACEBOOK_ACCESS_TOKEN:0:20}..."

# Step 0: Validate token and IG account
echo -e "\n[0] Validating token and Instagram Business Account..."
VALIDATE_RESPONSE=$(curl -s "https://graph.facebook.com/v18.0/${INSTAGRAM_BUSINESS_ACCOUNT_ID}?fields=id,username,ig_id,profile_picture_url&access_token=${FACEBOOK_ACCESS_TOKEN}")
VALIDATE_ERROR=$(echo "$VALIDATE_RESPONSE" | jq -r '.error.message // empty')
IG_USERNAME=$(echo "$VALIDATE_RESPONSE" | jq -r '.username // empty')

if [ -n "$VALIDATE_ERROR" ]; then
    echo "Validation failed: $VALIDATE_ERROR"
    echo "Full response: $VALIDATE_RESPONSE"
    echo "\nPossible reasons:"
    echo "- Token lacks instagram_basic permission"
    echo "- Instagram Business Account not linked to Facebook Page"
    echo "- Access token expired"
    exit 1
fi

echo "✅ Instagram Business Account validated"
echo "   Username: ${IG_USERNAME:-<not set>}"
echo "   IG ID: $INSTAGRAM_BUSINESS_ACCOUNT_ID"

# Note: Instagram requires a publicly accessible image URL (minimum 1080x1080 recommended)
# You must provide a real hosted image. Replace TEST_IMAGE_URL with your actual image URL.

TEST_IMAGE_URL="https://images.unsplash.com/photo-1611162617474-5b21e879e113?ixlib=rb-4.0.3&auto=format&fit=crop&w=1080&q=80"
TEST_CAPTION="Jarvis test post from OpenClaw 🤖 #devlomatix"

echo -e "\n[1] Creating media container..."
echo "   Image URL: $TEST_IMAGE_URL"
echo "   Caption: $TEST_CAPTION"

CREATE_RESPONSE=$(curl -s -X POST "https://graph.facebook.com/v18.0/${INSTAGRAM_BUSINESS_ACCOUNT_ID}/media" \
    -d "image_url=${TEST_IMAGE_URL}" \
    -d "caption=${TEST_CAPTION}" \
    -d "access_token=${FACEBOOK_ACCESS_TOKEN}")

CREATE_ERROR=$(echo "$CREATE_RESPONSE" | jq -r '.error.message // empty')
CONTAINER_ID=$(echo "$CREATE_RESPONSE" | jq -r '.id // empty')

if [ -n "$CREATE_ERROR" ]; then
    echo "❌ Container creation failed: $CREATE_ERROR"
    echo "Full response: $CREATE_RESPONSE"
    echo "\nTroubleshooting:"
    echo "- Ensure image URL is publicly accessible (no auth, no 403)"
    echo "- Image must be at least 1080x1080"
    echo "- Allowed formats: JPEG, PNG"
    echo "- Use a reliable CDN (Unsplash, Imgur, Cloudinary, etc.)"
    exit 1
fi

echo "✅ Container created! ID: $CONTAINER_ID"

# Wait for processing
echo -e "\n[2] Waiting for container to process (3 seconds)..."
sleep 3

# Optional: Check container status
# STATUS_RESPONSE=$(curl -s "https://graph.facebook.com/v18.0/${CONTAINER_ID}?fields=status_code&access_token=${FACEBOOK_ACCESS_TOKEN}")
# echo "   Status: $(echo "$STATUS_RESPONSE" | jq -r '.status_code // "unknown"')"

# Step 3: Publish the container
echo -e "\n[3] Publishing container..."
PUBLISH_RESPONSE=$(curl -s -X POST "https://graph.facebook.com/v18.0/${INSTAGRAM_BUSINESS_ACCOUNT_ID}/media_publish" \
    -d "creation_id=${CONTAINER_ID}" \
    -d "access_token=${FACEBOOK_ACCESS_TOKEN}")

PUBLISH_ERROR=$(echo "$PUBLISH_RESPONSE" | jq -r '.error.message // empty')
POST_ID=$(echo "$PUBLISH_RESPONSE" | jq -r '.id // empty')

if [ -n "$PUBLISH_ERROR" ]; then
    echo "❌ Publish failed: $PUBLISH_ERROR"
    echo "Full response: $PUBLISH_RESPONSE"
    exit 1
fi

echo "✅ Instagram post published successfully!"
echo "   Container ID: $CONTAINER_ID"
echo "   Post ID: $POST_ID"

# Fetch permalink for the post
POST_URL="https://www.instagram.com/p/$POST_ID"  # will verify/overwrite if API returns
PERM_RESP=$(curl -s "https://graph.facebook.com/v18.0/${POST_ID}?fields=permalink&access_token=${FACEBOOK_ACCESS_TOKEN}")
PERM_URL=$(echo "$PERM_RESP" | jq -r '.permalink // empty')
if [ -n "$PERM_URL" ]; then
    POST_URL="$PERM_URL"
fi
echo "   Link: $POST_URL"

# Send Slack notification if configured
if [ -n "$SLACK_BOT_TOKEN" ] && [ -n "$SLACK_CHANNEL_ID" ]; then
    echo -e "\n[4] Sending Slack notification..."
    SLACK_MSG="📢 *New Post Published*\n*Platform:* Instagram\n*Content:* $TEST_CAPTION\n*Link:* $POST_URL\n*ID:* $POST_ID\n*Time:* $(date -Iseconds)"
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

echo "\n⚠️  If permalink not returned, check Instagram manually: https://www.instagram.com/"

