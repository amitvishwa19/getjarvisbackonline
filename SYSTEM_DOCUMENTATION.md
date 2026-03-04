# JARVIS System Documentation & Workflow

**Version:** 1.0  
**Last Updated:** March 4, 2025  
**System:** OpenClaw Agent (JARVIS) with automated backups, monitoring, research, and publication

---

## Table of Contents
1. [System Overview](#system-overview)
2. [Agent Architecture](#agent-architecture)
3. [Sub-Agent Registry](#sub-agent-registry)
4. [Cron Jobs & Schedules](#cron-jobs--schedules)
5. [Skills & Tools](#skills--tools)
6. [Backup System](#backup-system)
7. [Monitoring & Alerts](#monitoring--alerts)
8. [Deployment & Publishing](#deployment--publishing)
9. [Workflow Examples](#workflow-examples)
10. [Troubleshooting](#troubleshooting)

---

## System Overview

JARVIS is an AI assistant built on OpenClaw with a multi-agent architecture. It provides:

- **Automated Workspace Backups** (hourly/daily, with retention)
- **Health Monitoring** (disk, memory, gateway, backup freshness)
- **Research Agent** (web search via Tavily/Firecrawl)
- **Publishing** (docs deployment to here.now with Tailwind CSS)
- **System Status Reporting** (every hour to Slack #system-monitor)

**Core Components:**
- Main agent (telegram:8228016833)
- 6 specialized sub-agents (spawned on-demand)
- Workspace: `/home/ubuntu/.openclaw/workspace`
- Logs: `logs/`
- Memory: `memory/` (daily) + `MEMORY.md` (long-term)
- Backup repo: `backup-system/backup-repo`

---

## Agent Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Main Agent (JARVIS)               │
│  • Telegram interface (direct chat)                │
│  • Orchestrates sub-agents                         │
│  • Manages memory, context, user preferences       │
└─────────────────┬───────────────────────────────────┘
                  │ spawns on-demand
                  ▼
    ┌─────────────────────────────────────┐
    │    Specialized Sub-Agents           │
    ├─────────────────────────────────────┤
    │ • daily-planner                     │
    │ • google-workspace-manager          │
    │ • medical-bulletin                 │
    │ • researcher (stepfun/step-3.5-flash:free) │
    │ • socialmedia-manager              │
    │ • system-monitor                   │
    └─────────────────────────────────────┘
```

---

## Sub-Agent Registry

### 1. daily-planner
- **Purpose:** Task planning, sprints, project breakdown, timelines
- **Model:** `openrouter/auto` (structured reasoning)
- **Thinking:** High
- **Use-cases:** Sprint planning, task division, resource allocation, Gantt-style breakdown
- **Example spawn:**
  ```yaml
  task: "Break down the following project into sprints with timelines:\n\n<project_description>"
  ```

### 2. google-workspace-manager
- **Purpose:** Emails, proposals, client communication, documentation
- **Model:** `openrouter/auto` (clarity + tone)
- **Thinking:** Medium
- **Skills:** `google-workspace` (gdrive, gmail, calendar APIs)
- **Use-cases:** Client quotes, technical proposals, progress reports, SRS/PRD outlines
- **Example spawn:**
  ```yaml
  task: "Draft a professional client update email about <topic>. Include progress summary."
  ```

### 3. medical-bulletin (Agency Wellness)
- **Purpose:** Research + summaries on mental health, ergonomics, team wellness
- **Model:** `openrouter/auto` (factual reliability)
- **Thinking:** Medium
- **Safety:** Informational only, not medical advice
- **Use-cases:** Ergonomic best practices for devs, productivity physiology tips, mental health resource curation
- **Example spawn:**
  ```yaml
  task: "Research best ergonomic setups for remote developers in 2025"
  ```

### 4. researcher
- **Purpose:** Deep technical research, trend analysis, competitive comparison
- **Model:** `openrouter/stepfun/step-3.5-flash:free` (fast, balanced coding)
- **Thinking:** High
- **Skills:** `tavily-search`, `firecrawl-search`
- **Use-cases:** Comparing frameworks, API documentation analysis, benchmarking, security/compliance research, AI trends (like this report)
- **Behavior:**
  - Searches web with Tavily/Firecrawl
  - Posts full detailed results to Slack `#research-analyst` (C0AHF291VE3)
  - Returns concise summary to main agent (user)
- **Example spawn:**
  ```yaml
  task: "Search the web for latest AI updates 2025 and summarize key trends"
  ```

### 5. socialmedia-manager
- **Purpose:** Agency marketing, content creation, posts, case studies
- **Model:** `openrouter/auto` (creativity)
- **Thinking:** Medium
- **Use-cases:** LinkedIn agency content, developer marketing, portfolio case studies, hashtag optimization
- **Example spawn:**
  ```yaml
  task: "Write a LinkedIn post about <topic> targeting developer audience. Include hashtags."
  ```

### 6. system-monitor
- **Purpose:** Technical diagnostics, DevOps analysis, code review, health monitoring
- **Model:** `openrouter/auto` (technical depth)
- **Thinking:** High
- **Skills:** None (uses local scripts)
- **Use-cases:**
  - Code smell detection
  - Risk assessment
  - Performance optimization
  - Infrastructure health checks
  - Backup health validation
- **Automated schedules:**
  - Hourly: `status-and-post.sh` runs and posts to Slack `#system-monitor`
  - Every 30 min: `health-monitor.sh` runs
  - Every 5 min: `watchdog.sh` checks backup freshness & gateway health
- **Example spawn:**
  ```yaml
  task: "Review this code for security issues:\n\n<code_snippet>"
  ```

---

## Cron Jobs & Schedules

All cron jobs are set for user `ubuntu` (`crontab -l`):

```
*/30 * * * * cd /home/ubuntu/.openclaw/workspace && ./scripts/health-monitor.sh >> .health.log 2>&1
0 2 * * * cd /home/ubuntu/.openclaw/workspace/backup-system && ./backup-v2.sh >> logs/backup-cron.log 2>&1
*/5 * * * * /home/ubuntu/.openclaw/workspace/backup-system/scripts/watchdog.sh
*/5 * * * * /home/ubuntu/.openclaw/workspace/backup-system/scripts/push-offsite.sh
0 * * * * /home/ubuntu/.openclaw/workspace/scripts/status-and-post.sh >> /home/ubuntu/.openclaw/workspace/logs/system-status.log 2>&1
```

### Job Descriptions

| Schedule | Script | Purpose |
|----------|--------|---------|
| `*/30 * * * *` | `scripts/health-monitor.sh` | Check disk space, load, gateway health; alert if issues |
| `0 2 * * *` | `backup-system/backup-v2.sh` | Daily full workspace backup (git commit + tar) |
| `*/5 * * * *` | `backup-system/scripts/watchdog.sh` | Auto-recovery: if backup stale or gateway down, restore latest backup and restart |
| `*/5 * * * *` | `backup-system/scripts/push-offsite.sh` | Push backup-repo to remote GitHub (`backup-data` branch) |
| `0 * * * *` | `scripts/status-and-post.sh` | Hourly system status report to Slack `#system-monitor` |

---

## Skills & Tools

### Core Skills
| Skill | Usage | Description |
|-------|-------|-------------|
| `google-workspace` | Manager agent | API access to Google Workspace (Gmail, Drive, Calendar) |
| `tavily-search` | Researcher | Fast web search API (AI-optimized results) |
| `firecrawl-search` | Researcher | Alternative web search/scraping |
| `here-now` | Publishing | Deploy static sites to here.now hosting |
| `vercel-deploy` | Publishing | Deploy to Vercel (optional) |

### Scripts Directory
| Script | Purpose |
|--------|---------|
| `scripts/system-status.sh` | Collect memory, disk, load, gateway, backup status |
| `scripts/status-and-post.sh` | Run system-status and post to Slack |
| `scripts/health-monitor.sh` | Comprehensive health checks (runs every 30 min) |
| `backup-system/backup-v2.sh` | Main backup script (atomic, locked, compressed) |
| `backup-system/scripts/watchdog.sh` | Auto-recovery daemon (checks backup age, gateway) |
| `backup-system/scripts/push-offsite.sh` | Remote sync to GitHub backup-data branch |
| `backup-system/scripts/health-backup.sh` | Backup-specific health checks |

---

## Backup System

### Overview
- **Backup repo:** `backup-system/backup-repo/` (separate git repo, nested allowed)
- **Schedule:** Daily at 2 AM
- **Retention:** 365 commits OR 90 days, whichever first
- **Compression:** `gzip -1` (fastest) with `nice -n 19 ionice -c3`
- **Exclusions:** `backup-system/backup-repo`, `test-site`, `node_modules`, `logs`, `*.log`, `*.tmp`, `.DS_Store`, `Thumbs.db`
- **Locking:** `mkdir .backup.lock` (atomic, POSIX)
- **Offsite:** Push to GitHub repo `amitvishwa19/getjarvisbackonline` on branch `backup-data`

### Backup Script Flow
```
1. Check disk space (>5GB free required)
2. Check system load (1min loadavg < 4.0)
3. Create lock: .backup.lock/
4. rsync workspace to temp dir, apply exclusions
5. tar -czf backup-YYYYMMDD-HHMMSS.tar.gz (gzip -1)
6. Move tar to backup-repo/
7. git add/commit ("Backup: 2025-03-04 02:00")
8. git push (local repo only)
9. Clean old backups (git reflog expire --expire=90d, git gc --aggressive)
10. Remove lock
```

### Watchdog (Auto-Recovery)
Runs every 5 minutes:
- Check gateway API health (`http://127.0.0.1:18789/health`)
- Check last backup age (should be < 24h)
- If either fails:
  1. Restore latest backup from `backup-repo/`
  2. Restart OpenClaw gateway service
  3. Log action to `backup-system/logs/watchdog.log`

---

## Monitoring & Alerts

### Slack Channels
| Channel | Purpose | Posted By |
|---------|---------|-----------|
| `#system-monitor` (C0AHPT66TV3) | Hourly system status (memory, disk, load, gateway, backup) | `status-and-post.sh` |
| `#research-analyst` (C0AHF291VE3) | Full research results (Tavily output) | Researcher agent |
| `#backup-logs` | Backup cron output, errors | Backup scripts (manual) |

### Telegram
- Main agent interface: Direct chat (telegram:8228016833)
- Summaries from sub-agents forwarded here

### Health Checks
- `health-monitor.sh` (30 min): disk >80%, load >4.0, gateway down, backup repo size >10GB → Alerts via Slack (optional email)
- `system-status.sh` (hourly): Full report, posted to Slack

---

## Deployment & Publishing

### here.now (Primary)
- Skill: `here-now`
- API key: `HERENOW_API_KEY` in `.env`
- Deploy command:
  ```bash
  node skills/here-now/index.js --dir ./backup-docs-site
  ```
- Live URL: `https://<slug>.here.now/`
- Current slug: `pearly-osprey-zggg`

### Vercel (Optional)
- Skill: `vercel-deploy`
- API token: `VERCEL_API_TOKEN`
- Deploy: `vercel-deploy --dir ./dist --prod`

### Publishing Workflow
1. Create content in `backup-docs-site/` (HTML)
2. Use Tailwind CSS via CDN for modern styling
3. Deploy via `here-now` skill
4. Result: public URL (Slack/Telegram)

---

## Workflow Examples

### 1. Research & Publish AI Trends
```
User: "JARVIS, research latest AI updates 2025"

→ Researcher agent spawned (model: stepfun/step-3.5-flash:free)
→ Tavily search executed
→ Full results posted to Slack #research-analyst
→ Concise summary returned to user

User: "Publish karo"

→ Create HTML page in backup-docs-site/ with Tailwind CSS
→ Deploy via here.now skill
→ Live URL returned
→ User shares URL
```

### 2. Automated Monitoring
```
Every hour:
  status-and-post.sh → system-status.sh → Slack #system-monitor

Every 30 min:
  health-monitor.sh → checks thresholds → alerts if needed

Every 5 min:
  watchdog.sh → checks backup freshness + gateway health → auto-restore if failed
```

### 3. Daily Backup
```
At 2 AM:
  backup-v2.sh
    → rsync workspace (with exclusions)
    → create timestamped tar.gz
    → commit to backup-repo
    → prune old commits (90d / 365 limit)
    → logs written to logs/backup-cron.log

Immediately after:
  push-offsite.sh → git push to GitHub backup-data branch
```

---

## Troubleshooting

### Backup fails?
- Check `logs/backup-cron.log`
- Verify disk space (`df -h`), load (`uptime`)
- Ensure no stale lock: `rm -rf backup-system/backup-repo/.backup.lock`
- Test manually: `./backup-system/backup-v2.sh`

### Gateway down?
- `openclaw gateway status`
- `openclaw gateway start`
- Watchdog should auto-restore from backup within 5 min

### Researcher not working?
- Verify `TAVILY_API_KEY` set in `.env`
- Test skill: `node skills/tavily-search/index.js --query "test"`

### Cron not running?
- `crontab -l` verify entries
- Check logs in `logs/` or home directory `.health.log`
- System cron daemon running: `systemctl status cron`

### here.now deploy fails?
- Check `HERENOW_API_KEY` valid
- Ensure `backup-docs-site/` has `index.html`
- Test: `node skills/here-now/index.js --dir ./backup-docs-site`

---

## Appendix

### Environment Variables (`.env`)

All sensitive credentials are stored in `.env` (git-ignored). See `ENVIRONMENT_VARIABLES.md` for complete reference.

Key variables:
- `OPENROUTER_API_KEY` — LLM provider
- `SLACK_BOT_TOKEN` — Slack messaging
- `TAVILY_API_KEY` — Web search
- `HERENOW_API_KEY` — here.now deployment
- `GOOGLE_CLIENT_ID/SECRET/REFRESH_TOKEN` — Google Workspace
- `FIRECRAWL_API_KEY` — Optional web scraping
- `OPENCLAW_TOKEN` — Internal gateway token

Template: `.env.example`

### File Structure
```
workspace/
├── AGENTS.md
├── SUBSCRIPTIONS.md
├── MEMORY.md
├── USER.md
├── SOUL.md
├── TOOLS.md
├── .env
├── scripts/
│   ├── system-status.sh
│   ├── status-and-post.sh
│   └── health-monitor.sh
├── backup-system/
│   ├── backup-repo/      # git repo with backups
│   ├── backup-v2.sh
│   ├── scripts/
│   │   ├── watchdog.sh
│   │   ├── push-offsite.sh
│   │   └── health-backup.sh
│   └── logs/
├── backup-docs-site/      # static site to deploy
│   ├── index.html
│   └── ai-updates-2025.html
├── skills/
│   ├── google-workspace/
│   ├── tavily-search/
│   ├── here-now/
│   └── vercel-deploy/
└── logs/
    ├── system-status.log
    └── backup-cron.log
```

---

**End of Documentation**
