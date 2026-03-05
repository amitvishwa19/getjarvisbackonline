#!/usr/bin/env bash
# Simple test snapshot — guaranteed to work
WORKSPACE="/home/ubuntu/.openclaw/workspace"
SNAPSHOT_DIR="$WORKSPACE/snapshots"
TIMESTAMP=$(date '+%Y%m%d-%H%M%S')
OUTPUT="$SNAPSHOT_DIR/system-snapshot-$TIMESTAMP.md"

mkdir -p "$SNAPSHOT_DIR"

cat > "$OUTPUT" <<EOF
# JARVIS System Snapshot (Test)
Generated: $(date -Iseconds)
Workspace: $WORKSPACE

## Info
- This is a test snapshot.
- Workspace size: $(du -sh "$WORKSPACE" 2>/dev/null | cut -f1 || echo "N/A")
- Tracked files: $(git -C "$WORKSPACE" ls-files 2>/dev/null | wc -l | tr -d ' ' || echo "0")
- Load: $(awk '{print $1}' /proc/loadavg 2>/dev/null || echo "N/A")

EOF

echo "Snapshot created: $OUTPUT"