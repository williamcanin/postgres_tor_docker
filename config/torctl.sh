#!/bin/bash

TOR_USER="debian-tor"
TOR_BIN="/usr/bin/tor"
TOR_PIDFILE="/run/tor/tor.pid"
TOR_DIR="/run/tor"
TORRC="/etc/tor/torrc"

check_run_dir() {
    mkdir -p "$TOR_DIR"
    chown "$TOR_USER:$TOR_USER" "$TOR_DIR"
    chmod 700 "$TOR_DIR"
}

tor_start() {
    if pgrep -u "$TOR_USER" tor >/dev/null; then
        echo "Tor is already running."
        return 0
    fi

    echo "Starting Tor..."
    check_run_dir
    sudo -u "$TOR_USER" "$TOR_BIN" -f "$TORRC" --runasdaemon 1

    sleep 1
    if pgrep -u "$TOR_USER" tor >/dev/null; then
        echo "Tor started successfully."
    else
        echo "[ERROR] Failed to start Tor."
    fi
}

tor_stop() {
    echo "Stopping Tor..."
    if [ -f "$TOR_PIDFILE" ]; then
        kill "$(cat $TOR_PIDFILE)" && echo "Tor: stopped!"
        rm -f "$TOR_PIDFILE"
    else
        pkill -u "$TOR_USER" tor && echo "Tor stopped (by pkill)."
    fi
}

tor_status() {
    if pgrep -u "$TOR_USER" tor >/dev/null; then
        echo "Tor (PID $(pgrep -u $TOR_USER tor)): running"
    else
        echo "Tor: stopped!"
    fi
}

tor_restart() {
    tor_stop
    sleep 1
    tor_start
}

test_tor() {
  echo "Testing connection through the Tor network..."
  response=$(curl --socks5-hostname 127.0.0.1:9050 -s https://check.torproject.org)

  if echo "$response" | grep -q "Congratulations. This browser is configured to use Tor"; then
    echo "Congratulations. This machine is configured to use Tor."
  else
    echo "This machine is NOT using the Tor network."
  fi
}

case "$1" in
    start)
        tor_start
        ;;
    stop)
        tor_stop
        ;;
    status)
        tor_status
        ;;
    restart)
        tor_restart
        ;;
    check)
        test_tor
    ;;
    *)
        echo "Usage: $0 {start|stop|status|restart|check}"
        exit 1
        ;;
esac
