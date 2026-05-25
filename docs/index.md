# PostgreSQL Backup and Recovery

Operational documentation for the [postgres-backup-recovery-system](https://github.com/Makhosetive7/postgres-backup-recovery-system) project.

## Documentation

| Document | Description |
|----------|-------------|
| [DR Runbook](dr_runbook.md) | Step-by-step recovery procedures |
| [RTO / RPO Policy](rto_rpo_policy.md) | Recovery objectives and backup strategy |
| [Backup Schedule](backup_schedule.md) | Automation and retention |
| [Recovery Quick Steps](recovery_quick_steps.md) | Short reference for emergencies |
| [GitHub Setup](GITHUB_SETUP.md) | Publish repo and configure Actions |

## System summary

- **Database:** PostgreSQL on Neon
- **Backup:** `pg_dump` custom format (`.dump`), daily via GitHub Actions
- **Validation:** `pg_restore --list` on every backup; weekly row-count checks
- **Restore:** `restore.sh` with optional disaster simulation

## Repository

[github.com/Makhosetive7/postgres-backup-recovery-system](https://github.com/Makhosetive7/postgres-backup-recovery-system)
