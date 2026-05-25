# PostgreSQL Backup and Recovery System

Automated logical backups, restore testing, and disaster recovery documentation for PostgreSQL. Built as a hands-on portfolio project covering backup strategy, validation, retention, and CI automation.

## Overview

This repository implements a complete backup workflow:

- Full logical backups with `pg_dump` (custom format)
- Restore with `pg_restore` and row-count verification
- Tiered local retention (7 daily, 4 weekly, 3 monthly)
- Scheduled GitHub Actions for backup and weekly validation
- Health checks for backup age and file size

The sample workload is an e-commerce schema (~161,000 rows) suitable for realistic backup and restore tests.

## Architecture

```
PostgreSQL (Neon)  -->  pg_dump / pg_restore (Bash)
        |
        v
Local backups/     -->  retention_policy.sh
        |
        v
GitHub Actions     -->  daily backup + weekly validation (artifacts)
        |
        v
docs/              -->  recovery procedures
```

**Stack:** PostgreSQL 16+, Neon (or any Postgres with a connection URL), Bash, Python 3.11+, GitHub Actions, `pg_dump` / `pg_restore`.

## Project structure

```
postgres-backup-recovery-system/
├── .github/workflows/
│   ├── daily_backup.yml
│   └── weekly_validation.yml
├── scripts/
│   ├── backup_full.sh
│   ├── restore.sh
│   ├── validate_backup.sh
│   ├── retention_policy.sh
│   ├── create_sample_db.py
│   └── lib/env.sh
├── monitoring/
│   └── backup_health_check.py
├── config/
│   └── retention_rules.conf
├── docs/
│   └── recovery_quick_steps.md
├── guides/
│   ├── PHASE_1_SETUP.md
│   ├── PHASE_2_AUTOMATION.md
│   └── DAY_4_WAL_AND_PITR.md
├── docker-compose.yml          # optional local Postgres
└── .env.example
```

## Quick start

### Prerequisites

- PostgreSQL client tools (`psql`, `pg_dump`, `pg_restore`)
- Python 3.11+
- A PostgreSQL database ([Neon](https://neon.tech) free tier works well)

### Setup

```bash
git clone https://github.com/Makhosetive7/postgres-backup-recovery-system.git
cd postgres-backup-recovery-system

python3 -m venv venv
./venv/bin/pip install -r requirements.txt

cp .env.example .env
# Edit .env: set DATABASE_URL (use single quotes if the URL contains &)
# Prefer a direct Neon host for pg_dump/pg_restore (not the pooler)

./venv/bin/python scripts/create_sample_db.py
./scripts/backup_full.sh
./scripts/validate_backup.sh --latest
```

### Restore test (lab database only)

```bash
./scripts/restore.sh --latest --simulate-disaster
```

## GitHub Actions

Add a repository secret:

| Name | Value |
|------|--------|
| `DATABASE_URL` | PostgreSQL connection string (direct host recommended) |

Workflows:

- **Daily Backup** — 01:00 UTC, uploads `.dump` artifact (7-day retention)
- **Weekly Validation** — Sunday 02:00 UTC, backup + integrity check + row counts

Trigger manually from the Actions tab before relying on the schedule.

## Implementation phases

| Phase | Guide | Topics |
|-------|--------|--------|
| 1 | [guides/PHASE_1_SETUP.md](guides/PHASE_1_SETUP.md) | Schema, backup, restore, WAL/PITR concepts |
| 2 | [guides/PHASE_2_AUTOMATION.md](guides/PHASE_2_AUTOMATION.md) | Retention, validation, CI, health checks |

## Sample schema

Four related tables: `customers` (10k), `products` (1k), `orders` (50k), `order_items` (100k). See [scripts/create_sample_db.py](scripts/create_sample_db.py).

## Recovery objectives

| Scenario | Approach | Notes |
|----------|----------|--------|
| Full database loss | Restore latest `.dump` | See [docs/recovery_quick_steps.md](docs/recovery_quick_steps.md) |
| Bad DELETE between backups | Earlier dump or provider PITR | `pg_dump` alone cannot rewind minutes |
| Backup verification | `pg_restore --list`, row counts | Automated weekly in CI |

Target RPO/RTO depend on backup frequency and restore testing; document your measured values after restore drills.

## Security

- Never commit `.env` or `.dump` files
- Store `DATABASE_URL` in GitHub Secrets for CI
- Use `--no-owner` and `--no-acl` for portable restores

## Monitoring

```bash
./venv/bin/python monitoring/backup_health_check.py
./scripts/retention_policy.sh              # dry-run
./scripts/retention_policy.sh --execute    # delete old local backups
```

Fails if the latest backup is older than 25 hours or smaller than 100 KB.

## Documentation

| Resource | Link |
|----------|------|
| DR runbook | [docs/dr_runbook.md](docs/dr_runbook.md) |
| RTO / RPO | [docs/rto_rpo_policy.md](docs/rto_rpo_policy.md) |
| GitHub Pages | Enable in repo Settings (branch `main`, folder `/docs`) — [docs/index.md](docs/index.md) |
| Implementation guides | [guides/](guides/) |

## License

MIT
