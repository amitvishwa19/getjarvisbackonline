# JARVIS System Restore Guide — Complete, No-Assumptions Edition

**Goal:** Restore the entire JARVIS multi-agent system on a fresh machine from this GitHub repository, with all integrations (Telegram, Slack, Google Workspace, here.now publishing, backups) fully functional.

**Audience:** Anyone with basic Linux/Node.js knowledge. Follow step-by-step.

**Time estimate:** 30–60 minutes (depending on API approvals).

---

## 📦 What You're Restoring

A fully-featured AI assistant with:
- **6 specialized sub-agents** (planner, workspace manager, medical bulletin, researcher, social media, system monitor)
- **Automated backups** (daily at 2 AM, every 5 min offsite push to GitHub)
- **Health monitoring** (every 30 min, hourly status to Slack)
- **Integrated research** (Tavily + Firecrawl web search)
- **Publishing** (Tailwind CSS docs to here.now)
- **Cross-platform memory** (shared conversation across Telegram/webchat/Slack)
- **Slack integration** (agent-specific channels)
- **Google Workspace** (Gmail, Drive, Calendar)
- **OpenRouter LLM** (free models with fallback)

All of this is in this repository. Nothing external except API keys.

---

## 🛠️ Prerequisites Checklist

You need these installed **before** starting:

| Tool | Minimum Version | Install Command |
|------|-----------------|-----------------|
| Git | 2.30+ | `sudo apt install git` |
| Node.js | 18+ | `sudo apt install nodejs npm` or use nvm |
| npm | 8+ | (comes with Node) |
| OpenClaw CLI | latest | `npm install -g openclaw` |
| Bash | 4+ | (pre-installed on Ubuntu) |
| Cron | any | `sudo apt install cron` (usually pre-installed) |
| SSH (optional) | any | `sudo apt install openssh-client` |

**Verify:**
```bash
git --version    # e.g., git version 2.34.1
node --version   # e.g., v18.19.0
npm --version    # e.g., 9.8.1
openclaw --help  # should show help text
which cron       # should be /usr/sbin/cron
```

If any missing, install first.

---

## 🔐 Step 0: Get Your API Keys (Gather Credentials)

Before you even clone, collect these tokens. Make a list.

### **0.1 OpenRouter API Key** (LLM provider)
1. Go to: https://openrouter.ai/
2. Sign up / login
3. Click profile → **API Keys**
4. Copy key starting with `sk-or-v1-...`
5. Note: Free tier has usage limits but plenty for testing

### **0.2 Slack Bot Token** (for posting to #system-monitor, #research-analyst)
1. Go to: https://api.slack.com/apps
2. Create New App → From scratch
3. Name: `JARVIS`, Workspace: your workspace
4. Go to **OAuth & Permissions**:
   - Scopes → Bot Token Scopes:
     - `chat:write` (required)
     - `channels:read` (required)
     - `groups:read` (optional)
     - `im:write` (optional, for DMs)
   - Scroll up → **Install to Workspace** → Install
5. Copy **Bot User OAuth Token** (`xoxb-...`)
6. (Optional) Enable **Socket Mode** if needed (but not required for this setup)

**Add bot to channels:**
- Join `#system-monitor` and `#research-analyst` (create if not exist)
- Invite bot by username: `/invite @JARVIS` (or the bot name you gave)

### **0.3 Tavily API Key** (web search)
1. Go to: https://tavily.com/
2. Sign up (free tier available)
3. Dashboard → **API Keys**
4. Copy key (starts with `tvly-...`)

### **0.4 Here.Now API Key** (hosting)
1. Go to: https://here.now/ (or your hosting provider if different)
2. Account → API Tokens
3. Generate new token
4. Copy it

### **0.5 Google Workspace Credentials** (optional, for Gmail/Calendar/Drive)
If you want JARVIS to manage emails/docs, you need OAuth2:

1. Go to: https://console.cloud.google.com/
2. Create new project or select existing
3. Enable APIs:
   - Gmail API
   - Google Drive API
   - Google Calendar API
