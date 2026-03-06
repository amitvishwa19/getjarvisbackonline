#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.env"

# Get all IDs
IDS=$(curl -s -X GET "$SUPABASE_URL/rest/v1/todo?select=id" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" | jq -r '.[].id')

COUNT=0
for id in $IDS; do
  curl -s -X PATCH "$SUPABASE_URL/rest/v1/todo?id=eq.$id" \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
    -H "Content-Type: application/json" \
    -d '{"due_date":"2026-03-08T00:00:00Z"}' >/dev/null
  COUNT=$((COUNT+1))
done

echo "Updated $COUNT todos with due_date 2026-03-08"
