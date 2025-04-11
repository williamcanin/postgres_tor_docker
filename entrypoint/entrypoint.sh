#!/env/bin/zsh
# ------------------------------ entrypoint.sh -----------------------------------------
set -e

FLAG_FILE="/usr/local/entrypoint/.configured"
PGUSER="postgres"

# Carregando libs:
# --------------------------------------------------------------------------------------
source /usr/local/entrypoint/lib_message.sh
source /usr/local/entrypoint/lib_sql.sh
source /usr/local/entrypoint/lib_firewall.sh

# Função para alterar a senha de root:
# --------------------------------------------------------------------------------------
root_password() {
  echo "root:$1" | sudo chpasswd
}

# Função para iniciar o PostGreSQL:
# --------------------------------------------------------------------------------------
start_postgresql() {
  message "[+] Iniciando PostgreSQL..." "cyan"
  sudo /etc/init.d/postgresql start
  until pg_isready -U $PGUSER; do
      message "[+] Esperando PostGreSQL..." "cyan"
      sleep 1
  done
  message "[+] PostGreSQL iniciado!" "green"
}

stop_postgresql() {
  message "Parando o PostgreSQL com segurança..." "cyan"
  sudo /etc/init.d/postgresql stop
  sleep 1
  message "PostgreSQL parado com sucesso." "green"
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
  message "[+] Copiando nova configuração do PostGreSQL..." "cyan"
  sudo cp -f /opt/pg_hba.conf /etc/postgresql/$1/main/pg_hba.conf || true
  sudo cp -f /opt/postgresql.conf /etc/postgresql/$1/main/postgresql.conf || true
  sudo rm -f /opt/postgresql.conf /opt/pg_hba.conf
  message "[+] Configuração do PostGreSQL terminada!" "green"
}

# Função para iniciar o Tor:
# --------------------------------------------------------------------------------------
tor_start() {
  message "[+] Iniciando Tor..." "cyan"
  sudo /etc/init.d/torctl restart
  message "[+] Tor iniciado!" "green"
}

# Aplica as configurações:
# --------------------------------------------------------------------------------------
if [ ! -f "$FLAG_FILE" ]; then
    message "[+] Primeira inicialização detectada. Configurando sistema..." "cyan"
    root_password "$PASSWORD"
    start_firewall
    start_postgresql
    sql_postgresql
    stop_postgresql
    postgresql_conf "$POSTGRESQL_VERSION"
    sudo touch "$FLAG_FILE"
    message "[+] Configuração completa." "green"
else
    message "[+] Configuração já foi feita anteriormente. Pulando etapa de configuração." "yellow"
fi

tor_start
message "Todos os serviços iniciados." "green"
message "[+] Container pronto !!!" "green"

# Mantem o servidor rodando [NÃO REMOVER]:
# --------------------------------------------------------------------------------------
sleep 1
exec sudo -u $PGUSER /usr/lib/postgresql/$POSTGRESQL_VERSION/bin/postgres -D /etc/postgresql/$POSTGRESQL_VERSION/main