4. Go to **Credentials** → Create Credentials → OAuth 2.0 Client ID
   - Application type: **Web Application**
   - Name: `JARVIS OpenClaw`
   - Authorized redirect URIs: `https://developers.google.com/oauthplayground` (or use OAuth Playground)
5. Create → Note down:
   - `client_id` (looks like `...apps.googleusercontent.com`)
   - `client_secret`
6. Get **Refresh Token**:
   - Use OAuth 2.0 Playground: https://developers.google.com/oauthplayground/
   - Click gear icon → check "Use your own OAuth credentials" → enter client_id & secret
   - Select scopes: `https://mail.google.com/`, `https://www.googleapis.com/auth/drive`, `https://www.googleapis.com/auth/calendar`
   - Authorize → Get refresh token
7. Save these three:
   ```
   GOOGLE_CLIENT_ID=...
   GOOGLE_CLIENT_SECRET=...
   GOOGLE_REFRESH_TOKEN=...
   ```

### **0.6 Firecrawl API Key** (optional, for advanced scraping)
1. Go to: https://firecrawl.dev
2. Sign up → API Keys
3. Copy key (starts with `fc-...`)

### **0.7 GitHub Personal Access Token** (for offsite backup push via HTTPS)
If you prefer HTTPS over SSH for backup push:

1. GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token
3. Scopes: `repo` (full control of private repos)
4. Copy token (starts with `ghp_...` or `gho_...`)

---

**After gathering all, you should have a list like:**

```
OPENROUTER_API_KEY=sk-or-v1-...
SLACK_BOT_TOKEN=xoxb-...
TAVILY_API_KEY=tvly-...
HERENOW_API_KEY=...
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
GOOGLE_REFRESH_TOKEN=...
FIRECRAWL_API_KEY=...
GIT_REPO=https://<PAT>@github.com/amitvishwa19/getjarvisbackonline.git  # optional
```

---

## 🖥️ Step 1: Clone the Repository

```bash
# Go to your home (or desired location)
cd ~

# Clone repository
git clone git@github.com:amitvishwa19/getjarvisbackonline.git workspace
# If using HTTPS with PAT:
# git clone https://<YOUR_PAT>@github.com/amitvishwa19/getjarvisbackonline.git workspace

# Enter workspace
cd workspace
```

**Expected output:**
```
Cloning into 'workspace'...
...
```

**Verify:**
```bash
pwd
# Should show: /home/ubuntu/workspace (or wherever you cloned)

ls -la
# Should list: AGENTS.md, SUBSCRIPTIONS.md, scripts/, skills/, etc.
```

---

## 📦 Step 2: Install Node.js Dependencies

```bash
npm install
```

**What this does:**
- Reads `package.json`
- Installs `googleapis` and any other dependencies
- Creates `node_modules/`

**Expected output:**
```
added X packages in Ys
```

**Verify:**
```bash
ls node_modules | head -10
# Should show many packages
```

---

## 🔐 Step 3: Setup Environment Variables

```bash
# Copy example template
cp .env.example .env

# Edit .env with your actual values
nano .env
```

**Fill in each line with your real keys from Step 0.** Example:

```bash
OPENROUTER_API_KEY=your-openrouter-key
OPENCLAW_TOKEN=any-random-secure-string
SLACK_BOT_TOKEN=xoxb-your-bot-token
TAVILY_API_KEY=tvly-your-key
HERENOW_API_KEY=your-here-now-api-key
GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-client-secret
GOOGLE_REFRESH_TOKEN=your-refresh-token
FIRECRAWL_API_KEY=fc-your-key
OPENCLAW_GATEWAY_PORT=18789
OPENCLAW_LOG_LEVEL=info
```

**Save & exit** (Ctrl+X, then Y, then Enter in nano).

**Verify:**
```bash
head -20 .env
# Should show your filled values (not the placeholder ones)
```

**Important:** `.env` is gitignored — it will never be committed. Keep it safe.

