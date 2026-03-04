# Setup Guide — OpenClaw Agent

Complete step-by-step to get your agent running.

## Phase 1: Identity & User

1. Edit `IDENTITY.md` with your chosen name, creature type, vibe, and emoji.
2. Edit `USER.md` with your name, what to call you, timezone, and any preferences.

## Phase 2: Environment Variables (SENSITIVE CONFIG)

**IMPORTANT:** All tokens, API keys, and secrets MUST be stored in environment variables, never in config files.

Set these in your system (Windows: PowerShell; Linux: shell profile):

```powershell
# OpenRouter (for LLM providers)
[System.Environment]::SetEnvironmentVariable("OPENROUTER_API_KEY","your_key_here","User")

# OpenClaw Gateway
[System.Environment]::SetEnvironmentVariable("OPENCLAW_TOKEN","your_gateway_token_here","User")

# Telegram
[System.Environment]::SetEnvironmentVariable("TELEGRAM_BOT_TOKEN","your_bot_token","User")
[System.Environment]::SetEnvironmentVariable("TELEGRAM_CHAT_ID","your_chat_id","User")

# Slack (if using)
[System.Environment]::SetEnvironmentVariable("SLACK_BOT_TOKEN","xoxb-...","User")
[System.Environment]::SetEnvironmentVariable("SLACK_APP_TOKEN","xapp-...","User")

# GitHub backup repo
[System.Environment]::SetEnvironmentVariable("GIT_REPO","https://github.com/yourname/your-backup-repo.git","User")

# Google AI Studio (optional)
[System.Environment]::SetEnvironmentVariable("GOOGLE_AI_STUDIO_KEY","your_key","User")
```

After setting, restart your terminal/IDE to pick up changes.

**Rule for Future:** Any new service that requires tokens → add a new env var and reference it in config files as `"${VAR_NAME}"`. Never commit actual secrets.

## Phase 2: OpenClaw Installation

- Install Node.js (v18+).
- `npm i -g openclaw`
- Verify: `openclaw --version`

## Phase 3: Start Gateway

Option A: Direct (dev)
```bash
openclaw gateway start
```

Option B: Windows Service (NSSM)
- Install NSSM from https://nssm.cc
- Run `scripts/gateway-service-nssm.ps1` as Admin
- Start service: `nssm start OpenClawGateway`

Option C: Linux systemd
- Copy `systemd/openclaw-gateway.service` to `/etc/systemd/system/`
- `systemctl daemon-reload && systemctl enable --now openclaw-gateway`

## Phase 4: Configure Integrations

### Telegram
- Set `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID` environment variables.
- Or edit `config/telegram.json` (not tracked).

### Slack
- Create Slack app with `chat:write` scope, install to workspace.
- Fill `config/slack_bridge.json` with tokens and channel IDs.
- Test: `powershell scripts/slack_diagnostic.ps1`

## Phase 5: Backup & Sync

### Automatic (recommended)
- Import Task Scheduler tasks:
  - `scripts/backup_task.xml` (15-minute backup)
  - `scripts/cloud-sync_task.xml` (15-minute cloud sync)
- Or run `scripts/setup_doctorx_tasks.ps1` as Admin for full suite.

### Manual
```powershell
.\scripts\backup_simple.ps1
```

## Phase 6: Subagents

Create new subagent:
```bash
mkdir subagents/myagent
cd subagents/myagent
# Add agent code, SKILL.md, etc.
```

Register with gateway via ENV `OPENCLAW_ALLOWED_AGENTS` or config.

## Troubleshooting

- Gateway not starting? Check logs: `~/.openclaw/logs/`
- Backup failing? Verify `GIT_REPO` env var points to your backup repo.
- Health watcher not restarting? Ensure NSSM is installed and service name is `OpenClawGateway`.

## Next Steps

- Customize `SOUL.md` for your agent's personality.
- Add skills in `skills/` and reference them in agent configs.
- Set up heartbeat tasks in `HEARTBEAT.md`.
