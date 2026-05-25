# Publish to GitHub

SSH is configured for `Makhosetive7`. Create the empty repo once, then push.

## 1. Create empty repository

Open (pre-filled form):

https://github.com/new?name=postgres-backup-recovery-system&description=PostgreSQL+backup+and+recovery+automation&visibility=public

Important:

- Do **not** add a README, license, or `.gitignore` (this project already has them).
- Click **Create repository**.

## 2. Push local commits

```bash
cd ~/projects/postgres-backup-recovery-system
git push -u origin main
```

## 3. Enable Actions

**Settings → Secrets and variables → Actions → New repository secret**

| Name | Value |
|------|--------|
| `DATABASE_URL` | Neon connection string (direct host, `sslmode=require`) |

**Actions → Daily Backup → Run workflow** (manual test).

## Alternative: GitHub CLI

```bash
gh auth login
gh repo create postgres-backup-recovery-system --public --source=. --remote=origin --push
```
