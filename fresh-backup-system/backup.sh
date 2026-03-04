#!/usr/bin/env bash
# JARVIS Backup System — Production Ready
# Creates a compressed, git-versioned backup of critical paths.
# Includes locking, resource limiting, and cleanup.

set -euo pipefail

# ============================================
# Configuration (override with backup.conf)
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/config/backup.conf"

# Load config if exists
if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

# Defaults
: "${BACKUP_PATHS:="/home/ubuntu/.openclaw/workspace"}"
: "${BACKUP_REPO:="${SCRIPT_DIR}/backup-repo"}"
: "${RETENTION_DAYS:=90}"
: "${RETENTION_COUNT:=365}"
: "${COMPRESS_LEVEL:=6}"
: "${COMPRESS_EXT:=tar.gz}"
: "${LOG_FILE:="${HOME}/.openclaw/workspace/backup-system/logs/backup.log"}"
: "${LOG_LEVEL:=info}"
: "${ENCRYPT:=false}"
: "${ENCRYPTION_KEY_ID:=}"
: "${NOTIFY_TELEGRAM:=false}"
: "${NOTIFY_SLACK:=false}"
: "${TELEGRAM_BOT_TOKEN:=}"
: "${TELEGRAM_CHAT_ID:=}"
: "${SLACK_WEBHOOK_URL:=}"
: "${EXCLUDE_PATTERNS:="backup-repo
node_modules
test-site
*.log
*.tmp
.env.example"}"
: "${PRE_HOOK:=}"
: "${POST_HOOK:=}"

# Create log dir
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true

# Lock file prevents concurrent runs
LOCK_DIR="${BACKUP_REPO}/.lock"

# ============================================
# Logging
# ============================================

log() {
  local level="$1"; shift
  local msg="$*"
  local ts=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$ts] [$level] $msg" | tee -a "$LOG_FILE"
}
debug() { [[ "$LOG_LEVEL" == "debug" ]] && log DEBUG "$@"; }
info()  { [[ "$LOG_LEVEL" =~ (debug|info) ]] && log INFO "$@"; }
warn()  { [[ "$LOG_LEVEL" =~ (debug|info|warn) ]] && log WARN "$@"; }
error() { log ERROR "$@"; }

# ============================================
# Locking & Cleanup
# ============================================

acquire_lock() {
  if mkdir "$LOCK_DIR" 2>/dev/null; then
    info "Lock acquired"
    return 0
  else
    error "Another backup is already running"
    return 1
  fi
}

release_lock() {
  rmdir "$LOCK_DIR" 2>/dev/null || true
}
trap release_lock EXIT INT TERM

# ============================================
# Notifications
# ============================================

send_telegram() {
  [[ -n "$TELEGRAM_BOT_TOKEN" && -n "$TELEGRAM_CHAT_ID" ]] || return 0
  local msg="$1"
  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d chat_id="$TELEGRAM_CHAT_ID" \
    -d text="$msg" \
    -d parse_mode="HTML" >/dev/null 2>&1 || warn "Telegram failed"
}

send_slack() {
  [[ -n "$SLACK_WEBHOOK_URL" ]] || return 0
  local msg="$1"
  curl -s -X POST "$SLACK_WEBHOOK_URL" \
    -H 'Content-type: application/json' \
    --data "{\"text\":\"$msg\"}" >/dev/null 2>&1 || warn "Slack failed"
}

notify() {
  local status="$1"; local message="$2"
  local icon; [[ "$status" == "success" ]] && icon="✅" || icon="❌"
  local text="${icon} JARVIS Backup: ${status}\n${message}"

  $NOTIFY_TELEGRAM && send_telegram "$text"
  $NOTIFY_SLACK && send_slack "$text"
}

# ============================================
# Preflight
# ============================================

check_deps() {
  for cmd in git tar gzip; do
    command -v "$cmd" >/dev/null 2>&1 || { error "Missing dependency: $cmd"; return 1; }
  done
  return 0
}

init_repo() {
  [[ -d "$BACKUP_REPO/.git" ]] && return 0
  info "Initializing backup repository at $BACKUP_REPO"
  mkdir -p "$BACKUP_REPO"
  git init "$BACKUP_REPO"
  git -C "$BACKUP_REPO" config user.email "jarvis-backup@localhost"
  git -C "$BACKUP_REPO" config user.name "JARVIS Backup"
}

# ============================================
# Archive Creation
# ============================================

