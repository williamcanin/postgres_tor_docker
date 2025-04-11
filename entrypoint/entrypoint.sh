#!/env/bin/zsh
# ------------------------------ entrypoint.sh -----------------------------------------
set -e

INIT_FLAG="/var/lib/postgresql/.initialized"

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
  sudo /etc/init.d/postgresql start
  until pg_isready -U postgres; do
      echo "[+] Iniciando PostGreSQL..."
      sleep 1
  done
  echo "[+] PostGreSQL iniciado!"
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
if [ ! -f "$INIT_FLAG" ]; then
  echo "[+] Primeira inicialização detectada. Configurando sistema..."
  root_password "$PASSWORD"
  start_firewall
  start_postgresql
  sql_postgresql "$POSTGRES_PASSWORD"
  stop_postgresql
  postgresql_conf "$POSTGRESQL_VERSION"
  touch "$INIT_FLAG"
  echo "[+] Inicialização completa."
else
  echo "[+] Inicialização já foi feita anteriormente. Pulando etapa de setup."
fi


# Mantem o servidor rodando [NÃO REMOVER]:
# --------------------------------------------------------------------------------------
echo "[+] Container pronto."
exec sudo -u postgres /usr/lib/postgresql/$POSTGRESQL_VERSION/bin/postgres -D /etc/postgresql/$POSTGRESQL_VERSION/main
