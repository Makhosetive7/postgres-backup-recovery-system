# Recovery Quick Steps (Phase 1)

Lab database on Neon. **Do not run on production without change control.**

## Scenario: Full database loss (restore from latest dump)

1. Confirm latest backup exists and is valid:
   ```bash
   ls -lh backups/
   pg_restore --list backups/backup_LATEST.dump | head
   ```

2. Restore (replaces objects in target DB):
   ```bash
   ./scripts/restore.sh --latest
   ```

3. Verify row counts (script does this automatically):
   - customers: 10,000
   - products: 1,000
   - orders: 50,000
   - order_items: 100,000

4. Spot-check data:
   ```bash
   set -a && source .env && set +a
   psql "$DATABASE_URL" -c "SELECT COUNT(*) FROM orders;"
   ```

## Scenario: Practice disaster (drop tables, then restore)

```bash
./scripts/restore.sh --latest --simulate-disaster
```

## RPO reminder

Restore brings you back to **backup time**, not “five minutes ago.”  
Improve RPO by running `backup_full.sh` more often.

## RTO

Measure wall-clock time from start of `restore.sh` to “Restore OK” (network + ~160k rows).
