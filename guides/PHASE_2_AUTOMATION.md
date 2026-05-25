# Phase 2: Automation & Testing (Days 6–10)

**Prerequisite:** Phase 1 complete (backup + restore proven).

---

## Day 6 — Retention policy

**Goal:** Stop `backups/` from growing forever.

**Script:** `scripts/retention_policy.sh`

**Policy (from `.env`):**
- Keep all backups from the last `DAILY_RETENTION` days (default 7)
- Keep the **newest backup per week** for `WEEKLY_RETENTION` weeks (default 4)
- Keep the **newest backup per month** for `MONTHLY_RETENTION` months (default 3)

**Commands:**
```bash
./scripts/retention_policy.sh           # dry-run (shows what would be deleted)
./scripts/retention_policy.sh --execute # actually delete
```

---

## Day 7 — Backup validation

**Goal:** Standalone validator for any `.dump` file.

**Script:** `scripts/validate_backup.sh`

```bash
./scripts/validate_backup.sh --latest
./scripts/validate_backup.sh backups/backup_20260525_112322.dump
```

Checks: file exists, minimum size, `pg_restore --list`.

---

## Day 8 — GitHub Actions daily backup

**Workflow:** `.github/workflows/daily_backup.yml`

**Schedule:** 01:00 UTC daily (+ manual trigger).

**You must add a repo secret:**
- `DATABASE_URL` — same Neon URL as local (quoted value in secret is fine; use **direct** host, not pooler if possible)

**What CI does:**
1. Install `postgresql-client`
2. Run `backup_full.sh`
3. Upload `.dump` as artifact (7-day retention on free GitHub)

---

## Day 9 — Weekly validation

**Workflow:** `.github/workflows/weekly_validation.yml`

**Schedule:** Sunday 02:00 UTC.

**What CI does:**
1. Fresh backup
2. `validate_backup.sh`
3. Query live DB row counts vs expected

---

## Day 10 — Health check

**Script:** `monitoring/backup_health_check.py`

```bash
./venv/bin/python monitoring/backup_health_check.py
```

Alerts if:
- No backup in last 25 hours
- Latest backup smaller than 100 KB

Use in cron or as a final step in Actions (optional).

---

## Phase 2 checklist

- [ ] Retention dry-run + `--execute` tested locally
- [ ] `validate_backup.sh --latest` passes
- [ ] `DATABASE_URL` added to GitHub Secrets
- [ ] `daily_backup` workflow run succeeds (manual dispatch first)
- [ ] `weekly_validation` workflow run succeeds
- [ ] `backup_health_check.py` exits 0 after a recent backup

**Next:** Phase 3 — DR runbook, GitHub Pages, polish.
