#!/usr/bin/env bash
# Rejoue de zéro le schéma Palabre sur un Postgres local, charge le jeu de
# test et lance les assertions SQL.
#
#   scripts/db_check.sh            # base « palabre_check » sur le socket local
#   PGURL=postgresql://... scripts/db_check.sh
#
# Sur un vrai projet Supabase, utiliser `supabase db reset` : le stub n'est
# alors pas nécessaire.

set -euo pipefail
cd "$(dirname "$0")/.."

DB="${PGDB:-palabre_check}"
PGURL="${PGURL:-}"

if [[ -n "$PGURL" ]]; then
  psql_admin() { psql "$PGURL" -v ON_ERROR_STOP=1 -q "$@"; }
  psql_db()    { psql "$PGURL" -v ON_ERROR_STOP=1 -q "$@"; }
elif [[ "$(id -u)" == "0" ]] && id postgres >/dev/null 2>&1; then
  psql_admin() { su postgres -c "psql -v ON_ERROR_STOP=1 -q $*"; }
  psql_db()    { su postgres -c "psql -v ON_ERROR_STOP=1 -q -d $DB $*"; }
else
  psql_admin() { psql -v ON_ERROR_STOP=1 -q "$@"; }
  psql_db()    { psql -v ON_ERROR_STOP=1 -q -d "$DB" "$@"; }
fi

if [[ -z "$PGURL" ]]; then
  echo "▸ base $DB : recréation"
  psql_admin -c "\"drop database if exists $DB\"" >/dev/null
  psql_admin -c "\"create database $DB\"" >/dev/null
fi

echo "▸ stub Supabase"
psql_db -f supabase/tests/stub_supabase.sql

for f in supabase/migrations/*.sql; do
  echo "▸ migration $(basename "$f")"
  psql_db -f "$f"
done

echo "▸ seed"
psql_db -f supabase/seed.sql

echo "▸ tests"
psql_db -f supabase/tests/schema_test.sql

echo "✓ schéma, seed et tests OK sur $DB"
