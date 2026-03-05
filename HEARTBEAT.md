# HEARTBEAT.md

# Periodic health checks for JARVIS (runs approx every 30 minutes)

## System Health
- ./scripts/health-monitor.sh

## Backup System Health
- /home/ubuntu/.openclaw/workspace/backup-system/scripts/health-backup.sh

## Optional checks (enable when ready)
# - skill: google-workspace calendar-list --days 2
# - skill: google-workspace gmail-check --unread
# - ./scripts/memory-logger.sh (daily via cron instead)
# - researcher: "Check Twitter for mentions of agency name"

## Notes
# The health-monitor.sh script checks gateway, disk space, backup age, etc.
# The backup health check validates repository size, last backup time, and config.
# Adjust thresholds in scripts if needed.

# End of tasks