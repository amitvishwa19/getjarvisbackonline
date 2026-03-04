#!/usr/bin/env bash
# JARVIS System Status — Human readable summary
# Run via cron (e.g., every 6 hours) or manually

set -euo pipefail

WORKSPACE="/home/ubuntu/.openclaw/workspace"
BACKUP_REPO="${WORKSPACE}/backup-system/backup-repo"
NOW=$(date '+%Y-%m-%d %H:%M:%S')

echo "=== JARVIS SYSTEM STATUS ==="
echo "Timestamp: $NOW"
echo ""

# Memory
echo "--- Memory ---"
if command -v free >/dev/null 2>&1; then
  free -h | awk '/Mem:/ {print "Total: "$2" | Used: "$3" | Free: "$4" | Usage: "$3/$2" ("$5"%)"}'
else
  echo "free command not available"
fi
echo ""

# Disk — /home/ubuntu
echo "--- Disk (/home/ubuntu) ---"
df -h "$WORKSPACE" | tail -1 | awk '{print "Total: "$2" | Used: "$3" ("$5") | Free: "$4""}'
echo ""

# Disk — root
echo "--- Disk (/) ---"
df -h / | tail -1 | awk '{print "Total: "$2" | Used: "$3" ("$5") | Free: "$4""}'
echo ""

# Workspace size
echo "--- Workspace Size ---"
if [[ -d "$WORKSPACE" ]]; then
  du -sh "$WORKSPACE" 2>/dev/null || echo "Size calculation failed"
else
  echo "Workspace not found"
fi
echo ""

# Load average
echo "--- Load Average (1/5/15 min) ---"
if [[ -f /proc/loadavg ]]; then
  awk '{print $1" | "$2" | "$3}' /proc/loadavg
else
  echo "Load average not available"
fi
echo ""

# Gateway health
echo "--- Gateway Health ---"
if curl -sf --max-time 3 http://127.0.0.1:18789/health >/dev/null 2>&1; then
  echo "Gateway is UP ✅"
else
  echo "Gateway is DOWN ❌"
fi
echo ""

# Backup status
echo "--- Backup Status ---"
if [[ -d "$BACKUP_REPO/.git" ]]; then
  LAST_DATE=$(git -C "$BACKUP_REPO" log -1 --format=%ci 2>/dev/null || echo "none")
  if [[ "$LAST_DATE" != "none" ]]; then
    LAST_EPOCH=$(date -d "$LAST_DATE" +%s 2>/dev/null || echo "0")
    NOW_EPOCH=$(date +%s)
    HOURS=$(( (NOW_EPOCH - LAST_EPOCH) / 3600 ))
    echo "Last backup: ${HOURS}h ago"
    SIZE=$(du -sh "$BACKUP_REPO" 2>/dev/null | awk '{print $1}' || echo "0")
    echo "Backup repo size: $SIZE"
    COMMITS=$(git -C "$BACKUP_REPO" rev-list --count HEAD 2>/dev/null || echo "0")
    echo "Total commits: $COMMITS"
  else
    echo "No backups yet"
  fi
else
  echo "Backup repo not initialized"
fi
echo ""

echo "=== END OF STATUS ==="