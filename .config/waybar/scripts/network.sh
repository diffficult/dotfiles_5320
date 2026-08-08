#!/usr/bin/env bash
# Waybar Network Module - Enhanced network monitor with usage graph
# Based on XFCE network.sh applet

# Get network interface (prefer wired over wireless)
INTERFACE=$(ip route | awk '/default/ {print $5}' | head -1)
if [[ -z "$INTERFACE" ]]; then
    echo '{"text":"No Network","tooltip":"No active network interface","class":"disconnected"}'
    exit 0
fi

# Get network type and name
if [[ "$INTERFACE" =~ ^(eth|enp|eno) ]]; then
    NETWORK_TYPE="ethernet"
    NETWORK_NAME="$INTERFACE"
elif [[ "$INTERFACE" =~ ^(wlan|wlp) ]]; then
    NETWORK_TYPE="wifi"
    NETWORK_NAME=$(iwgetid -r 2>/dev/null || echo "$INTERFACE")
else
    NETWORK_TYPE="unknown"
    NETWORK_NAME="$INTERFACE"
fi

# Check for VPN connection
VPN_ACTIVE=false
if ip link show | grep -qE "(tun|tap|wg|ppp)"; then
    VPN_ACTIVE=true
fi

# Determine status and color
if [[ "$VPN_ACTIVE" == true ]]; then
    STATUS_COLOR="#cba6f7"  # Magenta for VPN
    STATUS_TEXT="VPN"
elif [[ "$LINK_STATUS" == "UP" ]]; then
    # Check if we have internet connectivity
    if ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; then
        STATUS_COLOR="#acb0be"  # White for online
        STATUS_TEXT="Online"
    else
        STATUS_COLOR="#e64553"  # Red for no internet
        STATUS_TEXT="No Internet"
    fi
else
    STATUS_COLOR="#e64553"  # Red for link down
    STATUS_TEXT="Disconnected"
fi

ICON=" "

# Get current RX/TX bytes
RX_BYTES=$(cat /sys/class/net/"$INTERFACE"/statistics/rx_bytes 2>/dev/null || echo 0)
TX_BYTES=$(cat /sys/class/net/"$INTERFACE"/statistics/tx_bytes 2>/dev/null || echo 0)

# History file for network usage
HISTORY_FILE="/tmp/waybar_network_history"
CURRENT_TIME=$(date +%s)

# Read previous values if they exist
if [[ -f "$HISTORY_FILE" ]]; then
    PREV_DATA=$(cat "$HISTORY_FILE")
    PREV_TIME=$(echo "$PREV_DATA" | cut -d' ' -f1)
    PREV_RX=$(echo "$PREV_DATA" | cut -d' ' -f2)
    PREV_TX=$(echo "$PREV_DATA" | cut -d' ' -f3)

    # Calculate time difference and rates
    TIME_DIFF=$((CURRENT_TIME - PREV_TIME))
    if [[ $TIME_DIFF -gt 0 ]]; then
        RX_RATE=$(( (RX_BYTES - PREV_RX) / TIME_DIFF ))
        TX_RATE=$(( (TX_BYTES - PREV_TX) / TIME_DIFF ))

        # Convert to human readable
        RX_RATE_HUMAN=$(numfmt --to=iec-i --suffix=B/s "$RX_RATE" 2>/dev/null || echo "${RX_RATE} B/s")
        TX_RATE_HUMAN=$(numfmt --to=iec-i --suffix=B/s "$TX_RATE" 2>/dev/null || echo "${TX_RATE} B/s")
    else
        RX_RATE_HUMAN="0 B/s"
        TX_RATE_HUMAN="0 B/s"
    fi
else
    RX_RATE_HUMAN="0 B/s"
    TX_RATE_HUMAN="0 B/s"
fi

# Save current values for next run
echo "$CURRENT_TIME $RX_BYTES $TX_BYTES" > "$HISTORY_FILE"

# Network usage graph (track download rate history)
GRAPH_HISTORY_FILE="/tmp/waybar_network_graph"
echo "$RX_RATE" >> "$GRAPH_HISTORY_FILE"
tail -8 "$GRAPH_HISTORY_FILE" > "${GRAPH_HISTORY_FILE}.tmp" && mv "${GRAPH_HISTORY_FILE}.tmp" "$GRAPH_HISTORY_FILE"

