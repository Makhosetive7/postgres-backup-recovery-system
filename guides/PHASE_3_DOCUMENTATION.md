# Phase 3: Documentation and Polish (Days 11–15)

**Prerequisite:** Phase 1 and Phase 2 complete; repo on GitHub.

---

## Day 11 — DR runbook

**Deliverable:** [docs/dr_runbook.md](../docs/dr_runbook.md)

Full recovery procedures, escalation, and validation steps.

---

## Day 12 — RTO / RPO policy

**Deliverable:** [docs/rto_rpo_policy.md](../docs/rto_rpo_policy.md)

Document targets and how this project meets them (honest about `pg_dump` limits).

---

## Day 13 — GitHub Pages

**Deliverable:** [docs/index.md](../docs/index.md) (site root)

1. Repo **Settings → Pages**
2. Source: **Deploy from a branch**
3. Branch: `main`, folder: `/docs`
4. Save — site URL: `https://makhosetive7.github.io/postgres-backup-recovery-system/`

---

## Day 14 — Alerts (optional)

- Use `monitoring/backup_health_check.py` in cron or a workflow step
- Add `SLACK_WEBHOOK_URL` or email in `.env` later if needed

---

## Day 15 — Final checklist

- [ ] DR runbook and RTO/RPO docs reviewed
- [ ] GitHub Pages live
- [ ] `DATABASE_URL` secret set; Daily Backup workflow green
- [ ] Weekly Validation workflow green
- [ ] README links to repo and Actions

---

## Phase 3 complete when

You can share in an interview:

- Public repo with Actions history
- Published DR documentation (GitHub Pages)
- Documented RPO/RTO and restore test evidence
