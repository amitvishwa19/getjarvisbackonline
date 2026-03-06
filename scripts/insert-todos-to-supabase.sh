#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.env"

# Extract todos from MEMORY.md and daily logs
ITEMS=()

# From MEMORY.md: lines under "### Pending Tasks" until next heading
# Grab lines starting with "- [" and "- "
while IFS= read -r line; do
  # Clean: remove leading "- " or "- [" etc
  todo=$(echo "$line" | sed 's/^[-*] *//; s/^\[x\] //; s/^\[X\] //; s/^\[ \] //')
  if [ -n "$todo" ]; then
    ITEMS+=("$todo")
  fi
done < <(sed -n '/### Pending Tasks/,/### /p' "$SCRIPT_DIR/../MEMORY.md" | grep '^- ')

# From 2026-03-05.md: under "## To Do"
while IFS= read -r line; do
  todo=$(echo "$line" | sed 's/^[-*] *//')
  if [ -n "$todo" ]; then
    ITEMS+=("$todo")
  fi
done < <(sed -n '/## To Do/,/## /p' "$SCRIPT_DIR/../memory/2026-03-05.md" | grep '^- ')

# Deduplicate
UNIQUE=($(printf "%s\n" "${ITEMS[@]}" | sort -u))

echo "Found ${#UNIQUE[@]} unique todo items. Inserting..."

for todo in "${UNIQUE[@]}"; do
  # JSON encode properly
  JSON=$(jq -n --arg t "$todo" '{title: $t, priority: 2, status: "pending"}')
  echo "Inserting: $todo"
  curl -s -X POST "$SUPABASE_URL/rest/v1/todo" \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
    -H "Content-Type: application/json" \
    -d "$JSON" >/dev/null || echo "Failed: $todo"
done

echo "Done."
