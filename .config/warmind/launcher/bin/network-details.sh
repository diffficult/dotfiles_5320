#!/usr/bin/env bash
set -euo pipefail

INTERFACE=$(ip route | awk '/default/ {print $5; exit}')
if [[ -z "$INTERFACE" ]]; then
  printf 'NO ACTIVE NETWORK\n'
  exit 0
fi

if [[ "$INTERFACE" =~ ^(eth|enp|eno) ]]; then
  NETWORK_TYPE="ethernet"
elif [[ "$INTERFACE" =~ ^(wlan|wlp) ]]; then
  NETWORK_TYPE="wifi"
else
  NETWORK_TYPE="unknown"
fi

CONNECTION_NAME=$(nmcli -t -f NAME connection show --active 2>/dev/null | grep -v 'lo\|docker\|virbr\|br-' | head -1)
[[ -z "$CONNECTION_NAME" ]] && CONNECTION_NAME="$INTERFACE"

LINK_STATUS=$(ip link show "$INTERFACE" | awk '/state/ {print $9; exit}')
STATUS_TEXT=$([[ "$LINK_STATUS" == "UP" ]] && echo "Online" || echo "Link Down")

VPN_ACTIVE=false
if ip link show | grep -qE '(tun|tap|wg|ppp)'; then
  VPN_ACTIVE=true
fi

RX_BYTES=$(cat "/sys/class/net/$INTERFACE/statistics/rx_bytes" 2>/dev/null || echo 0)
TX_BYTES=$(cat "/sys/class/net/$INTERFACE/statistics/tx_bytes" 2>/dev/null || echo 0)
HISTORY_FILE="/tmp/omnimenu_network_details_history"
CURRENT_TIME=$(date +%s)
RX_RATE_HUMAN="0 B/s"
TX_RATE_HUMAN="0 B/s"

if [[ -f "$HISTORY_FILE" ]]; then
  read -r PREV_TIME PREV_RX PREV_TX < "$HISTORY_FILE" || true
  TIME_DIFF=$((CURRENT_TIME - ${PREV_TIME:-0}))
  if [[ $TIME_DIFF -gt 0 ]]; then
    RX_RATE=$(( (RX_BYTES - ${PREV_RX:-0}) / TIME_DIFF ))
    TX_RATE=$(( (TX_BYTES - ${PREV_TX:-0}) / TIME_DIFF ))
    (( RX_RATE < 0 )) && RX_RATE=0
    (( TX_RATE < 0 )) && TX_RATE=0
    RX_RATE_HUMAN=$(numfmt --to=iec-i --suffix=B/s "$RX_RATE" 2>/dev/null || echo "$RX_RATE B/s")
    TX_RATE_HUMAN=$(numfmt --to=iec-i --suffix=B/s "$TX_RATE" 2>/dev/null || echo "$TX_RATE B/s")
  fi
fi
printf '%s %s %s\n' "$CURRENT_TIME" "$RX_BYTES" "$TX_BYTES" > "$HISTORY_FILE"

IP_ADDR=$(ip addr show "$INTERFACE" | awk '/inet / {print $2}' | cut -d/ -f1 | head -1)
[[ -z "$IP_ADDR" ]] && IP_ADDR="No IP"

PUBLIC_IP_CACHE="/tmp/omnimenu_public_ip_cache"
CACHE_TIME=300
if [[ -f "$PUBLIC_IP_CACHE" ]]; then
  CACHE_AGE=$(( $(date +%s) - $(stat -c %Y "$PUBLIC_IP_CACHE" 2>/dev/null || echo 0) ))
  if [[ $CACHE_AGE -lt $CACHE_TIME ]]; then
    PUBLIC_IP=$(cat "$PUBLIC_IP_CACHE")
  else
    PUBLIC_IP=$(curl -s --max-time 3 icanhazip.com 2>/dev/null || echo "N/A")
    printf '%s\n' "$PUBLIC_IP" > "$PUBLIC_IP_CACHE"
  fi
else
  PUBLIC_IP=$(curl -s --max-time 3 icanhazip.com 2>/dev/null || echo "N/A")
  printf '%s\n' "$PUBLIC_IP" > "$PUBLIC_IP_CACHE"
fi

printf '%s - %s\n\n' "$CONNECTION_NAME" "$STATUS_TEXT"
printf 'Traffic\n'
printf '├─ Download: %s\n' "$RX_RATE_HUMAN"
printf '└─ Upload: %s\n\n' "$TX_RATE_HUMAN"
printf 'Local IP: %s\n' "$IP_ADDR"
printf 'Public IP: %s\n\n' "$PUBLIC_IP"
printf 'Connection Details\n'
printf '├─ Name: %s\n' "$CONNECTION_NAME"
printf '├─ Type: %s\n' "$NETWORK_TYPE"
printf '├─ Interface: %s\n' "$INTERFACE"
printf '└─ VPN: %s\n' "$([[ "$VPN_ACTIVE" == true ]] && echo Active || echo Inactive)"
