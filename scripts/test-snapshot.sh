#!/usr/bin/env bash
WORKSPACE="/home/ubuntu/.openclaw/workspace"
SNAPSHOT_DIR="$WORKSPACE/snapshots"
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
OUTPUT="$SNAPSHOT_DIR/system-snapshot-$TIMESTAMP.md"

mkdir -p "$SNAPSHOT_DIR"

cat > "$OUTPUT" <<EOF
# JARVIS System Snapshot
Generated: $(date -Iseconds)
Workspace: $WORKSPACE
Hostname: $(hostname)
User: $(whoami)

## Quick Info
- Disk: $(df -h /home/ubuntu | tail -1 | awk '{print $5 " used, "$4" free"}')
- Workspace size: $(du -sh "$WORKSPACE" | cut -f1)
- Memory: $(free -m | awk '/Mem:/ {print $3"MB/"$2"MB"}')
- Load: $(cat /proc/loadavg | awk '{print $1","$2","$3}')
- Git branch: $(git -C "$WORKSPACE" branch --show-current 2>/dev/null || echo "none")
- Tracked files: $(git -C "$WORKSPACE" ls-files 2>/dev/null | wc -l | tr -d ' ')
EOF

echo "Snapshot created: $OUTPUT"