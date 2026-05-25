#!/usr/bin/env bash
#
# Phase 2 Day 7: Validate a backup file (integrity + minimum size).
#
# Usage:
#   ./scripts/validate_backup.sh --latest
#   ./scripts/validate_backup.sh backups/backup_20260525_112322.dump
#
set -euo pipefail

MIN_SIZE_BYTES=102400  # 100 KB — empty/corrupt dumps are usually tiny

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BACKUP_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --latest)
      BACKUP_FILE="$(ls -t "${PROJECT_ROOT}"/backups/backup_*.dump 2>/dev/null | head -1 || true)"
      shift
      ;;
    -h|--help)
      echo "Usage: $0 --latest | <backup.dump>" >&2
      exit 0
      ;;
    *)
      BACKUP_FILE="$1"
      shift
      ;;
  esac
done

[[ -n "${BACKUP_FILE}" ]] || { echo "Usage: $0 --latest | <backup.dump>" >&2; exit 1; }
[[ -f "${BACKUP_FILE}" ]] || { echo "ERROR: Not found: ${BACKUP_FILE}" >&2; exit 1; }

size_bytes="$(stat -c%s "${BACKUP_FILE}")"
if [[ "${size_bytes}" -lt "${MIN_SIZE_BYTES}" ]]; then
  echo "ERROR: Backup too small (${size_bytes} bytes < ${MIN_SIZE_BYTES})" >&2
  exit 1
fi

echo "File: ${BACKUP_FILE}"
echo "Size: $(du -h "${BACKUP_FILE}" | cut -f1) (${size_bytes} bytes)"
echo "Running pg_restore --list..."
object_count="$(pg_restore --list "${BACKUP_FILE}" | wc -l)"
echo "Objects in archive: ${object_count}"
echo "VALIDATION OK"
