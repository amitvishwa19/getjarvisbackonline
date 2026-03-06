#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.env"

TMP=$(mktemp)

# Extract bullet lines from MEMORY.md (Pending Tasks section)
sed -n '/^## Pending Tasks/,/^## /p' "$SCRIPT_DIR/../MEMORY.md" | grep '^- ' | sed 's/^- *//' > "$TMP"

# Extract bullet lines from daily log (To Do section)
sed -n '/## To Do/,/## /p' "$SCRIPT_DIR/../memory/2026-03-05.md" | grep '^- ' | sed 's/^- *//' >> "$TMP"

# Deduplicate
sort -u "$TMP" -o "$TMP"

COUNT=$(wc -l < "$TMP")
echo "Found $COUNT unique todo items. Inserting..."

while IFS= read -r title; do
  [ -z "$title" ] && continue
  JSON=$(jq -n --arg t "$title" '{title: $t, priority: 2, status: "pending"}')
  curl -s -X POST "$SUPABASE_URL/rest/v1/todo" \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
    -H "Content-Type: application/json" \
    -d "$JSON" >/dev/null || echo "Failed: $title"
done < "$TMP"

rm -f "$TMP"
echo "Done."
