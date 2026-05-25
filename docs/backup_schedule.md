# Backup Schedule and Retention

## Automated schedule (GitHub Actions)

| Workflow | Schedule (UTC) | Purpose |
|----------|----------------|---------|
| Daily Backup | `0 1 * * *` (01:00 daily) | Full `pg_dump`, upload artifact |
| Weekly Validation | `0 2 * * 0` (02:00 Sunday) | Backup + validate + live row counts |

Manual runs: **Actions →** select workflow → **Run workflow**.

---

## Local scripts

| Script | When to run |
|--------|-------------|
| `backup_full.sh` | Ad hoc or cron on operator host |
| `retention_policy.sh` | After backups accumulate; use `--execute` to prune |
| `validate_backup.sh` | After any backup |
| `backup_health_check.py` | Cron every 6–12 hours |

---

## Retention

### Local (`backups/`)

Configured in `.env`:

| Setting | Default | Meaning |
|---------|---------|---------|
| `DAILY_RETENTION` | 7 | Keep all dumps from last 7 days |
| `WEEKLY_RETENTION` | 4 | Keep newest dump per week |
| `MONTHLY_RETENTION` | 3 | Keep newest dump per month |

```bash
./scripts/retention_policy.sh           # preview
./scripts/retention_policy.sh --execute # delete
```

### GitHub Actions artifacts

Artifact retention: **7 days** (GitHub free tier).  
Long-term archive: copy artifacts to object storage (e.g. R2) in a future phase.

---

## Secrets

| Secret | Used by |
|--------|---------|
| `DATABASE_URL` | Daily Backup, Weekly Validation |

Use a **direct** Neon connection string for `pg_dump` / `pg_restore` (hostname without `-pooler`).
