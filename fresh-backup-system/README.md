# JARVIS Backup System

Production-ready, git-based backup for your JARVIS agent workspace. Simple, reliable, restorable.

## Features

- ✅ **Git versioning** — every backup is a commit; full history
- ✅ **Resource-limited** — `nice` + `ionice` to avoid system load
- ✅ **Locking** — prevents concurrent runs
- ✅ **Compression** — gzip level 6 (adjustable)
- ✅ **Exclusions** — skip `node_modules`, `backup-repo`, logs, etc.
- ✅ **Retention** — keep N days / N commits, auto-prune
- ✅ **Encryption** — optional GPG
- ✅ **Notifications** — Telegram, Slack
- ✅ **Health check** — built-in script
- ✅ **Restore** — point-in-time recovery

## Quick Start (2 minutes)

1. **Clone or copy this repository** to your server.

2. **Configure** `config/backup.conf`:
   ```bash
   BACKUP_PATHS="/path/to/workspace"
   # other settings optional
   ```

3. **Test configuration**:
   ```bash
   ./backup.sh --test
   ```

4. **Run first backup**:
   ```bash
   ./backup.sh
   ```

5. **Schedule daily** (cron):
   ```bash
   0 2 * * * cd /path/to/backup-system && ./backup.sh >> logs/backup-cron.log 2>&1
   ```

6. **Monitor health** (add to HEARTBEAT.md or cron):
   ```bash
   /path/to/backup-system/scripts/health-backup.sh
   ```

## File Structure

```
backup-system/
├── backup.sh              # main script
├── config/
│   └── backup.conf        # configuration
├── scripts/
│   ├── health-backup.sh   # health check
│   └── restore.sh         # restore utility
├── backup-repo/           # created automatically (git repo)
├── logs/                  # created automatically
└── README.md
```

## Configuration (`config/backup.conf`)

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `BACKUP_PATHS` | yes | — | Space-separated absolute paths to backup |
| `BACKUP_REPO` | no | `./backup-repo` | Local directory for backup repository |
| `RETENTION_DAYS` | no | 90 | Delete backups older than N days |
| `RETENTION_COUNT` | no | 365 | Keep at least N most recent commits |
| `COMPRESS_LEVEL` | no | 6 | 1 (fast) to 9 (max compression) |
| `EXCLUDE_PATTERNS` | no | see below | Patterns to exclude (one per line) |
| `LOG_FILE` | no | `~/.openclaw/workspace/backup-system/logs/backup.log` | Log path |
| `LOG_LEVEL` | no | `info` | `debug`, `info`, `warn`, `error` |
| `ENCRYPT` | no | `false` | Set `true` to enable GPG encryption |
| `ENCRYPTION_KEY_ID` | conditional | — | Your GPG key ID (required if ENCRYPT=true) |
| `NOTIFY_TELEGRAM` | no | `false` | Enable Telegram alerts |
| `TELEGRAM_BOT_TOKEN` | conditional | — | Bot token from @BotFather |
| `TELEGRAM_CHAT_ID` | conditional | — | Your chat ID |
| `NOTIFY_SLACK` | no | `false` | Enable Slack webhook |
| `SLACK_WEBHOOK_URL` | conditional | — | Slack incoming webhook URL |
| `PRE_HOOK` | no | — | Script to run before backup |
| `POST_HOOK` | no | — | Script to run after backup |

### Default Exclusions

```
backup-repo
node_modules
test-site
*.log
*.tmp
.DS_Store
Thumbs.db
```

These ensure the backup doesn't include:
- The backup repository itself (recursive)
- npm dependencies (reinstallable)
- Temporary test deployments
- Log files (regenerable)

## Usage

### Manual backup
```bash
./backup.sh
```

### Test configuration
```bash
./backup.sh --test
```

### Restore a specific backup

First, find the commit hash:
```bash
cd backup-repo
git log --oneline
```

Then restore:
```bash
./scripts/restore.sh <commit-hash> /target/path
```

Example:
```bash
./scripts/restore.sh a1b2c3d /tmp/restore
```

All archives from that commit will be extracted into `/tmp/restore/<archive-name>/`.

### Health check
```bash
./scripts/health-backup.sh
```

Checks:
- Repository exists
- Disk space (>5GB)
- Last backup age (<48h)
- Configuration validity
- Backup paths exist

## Retention

Two-tier policy:
- **Count**: Keeps at least N most recent commits (even if younger than days limit)
- **Age**: Commits older than N days are candidates for removal

Pruning runs automatically after each backup commit using `git reflog expire` + `git gc`.

## Encryption (Optional)

1. Generate a GPG key (if you don't have one):
   ```bash
   gpg --full-generate-key
   ```

2. Get your key ID:
   ```bash
   gpg --list-secret-keys --keyid-format LONG
   # Output: sec   rsa4096/ABCDEF1234567890 ...
   ```

3. Set in `backup.conf`:
   ```bash
   ENCRYPT=true
   ENCRYPTION_KEY_ID=ABCDEF1234567890
   ```

All archives will be encrypted with `.gpg` extension. To restore, your private key must be available on the restore machine.

## Notifications

### Telegram
```bash
NOTIFY_TELEGRAM=true
TELEGRAM_BOT_TOKEN="123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"
TELEGRAM_CHAT_ID="123456789"
```

### Slack
```bash
NOTIFY_SLACK=true
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
```

## Hooks

Pre- and post-backup hooks allow custom actions.

Example `pre-backup.sh`:
```bash
#!/bin/bash
# Dump a database before backup
mysqldump -u root -p"$DB_PASS" mydb > /tmp/dump.sql
```

Example `post-backup.sh`:
```bash
#!/bin/bash
# Push backup repo to remote
cd /path/to/backup-repo && git push origin main
```

Make executable and set in config:
```bash
PRE_HOOK="/path/to/pre-backup.sh"
POST_HOOK="/path/to/post-backup.sh"
```

## Troubleshooting

### "Nothing to commit" every run
This is normal if source files haven't changed. Backup creates a commit only when changes detected.

### "tar: command not found"
Install tar (Linux: usually preinstalled; macOS: comes with Xcode CLI tools).

### Low disk space
Adjust `RETENTION_DAYS`/`RETENTION_COUNT` or prune manually:
```bash
cd backup-repo
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

### Permission denied
Ensure the user running backup has:
- Read access to all `BACKUP_PATHS`
- Write access to `BACKUP_REPO` and `LOG_FILE`

## Security Notes

- Keep `backup.conf` (or `.env`) secure; it may contain credentials.
- If using encryption, back up your **private GPG key** separately.
- Limit filesystem permissions: `chmod 700 backup-system`.
- Remote git pushes should use SSH keys, not passwords.

## License

MIT — Use freely. Part of JARVIS agent ecosystem.

---

**JARVIS Backup System v1.0** — Keep your agent alive. 🚀