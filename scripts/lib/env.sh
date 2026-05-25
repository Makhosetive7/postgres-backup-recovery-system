# Shared helpers for backup/restore scripts.
# Source from other scripts: source "$(dirname "$0")/lib/env.sh"

load_project_env() {
  local root="${1:?project root required}"
  cd "${root}"

  if [[ -f .env ]]; then
    set -a
    # shellcheck source=/dev/null
    source .env
    set +a
  fi

  if [[ -z "${DATABASE_URL:-}" ]]; then
    echo "ERROR: DATABASE_URL not set (use .env or export for CI)." >&2
    return 1
  fi
}

# Neon pooler URLs break pg_dump/pg_restore; use direct host when possible.
# Override with DATABASE_URL_DIRECT in .env if needed.
database_url_for_admin() {
  if [[ -n "${DATABASE_URL_DIRECT:-}" ]]; then
    echo "${DATABASE_URL_DIRECT}"
  else
    echo "${DATABASE_URL//-pooler/}"
  fi
}
