#!/usr/bin/env bash
# System Snapshot — simple, reliable
# Overwrites: snapshots/system-snapshot
# Commits to Git (main branch) and pushes to GitHub
# Also posts summary to Slack #system-monitor

set -e

WORKSPACE="/home/ubuntu/.openclaw/workspace"
SNAPSHOT_DIR="$WORKSPACE/snapshots"
OUTPUT="$SNAPSHOT_DIR/system-snapshot"

mkdir -p "$SNAPSHOT_DIR"

# Create snapshot content (simple)
cat > "$OUTPUT" <<EOF
# JARVIS System Snapshot
Generated: $(date -Iseconds)
Workspace: $WORKSPACE

## Quick Status
- Disk: $(df -h /home/ubuntu 2>/dev/null | tail -1 | awk '{print $5 " used, "$4" free"}' || echo "N/A")
- Size: $(du -sh "$WORKSPACE" 2>/dev/null | cut -f1 || echo "N/A")
- Memory: $(free -m 2>/dev/null | awk '/Mem:/ {print $3"MB/"$2"MB"}' || echo "N/A")
- Load: $(awk '{print $1","$2","$3}' /proc/loadavg 2>/dev/null || echo "N/A")
- Branch: $(git -C "$WORKSPACE" branch --show-current 2>/dev/null || echo "none")
- Tracked files: $(git -C "$WORKSPACE" ls-files 2>/dev/null | wc -l | tr -d ' ' || echo "0")
EOF

# Git: add, commit if changed, push
if git -C "$WORKSPACE" status --porcelain | grep -q "snapshots/system-snapshot"; then
  git -C "$WORKSPACE" add "$OUTPUT"
  git -C "$WORKSPACE" -c user.email="jarvis-backup@localhost" -c user.name="JARVIS Auto" \
    commit -m "chore: update system snapshot $(date -Iseconds)" || true
  git -C "$WORKSPACE" push origin HEAD:main 2>/dev/null || true
fi

# Post to Slack
if [[ -f "$WORKSPACE/.env" ]]; then
  source "$WORKSPACE/.env" 2>/dev/null || true
fi

if [[ -n "${SLACK_BOT_TOKEN:-}" ]]; then
  SIZE=$(du -sh "$WORKSPACE" 2>/dev/null | cut -f1 || echo "N/A")
  FILES=$(git -C "$WORKSPACE" ls-files 2>/dev/null | wc -l | tr -d ' ' || echo "0")
  LOAD=$(awk '{print $1}' /proc/loadavg 2>/dev/null || echo "N/A")
  MSG="🔄 System snapshot updated: \`system-snapshot\` | Size: $SIZE | Files: $FILES | Load: $LOAD"
  ESCAPED=$(echo "$MSG" | sed 's/\\/\\\\/g; s/"/\\"/g')
  curl -s -X POST -H "Authorization: Bearer $SLACK_BOT_TOKEN" -H "Content-type: application/json" \
    --data "{\"channel\":\"C0AHPT66TV3\",\"text\":\"$ESCAPED\",\"mrkdwn\":true}" \
    https://slack.com/api/chat.postMessage >/dev/null 2>&1 || true
fi

echo "Snapshot updated successfully."
