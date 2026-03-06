#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.env"

# Map id to generated description (simple expansion)
declare -A DESC

# Fetch current todos
mapfile -t todos < <(curl -s -X GET "$SUPABASE_URL/rest/v1/todo?select=id,title" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" | jq -r '.[] | "\(.id)|\(.title)"')

for entry in "${todos[@]}"; do
  id="${entry%%|*}"
  title="${entry#*|}"
  # Generate description: expand the title into a detailed paragraph
  desc=""
  case "$title" in
    *Carewell*Demo*Scheduler*)
      desc="Set up a demo scheduling system for Carewell. Integrate calendar functionality (e.g., Google Calendar) and a booking mechanism to allow leads to book demo appointments automatically. Include calendar invite generation, timezone handling, and notification reminders via Slack/email."
      ;;
    *Ludo*Game*Development*)
      desc="Begin development of a Ludo game. Define game rules, UI/UX design (board, pieces, dice), core mechanics (multiplayer, turn logic, animations), and backend (if networked). Prioritize mobile-friendly interface using React Native or web-first approach."
      ;;
    *Research*WhatsApp*WebStore*)
      desc="Explore WhatsApp WebStore/Business API: review official documentation, pricing tiers, setup requirements, message templates, and rate limits. Assess feasibility of automation (sending posts, receiving replies). Provide a comprehensive report with code samples and limitations."
      ;;
    *System*Rule*)
      desc="Enforce a system-wide rule: All API integrations must use direct HTTP calls (curl/fetch) instead of browser automation due to lack of browser installation on the server. This ensures reliability and avoids subagent timeouts."
      ;;
    *Consider*updating*Facebook*Poster*skill*)
      desc="Evaluate the existing Facebook Poster skill. Propose modifications to use direct Graph API calls (bypass browser) for improved stability. Outline required permissions, token management, and error handling."
      ;;
    *Consider*updating*social*media*skills*to*bypass*)
      desc="Review current social media skills (Facebook, Instagram) to replace any browser-dependent components with direct API calls. Document changes, test matrices, and deployment steps. Update skill definitions accordingly."
      ;;
    *Create*curl-based*Instagram*test*script*)
      desc="Create a standalone curl-based script to test Instagram Business API: authenticate, upload a media object, add caption, and retrieve post metrics. Include error handling and Slack notification on success/failure."
      ;;
    *Create*similar*curl*script*for*Instagram*Poster*)
      desc="Expand the Instagram test script into a full Poster skill replacement: accept image + caption inputs, handle OAuth tokens, schedule posts if needed, and send Slack notifications. Ensure idempotency and retry logic."
      ;;
    *Fix*Slack*bot*token*scopes*)
      desc="Diagnose Slack bot token permissions. If Slack API indicates missing 'chat:write' scope, generate a new OAuth token with proper scopes or switch to Incoming Webhook for simple messaging. Update .env and test via scripts."
      ;;
    *Install*browser*system*browser*automation*)
      desc="If browser automation becomes necessary, install a headless browser (e.g., Chromium or Puppeteer). Configure environment variables, PATH, and test basic automation scripts. Evaluate security and performance impact."
      ;;
    *Update*Backup*tasks*Task*Scheduler*logon*type*)
      desc="Fix Windows Task Scheduler backup tasks that are currently set to 'Run only when user is logged on'. Change to 'Run whether user is logged on or not' and store password. Test backup execution manually and verify logs."
      ;;
    *)
      desc="(Auto-generated) Additional details to be defined based on the todo title."
      ;;
  esac

  # Update with description
  JSON=$(jq -n --arg d "$desc" '{description: $d}')
  curl -s -X PATCH "$SUPABASE_URL/rest/v1/todo?id=eq.$id" \
    -H "apikey: $SUPABASE_ANON_KEY" \
    -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
    -H "Content-Type: application/json" \
    -d "$JSON" >/dev/null

  echo "Updated id $id: $title"
done

echo "All descriptions set."
