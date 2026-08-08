#!/usr/bin/env bash
# Waybar GPU Module - Enhanced NVIDIA GPU monitor
# Based on XFCE gpu.sh applet

# Check if nvidia-smi is available
if ! command -v nvidia-smi &>/dev/null; then
    echo '{"text":"N/A","tooltip":"NVIDIA driver not found","class":"error"}'
    exit 0
fi

# Single efficient query for all GPU metrics
GPU_METRICS="$(nvidia-smi --query-gpu=name,temperature.gpu,utilization.gpu,utilization.memory,power.draw,fan.speed,memory.used,memory.total,clocks.current.graphics,pstate --format=csv,noheader,nounits 2>/dev/null)"

if [[ -z "$GPU_METRICS" ]]; then
    echo '{"text":"Error","tooltip":"Failed to query GPU metrics","class":"error"}'
    exit 1
fi

# Parse metrics from single query
GPU_NAME="$(echo "$GPU_METRICS" | awk -F', ' '{print $1}')"
GPU_TEMP="$(echo "$GPU_METRICS" | awk -F', ' '{print $2}')"
GPU_UTIL="$(echo "$GPU_METRICS" | awk -F', ' '{print $3}')"
GPU_MEMORY="$(echo "$GPU_METRICS" | awk -F', ' '{print $4}')"
GPU_POWER="$(echo "$GPU_METRICS" | awk -F', ' '{print $5}')"
GPU_FAN_SPEED="$(echo "$GPU_METRICS" | awk -F', ' '{print $6}')"
GPU_MEM_USED="$(echo "$GPU_METRICS" | awk -F', ' '{print $7}')"
GPU_MEM_TOTAL="$(echo "$GPU_METRICS" | awk -F', ' '{print $8}')"
GPU_CLOCK="$(echo "$GPU_METRICS" | awk -F', ' '{print $9}')"
GPU_PSTATE="$(echo "$GPU_METRICS" | awk -F', ' '{print $10}')"

# Driver and CUDA version from nvidia-smi header
DRIVER_VERSION="$(nvidia-smi 2>/dev/null | awk '/NVIDIA-SMI/ {print $3}' || echo "N/A")"
CUDA_VERSION="$(nvidia-smi 2>/dev/null | awk '/CUDA Version/ {print $NF}' || echo "N/A")"

# Temperature-based color coding
COLOR_NORMAL="#cdd6f4"
COLOR_LOW="#a6da95"
COLOR_MODERATE="#fe640b"
COLOR_HIGH="#e64553"
COLOR_CRITICAL="#d20f39"

TEMP_INT=$(printf "%.0f" "$GPU_TEMP")
if [[ $TEMP_INT -ge 100 ]]; then
    TEMP_COLOR="$COLOR_CRITICAL"
    TEMP_CLASS="critical"
elif [[ $TEMP_INT -ge 90 ]]; then
    TEMP_COLOR="$COLOR_HIGH"
    TEMP_CLASS="high"
elif [[ $TEMP_INT -ge 80 ]]; then
    TEMP_COLOR="$COLOR_MODERATE"
    TEMP_CLASS="moderate"
elif [[ $TEMP_INT -ge 70 ]]; then
    TEMP_COLOR="$COLOR_LOW"
    TEMP_CLASS="low"
else
    TEMP_COLOR="$COLOR_NORMAL"
    TEMP_CLASS="normal"
fi

# Emoji/Icon Selection
# EMOJI="🎮"
ICON="󰢮" # Nerd Font GPU icon

# Build display text with Pango markup
DISPLAY_TEXT="<span font_desc='JetBrainsMono Nerd Font 16' color='${TEMP_COLOR}'>${ICON}</span>  <span font_desc='JetBrainsMono Nerd Font Bold 14' color='${TEMP_COLOR}'>${GPU_TEMP}°C</span>"

# Build detailed tooltip
TOOLTIP="${ICON} ${GPU_NAME}\n\n"
TOOLTIP+=" Performance\n"
TOOLTIP+="├─ GPU Load: ${GPU_UTIL}%\n"
TOOLTIP+="├─ Temperature: ${GPU_TEMP}°C\n"
TOOLTIP+="├─ Memory: ${GPU_MEM_USED}/${GPU_MEM_TOTAL} MB (${GPU_MEMORY}%)\n"
TOOLTIP+="├─ Power Draw: ${GPU_POWER} W\n"
TOOLTIP+="├─ Fan Speed: ${GPU_FAN_SPEED}%\n"
TOOLTIP+="├─ GPU Clock: ${GPU_CLOCK} MHz\n"
TOOLTIP+="└─ Power State: ${GPU_PSTATE}\n\n"

TOOLTIP+=" Drivers\n"
TOOLTIP+="├─ NVIDIA: ${DRIVER_VERSION}\n"
TOOLTIP+="└─ CUDA: ${CUDA_VERSION}\n\n"

TOOLTIP+="󰳽 Actions\n"
TOOLTIP+="└─ Click to open GPU settings"

# Output JSON for waybar
echo "{\"text\":\"${DISPLAY_TEXT}\",\"tooltip\":\"${TOOLTIP}\",\"class\":\"${TEMP_CLASS}\"}"
