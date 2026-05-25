#!/usr/bin/env bash
#
# Day 5: Restore a pg_dump custom-format (.dump) backup and verify row counts.
#
# Usage:
#   ./scripts/restore.sh backups/backup_20260525_112322.dump
#   ./scripts/restore.sh --latest
#   ./scripts/restore.sh --latest --simulate-disaster   # drop tables first (lab only)
#
# WARNING: --clean drops existing objects in the target database before restore.
#          Only use on lab databases (Neon dev project), never production without approval.
#
set -euo pipefail

# Expected row counts from create_sample_db.py
EXPECTED_CUSTOMERS=10000
EXPECTED_PRODUCTS=1000
EXPECTED_ORDERS=50000
EXPECTED_ORDER_ITEMS=100000

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=lib/env.sh
source "${SCRIPT_DIR}/lib/env.sh"
load_project_env "${PROJECT_ROOT}"

ADMIN_DATABASE_URL="$(database_url_for_admin)"

LOG_DIR="./logs"
LOG_FILE="${LOG_DIR}/restore.log"
SIMULATE_DISASTER=false
BACKUP_FILE=""

mkdir -p "${LOG_DIR}"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "${LOG_FILE}"
}

usage() {
  echo "Usage: $0 <backup.dump> | --latest [--simulate-disaster]" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --latest)
      BACKUP_FILE="$(ls -t ./backups/backup_*.dump 2>/dev/null | head -1 || true)"
      if [[ -z "${BACKUP_FILE}" ]]; then
        echo "ERROR: No backups found in ./backups/" >&2
        exit 1
      fi
      shift
      ;;
    --simulate-disaster)
      SIMULATE_DISASTER=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      if [[ -n "${BACKUP_FILE}" ]]; then
        usage
      fi
      BACKUP_FILE="$1"
      shift
      ;;
  esac
done

[[ -n "${BACKUP_FILE}" ]] || usage
[[ -f "${BACKUP_FILE}" ]] || { echo "ERROR: Backup not found: ${BACKUP_FILE}" >&2; exit 1; }

get_counts() {
  psql "${ADMIN_DATABASE_URL}" -v ON_ERROR_STOP=1 -t -A <<'SQL'
SELECT 'customers', COUNT(*)::text FROM customers
UNION ALL SELECT 'products', COUNT(*)::text FROM products
UNION ALL SELECT 'orders', COUNT(*)::text FROM orders
UNION ALL SELECT 'order_items', COUNT(*)::text FROM order_items;
SQL
}

simulate_disaster() {
  log "SIMULATE DISASTER: dropping application tables..."
  psql "${ADMIN_DATABASE_URL}" -v ON_ERROR_STOP=1 <<'SQL'
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
SQL
}

verify_counts() {
  local line table count expected ok=true
  declare -A expected=(
    [customers]="${EXPECTED_CUSTOMERS}"
    [products]="${EXPECTED_PRODUCTS}"
    [orders]="${EXPECTED_ORDERS}"
    [order_items]="${EXPECTED_ORDER_ITEMS}"
  )

  log "Verifying row counts..."
  local counts
  counts="$(get_counts)" || {
    log "ERROR: Could not read row counts from database"
    return 1
  }

  while IFS='|' read -r table count; do
    table="$(echo "${table}" | xargs)"
    count="$(echo "${count}" | xargs)"
    expected="${expected[$table]:-?}"
    if [[ "${count}" == "${expected}" ]]; then
      log "  OK  ${table}: ${count}"
    else
      log "  FAIL ${table}: got ${count}, expected ${expected}"
      ok=false
    fi
  done <<< "${counts}"

  if [[ "${ok}" != true ]]; then
    echo "ERROR: Row count validation failed. See ${LOG_FILE}" >&2
    exit 1
  fi
}

log "Restore started from: ${BACKUP_FILE}"

if [[ "${SIMULATE_DISASTER}" == true ]]; then
  simulate_disaster
fi

log "Running pg_restore (--clean --if-exists)..."
# pg_restore may emit warnings (exit 1) on harmless issues; we validate via row counts.
set +e
pg_restore \
  --dbname="${ADMIN_DATABASE_URL}" \
  --clean \
  --if-exists \
  --no-owner \
  --no-acl \
  --verbose \
  "${BACKUP_FILE}" 2>&1 | tee -a "${LOG_FILE}"
restore_status=$?
set -e

if [[ ${restore_status} -gt 1 ]]; then
  log "ERROR: pg_restore failed with exit code ${restore_status}"
  exit "${restore_status}"
fi

verify_counts

log "Restore completed successfully."
echo ""
echo "Restore OK from: ${BACKUP_FILE}"
echo "Log:             ${LOG_FILE}"
