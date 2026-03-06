#!/bin/bash
set -e

# Load env
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.env"

SQL="CREATE TABLE IF NOT EXISTS todo (
  id BIGSERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  priority INTEGER DEFAULT 2 CHECK (priority IN (1,2,3)),
  due_date TIMESTAMPTZ,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending','in_progress','done','cancelled')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);"

echo "Creating table 'todo'..."
JSON=$(jq -n --arg q "$SQL" '{query: $q}')
curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/exec_sql" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -d "$JSON" | jq '.' 2>/dev/null || echo "SQL executed (response above)."
