# Recovery Procedures

If your agent workspace gets corrupted or you need to restore from backup.

## From GitHub Backup

```bash
cd ~/.openclaw/workspace
git fetch origin
git reset --hard origin/main   # WARNING: discards local changes
```

Or use the restore script for selective restore:
```bash
./scripts/restore_from_github.sh --date 2026-03-01
```

## Rebuild from Scratch

1. Clone backup repo: `git clone <your-backup-repo> ~/.openclaw/workspace`
2. Copy `config-templates/*.json` to `config/` and edit with your tokens.
3. Install gateway service (see SETUP_GUIDE.md).
4. Start gateway: `openclaw gateway start`
5. Re-register any subagents.

## Lost Gateway Token

Generate a new token:
```bash
openclaw token generate
```
Then update:
- `config/slack_bridge.json` → `openclaw.token`
- Any scheduled task env vars `OPENCLAW_TOKEN`.

## Restore Subagent State

Subagent state lives in their own folders. If lost, you can:
- Re-clone their repository if they are separate.
- Rebuild from memory logs (`memory/YYYY-MM-DD.md`) to reconstruct conversations.

## Emergency Stop

To pause all automation:
- Disable Task Scheduler tasks (Doctor-X*, backup*, cloud-sync*).
- Stop gateway service: `nssm stop OpenClawGateway` or `openclaw gateway stop`.

## Verify Health

```bash
curl http://127.0.0.1:18789/health
```

Should return `{"status":"healthy",...}`.

If not, check logs:
- Windows: `%USERPROFILE%\.openclaw\logs\`
- Linux: `~/.openclaw/logs/`
