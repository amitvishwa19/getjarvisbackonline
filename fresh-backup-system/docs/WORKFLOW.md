# JARVIS Backup System — Workflow Overview

This document describes how the backup system fits into the JARVIS agent lifecycle and how to restore the entire agent from scratch.

---

## 1. Backup Flow

```
┌─────────────────────┐
│ backup.sh invoked   │ (cron or manual)
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ Acquire lock        │ (prevents concurrent runs)
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ Check dependencies  │ (git, tar, gzip)
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ Init backup-repo    │ (git init if needed)
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ For each path in    │
│ BACKUP_PATHS        │
│  ┌──────────────┐   │
│  │ Create tar   │   │ (with exclusions, nice/ionice)
│  │ + compress   │   │
│  └──────────────┘   │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ Git add + commit    │ (only if changes)
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ Retention prune     │ (reflog expire + gc)
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ Notify (optional)   │ (Telegram/Slack)
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ Release lock & exit │
└─────────────────────┘
```

---

## 2. Restore Flow

```
┌────────────────────────────┐
│ User requests restore      │
│ (e.g., after server loss)  │
└──────────┬─────────────────┘
           │
           ▼
┌────────────────────────────┐
│ Clone backup repo to new    │
│ server (git clone <repo>)   │
└──────────┬─────────────────┘
           │
           ▼
┌────────────────────────────┐
│ Pick a commit hash         │
│ (git log --oneline)        │
└──────────┬─────────────────┘
           │
           ▼
┌────────────────────────────┐
│ Run restore.sh             │
│ ./restore.sh <hash> /dest  │
└──────────┬─────────────────┘
           │
           ▼
┌────────────────────────────┐
│ Script:                     │
│  - checkout commit files   │
│  - decrypt if needed       │
│  - extract archives        │
│  - place in /dest          │
└──────────┬─────────────────┘
           │
           ▼
┌────────────────────────────┐
│ Agent workspace revived    │
│ (including .git history)   │
└────────────────────────────┘
```

**Note:** The backup repository contains the entire `.git` history of your workspace, so after restore you can `cd /dest && git log` to see full history.

---

## 3. Integration with JARVIS

### Heartbeat Monitoring

Add to `HEARTBEAT.md`:

```markdown
## Backup System Health
- /path/to/backup-system/scripts/health-backup.sh
```

This runs every ~30 minutes with other health checks.

### Manual Trigger from JARVIS

You can ask JARVIS to run a backup:

> "JARVIS, run backup now"

JARVIS would execute:
```bash
/path/to/backup-system/backup.sh
```

And report success/failure.

---

## 4. Disaster Recovery Playbook

### Scenario: Complete server loss

1. **Provision new server** (same OS or similar)
2. **Install dependencies**: git, bash, tar, gzip (gpg if encrypted)
3. **Clone backup data repo** (if stored remotely) or copy `backup-repo/`
4. **Restore latest**:
   ```bash
   cd backup-repo
   latest=$(git log -1 --format=%H)
   ../scripts/restore.sh $latest /home/ubuntu/.openclaw/workspace
   ```
5. **Reinstall npm dependencies**:
   ```bash
   cd /home/ubuntu/.openclaw/workspace
   npm install
   ```
6. **Restart OpenClaw gateway**:
   ```bash
   openclaw gateway start
   ```
7. **Verify**: JARVIS should be back online with full memory and history.

---

## 5. What Gets Backed Up

Everything except exclusions:

| Included | Excluded |
|----------|----------|
| All code (`skills/`, `scripts/`, `config/`) | `node_modules/` |
| `.git` history (essential for full restore) | `backup-repo/` (to avoid recursion) |
| Environment `.env` (credentials) | `test-site/` (temp) |
| Memory (`memory/`, `MEMORY.md`) | `*.log`, `*.tmp` |
| Documentation (`*.md`) | OS files (`.DS_Store`) |

**Total size**: ~30MB compressed for a typical JARVIS workspace.

---

## 6. Offsite Storage (Recommended)

To protect against server failure, push `backup-repo/` to a separate remote:

```bash
cd backup-repo
git remote add offsite git@github.com:yourname/jarvis-backup-offsite.git
git push -u offsite main
```

Add to `backup.conf`:

```bash
POST_HOOK="/path/to/push-offsite.sh"
```

Where `push-offsite.sh` contains:
```bash
#!/bin/bash
cd /path/to/backup-repo && git push offsite main
```

---

## 7. Testing Backups

Periodically perform a test restore:

```bash
# 1. Create a temp directory
mkdir /tmp/restore-test

# 2. Pick a recent commit
cd backup-repo
commit=$(git log -1 --format=%H)

# 3. Restore
../scripts/restore.sh $commit /tmp/restore-test

# 4. Verify expected files exist
ls /tmp/restore-test/workspace/
```

If restore succeeds, your backups are healthy.

---

**End of Workflow**