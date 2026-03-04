#!/usr/bin/env bash
# JARVIS System Health Snapshot — Compact JSON
# Run manually or via cron to get a one-line health summary

set -euo pipefail

WORKSPACE="/home/ubuntu/.openclaw/workspace"
BACKUP_SYS="${WORKSPACE}/backup-system"
BACKUP_REPO="${BACKUP_SYS}/backup-repo"
HEALTH_LOG="${WORKSPACE}/.health.log"
WATCHDOG_LOG="${WORKSPACE}/watchdog.log"
GATEWAY_URL="http://127.0.0.1:18789/health"

# Helper: json escape
json_escape() {
  printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null || printf '"%s"' "$1"
}

# Gather metrics
TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

# Gateway
GATEWAY_UP=0
if curl -sf --max-time 2 "$GATEWAY_URL" >/dev/null 2>&1; then
  GATEWAY_UP=1
fi

# Disk
DISK_TOTAL=$(df -h "$WORKSPACE" | tail -1 | awk '{print $2}')
DISK_USED=$(df -h "$WORKSPACE" | tail -1 | awk '{print $3}')
DISK_FREE=$(df -h "$WORKSPACE" | tail -1 | awk '{print $4}')
DISK_PCT=$(df -h "$WORKSPACE" | tail -1 | awk '{print $5}' | tr -d '%')

# Memory (if available)
if command -v free >/dev/null 2>&1; then
  MEM_TOTAL=$(free -h | awk '/Mem:/ {print $2}')
  MEM_USED=$(free -h | awk '/Mem:/ {print $3}')
  MEM_FREE=$(free -h | awk '/Mem:/ {print $4}')
else
  MEM_TOTAL="N/A"
  MEM_USED="N/A"
  MEM_FREE="N/A"
fi

# Load average
LOAD_1=$(awk '{print $1}' /proc/loadavg 2>/dev/null || echo "0")
LOAD_5=$(awk '{print $2}' /proc/loadavg 2>/dev/null || echo "0")
LOAD_15=$(awk '{print $3}' /proc/loadavg 2>/dev/null || echo "0")

# Backup repo
if [[ -d "$BACKUP_REPO/.git" ]]; then
  BACKUP_REPO_EXISTS=1
  LAST_COMMIT_DATE=$(git -C "$BACKUP_REPO" log -1 --format=%ci 2>/dev/null || echo "none")
  if [[ "$LAST_COMMIT_DATE" != "none" ]]; then
    LAST_COMMIT_EPOCH=$(date -d "$LAST_COMMIT_DATE" +%s 2>/dev/null || echo "0")
    NOW_EPOCH=$(date +%s)
    AGE_HOURS=$(( (NOW_EPOCH - LAST_COMMIT_EPOCH) / 3600 ))
    COMMIT_COUNT=$(git -C "$BACKUP_REPO" rev-list --count HEAD 2>/dev/null || echo "0")
    REPO_SIZE=$(du -sh "$BACKUP_REPO" 2>/dev/null | awk '{print $1}' || echo "0")
  else
    AGE_HOURS=0
    COMMIT_COUNT=0
    REPO_SIZE="0"
  fi
else
  BACKUP_REPO_EXISTS=0
  AGE_HOURS=-1
  COMMIT_COUNT=0
  REPO_SIZE="0"
fi

# Recent errors in backup log (last 24h)
if [[ -f "${BACKUP_SYS}/logs/backup.log" ]]; then
  BACKUP_ERRORS=$(grep -i "ERROR" "${BACKUP_SYS}/logs/backup.log" | tail -10 | wc -l)
  BACKUP_WARNINGS=$(grep -i "WARN" "${BACKUP_SYS}/logs/backup.log" | tail -10 | wc -l)
else
  BACKUP_ERRORS=0
  BACKUP_WARNINGS=0
fi

# Watchdog last run
if [[ -f "$WATCHDOG_LOG" ]]; then
  WATCHDOG_LAST=$(tail -1 "$WATCHDOG_LOG" | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} [0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}' || echo "none")
else
  WATCHDOG_LAST="none"
fi

# Build JSON
cat <<EOF
{
  "timestamp": "$TIMESTAMP",
  "gateway": {
    "up": $GATEWAY_UP,
    "url": "$GATEWAY_URL"
  },
  "disk": {
    "total": "$DISK_TOTAL",
    "used": "$DISK_USED",
    "free": "$DISK_FREE",
    "used_pct": $DISK_PCT
  },
  "memory": {
    "total": "$MEM_TOTAL",
    "used": "$MEM_USED",
    "free": "$MEM_FREE"
  },
  "load_avg": {
    "1m": $LOAD_1,
    "5m": $LOAD_5,
    "15m": $LOAD_15
  },
  "backup": {
    "repo_exists": $BACKUP_REPO_EXISTS,
    "commits": $COMMIT_COUNT,
    "size": "$REPO_SIZE",
    "last_backup_hours_ago": $AGE_HOURS,
    "errors_24h": $BACKUP_ERRORS,
    "warnings_24h": $BACKUP_WARNINGS
  },
  "watchdog": {
    "last_run": "$(json_escape "$WATCHDOG_LAST")"
  }
}
EOF