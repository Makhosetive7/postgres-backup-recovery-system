# Phase 1: Setup & Core Scripts (Days 1–5)

Build a working backup and restore loop before automation. Each day has a **goal**, **concepts**, and **checklist**.

---

## Day 1 — Environment & first connection

**Goal:** Tools installed, project folders exist, you can run `psql` against your database.

**Concepts:**
- `DATABASE_URL` — one connection string for all tools
- Client vs server — `psql`/`pg_dump` on your machine connect to Neon over the internet (SSL required)
- Neon free scales to zero after ~5 min idle — first connect may take a few seconds to wake up
- Never commit `.env` — secrets stay local; `.env.example` is the template

**Checklist:**
- [ ] Neon account + project created at [neon.tech](https://neon.tech)
- [ ] Connection string in `.env` with `?sslmode=require`
- [ ] `backups/` and `logs/` directories exist
- [ ] Python venv created and `pip install -r requirements.txt` succeeded
- [ ] `psql "$DATABASE_URL" -c "SELECT version();"` works

---

## Day 2 — Sample schema & data

**Goal:** E-commerce tables with realistic row counts for meaningful backup tests.

**Concepts:**
- Logical backup captures **schema + data** as SQL or custom format
- Foreign keys matter on restore — order of operations is handled by `pg_restore`

**Checklist:**
- [ ] `scripts/create_sample_db.py` creates tables (customers, products, orders, order_items)
- [ ] Row counts logged (target: ~10k / 1k / 50k / 100k)
- [ ] You can query tables in `psql`

---

## Day 3 — Full backup script

**Goal:** Repeatable `backup_full.sh` that writes timestamped `.dump` files.

**Concepts:**
- `pg_dump -Fc` — custom compressed format (good for `pg_restore`)
- Exit codes — script must fail loudly if dump fails
- `BACKUP_DIR` from `.env`

**Checklist:**
- [ ] `./scripts/backup_full.sh` creates `backups/backup_YYYYMMDD_HHMMSS.dump`
- [ ] `pg_restore --list` on the file succeeds (integrity smoke test)

---

## Day 4 — WAL & PITR (theory + limits)

**Read:** [DAY_4_WAL_AND_PITR.md](DAY_4_WAL_AND_PITR.md) — then fill in `NOTES.md` at project root.

**Goal:** Understand what PITR requires and what Neon free tier actually allows.

**Concepts:**
- WAL — write-ahead log; needed for point-in-time recovery
- Full PITR needs `archive_mode`, base backup, and `recovery_target_time`
- Managed free tiers often = **logical backups only** — that's still valid for a portfolio

**Checklist:**
- [ ] Notes in `NOTES.md`: your actual RPO with daily `pg_dump` only
- [ ] Optional: document "PITR would need X" for interviews

---

## Day 5 — Restore script

**Runbook:** [../docs/recovery_quick_steps.md](../docs/recovery_quick_steps.md)

**Goal:** Restore a `.dump` into a database (same or new) and verify row counts.

**Concepts:**
- `pg_restore` vs `psql -f` — custom format uses `pg_restore`
- `--clean` / `--if-exists` — drop objects before recreate (dangerous on production!)
- Validation = compare counts or checksums after restore

**Checklist:**
- [ ] `./scripts/restore.sh backups/<file>.dump` completes
- [ ] Row counts match pre-backup baseline
- [ ] Recovery steps drafted in `docs/` (stub is fine)

---

## When Phase 1 is done

You can say: *"I take daily logical backups with pg_dump, store them locally, validate with pg_restore --list, and I've proven a full restore with row-count checks."*

Next: [PHASE_2_AUTOMATION.md](PHASE_2_AUTOMATION.md)
