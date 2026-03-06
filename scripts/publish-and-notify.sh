#!/bin/bash

# publish-and-notify.sh
# Automated document publishing + Slack notification
# Usage: ./publish-and-notify.sh <markdown-file> <title>

set -e

# Load .env
if [ -f "/home/ubuntu/.openclaw/workspace/.env" ]; then
    source <(grep -v '^#' /home/ubuntu/.openclaw/workspace/.env | grep -v '^$')
else
    echo "ERROR: .env not found"
    exit 1
fi

# Check args
if [ $# -lt 2 ]; then
    echo "Usage: $0 <markdown-file> <title>"
    echo "Example: $0 docs/roadmap.md 'My Project Roadmap'"
    exit 1
fi

INPUT_FILE="$1"
TITLE="$2"

# Validate file
if [ ! -f "$INPUT_FILE" ]; then
    echo "ERROR: File not found: $INPUT_FILE"
    exit 1
fi

# Create temporary dist folder
DIST_DIR="/tmp/publish-$(date +%s)"
mkdir -p "$DIST_DIR"

# Convert markdown to HTML (using pandoc if available, else simple)
if command -v pandoc &> /dev/null; then
    pandoc "$INPUT_FILE" -o "$DIST_DIR/index.html" --metadata title="$TITLE" --self-contained
else
    # Simple conversion: just wrap in basic HTML
    echo "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>$TITLE</title></head><body><pre>" > "$DIST_DIR/index.html"
    cat "$INPUT_FILE" >> "$DIST_DIR/index.html"
    echo "</pre></body></html>" >> "$DIST_DIR/index.html"
fi

echo "📦 Prepared: $DIST_DIR/index.html"

# ============ PUBLISH TO HERE.NOW ============

if [ -z "$HERENOW_API_KEY" ]; then
    echo "⚠️ HERENOW_API_KEY not set, skipping here.now"
    PUBLISH_URL=""
else
    echo "🚀 Publishing to here.now..."

    # 1. Init
    FILES_JSON=$(ls -l "$DIST_DIR" | awk '{print $9}' | while read f; do
        SIZE=$(stat -c%s "$DIST_DIR/$f")
        CT=$(file -b --mime-type "$DIST_DIR/$f")
        echo "{\"path\":\"$f\",\"size\":$SIZE,\"contentType\":\"$CT\"}"
    done | paste -sd "," - | sed 's/^/[/' | sed 's/$/]/')

    INIT_RESP=$(curl -s -X POST "https://here.now/api/v1/publish" \
        -H "Authorization: Bearer $HERENOW_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{\"files\":$FILES_JSON}")

    SLUG=$(echo "$INIT_RESP" | jq -r '.slug // empty')
    SITE_URL=$(echo "$INIT_RESP" | jq -r '.siteUrl // empty')
    VERSION_ID=$(echo "$INIT_RESP" | jq -r '.upload.versionId // empty')
    FINALIZE_URL=$(echo "$INIT_RESP" | jq -r '.upload.finalizeUrl // empty')
    UPLOADS=$(echo "$INIT_RESP" | jq -r '.upload.uploads[]')

    if [ -z "$SLUG" ] || [ -z "$UPLOADS" ]; then
        echo "❌ here.now init failed: $INIT_RESP"
        PUBLISH_URL=""
    else
        echo "✅ Created: $SITE_URL (slug: $SLUG)"

        # 2. Upload files
        echo "$UPLOADS" | while read -r upload; do
            PATH=$(echo "$upload" | jq -r '.path')
            URL=$(echo "$upload" | jq -r '.url')
            echo "   Uploading: $PATH"
            curl -s -X PUT "$URL" \
                -H "Content-Type: $(echo "$upload" | jq -r '.headers.Content-Type')" \
                --data-binary @"$DIST_DIR/$PATH" > /dev/null
        done

        # 3. Finalize
        curl -s -X POST "$FINALIZE_URL" \
            -H "Authorization: Bearer $HERENOW_API_KEY" \
            -H "Content-Type: application/json" \
            -d "{\"versionId\":\"$VERSION_ID\"}" > /dev/null

        echo "✅ Deployed to: $SITE_URL"
        PUBLISH_URL="$SITE_URL"
    fi
fi

# ============ FALLBACK: NETLIFY DROP (manual) ============
if [ -z "$PUBLISH_URL" ]; then
    echo "📌 Manual Netlify Drop:"
    echo "   Open https://app.netlify.com/drop and drag: $DIST_DIR"
    echo "   (No automated fallback available without token)"
    PUBLISH_URL="(manual upload needed — see $DIST_DIR)"
fi

# ============ SLACK NOTIFICATION ============
if [ -n "$SLACK_BOT_TOKEN" ] && [ -n "$SLACK_CHANNEL_ID" ]; then
    echo "📨 Sending Slack notification..."
    MSG="📢 *Document Published*\n*Title:* $TITLE\n*Link:* $PUBLISH_URL\n*Time:* $(date -Iseconds)"
    curl -s -X POST "https://slack.com/api/chat.postMessage" \
        -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
        -H "Content-type: application/json; charset=utf-8" \
        --data "{\"channel\":\"$SLACK_CHANNEL_ID\",\"text\":\"${MSG//\"/\\\"}\"}" > /dev/null
    echo "✅ Slack notification sent to $SLACK_CHANNEL_ID"
else
    echo "⚠️ Slack notification skipped (SLACK_BOT_TOKEN or SLACK_CHANNEL_ID not set)"
fi

# ============ CLEANUP ============
rm -rf "$DIST_DIR"

echo "✅ Done."
