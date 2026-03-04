# OpenClaw Agent System — Complete Workflow

This document describes the full setup, operation, and restoration procedures for the OpenClaw agent workspace. It serves as a single source of truth for both humans and new agents to understand and rebuild the system.

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Initial Setup](#initial-setup)
3. [Environment Variables](#environment-variables)
4. [Repository Structure](#repository-structure)
5. [Starting the Gateway](#starting-the-gateway)
6. [Backup & Sync](#backup--sync)
7. [Health Monitoring](#health-monitoring)
8. [Subagents](#subagents)
9. [Restoration Procedures](#restoration-procedures)
10. [Security Best Practices](#security-best-practices)
11. [Troubleshooting](#troubleshooting)

---

## System Overview

This workspace implements a persistent AI assistant (Jarvis) with:
- **Long-term memory** via daily logs (`memory/YYYY-MM-DD.md`) and curated highlights (`MEMORY.md`)
- **Multi-provider LLM fallback chain** configured in `config-templates/llm-providers*.json`
- **Automatic backup** to GitHub every 15 minutes via Windows Task Scheduler
- **Health watcher** that restarts the gateway if it becomes unresponsive
- **Integration channels**: Telegram (primary), Slack (optional)
- **Subagents** for specialized tasks (bumblebee, doctor-x, etc.)

All secrets and tokens are **never committed**; they reside in environment variables only.

---

## Initial Setup

### 1. Identity & User

Edit these files to personalize the agent:
- `IDENTITY.md` — name, creature type, vibe, emoji
- `USER.md` — your name, timezone, preferences

Alternatively, run the setup wizard (`scripts/setup-complete.ps1`) which will create these with defaults and prompt for environment variables.

Example `IDENTITY.md`:
```markdown
- Name: Jarvis
- Creature: AI assistant
- Vibe: Helpful, competent, straightforward, not overly formal
- Emoji: 🤖
```

Example `USER.md`:
```markdown
- Name: Amit
- What to call them: Amit
- Timezone: India Kolkata (UTC+5:30)
- Notes: Use respectful "aap" level address. Do not use casual "tum".
```

### 2. Environment Variables (REQUIRED)

Set these in your system (Windows: PowerShell; Linux/macOS: shell profile). **Never commit actual values.**

| Variable | Purpose | How to obtain |
|----------|---------|---------------|
| `OPENROUTER_API_KEY` | OpenRouter API key for LLM access | https://openrouter.ai/keys |
| `OPENCLAW_TOKEN` | Gateway authentication token | Run `openclaw token generate` |
| `TELEGRAM_BOT_TOKEN` | Telegram bot token | Message @BotFather on Telegram |
| `TELEGRAM_CHAT_ID` | Your personal chat ID | Use @getidsbot or similar |
| `GIT_REPO` | Backup repository URL (HTTPS or SSH) | Create a GitHub repo, copy URL |

Optional variables:
- `SLACK_BOT_TOKEN`, `SLACK_APP_TOKEN` — Slack integration
- `GOOGLE_AI_STUDIO_KEY` — Gemini API key
- `OPENCLAW_ALLOWED_AGENTS` — Comma-separated allowed subagent IDs (e.g., `bumblebee,doctor-x`)
- `OPENCLAW_GATEWAY_PORT` — Gateway port (default: 18789)

#### Setting on Windows (PowerShell, user-level)
```powershell
[System.Environment]::SetEnvironmentVariable("OPENROUTER_API_KEY","sk-or-...","User")
[System.Environment]::SetEnvironmentVariable("OPENCLAW_TOKEN","your_token_here","User")
# ... repeat for other variables
```
Restart terminal/IDE after setting.

#### Setting on Linux/macOS
```bash
export OPENROUTER_API_KEY="sk-or-..."
export OPENCLAW_TOKEN="your_token_here"
# Add to ~/.bashrc or ~/.zshrc for persistence
```

**Important:** After setting env vars, create actual config files from templates:
```bash
cp config-templates/llm-providers.json config/llm-providers.json
cp config-templates/llm-providers-offline.json config/llm-providers-offline.json
# Edit if needed, but keep placeholders like ${OPENROUTER_API_KEY} as is.
```
(OpenClaw automatically substitutes environment variables.)

### 3. Install OpenClaw

- Install Node.js (v18+ recommended)
- `npm i -g openclaw`
- Verify: `openclaw --version`

### 4. SSH Key for GitHub Backup (Optional but Recommended)

If you prefer SSH over HTTPS for backups:
```bash
ssh-keygen -t ed25519 -C "amit@devlomatix.com" -f ~/.ssh/id_ed25519 -N ""
```
Add the public key (`~/.ssh/id_ed25519.pub`) to GitHub: Settings → SSH and GPG keys → New SSH key.

Test:
```bash
ssh -T git@github.com
```
Should return: `Hi <username>! You've successfully authenticated...`

Then set `GIT_REPO` to the SSH URL: `git@github.com:yourname/your-repo.git`

---

## Repository Structure

```
workspace/
├── AGENTS.md              # Guide to create agent skills
├── SOUL.md                # Agent personality principles
├── USER.md                # Human preferences
├── IDENTITY.md            # Agent identity (name, vibe, emoji)
├── MEMORY.md              # Curated long-term memories (auto-updated)
├── TOOLS.md               # Local notes (cameras, SSH, TTS)
├── HEARTBEAT.md           # Periodic tasks to check
├── TODO.md                # Ongoing checklist
├── ENVIRONMENT_VARIABLES.md # Reference for all env vars
├── README.md              # Quick overview
├── SETUP_GUIDE.md         # Step-by-step setup
├── RECOVERY.md            # Disaster recovery
├── WORKFLOW.md            # This file — complete workflow
├── backup_status.json     # Last backup status
├── lucy_backup            # Marker file for backup system
├── .gitignore             # What to ignore in git
├── config-templates/      # Template configs (committed)
│   ├── llm-providers.json
│   ├── llm-providers-offline.json
│   └── slack_bridge.json
├── config/                # Actual configs (may contain env refs)
│   └── slack_bridge.json
├── scripts/               # Utility scripts
│   ├── backup.bat                 # Windows Task Scheduler backup (5 min)
│   ├── backup_offline.ps1         # Encrypted hourly backups
│   ├── backup_openclaw_improved.ps1 # Full backup with Telegram
│   ├── backup_task.xml            # Task Scheduler import
│   ├── cloud-sync.ps1             # Background sync daemon
│   ├── cloud-sync_task.xml        # Task Scheduler import
│   ├── gateway-service-nssm.ps1   # Install gateway as Windows service
│   ├── generate_ssh_key.ps1       # SSH key generator
│   ├── health-watcher.ps1         # Monitors gateway, restarts if down
│   ├── health-watcher_task.xml    # Task Scheduler import
│   ├── memory-logger.sh           # Linux memory logger
│   ├── post_bumblebee_status.ps1  # Status to Slack
│   ├── post_to_slack.ps1          # Generic Slack poster
│   ├── restore_from_github.sh     # Restore from GitHub backup
│   ├── safe-config-update-improved.sh # Safe config editor
│   ├── setup_doctorx_elevated.ps1 # Self-elevating task setup
│   ├── setup_doctorx_tasks.bat    # Batch task setup
│   ├── setup_doctorx_tasks.ps1    # PowerShell task setup
│   ├── slack_bridge_final.ps1     # Slack ↔ OpenClaw bridge
│   ├── slack_diagnostic.ps1       # Debug Slack bridge
│   └── ... (more)
├── systemd/               # Linux service unit
│   └── openclaw-gateway.service
├── memory/                # Daily transcript logs (auto-created)
│   └── 2026-03-02.md
└── subagents/             # Isolated agent workspaces
    ├── bumblebee/
    ├── doctor-x/
    └── megaton-google-workspace/
```

---

## Starting the Gateway

### Option A: Direct (development)
```bash
openclaw gateway start
```
Logs appear in console. Use Ctrl+C to stop.

### Option B: Windows Service (NSSM) — Recommended for production
Prerequisite: Install NSSM from https://nssm.cc and extract to `C:\nssm`
```powershell
# Run as Administrator
powershell -ExecutionPolicy Bypass -File scripts\gateway-service-nssm.ps1
```
Then start:
```powershell
nssm start OpenClawGateway
```
Check status:
```powershell
nssm status OpenClawGateway
```
Logs: `%USERPROFILE%\.openclaw\logs\gateway.stdout.log`

### Option C: Linux systemd
```bash
sudo cp systemd/openclaw-gateway.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now openclaw-gateway
sudo systemctl status openclaw-gateway
```

### Verify
Open another terminal:
```bash
curl http://127.0.0.1:18789/health
```
Expected output: `{"status":"healthy",...}`

---

## Backup & Sync

### Automatic (Recommended)

#### Windows Task Scheduler
Import the provided XML tasks (run as Administrator):
- `scripts/backup_task.xml` → runs every 5 minutes
- `scripts/cloud-sync_task.xml` → syncs when online

Or use the Doctor-X suite which includes backup verification, health checks, and auto-recovery:
```powershell
# Run as Administrator
powershell -ExecutionPolicy Bypass -File scripts\setup_doctorx_tasks.ps1
```

The backup script (`backup.bat`) performs:
1. Creates today's memory file if missing (`memory/YYYY-MM-DD.md`)
2. Updates `MEMORY.md` timestamp
3. Stages important files: `memory/`, `MEMORY.md`, `AGENTS.md`, `SOUL.md`, `USER.md`, `IDENTITY.md`, `TOOLS.md`, `scripts/`, `systemd/`, `config-templates/`
4. Commits with timestamp
5. Pushes to remote `origin main` (retry 3 times)
6. Logs to `backup.log`

#### Cloud Sync Daemon (alternative)
`scripts/cloud-sync.ps1` runs in background (or as scheduled task) and pushes changes whenever online, polling every 5 minutes.

### Manual Backup
```powershell
cd C:\Users\Administrator\.openclaw\workspace
.\scripts\backup_test.ps1
```

### Encrypted Offline Backups (Optional)
`scripts/backup_offline.ps1` creates encrypted `.tar.gz.age` archives in `backups_enc/` with retention policies. Requires `age` encryption tool.

---

## Health Monitoring

### Health Watcher (Windows)
`scripts/health-watcher.ps1` runs as a background loop (install via Task Scheduler `health-watcher_task.xml`, every 1 minute):
- Checks `http://127.0.0.1:18789/health`
- On failure, waits for 3 consecutive misses
- Restarts the `OpenClawGateway` service via NSSM
- Throttles restarts (min 2 minutes between)

### Health Monitor (Linux)
`scripts/health-monitor.sh` checks gateway, disk space, last backup, daily memory file, and sends alerts (integration pending).

---

## Subagents

Each subagent lives in `subagents/<name>/` and runs as a separate process/agent, communicating via the gateway.

### Existing Subagents (Folders Exist, Not Implemented)

- `bumblebee/` — Social media manager (Google Play Console flipping business model)
- `doctor-x/` — System monitoring agent (health checks, reports, auto-recovery)
- `megaton-google-workspace/` — Placeholder for another agent

To activate a subagent:
1. Create its `SKILL.md` and code within its folder.
2. Define its identity in `subagents/<name>/IDENTITY.md`.
3. Add its ID to `OPENCLAW_ALLOWED_AGENTS` environment variable (comma-separated).
4. Restart gateway.

Subagents can have their own `scripts/`, `memory/`, and configuration.

---

## Restoration Procedures

If the workspace is lost or corrupted, follow these steps to restore from GitHub backup.

### Prerequisites
- Git installed
- Access to backup repository (URL in `GIT_REPO` or known)
- Environment variables set (tokens, keys)
- OpenClaw installed (`npm i -g openclaw`)

### Full Restore (from GitHub)

1. **Clone the backup repository** into the workspace:
   ```bash
   # If workspace doesn't exist, create it
   mkdir %USERPROFILE%\.openclaw\workspace
   cd %USERPROFILE%\.openclaw\workspace

   # Clone backup repo (HTTPS with PAT or SSH)
   git clone <your-backup-repo-url> .
   # If using HTTPS with PAT, you'll be prompted for username (anything) and password (PAT)
   # If using SSH, ensure your key is added to the agent
   ```

2. **Switch to the latest commit**:
   ```bash
   git checkout main
   ```

3. **Copy templates to config** if missing:
   ```bash
   cp -r config-templates/* config/
   # config/ files still reference env vars, no secrets in repo.
   ```

4. **Set environment variables** (if not already set):
   - `OPENROUTER_API_KEY`
   - `OPENCLAW_TOKEN` (generate new if lost)
   - `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID`
   - `GIT_REPO` (point to your backup repo)
   - (Optional) Slack tokens

5. **Start the gateway** (choose method from above).

6. **Verify health**:
   ```bash
   curl http://127.0.0.1:18789/health
   ```

7. **Re-register subagents** if needed (check subagent folders exist and are allowed).

### Selective Restore (by date)

Use the provided script:
```bash
./scripts/restore_from_github.sh --date 2026-03-01
```
This will:
- Fetch remote
- Find commit before the given date
- Extract `memory/`, `MEMORY.md`, `AGENTS.md`, `SOUL.md`, `USER.md`, `IDENTITY.md`, `TOOLS.md`
- Overwrite local ones (backup of current state saved in `restore_<timestamp>/`)

### Rebuild from Scratch (no backup)

1. Clone this repository (or create files manually).
2. Fill `IDENTITY.md` and `USER.md`.
3. Follow Initial Setup steps.
4. Create `memory/` folder and today's memory file manually or let the system create it on first message.
5. Start gateway.

---

## Security Best Practices

1. **Never commit secrets.** All tokens and keys must be in environment variables only.
2. **Use `.gitignore`** to exclude:
   - `.openclaw/config.json` (local runtime config)
   - `.openclaw/logs/`
   - `config/credentials.json` (if created)
   - `backups/`, `backups_enc/` (local backup artifacts)
3. **Prefer SSH over HTTPS** for GitHub operations (no passwords in scripts).
4. **Rotate tokens periodically** and update env vars.
5. **Restrict subagents** via `OPENCLAW_ALLOWED_AGENTS`.
6. **Radio mode** for production: disable unnecessary integrations.

When adding a new external service:
- Add its token to env vars (update `ENVIRONMENT_VARIABLES.md`).
- Reference it in config as `${TOKEN_NAME}`.
- Never hardcode.

---

## Troubleshooting

### Gateway won't start
- Check logs: `%USERPROFILE%\.openclaw\logs\gateway.stderr.log` (Windows) or `journalctl -u openclaw-gateway` (Linux)
- Verify `OPENCLAW_TOKEN` is set and matches any permitted agents.
- Ensure port 18789 is free.

### Backup fails
- Verify `GIT_REPO` is correct and you have push access.
- Check network connectivity.
- Look at `backup.log` in workspace root.
- If using SSH, ensure your key is added to the agent (`ssh-add -l`).

### Health watcher not restarting service
- Service name must be `OpenClawGateway` (NSSM).
- Health watcher needs admin rights to restart service (run as scheduled task with highest privileges).
- Check `health-watcher.log`.

### Subagent not responding
- Confirm subagent's folder contains a valid agent (main script, SKILL.md).
- Ensure its ID is in `OPENCLAW_ALLOWED_AGENTS`.
- Check gateway logs for registration errors.
- Verify subagent can reach gateway URL (default `http://127.0.0.1:18789`).

### SSH authentication to GitHub fails
- Ensure your public key is added to GitHub (https://github.com/settings/keys).
- Ensure you are using the correct private key (`~/.ssh/id_ed25519`).
- Start ssh-agent and add key:
  ```bash
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/id_ed25519
  ```
- Test: `ssh -T git@github.com`

### Need to reset everything
- Delete `~/.openclaw` folder (or `%USERPROFILE%\.openclaw` on Windows).
- Reclone backup repo.
- Re-set environment variables.
- Restart gateway.

---

## Adding New Integrations

### New Channel (e.g., Discord)

1. Create the bot/application on Discord, obtain token.
2. Add environment variable `DISCORD_BOT_TOKEN`.
3. Create config file `config/discord.json` referencing `${DISCORD_BOT_TOKEN}`.
4. Implement a bridge script or use an existing OpenClaw plugin.
5. Update `SETUP_GUIDE.md` and `ENVIRONMENT_VARIABLES.md`.

### New LLM Provider

1. Obtain API key, set env var (e.g., `ANTHROPIC_API_KEY`).
2. Add provider entry in `config-templates/llm-providers.json`:
   ```json
   {
     "name": "anthropic",
     "priority": 10,
     "enabled": true,
     "apiKeyEnv": "ANTHROPIC_API_KEY",
     "models": ["claude-3-opus-20240229"],
     "fallback": true,
     "timeoutMs": 30000
   }
   ```
3. Copy to `config/llm-providers.json` if not already.

---

## Notes

- **MEMORY.md** is curated from daily logs (`memory/YYYY-MM-DD.md`). Do not edit manually; let the system update it periodically or use the curation script.
- **HEARTBEAT.md** contains tasks checked every ~30 minutes via the heartbeat mechanism. Keep it minimal.
- **Subagents** are independent; they can have their own `memory/`, `SKILL.md`, and scripts.
- **Backup frequency**: 5 minutes via Task Scheduler; cloud-sync runs continuously in background (or as scheduled).
- **Log rotation**: Not implemented yet; consider adding logrotate or manual cleanup.

---

## Quick Reference Commands

| Task | Command |
|------|---------|
| Start gateway | `openclaw gateway start` |
| Stop gateway | `openclaw gateway stop` |
| Check health | `curl http://127.0.0.1:18789/health` |
| Manual backup (test) | `powershell scripts\backup_test.ps1` |
| Encrypted backup | `powershell scripts\backup_offline.ps1` |
| Restore from date | `bash scripts/restore_from_github.sh --date YYYY-MM-DD` |
| Generate SSH key | `ssh-keygen -t ed25519 -C "you@example.com" -f ~/.ssh/id_ed25519 -N ""` |
| Add SSH key to agent | `ssh-add ~/.ssh/id_ed25519` |
| Test GitHub SSH | `ssh -T git@github.com` |
| Import backup task (Windows) | `schtasks /create /xml scripts/backup_task.xml /tn "OpenClaw Backup"` |
| View gateway logs (Windows) | `type $env:USERPROFILE\.openclaw\logs\gateway.stdout.log` |
| View gateway logs (Linux) | `journalctl -u openclaw-gateway -f` |

---

*Last updated: 2026-03-02*
