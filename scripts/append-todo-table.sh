#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.env"

TMP=$(mktemp)

cat >> "$SCRIPT_DIR/../MEMORY.md" <<'EOF'

## Todo List (Supabase)

| ID | Title | Priority | Due Date | Status |
|---|-------|----------|----------|--------|
EOF

curl -s -X GET "$SUPABASE_URL/rest/v1/todo?select=id,title,priority,due_date,status" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" | jq -r '.[] | "| \(.id) | \(.title) | \(.priority) | \(.due_date | split("T")[0]) | \(.status) |"' >> "$SCRIPT_DIR/../MEMORY.md"

rm -f "$TMP"
echo "Appended todo table to MEMORY.md"
