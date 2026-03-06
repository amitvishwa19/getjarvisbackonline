#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../.env"

# The 11 titles as they appear in MEMORY.md Pending Tasks (without leading hyphen and space)
titles=(
  "**Carewell Demo Scheduler** — set up demo scheduling for Carewell (calendar integration, booking system)"
  "**Ludo Game Development** — work on Ludo game project today (specific tasks TBD)"
  "**Research WhatsApp WebStore** — explore integration options, API availability, and potential for posting/automation"
  "**System Rule:** Always use direct curl scripts from \`scripts/\` for API calls — subagents unreliable"
  "Consider updating Facebook Poster skill to use direct API calls (bypass browser)"
  "Consider updating social media skills to bypass browser dependency ✅ Updated (but prefer direct scripts)"
  "Create curl-based Instagram test script ✅ Done"
  "Create similar curl script for Instagram Poster"
  "Fix Slack bot token scopes or use Incoming Webhook"
  "Install browser on system if browser automation is desired"
  "Update Backup tasks in Task Scheduler (logon type fix)"
)

for t in "${titles[@]}"; do
  # Generate description based on title keywords (same logic as add-todo-auto)
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

  due_date="2026-03-08T00:00:00Z"
  JSON=$(jq -n --arg T "$t" --arg D "$d" --argjson p 2 --arg DD "$due_date" --arg s "pending" '{title: $T, description: $D, priority: $p, due_date: $DD, status: $s}')
  curl -s -X POST "$SUPABASE_URL/rest/v1/todo" -H "apikey: $SUPABASE_SERVICE_KEY" -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" -H "Content-Type: application/json" -d "$JSON" >/dev/null
  echo "Inserted: $t"
done

echo "Done. Total inserted: ${#titles[@]}"
