#!/usr/bin/env bash
# Waybar CPU Module - Enhanced CPU monitor with detailed metrics
# Based on XFCE cpu.sh applet

# Check if sensors is available
if ! command -v sensors &>/dev/null; then
    echo '{"text":"N/A","tooltip":"lm-sensors not installed","class":"error"}'
    exit 0
fi

# Get CPU model name (single read, more efficient)
CPU_MODEL="$(awk -F': ' '/model name/{print $2; exit}' /proc/cpuinfo)"

# Get number of physical cores and threads
PHYSICAL_CORES="$(grep -E "^cpu cores" /proc/cpuinfo | head -1 | awk '{print $4}')"
THREADS="$(grep -c "^processor" /proc/cpuinfo)"

# Get CPU frequencies (in MHz) from /proc/cpuinfo - single awk call
mapfile -t CPU_FREQS < <(awk '/cpu MHz/{printf "%.0f\n", $4}' /proc/cpuinfo)

# Calculate average CPU frequency
TOTAL_FREQ=0
for freq in "${CPU_FREQS[@]}"; do
    ((TOTAL_FREQ += freq))
done
AVG_FREQ=$((TOTAL_FREQ / ${#CPU_FREQS[@]}))
AVG_FREQ_GHZ=$(awk -v freq="$AVG_FREQ" 'BEGIN {printf "%.2f", freq / 1000}')

# Get min/max frequencies from cpufreq
MIN_FREQ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_min_freq 2>/dev/null)
MAX_FREQ=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null)
if [[ -n "$MIN_FREQ" && -n "$MAX_FREQ" ]]; then
    MIN_FREQ_GHZ=$(awk -v freq="$MIN_FREQ" 'BEGIN {printf "%.2f", freq / 1000000}')
    MAX_FREQ_GHZ=$(awk -v freq="$MAX_FREQ" 'BEGIN {printf "%.2f", freq / 1000000}')
else
    MIN_FREQ_GHZ="N/A"
    MAX_FREQ_GHZ="N/A"
fi

# Get CPU governor
CPU_GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "N/A")

# Get CPU temperature - robust parsing for AMD Ryzen (Tctl)
CPU_TEMP=$(sensors 2>/dev/null | awk '/^Tctl:/ {print $2}' | tr -d '+°C' | head -1)
if [[ -z "$CPU_TEMP" ]]; then
    # Fallback to Tdie or other common temp sensors
    CPU_TEMP=$(sensors 2>/dev/null | awk '/^Tdie:/ {print $2}' | tr -d '+°C' | head -1)
fi
if [[ -z "$CPU_TEMP" ]]; then
    # Final fallback to Core 0
    CPU_TEMP=$(sensors 2>/dev/null | awk '/^Core 0:/ {print $3}' | tr -d '+°C' | head -1)
fi
[[ -z "$CPU_TEMP" ]] && CPU_TEMP="N/A"

# Get per-core temperatures (for AMD Ryzen with CCDs)
CORE_TEMPS=$(sensors 2>/dev/null | awk '/^Tccd[0-9]:/ {printf "%s: %s  ", $1, $2}' | sed 's/://g')

# Get CPU utilization - calculate from idle percentage
CPU_IDLE=$(top -bn1 | awk '/^%Cpu\(s\):/ {print $8}')
if [[ -n "$CPU_IDLE" ]]; then
    CPU_USAGE=$(awk -v idle="$CPU_IDLE" 'BEGIN {printf "%.1f", 100 - idle}')
else
    CPU_USAGE="N/A"
fi

# Mini CPU usage graph (last 8 readings)
HISTORY_FILE="/tmp/waybar_cpu_history"
echo "$CPU_USAGE" >> "$HISTORY_FILE"
# Keep only last 8 entries
tail -8 "$HISTORY_FILE" > "${HISTORY_FILE}.tmp" && mv "${HISTORY_FILE}.tmp" "$HISTORY_FILE"

# Generate mini bar graph using Unicode block characters
if [[ "$CPU_USAGE" != "N/A" ]]; then
    # Read last 8 CPU values
    mapfile -t CPU_HISTORY < "$HISTORY_FILE"
    GRAPH=""
    for val in "${CPU_HISTORY[@]}"; do
        # Convert percentage to bar height (0-7)
        height=$(awk -v v="$val" 'BEGIN {printf "%.0f", (v/100)*7}')
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
    done
    CPU_GRAPH=" $GRAPH"
else
    CPU_GRAPH=""
fi

# Get load average
LOAD_AVG=$(awk '{printf "%s %s %s", $1, $2, $3}' /proc/loadavg)

# Temperature-based color coding (Catppuccin Mocha)
# Green (Normal) -> Yellow (Warning) -> Red (Critical)
COLOR_NORMAL="#a6e3a1"  # Green
COLOR_WARNING="#f9e2af" # Yellow
COLOR_CRITICAL="#f38ba8" # Red
COLOR_UNKNOWN="#cdd6f4" # Text

if [[ "$CPU_TEMP" != "N/A" ]]; then
    TEMP_INT=$(printf "%.0f" "$CPU_TEMP")
    if [[ $TEMP_INT -ge 85 ]]; then
        TEMP_COLOR="$COLOR_CRITICAL"
        TEMP_CLASS="critical"
    elif [[ $TEMP_INT -ge 75 ]]; then
        TEMP_COLOR="$COLOR_WARNING"
        TEMP_CLASS="warning"
    else
        TEMP_COLOR="$COLOR_NORMAL"
        TEMP_CLASS="normal"
    fi
else
    TEMP_COLOR="$COLOR_UNKNOWN"
    TEMP_CLASS="unknown"
fi

# Emoji/Icon Selection
# EMOJI="🖥"
ICON="" # Nerd Font CPU icon

# Build display text with Pango markup for color
#DISPLAY_TEXT="<span color='${TEMP_COLOR}'>${ICON} ${CPU_TEMP}°C</span>"
DISPLAY_TEXT="<span font_desc='JetBrainsMono Nerd Font 14' color='${TEMP_COLOR}'>${ICON}</span> <span color='${TEMP_COLOR}'>${CPU_TEMP}°C${CPU_GRAPH}</span>"

# Build detailed tooltip
TOOLTIP="${ICON} ${CPU_MODEL}\n\n"
TOOLTIP+="⚙️ Hardware\n"
TOOLTIP+="├─ Cores/Threads: ${PHYSICAL_CORES}C / ${THREADS}T\n"
TOOLTIP+="├─ Frequency: ${AVG_FREQ_GHZ} GHz (avg)\n"
TOOLTIP+="├─ Range: ${MIN_FREQ_GHZ} - ${MAX_FREQ_GHZ} GHz\n"
TOOLTIP+="└─ Governor: ${CPU_GOVERNOR}\n\n"

TOOLTIP+="📊 Performance\n"
TOOLTIP+="├─ CPU Usage: ${CPU_USAGE}%\n"
TOOLTIP+="├─ Temperature: ${CPU_TEMP}°C\n"
if [[ -n "$CORE_TEMPS" ]]; then
    TOOLTIP+="├─ Core Temps: ${CORE_TEMPS}\n"
fi
TOOLTIP+="└─ Load Average: ${LOAD_AVG}\n\n"

TOOLTIP+="🖱️ Actions\n"
TOOLTIP+="└─ Click to open task manager"

# Output JSON for waybar
echo "{\"text\":\"${DISPLAY_TEXT}\",\"tooltip\":\"${TOOLTIP}\",\"class\":\"${TEMP_CLASS}\"}"
