#!/env/bin/zsh
# ------------------------------ sql.sh -----------------------------------------

# Função para:
# - alterar a PASSWORD do usuário 'postgres'
# - criar novo USER com senha
# - criar novo DATABASE para esse usuário
# - criar novo SCHEMA para esse usuário
# --------------------------------------------------------------------------------------
sql_postgresql() {
  sudo -u postgres psql -v ON_ERROR_STOP=1 postgres <<-EOSQL
    -- Cria usuário se não existir
    DO \$\$
    BEGIN
      IF NOT EXISTS (
          SELECT FROM pg_catalog.pg_user WHERE usename = '${POSTGRES_USER}'
      ) THEN
          CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}';
      END IF;
    END
    \$\$;

    -- Cria o banco de dados se não existir
    SELECT 'CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER}'
    WHERE NOT EXISTS (
        SELECT FROM pg_database WHERE datname = '${POSTGRES_DB}'
    )\gexec
EOSQL

  # Cria schema (dentro do novo banco) e aplica grants
  sudo -u postgres psql -v ON_ERROR_STOP=1 "${POSTGRES_DB}" <<-EOSQL
    DO \$\$
    BEGIN
      IF NOT EXISTS (
          SELECT FROM pg_namespace WHERE nspname = '${POSTGRES_SCHEMA}'
      ) THEN
          CREATE SCHEMA ${POSTGRES_SCHEMA} AUTHORIZATION ${POSTGRES_USER};
      END IF;
    END
    \$\$;

    GRANT ALL ON SCHEMA ${POSTGRES_SCHEMA} TO ${POSTGRES_USER};
EOSQL

  # Altera senha do usuário postgres
  sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$1';"
}