create_archive() {
  local src="$1"
  local out_name="$2"
  local out_path="${BACKUP_REPO}/${out_name}.tar.${COMPRESS_EXT}"

  info "Archiving $src → $(basename "$out_path")"

  # Build exclude file
  local excl_file
  excl_file=$(mktemp)
  while IFS= read -r pat; do
    [[ -z "$pat" ]] && continue
    printf '%s\n' "$pat" >> "$excl_file"
  done <<< "$EXCLUDE_PATTERNS"

  # Archive: cd into source, tar everything, compress
  if [[ -s "$excl_file" ]]; then
    ( cd "$src" && nice -n 19 ionice -c2 -n7 tar -c --exclude-from="$excl_file" . ) | nice -n 19 gzip -${COMPRESS_LEVEL} > "$out_path"
  else
    ( cd "$src" && nice -n 19 ionice -c2 -n7 tar -c . ) | nice -n 19 gzip -${COMPRESS_LEVEL} > "$out_path"
  fi
  rm -f "$excl_file"

  # Optional GPG encryption
  if [[ "$ENCRYPT" == "true" ]] && command -v gpg >/dev/null 2>&1 && [[ -n "$ENCRYPTION_KEY_ID" ]]; then
    info "Encrypting archive"
    gpg --batch --yes --encrypt --recipient "$ENCRYPTION_KEY_ID" --output "${out_path}.gpg" "$out_path"
    rm -f "$out_path"
    echo "${out_path}.gpg"
  else
    echo "$out_path"
  fi
}

# ============================================
# Main Backup Flow
# ============================================

main() {
  info "=== Backup started ==="
  local start=$(date +%s)

  # Pre-hook
  if [[ -n "$PRE_HOOK" ]] && [[ -x "$PRE_HOOK" ]]; then
    info "Running pre-hook"
    "$PRE_HOOK" || { error "Pre-hook failed"; exit 1; }
  fi

  # Lock & deps
  acquire_lock || exit 1
  check_deps || exit 1

  # Init repo
  init_repo

  # Process each source path
  for src in $BACKUP_PATHS; do
    [[ -e "$src" ]] || { warn "Source missing: $src"; continue; }
    local base="$(basename "$src")"
    local ts="$(date +%Y%m%d-%H%M%S)"
    local archive_name="backup-${base}-${ts}"
    local archive_path
    archive_path="$(create_archive "$src" "$archive_name")"

    info "Created: $(basename "$archive_path")"
  done

  # Git commit (only if changes)
  git -C "$BACKUP_REPO" add -A
  if git -C "$BACKUP_REPO" diff-index --quiet HEAD --; then
    info "No changes to commit"
  else
    git -C "$BACKUP_REPO" commit -m "Backup $(date -u '+%Y-%m-%d %H:%M UTC')"
  fi

  # Retention: prune old commits
  info "Applying retention: keep ≤ $RETENTION_COUNT commits, last $RETENTION_DAYS days"
  local total
  total=$(git -C "$BACKUP_REPO" rev-list --count HEAD 2>/dev/null || echo "0")
  if (( total > RETENTION_COUNT )); then
    git -C "$BACKUP_REPO" reflog expire --expire=now --all
    git -C "$BACKUP_REPO" gc --prune=now --aggressive
    info "Pruned old commits"
  fi

  local end=$(date +%s)
  local dur=$((end-start))
  info "Backup completed in ${dur}s"
  notify success "Duration: ${dur}s"

  # Post-hook
  if [[ -n "$POST_HOOK" ]] && [[ -x "$POST_HOOK" ]]; then
    info "Running post-hook"
    "$POST_HOOK" || warn "Post-hook failed (non-critical)"
  fi
}

# ============================================
# Entrypoint
# ============================================

case "${1:-}" in
  --test)
    echo "Backup configuration loaded"
    echo "BACKUP_PATHS = $BACKUP_PATHS"
    echo "BACKUP_REPO  = $BACKUP_REPO"
    echo "RETENTION   = ${RETENTION_DAYS}d / ${RETENTION_COUNT} commits"
    echo "EXCLUDES    = $EXCLUDE_PATTERNS"
    exit 0
    ;;
  --restore)
    if [[ -z "${2:-}" ]]; then
      echo "Usage: $0 --restore <commit-hash> [target-dir]"
      exit 1
    fi
    exec "${SCRIPT_DIR}/scripts/restore.sh" "$2" "${3:-.}"
    ;;
  *)
    main "$@"
    ;;
esac