#!/bin/bash

# Get permalink for a specific Instagram media ID

if [ -f "/home/ubuntu/.openclaw/workspace/.env" ]; then
    source <(grep -v '^#' /home/ubuntu/.openclaw/workspace/.env | grep -v '^$')
else
    echo "ERROR: .env not found"
    exit 1
fi

MEDIA_ID="${1:-18114955210725355}"

echo "Fetching details for media ID: $MEDIA_ID"
curl -s "https://graph.facebook.com/v18.0/${MEDIA_ID}?fields=id,permalink,media_url,caption&access_token=${FACEBOOK_ACCESS_TOKEN}" | jq -r '.permalink // empty'
