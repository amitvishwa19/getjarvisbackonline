#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.env"

MEM_FILE="$SCRIPT_DIR/../MEMORY.md"

# 1) Ensure "## Pending Tasks" section exists and contains bullets from DB
# Fetch titles from DB
mapfile -t titles < <(curl -s --max-time 5 -X GET "$SUPABASE_URL/rest/v1/todo?select=title" -H "apikey: $SUPABASE_SERVICE_KEY" -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" | jq -r '.[].title')

# Build bullet lines
BULLETS=$(printf "%s\n" "${titles[@]}" | sed 's/^/- /')

# Check if "## Pending Tasks" exists
if grep -q '^## Pending Tasks' "$MEM_FILE"; then
  # Replace the section: from the heading to before the next heading
  # Use awk to print up to the heading, then bullets, then skip old section until next heading, then rest
  awk -v bullets="$BULLETS" '
    /^## Pending Tasks/ { print; print bullets; skip=1; next }
    /^## / && skip { skip=0 }
    !skip { print }
  ' "$MEM_FILE" > "${MEM_FILE}.new" && mv "${MEM_FILE}.new" "$MEM_FILE"
else
  # Append at end
  {
    echo ""
    echo "## Pending Tasks"
    echo ""
    echo "$BULLETS"
  } >> "$MEM_FILE"
fi

# 2) Append/Replace Todo List (Supabase) table
# Remove existing table if present
sed -i '/^## Todo List (Supabase)/,/^## /d' "$MEM_FILE" 2>/dev/null || true

# Append table
cat >> "$MEM_FILE" <<'EOF'

## Todo List (Supabase)

| ID | Title | Priority | Due Date | Status |
|---|-------|----------|----------|--------|
EOF

# Fill rows
curl -s --max-time 5 -X GET "$SUPABASE_URL/rest/v1/todo?select=id,title,priority,due_date,status" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" | jq -r '.[] | "| \(.id) | \(.title) | \(.priority) | \(.due_date | split("T")[0]) | \(.status) |"' >> "$MEM_FILE"

echo "MEMORY.md updated with Pending Tasks and Todo table."
