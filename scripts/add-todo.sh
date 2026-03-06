#!/bin/bash
set -euo pipefail

usage() {
  echo "Usage: $0 --title \"Title\" --description \"Desc\" --priority N --due-date YYYY-MM-DD --status pending|in_progress|done|cancelled"
  echo "Example: $0 --title \"Research WhatsApp\" --description \"Explore API\" --priority 1 --due-date 2026-03-08 --status pending"
  exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.env"

# Defaults
title=""
description=""
priority=2
due_date=""
status="pending"

# Parse args
while [[ $# -gt 0 ]]; do
  case $1 in
    --title) title="$2"; shift 2;;
    --description) description="$2"; shift 2;;
    --priority) priority="$2"; shift 2;;
    --due-date) due_date="$2"; shift 2;;
    --status) status="$2"; shift 2;;
    -h|--help) usage;;
    *) echo "Unknown arg: $1"; usage;;
  esac
done

if [ -z "$title" ] || [ -z "$due_date" ]; then
  echo "Error: --title and --due-date are required"
  usage
fi

# Format due_date: ensure it ends with T00:00:00Z if no time part
if [[ "$due_date" != *"T"* ]]; then
  due_date="${due_date}T00:00:00Z"
fi

# Validate status
if ! [[ "$status" =~ ^(pending|in_progress|done|cancelled)$ ]]; then
  echo "Error: status must be one of pending, in_progress, done, cancelled"
  exit 1
fi

# Build JSON payload
JSON=$(jq -n \
  --arg t "$title" \
  --arg d "$description" \
  --argjson p "$priority" \
  --arg dd "$due_date" \
  --arg s "$status" \
  '{title: $t, description: $d, priority: $p, due_date: $dd, status: $s}')

# Insert
response=$(curl -s -X POST "$SUPABASE_URL/rest/v1/todo" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -d "$JSON")

# Check result
id=$(echo "$response" | jq -r '.id' 2>/dev/null || true)
if [ -n "$id" ] && [ "$id" != "null" ]; then
  echo "✅ Added todo: $title (ID: $id)"
else
  echo "❌ Failed to add todo. Response:"
  echo "$response" | jq .
fi
