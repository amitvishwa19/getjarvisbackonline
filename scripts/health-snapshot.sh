#!/usr/bin/env bash
WORKSPACE="/home/ubuntu/.openclaw/workspace"
GATEWAY="down"
if curl -sf --max-time 2 http://127.0.0.1:18789/health >/dev/null 2>&1; then GATEWAY="up"; fi
DISK=$(df -h "$WORKSPACE" | tail -1)
DISK_TOTAL=$(echo "$DISK" | awk '{print $2}')
DISK_USED=$(echo "$DISK" | awk '{print $3}')
DISK_FREE=$(echo "$DISK" | awk '{print $4}')
DISK_PCT=$(echo "$DISK" | awk '{print $5}' | tr -d '%')
LOAD1=$(awk '{print $1}' /proc/loadavg)
LOAD5=$(awk '{print $2}' /proc/loadavg)
LOAD15=$(awk '{print $3}' /proc/loadavg)
NOW=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
echo "{\"timestamp\":\"$NOW\",\"gateway\":{\"up\":$([ \"$GATEWAY\" = up ] && echo 1 || echo 0)},\"disk\":{\"total\":\"$DISK_TOTAL\",\"used\":\"$DISK_USED\",\"free\":\"$DISK_FREE\",\"used_pct\":$DISK_PCT},\"load\":{\"1m\":$LOAD1,\"5m\":$LOAD5,\"15m\":$LOAD15}}"
