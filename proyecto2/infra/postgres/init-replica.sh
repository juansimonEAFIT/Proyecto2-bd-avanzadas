#!/usr/bin/env bash
set -euo pipefail

export PGPASSWORD="${REPLICATION_PASSWORD}"

if [ ! -s "${PGDATA}/PG_VERSION" ]; then
  echo "Initializing replica ${REPLICATION_NAME} ..."
  rm -rf "${PGDATA:?}"/*

  until pg_basebackup \
    -d "host=postgres-primary port=5432 user=${REPLICATION_USER} password=${REPLICATION_PASSWORD} application_name=${REPLICATION_NAME}" \
    -D "${PGDATA}" \
    -Fp \
    -Xs \
    -P \
    -R \
    -C \
    -S "${REPLICATION_SLOT}"; do
    echo "Primary is not ready yet or replication role is not available. Retrying in 3 seconds..."
    sleep 3
  done

  chown -R postgres:postgres "${PGDATA}"
  chmod 700 "${PGDATA}"
fi

exec docker-entrypoint.sh postgres \
  -c hot_standby=on \
  -c max_wal_senders=10 \
  -c max_replication_slots=10 \
  -c max_prepared_transactions=100