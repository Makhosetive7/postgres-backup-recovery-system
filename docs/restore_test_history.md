# Restore Test History

Record each restore drill or real recovery event.

---

## 2026-05-25 — Lab drill (Phase 1)

- **Backup file:** `backup_20260525_112322.dump`
- **Operator:** Local development
- **Method:** `restore.sh --latest --simulate-disaster`
- **Row counts OK:** Yes (10k / 1k / 50k / 100k)
- **Notes:** Validated full restore after DROP CASCADE on all tables.

---

## Template (copy for next entry)

```markdown
## YYYY-MM-DD — [Drill | Production incident]

- **Backup file:**
- **Operator:**
- **Start / end (RTO):**
- **Row counts OK:** yes / no
- **Notes:**
```
