#!/usr/bin/env bash
# JARVIS Backup Health Check
# Verifies backup repository health, disk space, and last backup age.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${SCRIPT_DIR}/config/backup.conf"
source "$CONFIG" 2>/dev/null || { echo "Cannot load config"; exit 1; }

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=== JARVIS Backup Health Check ==="
date

# 1. Repo exists
if [[ ! -d "$BACKUP_REPO/.git" ]]; then
  echo -e "${RED}✗ Backup repo not initialized${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Repository exists${NC}"

# 2. Disk space (>5GB free)
FREE_GB=$(df -BG "$BACKUP_REPO" | tail -1 | awk '{print $4}' | sed 's/G//')
if (( FREE_GB < 5 )); then
  echo -e "${RED}✗ Low disk space: ${FREE_GB}GB free${NC}"
else
  echo -e "${GREEN}✓ Disk space: ${FREE_GB}GB free${NC}"
fi

# 3. Last backup age (<48h)
LAST_DATE=$(git -C "$BACKUP_REPO" log -1 --format=%ci 2>/dev/null || echo "none")
if [[ "$LAST_DATE" == "none" ]]; then
  echo -e "${YELLOW}⚠ No backups yet${NC}"
else
  LAST_EPOCH=$(date -d "$LAST_DATE" +%s)
  NOW_EPOCH=$(date +%s)
  HOURS=$(( (NOW_EPOCH - LAST_EPOCH) / 3600 ))
  if (( HOURS > 48 )); then
    echo -e "${RED}✗ Last backup is ${HOURS}h old (stale)${NC}"
  else
    echo -e "${GREEN}✓ Last backup: ${HOURS}h ago${NC}"
  fi
fi

# 4. Repo size
SIZE=$(du -sh "$BACKUP_REPO" 2>/dev/null | awk '{print $1}')
echo "  Repository size: $SIZE"

# 5. Config syntax test
if "$SCRIPT_DIR/backup.sh" --test >/dev/null 2>&1; then
  echo -e "${GREEN}✓ Config valid${NC}"
else
  echo -e "${RED}✗ Config invalid${NC}"
  exit 1
fi

# 6. Backup paths exist
echo "Checking backup paths..."
for p in $BACKUP_PATHS; do
  if [[ -e "$p" ]]; then
    echo -e "  ${GREEN}✓ $p${NC}"
  else
    echo -e "  ${YELLOW}⚠ $p (missing)${NC}"
  fi
done

echo "=== Health check complete ==="