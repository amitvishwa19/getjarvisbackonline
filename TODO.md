# TODO — OpenClaw Agent Workspace

## High Priority (Initial Setup)

- [ ] Fill `IDENTITY.md` (name, creature, vibe, emoji)
- [ ] Fill `USER.md` (name, timezone, preferences)
- [ ] Set all required environment variables:
  - `OPENROUTER_API_KEY`
  - `OPENCLAW_TOKEN` (generate via `openclaw token generate`)
  - `TELEGRAM_BOT_TOKEN`
  - `TELEGRAM_CHAT_ID`
  - `GIT_REPO` (point to your backup repository)
- [ ] Copy config templates to `config/`:
  - `cp config-templates/llm-providers.json config/`
  - `cp config-templates/llm-providers-offline.json config/`
  - `cp config-templates/slack_bridge.json config/` (if using Slack)
- [ ] Install OpenClaw (`npm i -g openclaw`)
- [ ] Start gateway (`openclaw gateway start`) and verify `/health`
- [ ] Import Windows Task Scheduler tasks:
  - `scripts/backup_task.xml`
  - `scripts/cloud-sync_task.xml`
- [ ] Test backup manually (`.\scripts\backup_test.ps1`)
- [ ] Add SSH key to GitHub (optional but recommended for backups)
- [ ] Set up Telegram bot and get chat ID

## Medium Priority (Enhancements)

- [ ] Install gateway as Windows service (NSSM) for auto-start
- [ ] Set up health watcher task (`scripts/health-watcher_task.xml`)
- [ ] Configure Slack bridge (if needed):
  - Create Slack app, get tokens
  - Fill `config/slack_bridge.json` (using env vars)
  - Test with `scripts/slack_diagnostic.ps1`
- [ ] Tune LLM provider priorities in `config/llm-providers.json`
- [ ] Create first subagent (bumblebee or doctor-x):
  - Add `SKILL.md` and code
  - Add ID to `OPENCLAW_ALLOWED_AGENTS`
  - Test registration
- [ ] Customize `HEARTBEAT.md` with periodic checks (email, calendar, etc.)
- [ ] Set up encrypted offline backups (`scripts/backup_offline.ps1`) if needed
- [ ] Review and prune old `memory/` logs (keep last 30 days)

## Nice-to-Have

- [ ] Fancy dashboard for backup status (web UI)
- [ ] Email notifications for backup failures
- [ ] Log rotation for gateway logs
- [ ] Multi-gateway redundancy (failover)
- [ ] Implement second subagent (doctor-x or megaton)
- [ ] Add skills: web search, file management, calendar integration
- [ ] Set up two-way Slack bridge (polling script)
- [ ] Create a custom skill for media uploads (video/image)
- [ ] Add Telegram inline buttons / interactive commands
- [ ] Implement memory curation automation (update MEMORY.md daily)

## Known Issues

- SSH connection on Windows sometimes hangs (workaround: use HTTPS + PAT)
- NSSM installation not automated (download required)
- No built-in log rotation (manual cleanup needed)
- Health watcher needs manual task setup (docs ready)

## Completed ✅

- [x] Bootstrap workspace from GitHub repo
- [x] Set identity (Jarvis 🤖) and user (Amit, Kolkata)
- [x] Restore full file structure from upstream
- [x] Create comprehensive documentation (WORKFLOW.md, SETUP_GUIDE.md, ENVIRONMENT_VARIABLES.md, README.md)
- [x] Configure multi-provider LLM fallback chain (9 OpenRouter providers + fallbacks)
- [x] Update backup scripts to use `git add -A` (full backup)
- [x] Change backup interval from 5 min to 15 min (both backup.bat and cloud-sync)
- [x] Create and push initial README with status to GitHub (via PAT)
- [x] Ensure all configs use environment variables only (no secrets in repo)
- [x] Implement backup health status file (`.backup_health.json`)
- [x] Write restore script (`restore_from_github.sh`)
- [x] Write encrypted backup script (`backup_offline.ps1`)
- [x] Write health watcher with auto-restart (Windows)
- [x] Write Doctor-X task setup scripts (batch + PowerShell)

---

## Scripts Overview

| Script | Purpose |
|--------|---------|
| `backup.bat` | Simple backup ( Task Scheduler ) |
| `backup_openclaw_improved.ps1` | Full backup with Telegram alerts |
| `backup_offline.ps1` | Encrypted hourly backups with retention |
| `cloud-sync.ps1` | Background sync daemon |
| `health-watcher.ps1` | Monitors gateway, restarts if down |
| `restore_from_github.sh` | Restore workspace from backup by date |
| `setup_doctorx_tasks.ps1` | Install comprehensive monitoring tasks |
| `slack_diagnostic.ps1` | Test Slack connectivity |

---

## Environment Variables Checklist

- [ ] `OPENROUTER_API_KEY` — from https://openrouter.ai/keys
- [ ] `OPENCLAW_TOKEN` — from `openclaw token generate`
- [ ] `TELEGRAM_BOT_TOKEN` — from @BotFather
- [ ] `TELEGRAM_CHAT_ID` — from @getidsbot or similar
- [ ] `GIT_REPO` — your backup repository URL
- [ ] `SLACK_BOT_TOKEN` — optional, Slack integration
- [ ] `SLACK_APP_TOKEN` — optional, Slack integration
- [ ] `GOOGLE_AI_STUDIO_KEY` — optional, Gemini

---

## Notes

- **Backup frequency:** 15 minutes is default; adjust in Task Scheduler if needed.
- **Memory logging:** Daily files in `memory/` are verbatim transcripts; `MEMORY.md` is curated (auto-updated by backup script).
- **Subagents:** They are independent; you can develop them separately and enable via `OPENCLAW_ALLOWED_AGENTS`.
- **Secrets:** Never commit actual tokens. Use placeholders in templates; set real values in env vars.

---

*Last updated: 2026-03-02*
