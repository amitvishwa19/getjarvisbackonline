#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.env"

TMP_LOCAL=$(mktemp)
TMP_DB=$(mktemp)
TMP_NEW_LOCAL=$(mktemp)
TMP_NEW_DB=$(mktemp)

# 1) Collect local todos from MEMORY.md "## Pending Tasks"
# Extract lines after heading until next heading, keep only bullet lines, strip hyphen and spaces, dedup
sed -n '/^## Pending Tasks/,/^## /p' "$SCRIPT_DIR/../MEMORY.md" |
  grep '^- ' |
  sed -e 's/^- *//' -e 's/[[:space:]]*$//' |
  sed '/^$/d' |
  sort -u > "$TMP_LOCAL"

# 2) Fetch DB titles
curl -s --max-time 10 -X GET "$SUPABASE_URL/rest/v1/todo?select=title" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" |
  jq -r '.[].title // empty' |
  sed 's/[[:space:]]*$//' |
  sort -u > "$TMP_DB"

# 3) Diff
comm -23 "$TMP_LOCAL" "$TMP_DB" > "$TMP_NEW_LOCAL"   # local-only → insert to DB
comm -13 "$TMP_LOCAL" "$TMP_DB" > "$TMP_NEW_DB"     # DB-only → insert to local

NL=$(wc -l < "$TMP_NEW_LOCAL")
NDB=$(wc -l < "$TMP_NEW_DB")

if [ "$NL" -eq 0 ] && [ "$NDB" -eq 0 ]; then
  echo "$(date): Sync: everything up to date."
  rm -f "$TMP_LOCAL" "$TMP_DB" "$TMP_NEW_LOCAL" "$TMP_NEW_DB"
  exit 0
fi

# A) Local → DB: insert new local todos with auto-description
if [ "$NL" -gt 0 ]; then
  echo "$(date): Syncing $NL new local todos to DB..."
  while IFS= read -r t; do
    [ -z "$t" ] && continue
    case "$(echo "$t" | tr '[:upper:]' '[:lower:]')" in
      *whatsapp*|*webstore*|*business*api*) d="Explore WhatsApp WebStore/Business API: review official documentation, pricing tiers, setup requirements, message templates, and rate limits. Assess feasibility of automation (sending posts, receiving replies). Provide a comprehensive report with code samples and limitations." ;;
      *ludo*|*game*) d="Begin development of a Ludo game. Define game rules, UI/UX design (board, pieces, dice), core mechanics (multiplayer, turn logic, animations), and backend (if networked). Prioritize mobile-friendly interface using React Native or web-first approach." ;;
      *carewell*|*demo*|*scheduler*|*booking*) d="Set up a demo scheduling system for Carewell. Integrate calendar functionality (e.g., Google Calendar) and a booking mechanism to allow leads to book demo appointments automatically. Include calendar invite generation, timezone handling, and notification reminders via Slack/email." ;;
      *facebook*|*poster*|*skill*) d="Evaluate the existing Facebook Poster skill. Propose modifications to use direct Graph API calls (bypass browser) for improved stability. Outline required permissions, token management, and error handling." ;;
      *instagram*) d="Create a standalone curl-based script to test Instagram Business API: authenticate, upload a media object, add caption, and retrieve post metrics. Include error handling and Slack notification on success/failure." ;;
      *slack*|*token*|*scope*|*webhook*) d="Diagnose Slack bot token permissions. If Slack API indicates missing 'chat:write' scope, generate a new OAuth token with proper scopes or switch to Incoming Webhook for simple messaging. Update .env and test via scripts." ;;
      *backup*|*task*scheduler*) d="Fix Windows Task Scheduler backup tasks that are currently set to 'Run only when user is logged on'. Change to 'Run whether user is logged on or not' and store password. Test backup execution manually and verify logs." ;;
      *browser*|*install*) d="If browser automation becomes necessary, install a headless browser (e.g., Chromium or Puppeteer). Configure environment variables, PATH, and test basic automation scripts. Evaluate security and performance impact." ;;
      *system*rule*|*curl*|*api*call*) d="Enforce a system-wide rule: All API integrations must use direct HTTP calls (curl/fetch) instead of browser automation due to lack of browser installation on the server. This ensures reliability and avoids subagent timeouts." ;;
      *) d="Implement the task: '$t'. This involves planning, execution, testing, and documentation. Define acceptance criteria, estimate effort, track progress, and deliver a working solution meeting quality standards." ;;
    esac
    due_date="$(date -d "+1 day" +%Y-%m-%d)T00:00:00Z"
    JSON=$(jq -n --arg T "$t" --arg D "$d" --argjson p 2 --arg DD "$due_date" --arg s "pending" '{title: $T, description: $D, priority: $p, due_date: $DD, status: $s}')
    # Insert, capture response
    resp=$(curl -s -w "\n%{http_code}" -X POST "$SUPABASE_URL/rest/v1/todo" \
      -H "apikey: $SUPABASE_SERVICE_KEY" \
      -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
      -H "Content-Type: application/json" \
      -d "$JSON")
    body=$(echo "$resp" | sed '$d')
    code=$(echo "$resp" | tail -n1)
    if [[ "$code" =~ ^(200|201|204)$ ]]; then
      echo "  → Inserted: $t"
    else
      echo "  → Failed ($code): $t" >&2
    fi
  done < "$TMP_NEW_LOCAL"
fi

# B) DB → Local: append new DB todos to MEMORY.md under "## Pending Tasks"
if [ "$NDB" -gt 0 ]; then
  echo "$(date): Syncing $NDB new DB todos to MEMORY.md..."
  BULLETS=$(mktemp)
  while IFS= read -r t; do
    echo "- $t" >> "$BULLETS"
  done < "$TMP_NEW_DB"

  MEM_FILE="$SCRIPT_DIR/../MEMORY.md"
  if grep -q '^## Pending Tasks' "$MEM_FILE"; then
    # Insert bullets after the heading line (before any existing bullets)
    awk -v bullets="$(cat "$BULLETS")" '
      /^## Pending Tasks/ { print; print bullets; next }
      { print }
    ' "$MEM_FILE" > "${MEM_FILE}.new" && mv "${MEM_FILE}.new" "$MEM_FILE"
  else
    {
      echo ""
      echo "## Pending Tasks"
      echo ""
      cat "$BULLETS"
    } >> "$MEM_FILE"
  fi
  rm -f "$BULLETS"
  echo "  → Appended to MEMORY.md"
fi

rm -f "$TMP_LOCAL" "$TMP_DB" "$TMP_NEW_LOCAL" "$TMP_NEW_DB"
echo "$(date): Sync complete."
