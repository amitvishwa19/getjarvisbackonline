# JARVIS — OpenClaw Agent Workspace

**Sovereign master-intelligence for Amit's Software Development Agency.** This workspace powers JARVIS with persistent memory, multi-provider LLM failover, specialized skills, health monitoring, and automated sub-agent orchestration.

---

## 🚀 Quick Start (5 minutes)

### 1. Environment Variables

Copy `.env.example` to `.env` and fill in your secrets:

```bash
cp .env.example .env
# Edit .env with your values:
# - OPENROUTER_API_KEY (already set)
# - OPENCLAW_TOKEN (from `openclaw token generate`)
# - TELEGRAM_BOT_TOKEN & TELEGRAM_CHAT_ID (optional)
# - GOOGLE_CLIENT_ID/SECRET/REFRESH_TOKEN (if using Google Workspace)
# - HERENOW_API_KEY (if using Here.Now)
# - VERCEL_API_TOKEN (if using Vercel)
```

### 2. Start the Gateway

The OpenClaw gateway is managed by systemd (user service). Enable and start:

```bash
# Enable at login
systemctl --user enable openclaw-gateway.service

# Start now
systemctl --user start openclaw-gateway.service

# Check status
systemctl --user status openclaw-gateway.service
```

Or use the CLI directly:

```bash
openclaw gateway start
```

The gateway runs on `http://127.0.0.1:18789` and is automatically used by this workspace.

### 3. Verify Installation

```bash
# Check health
curl http://127.0.0.1:18789/health

# Test a skill (Google Workspace example, after setting its env vars)
node -e "const { handler } = require('./skills/google-workspace/index.js'); handler({ action: 'gdrive-list', args: {} }, {}).then(console.log).catch(console.error)"
```

---

## 🧠 What's Included

| Component | Description |
|-----------|-------------|
| **LLM Provider Chain** | 10 providers with auto-failover and circuit breaker (`config/llm-providers.json`) |
| **Skills** | `google-workspace` (Drive/Gmail/Calendar), `here-now` (instant deploy), `vercel-deploy` |
| **Memory System** | Daily logs (`memory/YYYY-MM-DD.md`) + curated `MEMORY.md` |
| **Health Monitor** | Cron-driven script checking gateway, disk, backups, memory (runs every 30 min) |
| **Sub-Agent Layer** | 6 specialized agents: daily-planner, google-workspace-manager, medical-bulletin, researcher, socialmedia-manager, system-monitor |
| **Configuration** | Environment-based, with templates in `config-templates/` |
| **Backup Scripts** | Cross-platform shell & PowerShell scripts for workspace backup |
| **Documentation** | Full reference: ENVIRONMENT_VARIABLES.md, SUBSCRIPTIONS.md, WORKFLOW.md, SETUP_GUIDE.md |

---

## 📦 Skills Reference

### google-workspace
```
gdrive-list [--folder-id <id>]
gdrive-upload --file <path> [--name <name>] [--folder-id <id>]
gmail-send --to <email> --subject <subj> --body <body>
calendar-create --title <title> --start <ISO> --end <ISO> [--description <desc>]
calendar-list [--days <N>]
```
**Env vars:** `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_REFRESH_TOKEN`

### here-now
```
here-now publish --dir <folder> [--prod]
```
**Env vars:** `HERENOW_API_KEY`

### vercel-deploy
```
vercel-deploy --dir <folder> [--prod]
```
**Env vars:** `VERCEL_API_TOKEN`

---

## 💓 Heartbeat & Scheduler

Heartbeat tasks are defined in `HEARTBEAT.md`. The health monitor cron job runs automatically every 30 minutes. Adjust or add tasks as needed.

To run manual checks:
```bash
./scripts/health-monitor.sh
```

---

## 🗂️ Workspace Layout

```
.
├── config/                   # Active config (llm-providers.json, slack_bridge.json)
├── config-templates/         # Templates with ${ENV_VAR} placeholders
├── skills/                   # Skill modules (index.js + SKILL.md)
├── scripts/                  # Health, backup, setup scripts
├── memory/                   # Daily logs (YYYY-MM-DD.md)
├── MEMORY.md                 # Curated long-term memory
├── .env                      # Your secrets (DO NOT COMMIT)
├── .env.example              # Template for environment variables
├── HEARTBEAT.md              # Periodic task checklist
├── SUBSCRIPTIONS.md          # Sub-agent definitions & spawn patterns
├── ENVIRONMENT_VARIABLES.md  # Full env var reference
└── README.md                 # This file
```

---

## 🛠️ Development

### Testing a skill directly
```bash
node -e "const { handler } = require('./skills/<skill-name>/index.js'); handler(<args>, <context>).then(console.log)"
```

### Spawning a sub-agent
```bash
openclaw sessions spawn --runtime subagent --task "<task description>" --model openrouter/auto
```
Or from within a session, I (JARVIS) will orchestrate automatically.

### Viewing logs
- Gateway logs: `journalctl --user -u openclaw-gateway.service -f` (systemd) or `openclaw logs`
- Health monitor: `tail -f .health.log`
- Memory daily logs: `memory/YYYY-MM-DD.md`

---

## 📚 Documentation

- `ENVIRONMENT_VARIABLES.md` — All required and optional environment variables
- `SUBSCRIPTIONS.md` — Sub-agent registry and invocation patterns
- `WORKFLOW.md` — Complete system workflow overview (from upstream)
- `SETUP_GUIDE.md` — Detailed setup instructions (from upstream)
- `AGENTS.md` — Agent onboarding and memory conventions
- `SOUL.md` — JARVIS personality and core truths

---

## 🔒 Security Notes

- Never commit `.env` or any files containing real tokens.
- Gateway is bound to loopback (127.0.0.1) by default; only local processes can connect.
- Set `OPENCLAW_TOKEN` to secure the gateway API.
- Use `config-templates/` for configs; keep `config/` out of version control if it contains sensitive defaults.

---

## 🤝 Support

- OpenClaw docs: https://docs.openclaw.ai
- Community: https://discord.com/invite/clawd
- Issues: https://github.com/openclaw/openclaw/issues

---

**JARVIS v1.0** — Sovereign master-intelligence, at your service. 🤖