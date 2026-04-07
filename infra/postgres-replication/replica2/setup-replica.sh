#!/bin/bash
set -e

echo "Iniciando configuración de replica2..."

PGDATA="${PGDATA:-/var/lib/postgresql/data/pgdata}"
PRIMARY_HOST="${PRIMARY_HOST:-primary}"
PRIMARY_PORT="${PRIMARY_PORT:-5432}"
REPL_USER="${POSTGRES_USER:-admin}"
REPL_PASSWORD="${POSTGRES_PASSWORD:-admin123}"
REPLICA_NAME="replica2"

export PGPASSWORD="${REPL_PASSWORD}"

mkdir -p "${PGDATA}"
chown -R postgres:postgres /var/lib/postgresql/data

echo "Esperando a que el nodo primario esté disponible..."
until pg_isready -h "${PRIMARY_HOST}" -p "${PRIMARY_PORT}" -U "${REPL_USER}" -d postgres; do
  sleep 2
done

if [ ! -f "${PGDATA}/PG_VERSION" ]; then
  echo "No se encontró clúster previo. Creando réplica base para replica2..."
  rm -rf "${PGDATA:?}"/*

  gosu postgres pg_basebackup \
    -h "${PRIMARY_HOST}" \
    -p "${PRIMARY_PORT}" \
    -U "${REPL_USER}" \
    -D "${PGDATA}" \
    -Fp \
    -Xs \
    -P \
    -R

  cat >> "${PGDATA}/postgresql.auto.conf" <<EOF
primary_conninfo = 'host=${PRIMARY_HOST} port=${PRIMARY_PORT} user=${REPL_USER} password=${REPL_PASSWORD} application_name=${REPLICA_NAME}'
hot_standby = on
EOF
fi

chown -R postgres:postgres /var/lib/postgresql/data

echo "Arrancando replica2..."
exec gosu postgres postgres -D "${PGDATA}"