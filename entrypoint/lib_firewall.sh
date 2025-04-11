#!/env/bin/zsh
# ------------------------------ firewall.sh -----------------------------------------

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