#!/usr/bin/env bash
#
# Phase 2 Day 6: Tiered retention for local backup_*.dump files.
#
# Usage:
#   ./scripts/retention_policy.sh            # dry-run (default)
#   ./scripts/retention_policy.sh --execute  # delete files
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck source=lib/env.sh
source "${SCRIPT_DIR}/lib/env.sh"
load_project_env "${PROJECT_ROOT}"

BACKUP_DIR="${BACKUP_DIR:-./backups}"
DAILY_RETENTION="${DAILY_RETENTION:-7}"
WEEKLY_RETENTION="${WEEKLY_RETENTION:-4}"
MONTHLY_RETENTION="${MONTHLY_RETENTION:-3}"
EXECUTE=false

if [[ "${1:-}" == "--execute" ]]; then
  EXECUTE=true
elif [[ -n "${1:-}" ]]; then
  echo "Usage: $0 [--execute]" >&2
  exit 1
fi

mapfile -t ALL_FILES < <(find "${BACKUP_DIR}" -maxdepth 1 -name 'backup_*.dump' -type f 2>/dev/null | sort)
if [[ ${#ALL_FILES[@]} -eq 0 ]]; then
  echo "No backup files in ${BACKUP_DIR}"
  exit 0
fi

declare -A KEEP=()
TODAY="$(date +%Y%m%d)"

# --- Mark files to keep ------------------------------------------------------
for f in "${ALL_FILES[@]}"; do
  base="$(basename "${f}")"
  # backup_YYYYMMDD_HHMMSS.dump
  if [[ "${base}" =~ backup_([0-9]{8})_([0-9]{6})\.dump ]]; then
    file_date="${BASH_REMATCH[1]}"
  else
    continue
  fi

  # Daily: last N days
  days_old=$(( ( $(date -d "${TODAY}" +%s) - $(date -d "${file_date}" +%s) ) / 86400 ))
  if [[ ${days_old} -le ${DAILY_RETENTION} ]]; then
    KEEP["${f}"]=1
  fi
done

# Weekly: newest file per ISO week for last W weeks
declare -A WEEK_BEST=()
for f in "${ALL_FILES[@]}"; do
  base="$(basename "${f}")"
  [[ "${base}" =~ backup_([0-9]{8})_([0-9]{6})\.dump ]] || continue
  file_date="${BASH_REMATCH[1]}"
  week_key="$(date -d "${file_date}" +%G-W%V)"
  if [[ -z "${WEEK_BEST[$week_key]:-}" ]] || [[ "${f}" > "${WEEK_BEST[$week_key]}" ]]; then
    WEEK_BEST["${week_key}"]="${f}"
  fi
done
mapfile -t WEEK_KEYS < <(printf '%s\n' "${!WEEK_BEST[@]}" | sort -r)
for i in "${!WEEK_KEYS[@]}"; do
  [[ ${i} -lt ${WEEKLY_RETENTION} ]] || break
  KEEP["${WEEK_BEST[${WEEK_KEYS[$i]}]}"]=1
done

# Monthly: newest file per month for last M months
declare -A MONTH_BEST=()
for f in "${ALL_FILES[@]}"; do
  base="$(basename "${f}")"
  [[ "${base}" =~ backup_([0-9]{8})_([0-9]{6})\.dump ]] || continue
  file_date="${BASH_REMATCH[1]}"
  month_key="$(date -d "${file_date}" +%Y-%m)"
  if [[ -z "${MONTH_BEST[$month_key]:-}" ]] || [[ "${f}" > "${MONTH_BEST[$month_key]}" ]]; then
    MONTH_BEST["${month_key}"]="${f}"
  fi
done
mapfile -t MONTH_KEYS < <(printf '%s\n' "${!MONTH_BEST[@]}" | sort -r)
for i in "${!MONTH_KEYS[@]}"; do
  [[ ${i} -lt ${MONTHLY_RETENTION} ]] || break
  KEEP["${MONTH_BEST[${MONTH_KEYS[$i]}]}"]=1
done

# --- Delete or report --------------------------------------------------------
echo "Retention: daily=${DAILY_RETENTION}d weekly=${WEEKLY_RETENTION} monthly=${MONTHLY_RETENTION}"
echo "Mode: $([[ "${EXECUTE}" == true ]] && echo EXECUTE || echo DRY-RUN)"
echo ""

deleted=0
kept=0
for f in "${ALL_FILES[@]}"; do
  if [[ -n "${KEEP[$f]:-}" ]]; then
    echo "KEEP  $(basename "${f}")"
    kept=$((kept + 1))
  else
    echo "DELETE $(basename "${f}")"
    if [[ "${EXECUTE}" == true ]]; then
      rm -f "${f}"
      deleted=$((deleted + 1))
    fi
  fi
done

echo ""
echo "Summary: kept=${kept} $([[ "${EXECUTE}" == true ]] && echo "deleted=${deleted}")"