---

## ⚙️ Step 4: Setup Slack Channel Configuration

The system uses `config/slack-channels.conf` to map each sub-agent to its dedicated Slack channel.

```bash
# Edit the config
nano config/slack-channels.conf
```

**Update with your actual Slack channel IDs** (not names). Example:

```
daily-planner: C0AH4TSS893
google-workspace-manager: C0AHTNLA8KC
medical-bulletin: C0AHYC3C58B
researcher: C0AHF291VE3
socialmedia-manager: C0AHWQG9536
system-monitor: C0AHPT66TV3
publisher: C0AJ152F8VD
```

**How to get channel IDs:**
- In Slack, open channel → look at URL: `https://app.slack.com/client/T05BGA09ZB9/C0AHF291VE3`
- The long string after last `/` is the channel ID (starts with `C` for public channels, `G` for private)
- Or use Slack API: `curl -H "Authorization: Bearer $SLACK_BOT_TOKEN" https://slack.com/api/conversations.list`

**Save** and exit.

---

## ⏰ Step 5: Setup Cron Jobs (Automation)

These cron jobs run backups, monitoring, and status reports.

```bash
# Open your user's crontab
crontab -e
```

**Add these lines** (exactly as shown):

```
*/30 * * * * cd /home/ubuntu/.openclaw/workspace && ./scripts/health-monitor.sh >> .health.log 2>&1
0 2 * * * cd /home/ubuntu/.openclaw/workspace/backup-system && ./backup-v2.sh >> logs/backup-cron.log 2>&1
*/5 * * * * /home/ubuntu/.openclaw/workspace/backup-system/scripts/watchdog.sh
*/5 * * * * /home/ubuntu/.openclaw/workspace/backup-system/scripts/push-offsite.sh
0 * * * * /home/ubuntu/.openclaw/workspace/scripts/status-and-post.sh >> /home/ubuntu/.openclaw/workspace/logs/system-status.log 2>&1
```

**Important:** Replace `/home/ubuntu/.openclaw/workspace` with your actual workspace path if different.

**Save and exit.** (In nano: Ctrl+X, Y, Enter)

**Verify:**
```bash
crontab -l
```
Should show all 5 entries.

---

## 🔧 Step 6: Configure Backup System (GitHub Remote)

The backup system stores workspace snapshots in `backup-system/backup-repo/`. By default it's a local git repo. To enable offsite backup to GitHub:

### **6.1 Check backup-repo exists and has local commit**

```bash
cd backup-system/backup-repo
git log --oneline -1
```

Expected: something like `497debc Backup 2026-03-04 13:38 UTC`

If empty, initialize:
```bash
git init
git config user.email "jarvis-backup@localhost"
git config user.name "JARVIS Backup"
# A backup will be created automatically at next scheduled run (2 AM) or you can run manually:
cd ~/workspace/backup-system && ./backup-v2.sh
```

### **6.2 Add GitHub remote**

```bash
# Still in backup-system/backup-repo
git remote add origin git@github.com:amitvishwa19/getjarvisbackonline.git
# OR use HTTPS with PAT:
# git remote add origin https://<YOUR_PAT>@github.com/amitvishwa19/getjarvisbackonline.git
```

**Verify:**
```bash
git remote -v
# Should show origin with fetch and push
```

### **6.3 Create and push backup-data branch**

```bash
# Create branch backup-data from current master (or main)
git branch -M backup-data
git push -u origin backup-data
```

