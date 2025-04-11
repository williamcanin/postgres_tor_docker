#!/env/bin/zsh
# ------------------------------ entrypoint.sh -----------------------------------------
set -e

FLAG_FILE="/usr/local/entrypoint/.configured"
PGUSER="postgres"

# Carregando libs:
# --------------------------------------------------------------------------------------
source /usr/local/entrypoint/sql.sh
source /usr/local/entrypoint/firewall.sh

# Função para alterar a senha de root:
# --------------------------------------------------------------------------------------
root_password() {
  echo "root:$1" | sudo chpasswd
}

# Função para iniciar o PostGreSQL:
# --------------------------------------------------------------------------------------
start_postgresql() {
  echo "[+] Iniciando PostgreSQL..."
  sudo /etc/init.d/postgresql start
  until pg_isready -U $PGUSER; do
      echo "[+] Esperando PostGreSQL..."
      sleep 1
  done
  echo "[+] PostGreSQL iniciado!"
}

stop_postgresql() {
  echo "Parando o PostgreSQL com segurança..."
  sudo /etc/init.d/postgresql stop
  sleep 1
  echo "PostgreSQL parado com sucesso."
}

# # DEPRECATED
# stop_postgresql() {
#   echo "Parando o PostgreSQL com segurança..."

#   PGDATA="/var/lib/postgresql/data"  # ou o caminho real do seu diretório de dados

#   sudo -u "$PGUSER" /usr/lib/postgresql/$1/bin/pg_ctl stop -D "$PGDATA" -m fast

#   if [ $? -eq 0 ]; then
#     echo "PostgreSQL parado com sucesso."
#   else
#     echo "[ERROR] Falha ao parar o PostgreSQL."
#   fi
# }

# Função para aplicar nova .conf no PostGreSQL:
# --------------------------------------------------------------------------------------
postgresql_conf() {
  stop_postgresql
  echo "[+] Copiando nova configuração do PostGreSQL..."
  sudo cp -f /opt/pg_hba.conf /etc/postgresql/$1/main/pg_hba.conf || true
  sudo cp -f /opt/postgresql.conf /etc/postgresql/$1/main/postgresql.conf || true
  sudo rm -f /opt/postgresql.conf /opt/pg_hba.conf
  echo "[+] Configuração do PostGreSQL terminada!"
}

# Aplica as configurações:
# --------------------------------------------------------------------------------------
if [ ! -f "$FLAG_FILE" ]; then
    echo "[+] Primeira inicialização detectada. Configurando sistema..."
    root_password "$PASSWORD"
    start_firewall
    start_postgresql
    sql_postgresql
    postgresql_conf "$POSTGRESQL_VERSION"
    sudo touch "$INIT_FLAG"
    echo "[+] Configuração completa."
    sudo touch "$FLAG_FILE"
else
    echo "[+] Configuração já foi feita anteriormente. Pulando etapa de configuração."
fi

# Mantem o servidor rodando [NÃO REMOVER]:
# --------------------------------------------------------------------------------------
echo "Todos os serviços iniciados."
echo "[+] Container pronto."
sleep 1
exec sudo -u $PGUSER /usr/lib/postgresql/$POSTGRESQL_VERSION/bin/postgres -D /etc/postgresql/$POSTGRESQL_VERSION/main
