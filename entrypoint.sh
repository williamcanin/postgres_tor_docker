#!/env/bin/zsh
# ------------------------------ entrypoint.sh -----------------------------------------
set -e

# Função para alterar a senha de root:
# --------------------------------------------------------------------------------------
root_password() {
  echo "root:$1" | sudo chpasswd
}

# Função para criar serviço de firewall (NFTables):
# --------------------------------------------------------------------------------------
start_firewall() {

  sudo tee /etc/init.d/nftables > /dev/null << 'EOF'
#!/bin/sh
### BEGIN INIT INFO
# Provides:          nftables
# Required-Start:    $network
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:
# Short-Description: Firewall usando nftables
### END INIT INFO

NFT="/usr/sbin/nft"
RULES="/etc/nftables.conf"

case "$1" in
  start)
    echo "Aplicando regras de firewall..."
    $NFT -f "$RULES"
    echo "Feito!"
    ;;
  stop)
    echo "Parado firewall..."
    $NFT flush ruleset
    echo "Firewall parado!"
    ;;
  restart)
    echo "Reaplicando regras de firewall..."
    $NFT flush ruleset
    $NFT -f "$RULES"
    echo "Feito!"
    ;;
  status)
    echo "Status das regras de firewall:"
    $NFT list ruleset
    ;;
  edit)
    vim +startinsert "$RULES"
    ;;
  *)
    echo "Uso: $0 {start|stop|restart|edit|status}"
    exit 1
esac

exit 0
EOF

  sudo chmod +x /etc/init.d/nftables
  sudo update-rc.d nftables defaults
  sudo /etc/init.d/nftables start
}

# Função para iniciar o PostGreSQL:
# --------------------------------------------------------------------------------------
start_postgresql() {
  sudo /etc/init.d/postgresql start
  until pg_isready -U postgres; do
      echo "[+] Iniciando PostGreSQL..."
      sleep 1
  done
  echo "[+] PostGreSQL iniciado!"
}

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

stop_postgresql() {
  echo "[+] Parando PostGreSQL..."
  sudo /etc/init.d/postgresql stop
  echo "PostGreSQL parado!"
}

# Função para aplicar nova .conf no PostGreSQL:
# --------------------------------------------------------------------------------------
postgresql_conf() {
  echo "[+] Copiando nova configuração do PostGreSQL..."
  sudo cp -f /opt/pg_hba.conf /etc/postgresql/$1/main/pg_hba.conf || true
  sudo cp -f /opt/postgresql.conf /etc/postgresql/$1/main/postgresql.conf || true
  sudo rm -f /opt/postgresql.conf /opt/pg_hba.conf
  echo "[+] Configuração do PostGreSQL terminada!"
}


# Iniciando as funções e ações das mesmas:
# --------------------------------------------------------------------------------------
root_password $PASSWORD
start_firewall
start_postgresql
sql_postgresql $POSTGRES_PASSWORD
stop_postgresql
postgresql_conf $POSTGRESQL_VERSION
start_postgresql


# Mantem o servidor rodando [NÃO REMOVER]:
# --------------------------------------------------------------------------------------
tail -f /dev/null




















# sudo -u postgres psql "user=postgres" <<- EOSQL
#   ALTER USER $POSTGRES_USER_DEFAULT WITH PASSWORD '${POSTGRES_PASSWORD}';
#   DO \$\$
#   BEGIN
#       IF NOT EXISTS (
#           SELECT FROM pg_catalog.pg_user WHERE usename = '${POSTGRES_USER}'
#       ) THEN
#           CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}';
#       END IF;
#   END
#   \$\$;
#   DO \$\$
#   BEGIN
#       IF NOT EXISTS (
#           SELECT FROM pg_catalog.pg_database WHERE datname = '${POSTGRES_USER}'
#       ) THEN
#           CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER};
#       END IF;
#   END
#   \$\$;
#   DO \$\$
#   BEGIN
#       IF NOT EXISTS (
#           SELECT FROM pg_catalog.pg_namespace WHERE nspname = '${POSTGRES_USER}'
#       ) THEN
#           CREATE SCHEMA ${POSTGRES_SCHEMA} AUTHORIZATION ${POSTGRES_USER};
#       END IF;
#   END
#   \$\$;
#   GRANT ALL ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_USER};
#   GRANT ALL ON SCHEMA ${POSTGRES_SCHEMA} TO ${POSTGRES_USER};
# EOSQL






