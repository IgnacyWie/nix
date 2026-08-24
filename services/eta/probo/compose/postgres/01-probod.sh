#!/bin/sh

set -eu

: "${PROBOD_PG_USERNAME:?}"
: "${PROBOD_PG_PASSWORD:?}"
: "${PROBOD_PG_DATABASE:?}"

psql \
  -v ON_ERROR_STOP=1 \
  -v app_user="$PROBOD_PG_USERNAME" \
  -v app_password="$PROBOD_PG_PASSWORD" \
  -v app_database="$PROBOD_PG_DATABASE" \
  -U "$POSTGRES_USER" <<'EOSQL'
SELECT format('CREATE USER %I', :'app_user') \gexec
SELECT format('ALTER USER %I WITH SUPERUSER PASSWORD %L', :'app_user', :'app_password') \gexec
SELECT format('CREATE DATABASE %I', :'app_database') \gexec
SELECT format('GRANT ALL PRIVILEGES ON DATABASE %I TO %I', :'app_database', :'app_user') \gexec
EOSQL

psql \
  -v ON_ERROR_STOP=1 \
  -v app_user="$PROBOD_PG_USERNAME" \
  -U "$POSTGRES_USER" \
  -d "$PROBOD_PG_DATABASE" <<'EOSQL'
SELECT format('ALTER SCHEMA public OWNER TO %I', :'app_user') \gexec
SELECT format('GRANT ALL ON SCHEMA public TO %I', :'app_user') \gexec
EOSQL
