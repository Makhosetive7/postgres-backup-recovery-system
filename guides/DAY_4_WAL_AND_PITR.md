# Day 4: WAL, PITR, and What Your Project Actually Provides

**Goal:** Know the difference between *your* `pg_dump` backups and *true* point-in-time recovery — and explain it clearly in an interview.

No new scripts today. This is concepts + a short note you write in `NOTES.md`.

---

## 1. WAL in one paragraph

**WAL (Write-Ahead Log)** is Postgres’s journal of changes. Before Postgres applies a change to data files, it writes that change to WAL. If the server crashes, it replays WAL to catch up.

Think of it like:

- **Data files** = the textbook
- **WAL** = the notebook of every edit made today

Backups copy the textbook. **PITR** uses the notebook to replay edits *up to a specific moment*.

---

## 2. Three backup ideas (don’t mix them up)

| Type | Tool / mechanism | What you get | RPO (roughly) |
|------|------------------|--------------|---------------|
| **Logical full** | `pg_dump -Fc` (your Day 3 script) | Portable `.dump` file | Time since **last successful dump** |
| **Physical full** | `pg_basebackup` | Binary copy of data directory | Time since last base backup |
| **Continuous** | WAL archiving + base backup | Replay to a timestamp | Minutes / seconds |

**Your project (Phase 1):** logical full backups only → RPO = “how long since the last `backup_full.sh` run.”

If you run one backup per day at 01:00 UTC and fail at 23:00, you could lose **up to ~24 hours** of changes — unless you run dumps more often.

---

## 3. What is PITR?

**Point-in-Time Recovery (PITR)** = restore to an exact moment, e.g.:

> “Restore to 2026-05-25 10:47:00 — right before someone ran `DELETE FROM orders`.”

### What PITR needs (self-managed Postgres)

1. **Base backup** — a starting snapshot (`pg_basebackup` or filesystem snapshot).
2. **Archived WAL** — continuous copy of WAL segments (`archive_mode = on`, `archive_command`).
3. **Recovery config** — tell Postgres which WAL to replay and stop at `recovery_target_time`.

```text
[Base backup from Sunday]  +  [WAL segments Mon–Thu]  →  recover to Thursday 10:47
```

You do **not** get this from `pg_dump` alone. `pg_dump` is a snapshot at dump time, not a replay log.

---

## 4. What *your* `pg_dump` backups give you

From Day 3 you have files like:

```text
backups/backup_20260525_112322.dump  (1.7M)
```

| Question | Answer with pg_dump only |
|----------|---------------------------|
| Can you restore all four tables + data? | **Yes** (Day 5) |
| Can you restore to *between* two dumps? | **No** — only to dump time |
| RPO with daily backups | **Up to 24 hours** (or less if you run dumps more often) |
| RTO | Depends on restore time (network, DB size) — you’ll measure on Day 5 |

**Honest portfolio line:**

> “My system uses scheduled logical full backups with `pg_dump`. RPO is bounded by backup frequency. True sub-hour PITR would require WAL archiving and base backups, which managed Neon handles differently than a self-hosted Postgres VM.”

---

## 5. Neon free tier vs your backups

Two separate things:

| Source | Who runs it | What it is |
|--------|-------------|------------|
| **Neon built-in** | Neon platform | Short history / branch / restore features on their storage |
| **Your `pg_dump`** | You | `.dump` files you store (local, R2, GitHub Artifacts later) |

On **Neon Free** (check [Neon plans](https://neon.com/docs/introduction/plans) for current limits):

- Storage cap (~0.5 GB per project) — your ~1.7M dump compresses the DB; the live DB must fit Neon limits.
- **History / instant restore** on free is **limited** (short window, not the same as running your own WAL archive).
- You typically **cannot** SSH in and set `archive_command` like on a VPS.

So for **this project**, treat **your** disaster recovery story as:

1. Latest good `.dump` from `backup_full.sh`
2. Optional: more frequent dumps → better RPO
3. Neon’s console restore = separate safety net, not what you’re automating in GitHub Actions

---

## 6. Logical vs physical (interview cheat sheet)

**Logical (`pg_dump`):**

- Pros: portable, works over `DATABASE_URL`, easy on Neon
- Cons: slower on huge DBs; snapshot at one instant; no between-dump PITR

**Physical (`pg_basebackup` + WAL):**

- Pros: true PITR; faster restore at very large scale
- Cons: needs filesystem/access; awkward on serverless managed Postgres

For Neon + portfolio: **logical is the right choice.**

---

## 7. Scenarios mapped to your stack

| Scenario | Tool you use | PITR needed? |
|----------|--------------|--------------|
| Entire DB lost | Restore latest `.dump` | No |
| Bad migration wiped schema | Restore `.dump` or Neon branch if available | No |
| `DELETE` at 10:47, noticed at 11:00 | Need WAL PITR or Neon point restore | **Yes** for minute-level |
| Corrupt one table | Restore table from dump to temp schema, merge | Partial restore (Day 5+) |

---

## 8. Your exercise — fill in `NOTES.md`

Create or edit `NOTES.md` in the project root (gitignored) with **your** numbers:

```markdown
## Day 4 — RPO / RTO (my project)

**Backup method:** pg_dump -Fc, manual script backup_full.sh

**Backup frequency (planned):** daily at ___ UTC (Phase 2: GitHub Actions)

**Measured RPO (pg_dump only):** up to ___ hours between successful dumps

**Neon free built-in restore:** short window; I rely on my own .dump files for DR story

**True PITR would require:** base backup + archived WAL + recovery_target_time
(on Neon I would use ___ instead of self-hosted WAL)

**Interview sentence:**
"I take logical full backups with pg_dump, validate with pg_restore --list,
and my RPO is bounded by backup frequency. For minute-level recovery I'd need
WAL-based PITR or the provider's point-in-time restore."
```

---

## 9. Common interview questions

**Q: What is WAL?**  
A: The transaction log Postgres writes before applying changes; used for crash recovery and, when archived, for PITR.

**Q: Difference between full backup and PITR?**  
A: Full backup restores to backup time. PITR restores to any moment between base backup and last archived WAL.

**Q: Does pg_dump support PITR?**  
A: No. It’s a consistent snapshot at dump completion time.

**Q: How do you improve RPO without PITR?**  
A: Run `pg_dump` more often (hourly), or add WAL archiving if infrastructure allows.

**Q: How do you validate backups?**  
A: `pg_restore --list` after every dump; periodic full restore + row counts (Day 5).

---

## Day 4 checklist

- [ ] Read sections 1–7 above
- [ ] Fill in `NOTES.md` exercise (section 8)
- [ ] Say out loud the “Interview sentence” once without reading

**Next:** [PHASE_1_SETUP.md](PHASE_1_SETUP.md) Day 5 — `restore.sh` and prove row counts match.
