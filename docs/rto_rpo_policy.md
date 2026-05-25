# RTO and RPO Policy

**System:** postgres-backup-recovery-system (Neon + logical backups)  
**Policy owner:** Platform / DBA  
**Review cycle:** Quarterly

---

## Definitions

**RPO (Recovery Point Objective)** — Maximum acceptable data loss, measured in time.

**RTO (Recovery Time Objective)** — Maximum acceptable downtime to restore service.

---

## Approved targets (this project)

| Tier | RPO | RTO | Method |
|------|-----|-----|--------|
| Lab / portfolio | 24 hours | 2 hours | Daily `pg_dump` + `restore.sh` |
| Production (if extended) | 1 hour | 4 hours | Hourly dumps and tested runbook |

Current automation: **daily backup at 01:00 UTC** (GitHub Actions).

---

## How RPO is achieved

| Control | Implementation |
|---------|----------------|
| Scheduled backup | `.github/workflows/daily_backup.yml` |
| Integrity check | `pg_restore --list` in `backup_full.sh` |
| Off-site copy | GitHub Actions artifacts (7-day retention) |
| Local retention | `retention_policy.sh` — 7 daily, 4 weekly, 3 monthly |

**Effective RPO:** Up to 24 hours between successful scheduled backups. Failed runs extend RPO until the next success.

**Not covered by pg_dump alone:** Sub-hour point-in-time recovery. That requires WAL archiving or Neon provider restore features.

---

## How RTO is achieved

| Step | Typical duration (lab) |
|------|-------------------------|
| Locate backup | Minutes |
| Validate dump | Seconds |
| `pg_restore` over network | 1–2 minutes |
| Row-count verification | Seconds |
| Application cutover | Environment-specific |

**Measured RTO:** Record start/end of `restore.sh` during drills; update this document with real numbers.

---

## Validation requirements

| Frequency | Activity |
|-----------|----------|
| Every backup | `pg_restore --list` |
| Weekly | GitHub Actions: backup + row counts |
| Quarterly | Manual restore drill with log in `restore_test_history.md` |

---

## Escalation

1. Operator fails restore twice — escalate to senior DBA / platform.
2. No backup within 25 hours — `backup_health_check.py` fails; investigate Actions and Neon connectivity.
3. Data loss within RPO window — incident review; consider more frequent backups or provider PITR.

---

## Exceptions

Increasing RPO beyond 24 hours requires documented risk acceptance.  
Decreasing RPO below 24 hours requires more frequent backups or WAL-based PITR.
