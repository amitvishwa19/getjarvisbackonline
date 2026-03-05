#!/usr/bin/env bash
# Restore from a backup commit
# Usage: restore.sh <commit-hash> [target-dir]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${SCRIPT_DIR}/../config/backup.conf"
source "$CONFIG" 2>/dev/null || { echo "Cannot load config"; exit 1; }

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <commit-hash> [target-dir]"
  echo "Example: $0 abc123 /restore/path"
  exit 1
fi

COMMIT_HASH="$1"
TARGET_DIR="${2:-.}"

# Ensure target exists
mkdir -p "$TARGET_DIR"

echo "Restoring commit $COMMIT_HASH from $BACKUP_REPO"
echo "Target: $TARGET_DIR"

# Create temp workdir
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Extract all files from that commit
git -C "$BACKUP_REPO" show "$COMMIT_HASH" --name-only | while read -r file; do
  [[ -z "$file" ]] && continue
  if [[ -f "$BACKUP_REPO/$file" ]]; then
    cp "$BACKUP_REPO/$file" "$TEMP_DIR/"
  fi
done

# Extract archives
echo "Extracting archives..."
for arc in "$TEMP_DIR"/*; do
  [[ -f "$arc" ]] || continue
  base=$(basename "$arc")
  # Remove extensions
  dir_name="${base%.tar.gz}"
  dir_name="${dir_name%.tar}"
  dir_name="${dir_name%.gz}"
  dir_name="${dir_name%.gpg}"

  # Decrypt if needed
  if [[ "$base" == *.gpg ]]; then
    echo "Decrypting $base..."
    gpg --batch --yes --decrypt --output "${TEMP_DIR}/${dir_name}" "$arc" || { echo "Decrypt failed"; exit 1; }
    arc="${TEMP_DIR}/${dir_name}"
    base="$dir_name"
  fi

  # Extract
  echo "Extracting $base → $TARGET_DIR/$dir_name"
  mkdir -p "$TARGET_DIR/$dir_name"
  if [[ "$base" == *.tar.gz ]]; then
    tar -xzf "$arc" -C "$TARGET_DIR/$dir_name"
  elif [[ "$base" == *.tar ]]; then
    tar -xf "$arc" -C "$TARGET_DIR/$dir_name"
  else
    echo "Unknown format: $base (skipping)"
  fi
done

echo "✅ Restore complete"
echo "Files extracted to: $TARGET_DIR"