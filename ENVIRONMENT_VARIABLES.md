# JARVIS Environment Variables Reference

All sensitive credentials and API keys are stored in the `.env` file (root of workspace). This file is git-ignored.

## Required Variables

### OpenRouter (LLM Provider)
```bash
OPENROUTER_API_KEY=sk-or-v1-...
```
Get from: https://openrouter.ai/keys

### OpenClaw Gateway
```bash
OPENCLAW_TOKEN=...
```
Internal token for gateway API authentication. Auto-generated on first run.

### Slack (for posting to channels)
```bash
SLACK_BOT_TOKEN=xoxb-...
SLACK_APP_TOKEN=xapp-...  # Optional: only needed for Socket Mode
```
Create a Slack App → OAuth & Permissions → Bot Token Scopes: `chat:write`, `channels:read`, `groups:read`, `im:write`. Install to workspace.

### Tavily (Web Search)
```bash
TAVILY_API_KEY=tvly-dev-...
```
Get from: https://tavily.com (free tier available)

### Firecrawl (Web Scraping)
```bash
FIRECRAWL_API_KEY=fc-...
```
Get from: https://firecrawl.dev

### Here.Now (Static Hosting)
```bash
HERENOW_API_KEY=...
```
Get from: https://here.now/account/api-keys

### Google Workspace (Optional — Gmail, Drive, Calendar)
```bash
GOOGLE_CLIENT_ID=...apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-...
GOOGLE_REFRESH_TOKEN=1//0...
```
Setup: Create OAuth 2.0 credentials in Google Cloud Console, grant scopes, obtain refresh token via OAuth flow.

## Optional Variables

### Telegram (Optional — Telegram bot)
```bash
TELEGRAM_BOT_TOKEN=...
TELEGRAM_CHAT_ID=...
```

### Vercel (Optional — alternative hosting)
```bash
VERCEL_API_TOKEN=...
```

### GitHub Offsite Backup (if using HTTPS instead of SSH)
```bash
GIT_REPO=https://<token>@github.com/username/repo.git
```
If you prefer HTTPS pushes over SSH, set this with a PAT-embedded URL.

### OpenClaw Configuration
```bash
OPENCLAW_GATEWAY_PORT=18789
OPENCLAW_LOG_LEVEL=info
OPENCLAW_ALLOWED_AGENTS=*
```

## Loading

The `.env` file is automatically sourced by:
- `scripts/health-monitor.sh`
- `scripts/status-and-post.sh`
- OpenClaw agent sessions (via gateway)
- Skills that use `process.env`

## Security Notes

- **Never commit `.env`** — it's git-ignored
- **Never share tokens** in chats or logs
- **Rotate tokens** periodically, especially if exposed
- **Use least-privilege scopes** for Slack/Google tokens
- **Backup `.env`** separately in a secure password manager

## Template

A template is provided in `.env.example`. Copy to `.env` and fill values:
```bash
cp .env.example .env
# edit .env with your actual credentials
```

## Troubleshooting

**"Missing environment variable" errors:**
- Ensure `.env` exists in workspace root
- Check variable names match exactly (case-sensitive)
- Verify the script sources `.env` (most do automatically)

**Slack posting fails:**
- Verify `SLACK_BOT_TOKEN` has `chat:write` and `channels:read` scopes
- Check bot is added to the target channel

**Tavily searches fail:**
- Verify `TAVILY_API_KEY` is active (check Tavily dashboard)
- Free tier has rate limits

**Google Workspace errors:**
- Ensure refresh token is valid and not expired
- Check client ID/secret match the OAuth credentials used to obtain refresh token

## Variable Index

| Variable | Purpose | Required? | Used By |
|----------|---------|-----------|---------|
| `OPENROUTER_API_KEY` | LLM inference | Yes | All agents |
| `OPENCLAW_TOKEN` | Gateway auth | Yes | Gateway, plugins |
| `SLACK_BOT_TOKEN` | Slack messaging | Yes (if using Slack) | status-and-post, researcher |
| `TAVILY_API_KEY` | Web search | Yes (researcher) | researcher agent |
| `HERENOW_API_KEY` | Site deployment | Yes (publishing) | here-now skill |
| `GOOGLE_CLIENT_ID` | Google API auth | Optional | google-workspace skill |
| `GOOGLE_CLIENT_SECRET` | Google API auth | Optional | google-workspace skill |
| `GOOGLE_REFRESH_TOKEN` | Google API auth | Optional | google-workspace skill |
| `FIRECRAWL_API_KEY` | Web scraping | Optional | researcher agent |
| `TELEGRAM_BOT_TOKEN` | Telegram bot | Optional | Telegram gateway |
| `VERCEL_API_TOKEN` | Vercel deploy | Optional | vercel-deploy skill |

---

**Last updated:** 2025-03-04  
**Maintained by:** JARVIS - Devlomatix Solutions