# echo "[+] Criando novo usuário, database, schema e dando permissões..."
# sudo -u root psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER_DEFAULT" <<-EOSQL
#     ALTER USER $POSTGRES_USER_DEFAULT WITH PASSWORD '${POSTGRES_PASSWORD}';
#     DO \$\$
#     BEGIN
#         IF NOT EXISTS (
#             SELECT FROM pg_catalog.pg_user WHERE usename = '${POSTGRES_USER}'
#         ) THEN
#             CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}';
#         END IF;
#     END
#     \$\$;

#     DO \$\$
#     BEGIN
#         IF NOT EXISTS (
#             SELECT FROM pg_catalog.pg_database WHERE datname = '${POSTGRES_USER}'
#         ) THEN
#             CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER};
#         END IF;
#     END
#     \$\$;

#     DO \$\$
#     BEGIN
#         IF NOT EXISTS (
#             SELECT FROM pg_catalog.pg_namespace WHERE nspname = '${POSTGRES_USER}'
#         ) THEN
#             CREATE SCHEMA ${POSTGRES_SCHEMA} AUTHORIZATION ${POSTGRES_USER};
#         END IF;
#     END
#     \$\$;
#     GRANT ALL ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_USER};
#     GRANT ALL ON SCHEMA ${POSTGRES_SCHEMA} TO ${POSTGRES_USER};
# EOSQL
# echo "[+] Criando novo usuário, database, schema e dando permissões. DONE!"


# echo "[+] Copiando nova configuração do PostGreSQL..."
# sudo cp -f /opt/pg_hba.conf /etc/postgresql/15/main/pg_hba.conf || true
# sudo cp -f /opt/postgresql.conf /etc/postgresql/15/main/postgresql.conf || true
# sudo rm -f /opt/postgresql.conf /opt/pg_hba.conf
# echo "[+] Configuração do PostGreSQL terminada!"






# Executa o script de criação de usuário no PostgreSQL
# echo "Executando script para criar usuário do PostgreSQL..."
# sudo -u postgres bash /usr/local/bin/init_pg_user.sh




# # Espera o PostgreSQL estar pronto
# until pg_isready -U postgres; do
#     echo "Aguardando PostgreSQL estar pronto.."
#     sleep 2
# done

# # ------------------------ CRIANDO USER, DATABASE, SCHEMA NO POSTGRESQL ---------------------
# echo "[+] Configurando PostgreSQL (usuário, banco e schema)..."
# sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '${POSTGRES_PASSWORD}';" || true
# sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='${POSTGRES_USER}'" | grep -q 1 \
# || sudo -u postgres psql -c "CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}';"
# sudo -u postgres psql -tc "SELECT 1 FROM pg_database WHERE datname='${POSTGRES_DB}'" | grep -q 1 \
# || sudo -u postgres psql -c "CREATE DATABASE ${POSTGRES_DB} OWNER ${POSTGRES_USER};"
# sudo -u postgres psql -d "${POSTGRES_DB}" -tc "SELECT schema_name FROM information_schema.schemata WHERE schema_name = '${POSTGRES_SCHEMA}'" | grep -q "${POSTGRES_SCHEMA}" || \
#   sudo -u postgres psql -d "${POSTGRES_DB}" -c "CREATE SCHEMA ${POSTGRES_SCHEMA} AUTHORIZATION ${POSTGRES_USER};"
# sudo -u postgres psql -c "GRANT ALL ON SCHEMA ${POSTGRES_SCHEMA} TO ${POSTGRES_USER};" || true
# sudo -u postgres psql -c "GRANT ALL ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_USER};" || true