If push fails with "refusing to update checked out branch", force push (only if remote is empty or you're okay overwriting):
```bash
git push -f -u origin backup-data
```

**Expected:**
```
To github.com:amitvishwa19/getjarvisbackonline.git
 * [new branch]      backup-data -> backup-data
Branch 'backup-data' set up to track remote branch 'backup-data' from 'origin'.
```

**Verify on GitHub:**
- Go to your repo: https://github.com/amitvishwa19/getjarvisbackonline
- Switch branch dropdown to `backup-data`
- You should see a file like `backup-workspace-YYYYMMDD-HHMMSS.tar.gz`

---

## 🔑 Step 7: SSH Setup for GitHub (if using SSH)

If you used `git@github.com:...` remote, you need SSH key added to GitHub.

### **7.1 Check existing SSH keys**

```bash
ls -la ~/.ssh/
```

Look for `id_ed25519` or `id_rsa` files.

### **7.2 If no key, generate one**

```bash
ssh-keygen -t ed25519 -C "jarvis@devlomatix.com"
# Press Enter for default location (~/.ssh/id_ed25519)
# Add passphrase (optional but recommended) or leave empty
```

### **7.3 Add key to ssh-agent**

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

### **7.4 Copy public key**

```bash
cat ~/.ssh/id_ed25519.pub
```

Copy the entire line (starts with `ssh-ed25519 ...`)

### **7.5 Add to GitHub**

- GitHub → Settings → SSH and GPG keys → New SSH key
- Title: `JARVIS Backup` (or any name)
- Key: paste your public key
- Add SSH key

### **7.6 Test connection**

```bash
ssh -T git@github.com
```

Expected:
```
Hi amitvishwa19! You've successfully authenticated, but GitHub does not provide shell access.
```

If you see "Permission denied", double-check key added correctly and ssh-agent running.

---

## 🚀 Step 8: Start the OpenClaw Gateway

Now everything is configured.

```bash
# From workspace root
openclaw gateway start
```

**What happens:**
- Gateway process starts on port 18789 (or `OPENCLAW_GATEWAY_PORT`)
- Loads agent config from `AGENTS.md`, `SUBSCRIPTIONS.md`
- Connects to Telegram (if `TELEGRAM_BOT_TOKEN` set)
- Connects to Slack (if `SLACK_BOT_TOKEN` set)
- Begins heartbeat and cron调度
- Loads memory from `memory/shared-conversation.md`

**Expected output:**
```
Gateway starting...
Listening on 127.0.0.1:18789
Telegram: connected
Slack: connected
```

---

## ✅ Step 9: Verify the System is Running

### **9.1 Check gateway status**

```bash
openclaw gateway status
```

Should show:
```
Status: running
Port: 18789
Uptime: X seconds
Memory: ...
```

### **9.2 Test health endpoint**

```bash
curl http://127.0.0.1:18789/health
```

Expected JSON:
```json
{"status":"ok"}
```

### **9.3 Check cron jobs are active**

```bash
crontab -l
```

They're set. You can also check system cron logs:
```bash
sudo grep CRON /var/log/syslog | tail -20
```

### **9.4 Test Slack posting**

The hourly status will post automatically, but you can test manually:

```bash
/home/ubuntu/.openclaw/workspace/scripts/status-and-post.sh
```

Then check Slack `#system-monitor` for a message.

### **9.5 Test researcher agent**

Send a message via Telegram or directly:

```bash
curl -X POST http://127.0.0.1:18789/message \
  -H "Content-Type: application/json" \
  -d '{"content":"JARVIS, research latest AI updates 2025"}'
```

Expected:
- Researcher spawns
- Full results posted to Slack `#research-analyst`
- Summary returned in response

### **9.6 Test backup**

Run backup manually to ensure it works:

```bash
cd backup-system
./backup-v2.sh
```

Expected output:
```
[INFO] === Backup started ===
[INFO] Lock acquired
[INFO] Archiving /home/ubuntu/.openclaw/workspace → backup-workspace-...
[INFO] Created: backup-workspace-YYYYMMDD-HHMMSS.tar.gz
[INFO] Backup completed in Xs
```

Check backup repo:
```bash
cd backup-repo
git status  # Should show new file added
git log -1   # Should show "Backup: ..."
```

---

## 📚 Step 10: Verify Documentation & Publishing

### **10.1 Here.Now deployment**

The docs site is in `backup-docs-site/`. Deploy it:

```bash
# From workspace root
node skills/here-now/index.js --dir ./backup-docs-site
```

Expected output:
```
✅ Deployed to here.now!
🌐 Site: https://<slug>.here.now/
🔖 Slug: <slug>
```

Open that URL in browser — you should see the JARVIS documentation site.

### **10.2 Check all pages**

- `/` — Home
- `/system-docs.html` — System reference
- `/workflow.html` — Visual diagrams
- `/ai-updates-2025.html` — Sample AI report

---

## 🧠 Step 11: Memory & Agent Configuration

### **11.1 Memory is already set**

The repository includes `memory/shared-conversation.md` with full conversation history (since we migrated). The agent will load this automatically on startup.

### **11.2 Agent model assignments**

Already configured in `SUBSCRIPTIONS.md`:
- **researcher** → `openrouter/stepfun/step-3.5-flash:free`
- All others → `openrouter/auto` (auto-selection)

To change, edit `SUBSCRIPTIONS.md` and restart gateway.

### **11.3 Slack channel mapping**

Already in `config/slack-channels.conf`. Update if your channel IDs differ.

---

## 🛡️ Step 12: Security Checklist

- [x] `.env` is gitignored (verify with `git status` — should not list `.env`)
- [x] No hardcoded tokens in any files (`grep -r "xoxb-" .` should only show in `.env` or memory logs)
- [x] `OPENCLAW_TOKEN` is random and strong
- [x] SSH keys are passphrase-protected (optional but recommended)
- [x] GitHub PAT has minimal scopes (`repo` only)
- [x] Slack bot has only needed scopes (`chat:write`, `channels:read`)
- [x] All tokens stored in `.env` only, not in logs or console output

---

## 🆘 Troubleshooting

| Problem | Likely Cause | Solution |
|---------|--------------|----------|
| Gateway won't start | Missing `.env` vars | `nano .env` and fill all required |
| Slack messages fail | Bot not in channel or wrong token | Invite bot to channel, check token scopes |
| Tavily search fails | Invalid API key | Check key in Tavily dashboard |
| Backups not running | Cron not installed or wrong path | `sudo apt install cron`; verify paths |
| GitHub push fails | SSH key not added or PAT wrong | `ssh -T git@github.com` to test; fix remote URL |
| here.now deploy fails | Missing `HERENOW_API_KEY` or network | Verify key; check internet |
| Memory not loading | `memory/shared-conversation.md` missing | Ensure file exists and is readable |
| Sub-agent not spawning | Model unavailable | Check OpenRouter dashboard for model access |

---

## 📊 What Gets Restored?

| Component | Source | State after restore |
|-----------|--------|--------------------|
| Agent config | `AGENTS.md`, `SUBSCRIPTIONS.md` | All 6 agents defined with models |
| Memory | `memory/shared-conversation.md` | Full conversation history |
| Skills | `skills/` folder | All skills installed locally |
| Scripts | `scripts/` | System-status, health-monitor, backup, etc. |
| Cron | User crontab | All 5 jobs scheduled |
| Slack config | `config/slack-channels.conf` | Agent→channel mapping |
| Docs site | `backup-docs-site/` | Ready to deploy |
| Backup history | `backup-system/backup-repo/` | Optional; restore from GitHub if needed |

---

## 🔄 Post-Restore Actions

1. **Monitor first backup** (tomorrow at 2 AM) or run manually: `./backup-system/backup-v2.sh`
2. **Check hourly status** in Slack `#system-monitor` (at minute 0)
3. **Test researcher** periodically
4. **Update docs** if you change anything
5. **Commit & push** any local changes to keep GitHub updated

---

## 📞 Support

- **System docs:** `SYSTEM_DOCUMENTATION.md`
- **Env vars:** `ENVIRONMENT_VARIABLES.md`
- **OpenClaw CLI:** `openclaw --help`
- **Community:** https://discord.com/invite/clawd

---

**You now have a complete, production-ready JARVIS system.** 🎉

Last updated: 2025-03-04  
By: JARVIS — Devlomatix Solutions
