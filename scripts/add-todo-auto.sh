#!/bin/bash
set -euo pipefail

usage() {
  echo "Usage: $0 --title \"Title\" [--priority 1|2|3] [--due-date YYYY-MM-DD] [--status pending|in_progress|done|cancelled]"
  echo "Example: $0 --title \"Research WhatsApp WebStore\" --priority 1 --due-date 2026-03-08"
  exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.env"

# Parse args
title=""
priority=2
due_date=""
status="pending"

while [[ $# -gt 0 ]]; do
  case $1 in
    --title) title="$2"; shift 2;;
    --priority) priority="$2"; shift 2;;
    --due-date) due_date="$2"; shift 2;;
    --status) status="$2"; shift 2;;
    -h|--help) usage;;
    *) echo "Unknown arg: $1"; usage;;
  esac
done

if [ -z "$title" ]; then
  echo "Error: --title is required"
  usage
fi

# Auto-generate description based on title keywords (simple rule-based)
desc=""
lower=$(echo "$title" | tr '[:upper:]' '[:lower:]')

if echo "$lower" | grep -qi "whatsapp\|webstore\|business api"; then
  desc="Explore WhatsApp WebStore/Business API: review official documentation, pricing tiers, setup requirements, message templates, and rate limits. Assess feasibility of automation (sending posts, receiving replies). Provide a comprehensive report with code samples and limitations."
elif echo "$lower" | grep -qi "ludo\|game"; then
  desc="Begin development of a Ludo game. Define game rules, UI/UX design (board, pieces, dice), core mechanics (multiplayer, turn logic, animations), and backend (if networked). Prioritize mobile-friendly interface using React Native or web-first approach."
elif echo "$lower" | grep -qi "carewell\|demo.*scheduler\|booking"; then
  desc="Set up a demo scheduling system for Carewell. Integrate calendar functionality (e.g., Google Calendar) and a booking mechanism to allow leads to book demo appointments automatically. Include calendar invite generation, timezone handling, and notification reminders via Slack/email."
elif echo "$lower" | grep -qi "facebook\|poster\|skill"; then
  desc="Evaluate the existing Facebook Poster skill. Propose modifications to use direct Graph API calls (bypass browser) for improved stability. Outline required permissions, token management, and error handling."
elif echo "$lower" | grep -qi "instagram"; then
  desc="Create a standalone curl-based script to test Instagram Business API: authenticate, upload a media object, add caption, and retrieve post metrics. Include error handling and Slack notification on success/failure."
elif echo "$lower" | grep -qi "slack\|token\|scope\|webhook"; then
  desc="Diagnose Slack bot token permissions. If Slack API indicates missing 'chat:write' scope, generate a new OAuth token with proper scopes or switch to Incoming Webhook for simple messaging. Update .env and test via scripts."
elif echo "$lower" | grep -qi "backup\|task.*scheduler"; then
  desc="Fix Windows Task Scheduler backup tasks that are currently set to 'Run only when user is logged on'. Change to 'Run whether user is logged on or not' and store password. Test backup execution manually and verify logs."
elif echo "$lower" | grep -qi "browser\|install"; then
  desc="If browser automation becomes necessary, install a headless browser (e.g., Chromium or Puppeteer). Configure environment variables, PATH, and test basic automation scripts. Evaluate security and performance impact."
elif echo "$lower" | grep -qi "system.*rule\|direct.*curl\|api.*call"; then
  desc="Enforce a system-wide rule: All API integrations must use direct HTTP calls (curl/fetch) instead of browser automation due to lack of browser installation on the server. This ensures reliability and avoids subagent timeouts."
else
  # Generic detailed description based on title
  desc="Implement the task: '$title'. This involves planning, execution, testing, and documentation. Define acceptance criteria, estimate effort, track progress, and deliver a working solution meeting quality standards. Ensure integration with existing systems and adherence to best practices."
fi

# Set default due_date if not provided (3 days from now)
if [ -z "$due_date" ]; then
  due_date=$(date -d "+3 days" +%Y-%m-%d)
fi

# Format due_date to ISO
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
  --arg d "$desc" \
  --argjson p "$priority" \
  --arg dd "$due_date" \
  --arg s "$status" \
  '{title: $t, description: $d, priority: $p, due_date: $dd, status: $s}')

# Insert (Supabase returns 201 with empty body by default; use --fail to error on 4xx/5xx)
if curl -s -f -X POST "$SUPABASE_URL/rest/v1/todo" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -d "$JSON" >/dev/null; then
  echo "✅ Added todo: $title"
  echo "   Description: $desc"
else
  echo "❌ Failed to add todo (HTTP error)."
fi
