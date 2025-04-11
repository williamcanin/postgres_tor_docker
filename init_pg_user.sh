#!/bin/bash

# Define valores padrão (altere como desejar)
PG_USER="${PG_USER:-defaultuser}"
PG_PASS="${PG_PASS:-defaultpass}"

# Cria o usuário no PostgreSQL
psql -v ON_ERROR_STOP=1 --username "postgres" <<-EOSQL
    DO \$\$
    BEGIN
        IF NOT EXISTS (
            SELECT FROM pg_catalog.pg_roles WHERE rolname = '${PG_USER}'
        ) THEN
            CREATE ROLE ${PG_USER} LOGIN PASSWORD '${PG_PASS}';
            ALTER ROLE ${PG_USER} CREATEDB;
        END IF;
    END
    \$\$;
EOSQL

echo "Usuário '${PG_USER}' criado ou já existia."