# Generate mini bar graph
if [[ -f "$GRAPH_HISTORY_FILE" ]]; then
    # Find max value for scaling
    MAX_RATE=$(sort -n "$GRAPH_HISTORY_FILE" | tail -1)
    if [[ "$MAX_RATE" -gt 0 ]]; then
        GRAPH=""
        while read -r rate; do
            # Scale to 0-7 based on max rate
            height=$(awk -v v="$rate" -v max="$MAX_RATE" 'BEGIN {printf "%.0f", (v/max)*7}')
            case $height in
                0) GRAPH+="▁" ;;
                1) GRAPH+="▂" ;;
                2) GRAPH+="▃" ;;
                3) GRAPH+="▄" ;;
                4) GRAPH+="▅" ;;
                5) GRAPH+="▆" ;;
                6) GRAPH+="▇" ;;
                7) GRAPH+="█" ;;
            esac
        done < "$GRAPH_HISTORY_FILE"
        NETWORK_GRAPH=" $GRAPH"
    else
        NETWORK_GRAPH=""
    fi
else
    NETWORK_GRAPH=""
fi

# Get IP address and link status
IP_ADDR=$(ip addr show "$INTERFACE" | awk '/inet / {print $2}' | cut -d'/' -f1 | head -1)
[[ -z "$IP_ADDR" ]] && IP_ADDR="No IP"

# Get NetworkManager connection name
CONNECTION_NAME=$(nmcli -t -f NAME connection show --active | grep -v "lo\|docker\|virbr\|br-" | head -1)
[[ -z "$CONNECTION_NAME" ]] && CONNECTION_NAME="Unknown"

# Check link status
LINK_STATUS=$(ip link show "$INTERFACE" | awk '/state/ {print $9}')
if [[ "$LINK_STATUS" == "UP" ]]; then
    STATUS_COLOR="#89b4fa"  # Blue for online
    STATUS_TEXT="Online"
else
    STATUS_COLOR="#f38ba8"  # Red for link down
    STATUS_TEXT="Link Down"
fi

# Get public IP (cached for 5 minutes to avoid API spam)
PUBLIC_IP_CACHE="/tmp/waybar_public_ip_cache"
CACHE_TIME=300  # 5 minutes

if [[ -f "$PUBLIC_IP_CACHE" ]]; then
    CACHE_AGE=$(( $(date +%s) - $(stat -c %Y "$PUBLIC_IP_CACHE" 2>/dev/null || echo 0) ))
    if [[ $CACHE_AGE -lt $CACHE_TIME ]]; then
        PUBLIC_IP=$(cat "$PUBLIC_IP_CACHE")
    else
        PUBLIC_IP=$(curl -s --max-time 3 icanhazip.com 2>/dev/null || echo "N/A")
        echo "$PUBLIC_IP" > "$PUBLIC_IP_CACHE"
    fi
else
    PUBLIC_IP=$(curl -s --max-time 3 icanhazip.com 2>/dev/null || echo "N/A")
    echo "$PUBLIC_IP" > "$PUBLIC_IP_CACHE"
fi

# Build display text with only the icon
DISPLAY_TEXT="<span font_desc='JetBrainsMono Nerd Font 14' color='${STATUS_COLOR}'>${ICON}</span>"

# Build tooltip with network info
TOOLTIP="<span color='${STATUS_COLOR}'>${ICON} ${CONNECTION_NAME}</span> - <span color='${STATUS_COLOR}'>${STATUS_TEXT}</span>\n\n"
TOOLTIP+=" Traffic\n"
TOOLTIP+="├─ Download: ${RX_RATE_HUMAN}\n"
TOOLTIP+="└─ Upload: ${TX_RATE_HUMAN}\n\n"
TOOLTIP+=" Local IP: ${IP_ADDR}\n"
TOOLTIP+="󱦂 Public IP: ${PUBLIC_IP}\n\n"
TOOLTIP+="󰌘 Connection Details\n"
TOOLTIP+="├─ Name: ${CONNECTION_NAME}\n"
TOOLTIP+="├─ Type: ${NETWORK_TYPE}\n"
TOOLTIP+="├─ Interface: ${INTERFACE}\n"
if [[ "$VPN_ACTIVE" == true ]]; then
    TOOLTIP+="└─󰌆 VPN: Active\n\n"
else
    TOOLTIP+="└─󰷖 VPN: Inactive\n\n"
fi
TOOLTIP+="󰳽 Click to open network settings"

# Set class based on status
if [[ "$VPN_ACTIVE" == true ]]; then
    WAYBAR_CLASS="vpn"
elif [[ "$LINK_STATUS" == "UP" ]]; then
    if ping -c 1 -W 1 8.8.8.8 >/dev/null 2>&1; then
        WAYBAR_CLASS="${NETWORK_TYPE}"
    else
        WAYBAR_CLASS="no-internet"
    fi
else
    WAYBAR_CLASS="disconnected"
fi

# Output JSON for waybar
echo "{\"text\":\"${DISPLAY_TEXT}\",\"tooltip\":\"${TOOLTIP}\",\"class\":\"${WAYBAR_CLASS}\"}"
