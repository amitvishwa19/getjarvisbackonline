# Environment Variables Reference

All sensitive configuration and tokens should be stored in environment variables, never in committed config files.

## Required Variables

| Variable | Purpose | Example / How to Get |
|----------|---------|---------------------|
| `OPENROUTER_API_KEY` | OpenRouter API key for LLM access | Get from https://openrouter.ai/keys |
| `OPENCLAW_TOKEN` | Gateway authentication token | Run `openclaw token generate` |
| `TELEGRAM_BOT_TOKEN` | Telegram bot token (from @BotFather) | `/newbot` command in Telegram |
| `TELEGRAM_CHAT_ID` | Your Telegram chat ID | Use @getidsbot or similar |
| `GIT_REPO` | Backup repository URL (HTTPS) | `https://github.com/you/backup.git` |

## Optional Variables

| Variable | Purpose | Default / Notes |
|----------|---------|-----------------|
| `SLACK_BOT_TOKEN` | Slack bot token (xoxb-...) | Slack App → OAuth & Permissions |
| `SLACK_APP_TOKEN` | Slack app-level token (xapp-...) | Slack App → Basic Information |
| `GOOGLE_AI_STUDIO_KEY` | Google AI Studio / Gemini API key | Google AI Studio |
| `OPENCLAW_ALLOWED_AGENTS` | Comma-separated allowed subagent IDs | e.g., `bumblebee,doctor-x` |
| `OPENCLAW_GATEWAY_PORT` | Gateway port (default 18789) | Change if port conflict |
| `OPENCLAW_LOG_LEVEL` | Logging level (info, debug, error) | Default: info |
| `TAVILY_API_KEY` | Tavily search/aggregation API key | https://tavily.com |
| `FIRECRAWL_API_KEY` | Firecrawl web scraping API key | https://firecrawl.dev |

## Setting Environment Variables

### Windows (PowerShell, User-level)
```powershell
[System.Environment]::SetEnvironmentVariable("VAR_NAME","value","User")
```
Restart terminal to apply.

### Linux/macOS (bash/zsh)
```bash
export VAR_NAME=value
# Add to ~/.bashrc or ~/.zshrc for persistence
```

## Best Practices

1. Never commit actual token values to git.
2. Use templates in `config-templates/` with `${VAR_NAME}` placeholders.
3. Copy templates to `config/` and keep them in .gitignore if they contain anything sensitive.
4. Rotate tokens periodically; update env vars accordingly.
5. For backup scripts, ensure `GIT_REPO` points to a repo you have push access to.

## Adding New Services

When integrating a new service:
1. Add a new environment variable name to this doc.
2. Reference it in config files as `"${NEW_VAR}"`.
3. Document the source for obtaining the token.
4. Never hardcode; always env var.
