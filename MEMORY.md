# MEMORY.md — Curated Long-Term Memories

**Agent:** Jarvis 🤖
**User:** Amit (Devlomatix Solutions)
**Last updated:** 2026-03-06 (Asia/Kolkata)

## System Setup
- **Browser Status:** No browser installed (Chrome/Brave/Edge/Chromium). All social media integrations (Facebook, Instagram) must use direct API calls (curl/fetch) instead of browser automation.
- **Shared Memory:** All channels use `memory/shared-conversation.md` as single source of truth.
- **Monitoring:** System Monitor task runs every 5 min (disk/RAM/CPU stats).
- **Discord Integration:** Bot token configured; channel `1479313775931822346`; groupPolicy=open.
- **Supabase:** Project `dnkwsqsxsyskdzxurnox`; service key present; `todo` table used for task sync.

## Credentials (`.env`)
- Facebook Page: `806031832584776`
- Instagram Business Account: `17841476586070758`
- Slack bot token: `xoxb-...` (lacks `chat:write` scope — needs fix)
- Supabase URL: `https://dnkwsqsxsyskdzxurnox.supabase.co`
- Supabase Service Key: (hidden)
- HERENOW_API_KEY: (set)
- Twitter credentials (may be stale)

## Achievements
- ✅ First successful Facebook test post via direct Graph API (2026-03-05)
- ✅ Instagram poster script with Slack notification
- ✅ Discord bot integration active
- ✅ Supabase `todo` table setup with hourly bidirectional sync
- ✅ Automated todo table in MEMORY.md

## Pending Tasks
- **Carewell Demo Scheduler** — set up demo scheduling for Carewell (calendar integration, booking system)
- **Ludo Game Development** — work on Ludo game project today (specific tasks TBD)
- **Research WhatsApp WebStore** — explore integration options, API availability, and potential for posting/automation
- **System Rule:** Always use direct curl scripts from `scripts/` for API calls — subagents unreliable
- Consider updating Facebook Poster skill to use direct API calls (bypass browser)
- Consider updating social media skills to bypass browser dependency ✅ Updated (but prefer direct scripts)
- Create curl-based Instagram test script ✅ Done
- Create similar curl script for Instagram Poster
- Fix Slack bot token scopes or use Incoming Webhook
- Install browser on system if browser automation is desired
- Update Backup tasks in Task Scheduler (logon type fix)
- Write WhatsApp report — Explore WhatsApp API and produce comprehensive report

## Working Scripts (scripts/)
- `facebook-test-post.sh` — Post to Facebook + Slack notification ✅ Working
- `instagram-test-post.sh` — Post to Instagram + Slack notification ✅ Working
- `slack-test.sh` — Test Slack token/channel ✅ Working
- `instagram-verify.sh` — Verify recent IG posts ✅ Working
- `instagram-permalink.sh` — Fetch post permalink ✅ Working
- `add-todo-auto.sh` — Add todo with auto-description (Supabase)
- `sync-todos.sh` — Hourly sync between MEMORY.md and Supabase (every hour)
- `rebuild-db-from-local.sh` — Rebuild DB from MEMORY
- `append-todo-table.sh` — Refresh Todo table in MEMORY
- `sync-memory-from-db.sh` — Full sync: bullets + table from DB

**Never use subagents or browser-dependent skills for social media.** Always call scripts directly via `exec`.

## Notes
- Hourly cron job: `0 * * * * /home/ubuntu/.openclaw/workspace/scripts/sync-todos.sh >> /home/ubuntu/.openclaw/workspace/logs/sync-todos.log 2>&1`
- Use `./add-todo-auto.sh` to add new tasks; they sync automatically.
- Supabase `todo` table schema: id, title, description, priority (1/2/3), due_date, status, created_at, updated_at.

## Todo List (Supabase)

| ID | Title | Priority | Due Date | Status |
|---|-------|----------|----------|--------|
| 370 | Install browser on system if browser automation is desired | 2 | 2026-03-07 | pending |
| 371 | Update Backup tasks in Task Scheduler (logon type fix) | 2 | 2026-03-07 | pending |
| 372 | Write WhatsApp report — Explore WhatsApp API and produce comprehensive report | 2 | 2026-03-07 | pending |
| 361 | **Carewell Demo Scheduler** — set up demo scheduling for Carewell (calendar integration, booking system) | 2 | 2026-03-07 | pending |
| 362 | **Ludo Game Development** — work on Ludo game project today (specific tasks TBD) | 2 | 2026-03-07 | pending |
| 363 | **Research WhatsApp WebStore** — explore integration options, API availability, and potential for posting/automation | 2 | 2026-03-07 | pending |
| 364 | **System Rule:** Always use direct curl scripts from `scripts/` for API calls — subagents unreliable | 2 | 2026-03-07 | pending |
| 365 | Consider updating Facebook Poster skill to use direct API calls (bypass browser) | 2 | 2026-03-07 | pending |
| 366 | Consider updating social media skills to bypass browser dependency ✅ Updated (but prefer direct scripts) | 2 | 2026-03-07 | pending |
| 367 | Create curl-based Instagram test script ✅ Done | 2 | 2026-03-07 | pending |
| 368 | Create similar curl script for Instagram Poster | 2 | 2026-03-07 | pending |
| 369 | Fix Slack bot token scopes or use Incoming Webhook | 2 | 2026-03-07 | pending |
