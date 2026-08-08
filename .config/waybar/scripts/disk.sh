#!/usr/bin/env bash
# Waybar Disk Module - Enhanced disk usage monitor
# Shows /home free space with detailed tooltip for all mounted drives

# Get /home partition info
HOME_INFO=$(df -h /home 2>/dev/null | awk 'NR==2 {printf "%s|%s|%s|%s", $2, $3, $4, $5}')

if [[ -z "$HOME_INFO" ]]; then
    echo '{"text":"N/A","tooltip":"Failed to get disk info","class":"error"}'
    exit 1
fi

# Parse /home info
IFS='|' read -r HOME_TOTAL HOME_USED HOME_FREE HOME_PERCENT <<< "$HOME_INFO"

# Parse metrics from single query
HOME_PERCENT_NUM="${HOME_PERCENT%\%}"  # Remove % sign for comparison

# Calculate free percentage for display and logic
HOME_FREE_PERCENT=$((100 - HOME_PERCENT_NUM))

# Available space-based color coding
COLOR_NORMAL="#cdd6f4"
COLOR_LOW="#a6da95"
COLOR_MODERATE="#fe640b"
COLOR_CRITICAL="#d20f39"

if [[ $HOME_FREE_PERCENT -le 10 ]]; then
    DISK_COLOR="$COLOR_CRITICAL"
    DISK_CLASS="critical"
elif [[ $HOME_FREE_PERCENT -le 40 ]]; then
    DISK_COLOR="$COLOR_MODERATE"
    DISK_CLASS="moderate"
elif [[ $HOME_FREE_PERCENT -le 60 ]]; then
    DISK_COLOR="$COLOR_LOW"
    DISK_CLASS="low"
else
    DISK_COLOR="$COLOR_NORMAL"
    DISK_CLASS="normal"
fi

# Emoji/Icon Selection
# EMOJI="💾"
ICON="" # Nerd Font Disk icon

# Build display text with Pango markup
if [[ "$DISK_CLASS" == "critical" ]]; then
    DISPLAY_TEXT="<span background='#d20f39' foreground='#232634'><b><span font_desc='JetBrainsMono Nerd Font 12'>${ICON}</span>  <span font_desc='SF Compact Rounded Bold 12'>${HOME_FREE_PERCENT}%</span></b></span>"
else
    DISPLAY_TEXT="<span font_desc='JetBrainsMono Nerd Font 12' color='${DISK_COLOR}'>${ICON}</span>  <span font_desc='SF Compact Rounded Bold 12' color='${DISK_COLOR}'>${HOME_FREE_PERCENT}%</span>"
fi

# Build detailed tooltip
TOOLTIP="${ICON} Disk Usage Report\n\n"

# Get all mounted filesystems (excluding pseudo filesystems)
mapfile -t FILESYSTEMS < <(df -h -x tmpfs -x devtmpfs -x squashfs -x overlay 2>/dev/null | awk 'NR>1 {print $0}')

# Add root filesystem info
ROOT_INFO=$(df -h / 2>/dev/null | awk 'NR==2 {printf "%-15s %6s  %6s  %6s  %5s", $1, $2, $3, $4, $5}')
if [[ -n "$ROOT_INFO" ]]; then
    TOOLTIP+="󰿠 Root (/)\n"
    TOOLTIP+="└─ ${ROOT_INFO}\n\n"
fi

# Add /home filesystem info
HOME_FULL_INFO=$(df -h /home 2>/dev/null | awk 'NR==2 {printf "%-15s %6s  %6s  %6s  %5s", $1, $2, $3, $4, $5}')
if [[ -n "$HOME_FULL_INFO" ]]; then
    TOOLTIP+=" Home (/home)\n"
    TOOLTIP+="└─ ${HOME_FULL_INFO}\n\n"
fi

# Add other mounted drives (excluding /, /home, /boot, /boot/efi)
OTHER_MOUNTS=$(df -h -x tmpfs -x devtmpfs -x squashfs -x overlay 2>/dev/null | \
    awk 'NR>1 && $6!="/" && $6!="/home" && $6!="/boot" && $6!="/boot/efi" && $6!~/^\/run/ && $6!~/^\/dev/ && $6!~/^\/sys/ {
        printf "%-15s %6s  %6s  %6s  %5s  %s\n", $1, $2, $3, $4, $5, $6
    }')

if [[ -n "$OTHER_MOUNTS" ]]; then
    TOOLTIP+=" Other Mounts\n"
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        MOUNT_POINT=$(echo "$line" | awk '{print $NF}')
        MOUNT_INFO=$(echo "$line" | awk '{printf "%-15s %6s  %6s  %6s  %5s", $1, $2, $3, $4, $5}')
        TOOLTIP+="├─ ${MOUNT_POINT}\n"
        TOOLTIP+="│  └─ ${MOUNT_INFO}\n"
    done <<< "$OTHER_MOUNTS"
    TOOLTIP+="\n"
fi

# Add legend
TOOLTIP+="󰄨 Legend\n"
TOOLTIP+="└─ Device  Total  Used  Free  %Used\n\n"

TOOLTIP+="󰯂 Actions\n"
TOOLTIP+="└─ Click to open file manager"

# Output JSON for waybar
echo "{\"text\":\"${DISPLAY_TEXT}\",\"tooltip\":\"${TOOLTIP}\",\"class\":\"${DISK_CLASS}\"}"
