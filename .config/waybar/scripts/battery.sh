#!/usr/bin/env bash
# Waybar Battery Module - Nerd Font icons with charge state and ETA

BAT_DIR="/sys/class/power_supply/BAT0"

if [[ ! -d "$BAT_DIR" ]]; then
    echo '{"text":"󰂎 N/A","tooltip":"No battery found","class":"critical"}'
    exit 0
fi

STATUS="$(cat "$BAT_DIR/status" 2>/dev/null || echo "Unknown")"
CAPACITY="$(cat "$BAT_DIR/capacity" 2>/dev/null || echo 0)"
CHARGE_NOW="$(cat "$BAT_DIR/charge_now" 2>/dev/null || echo 0)"
CHARGE_FULL="$(cat "$BAT_DIR/charge_full" 2>/dev/null || echo 0)"
CURRENT="$(cat "$BAT_DIR/current_now" 2>/dev/null || echo 0)"

# Absolute current draw (µA); negative while discharging on some kernels
CURRENT="${CURRENT#-}"

# Horizontal FontAwesome battery icons (verified against installed Nerd Font)
ICON_FULL=" "              # U+F240 fa-battery_full
ICON_THREE_QUARTERS=" "    # U+F241 fa-battery_three_quarters
ICON_HALF=" "              # U+F242 fa-battery_half
ICON_QUARTER=" "           # U+F243 fa-battery_quarter
ICON_EMPTY=" "             # U+F244 fa-battery_empty
ICON_PLUG=" "              # U+F1E6 fa-plug

pick_icon() {
    local cap=$1
    if (( cap >= 97 )); then
        echo "$ICON_FULL"
    elif (( cap >= 75 )); then
        echo "$ICON_THREE_QUARTERS"
    elif (( cap >= 50 )); then
        echo "$ICON_HALF"
    elif (( cap >= 25 )); then
        echo "$ICON_QUARTER"
    else
        echo "$ICON_EMPTY"
    fi
}

format_duration() {
    local minutes=$1
    if (( minutes < 0 )); then
        echo "calculating…"
    elif (( minutes >= 60 )); then
        printf "%dh %02dm" $((minutes / 60)) $((minutes % 60))
    else
        printf "%dm" "$minutes"
    fi
}

CLASS=""
if [[ "$STATUS" == "Charging" ]]; then
    ICON="$(pick_icon "$CAPACITY")"
    CLASS="charging"
    if (( CURRENT > 0 && CHARGE_FULL > 0 )); then
        REMAIN=$(( (CHARGE_FULL - CHARGE_NOW) * 60 / CURRENT ))
        ETA="$(format_duration "$REMAIN")"
    else
        ETA="calculating…"
    fi
elif [[ "$STATUS" == "Full" ]]; then
    ICON="$ICON_FULL"
    ETA="Fully charged"
elif [[ "$STATUS" == "Discharging" ]]; then
    ICON="$(pick_icon "$CAPACITY")"
    if (( CURRENT > 0 && CHARGE_NOW > 0 )); then
        REMAIN=$(( CHARGE_NOW * 60 / CURRENT ))
        ETA="$(format_duration "$REMAIN")"
    else
        ETA="calculating…"
    fi
else
    ICON="$ICON_PLUG"
    ETA="Battery status unknown"
fi

if [[ "$STATUS" != "Charging" ]]; then
    if (( CAPACITY > 80 )); then
        CLASS=""
    elif (( CAPACITY > 65 )); then
        CLASS="green"
    elif (( CAPACITY > 45 )); then
        CLASS="yellow"
    elif (( CAPACITY > 35 )); then
        CLASS="orange"
    else
        CLASS="red"
    fi
fi

# Power draw in watts: current (µA) * voltage (µV) / 1e12
VOLTAGE="$(cat "$BAT_DIR/voltage_now" 2>/dev/null || echo 0)"
POWER=""
if (( CURRENT > 0 && VOLTAGE > 0 )); then
    POWER=$(awk -v i="$CURRENT" -v v="$VOLTAGE" 'BEGIN {printf "%.1f", i * v / 1e12}')
fi

TOOLTIP="${ICON_FULL} Battery: ${CAPACITY}% ($STATUS)\n"
TOOLTIP+="${ICON_PLUG} Time: ${ETA}\n"
if [[ -n "$POWER" ]]; then
    TOOLTIP+="⚡ Power: ${POWER} W"
fi

echo "{\"text\":\"${ICON} <span font_desc='SF Compact Rounded Bold 12'>${CAPACITY}%</span>\",\"tooltip\":\"${TOOLTIP}\",\"class\":\"${CLASS}\"}"
