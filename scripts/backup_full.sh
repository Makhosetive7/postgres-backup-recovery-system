#!/usr/bin/env bash
#
# Day 3: Full logical backup with pg_dump (custom format).
#
# Usage (from anywhere):
#   ./scripts/backup_full.sh
#
# Creates: backups/backup_YYYYMMDD_HHMMSS.dump
# Logs to: logs/backup.log
#
set -euo pipefail

# --- Locate project root and load .env --------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=lib/env.sh
source "${SCRIPT_DIR}/lib/env.sh"
load_project_env "${PROJECT_ROOT}"

ADMIN_DATABASE_URL="$(database_url_for_admin)"

BACKUP_DIR="${BACKUP_DIR:-./backups}"
LOG_DIR="./logs"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_FILE="${BACKUP_DIR}/backup_${TIMESTAMP}.dump"
LOG_FILE="${LOG_DIR}/backup.log"

mkdir -p "${BACKUP_DIR}" "${LOG_DIR}"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_FILE}"
}

log "Starting full backup → ${BACKUP_FILE}"

# -Fc  = custom archive format (compressed; use pg_restore to recover)
# --no-owner / --no-acl = avoid role permission issues when restoring elsewhere
pg_dump "${ADMIN_DATABASE_URL}" \
  --format=custom \
  --no-owner \
  --no-acl \
  --file="${BACKUP_FILE}"

# Smoke test: if the dump is corrupt, --list will fail
log "Validating dump (pg_restore --list)..."
pg_restore --list "${BACKUP_FILE}" > /dev/null

SIZE="$(du -h "${BACKUP_FILE}" | cut -f1)"
log "Backup OK: ${BACKUP_FILE} (${SIZE})"
echo ""
echo "Backup saved: ${BACKUP_FILE}"
echo "Size:         ${SIZE}"
echo "Log:          ${LOG_FILE}"
echo "Tip: ./scripts/retention_policy.sh --execute  (prune old local backups)"
