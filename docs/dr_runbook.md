# Disaster Recovery Runbook

**System:** E-commerce sample database on Neon  
**Owner:** Database / platform team  
**Last updated:** 2026-05-25

---

## 1. Scope

This runbook covers full logical restore from `pg_dump` archives created by `backup_full.sh` or the Daily Backup GitHub Action.

**In scope:** Complete loss of application tables, bad migration, need to roll back to last good dump.

**Out of scope (requires provider PITR or WAL):** Point-in-time recovery between two dumps, e.g. undoing a `DELETE` from 10 minutes ago.

---

## 2. Recovery objectives

| Metric | Target | How measured |
|--------|--------|----------------|
| RPO | 24 hours (daily backup) | Time since last successful backup |
| RTO | 2 hours (lab); validate in your environment | Wall-clock for `restore.sh` |

See [rto_rpo_policy.md](rto_rpo_policy.md) for detail.

---

## 3. Prerequisites

- PostgreSQL client tools (`pg_dump`, `pg_restore`, `psql`)
- Valid `DATABASE_URL` in `.env` (local) or GitHub secret (CI)
- Access to latest `.dump` file (local `backups/` or Actions artifact)
- Approval for **destructive restore** on the target database

---

## 4. Roles

| Role | Responsibility |
|------|----------------|
| Operator | Runs restore, verifies counts |
| Reviewer | Confirms correct backup file and target database |

---

## 5. Scenario A — Full database loss

### 5.1 Assess

1. Confirm outage scope (all tables vs single table).
2. Identify latest **known good** backup:
   - Local: `ls -lt backups/backup_*.dump | head -1`
   - CI: download artifact from latest green **Daily Backup** run

### 5.2 Validate backup file

```bash
./scripts/validate_backup.sh backups/backup_YYYYMMDD_HHMMSS.dump
```

Expected: `VALIDATION OK`, size roughly 1–2 MB for sample data.

### 5.3 Restore

```bash
set -a && source .env && set +a
./scripts/restore.sh backups/backup_YYYYMMDD_HHMMSS.dump
```

Or latest local file:

```bash
./scripts/restore.sh --latest
```

**Warning:** `--clean` drops and recreates objects in the target database.

### 5.4 Verify

Script checks row counts automatically:

| Table | Expected |
|-------|----------|
| customers | 10,000 |
| products | 1,000 |
| orders | 50,000 |
| order_items | 100,000 |

Manual spot-check:

```bash
psql "$DATABASE_URL" -c "SELECT COUNT(*) FROM orders;"
```

### 5.5 Communicate

- Record restore start/end time (RTO evidence)
- Note backup file used and who approved restore
- Resume application traffic after validation

---

## 6. Scenario B — Practice / drill

For non-production drills only:

```bash
./scripts/restore.sh --latest --simulate-disaster
```

Drops all four tables, then restores from backup. Safe on lab Neon project only.

---

## 7. Scenario C — Restore from GitHub Actions artifact

1. Open **Actions → Daily Backup →** latest successful run.
2. Download artifact (`.dump` file).
3. Copy to `backups/` on operator machine.
4. Follow **Scenario A** steps 5.2–5.5.

---

## 8. Failure handling

| Symptom | Action |
|---------|--------|
| `pg_restore` connection error | Use direct Neon URL (not pooler); check `sslmode=require` |
| Row count mismatch | Try older backup; investigate data changes after dump |
| Backup too small | Do not restore; use previous artifact |
| `role does not exist` on psql | `DATABASE_URL` not loaded; quote URL if it contains `&` |

---

## 9. Post-incident

1. Log incident in `docs/restore_test_history.md` (template below).
2. Run root-cause analysis if production.
3. Confirm next scheduled backup succeeds.

### Restore log entry (copy per event)

```markdown
## YYYY-MM-DD — [Drill | Incident]

- Backup file:
- Operator:
- Start / end (RTO):
- Row counts OK: yes / no
- Notes:
```

---

## 10. Related documents

- [recovery_quick_steps.md](recovery_quick_steps.md)
- [backup_schedule.md](backup_schedule.md)
- [rto_rpo_policy.md](rto_rpo_policy.md)
