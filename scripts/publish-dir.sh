#!/bin/bash

# publish-dir.sh — Publish a folder to here.now + Slack notification
# Usage: ./scripts/publish-dir.sh <folder> "Document Title"

set -e
export PATH="/usr/bin:$PATH"

# Load .env
if [ -f "/home/ubuntu/.openclaw/workspace/.env" ]; then
    source <(grep -v '^#' /home/ubuntu/.openclaw/workspace/.env | grep -v '^$')
else
    echo "ERROR: .env not found"
    exit 1
fi

if [ $# -lt 2 ]; then
    echo "Usage: $0 <folder> <title>"
    echo "Example: $0 docs/dist 'Video Roadmap'"
    exit 1
fi

FOLDER="$1"
TITLE="$2"

if [ ! -d "$FOLDER" ]; then
    echo "ERROR: Folder not found: $FOLDER"
    exit 1
fi

# Build file list JSON
FILES=()
while IFS= read -r file; do
    RELPATH="${file#$FOLDER/}"
    SIZE=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file")
    CT=$(file -b --mime-type "$file" 2>/dev/null || echo "application/octet-stream")
    FILES+=("{\"path\":\"$RELPATH\",\"size\":$SIZE,\"contentType\":\"$CT\"}")
done < <(find "$FOLDER" -type f)
FILES_JSON="[$(IFS=,; echo "${FILES[*]}")]"
# Validate JSON (optional)
if ! echo "$FILES_JSON" | /usr/bin/jq . > /dev/null 2>&1; then
    echo "❌ Failed to build valid JSON"
    exit 1
fi

echo "📦 Publishing folder: $FOLDER ($(echo "$FILES_JSON" | jq length) files)"

# Init
INIT_RESP=$(curl -s -X POST "https://here.now/api/v1/publish" \
    -H "Authorization: Bearer $HERENOW_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"files\":$FILES_JSON}")

SLUG=$(echo "$INIT_RESP" | /usr/bin/jq -r '.slug // empty')
SITE_URL=$(echo "$INIT_RESP" | /usr/bin/jq -r '.siteUrl // empty')
VERSION_ID=$(echo "$INIT_RESP" | /usr/bin/jq -r '.upload.versionId // empty')
if [ -z "$SLUG" ] || [ -z "$VERSION_ID" ]; then
    echo "❌ here.now init failed: $INIT_RESP"
    exit 1
fi

echo "✅ Created: $SITE_URL"

# Upload files
echo "$INIT_RESP" | /usr/bin/jq -r '.upload.uploads[] | "\(.path)|\(.url)|\(.headers["Content-Type"])"' | while IFS='|' read -r PATH URL CT; do
    echo "   Uploading: $PATH"
    /usr/bin/curl -s -X PUT "$URL" \
        -H "Content-Type: $CT" \
        --data-binary @"$FOLDER/$PATH" > /dev/null
done

# Finalize
/usr/bin/curl -s -X POST "$(echo "$INIT_RESP" | /usr/bin/jq -r '.upload.finalizeUrl')" \
    -H "Authorization: Bearer $HERENOW_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"versionId\":\"$VERSION_ID\"}" > /dev/null

echo "✅ Deployed: $SITE_URL"

# Slack
if [ -n "$SLACK_BOT_TOKEN" ] && [ -n "$SLACK_CHANNEL_ID" ]; then
    MSG="📢 *Document Published*\n*Title:* $TITLE\n*Link:* $SITE_URL\n*Time:* $(date -Iseconds)"
    /usr/bin/curl -s -X POST "https://slack.com/api/chat.postMessage" \
        -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
        -H "Content-type: application/json; charset=utf-8" \
        --data "{\"channel\":\"$SLACK_CHANNEL_ID\",\"text\":\"${MSG//\"/\\\"}\"}" > /dev/null
    echo "✅ Slack notification sent"
else
    echo "⚠️ Slack notification skipped"
fi
