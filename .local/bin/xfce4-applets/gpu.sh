#!/usr/bin/env bash

# Portable directory
readonly DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Size used for the icons is 24x24 (16x16 is also ok for a smaller panel)
readonly ICON="${DIR}/icons/gpu.png"

# GPU values
readonly GPU_NAME="$(nvidia-smi -i 0 -q | grep " Product Name" | cut -c45-)"
readonly GPU_TEMP="$(nvidia-smi -q -d temperature | grep "GPU Current Temp" | cut -c45-46)"
readonly CUDA_VERSION="$(nvidia-smi -q -d performance | grep "CUDA Version" | cut -c45-)"
readonly DRIVER_VERSION="$(nvidia-smi -q -d performance | grep "Driver Version" | cut -c45-)"
readonly GPU_UTIL="$(nvidia-smi -q -d utilization | grep "Gpu" | cut -c38-42)"
readonly GPU_MEMORY="$(nvidia-smi -q -d utilization | grep "Memory" | cut -c45-46)"
readonly GPU_POWER="$(nvidia-smi -i 0 -q | grep " Power Draw" | cut -c45-)"
readonly GPU_FAN_SPEED="$(nvidia-smi -i 0 -q | grep "Fan Speed" | cut -c45-47)"

# Panel
if [[ $(file -b "${ICON}") =~ PNG|SVG ]]; then
  INFO="<img>${ICON}</img>"
  INFO+="<txt>"
else
  INFO="<txt>"
fi
#INFO+="${GPU_UTIL}"
INFO+=" $GPU_TEMP"°C" "
INFO+="</txt>"
    INFO+="<txtclick>gwe</txtclick>"

# Tooltip
MORE_INFO="<tool>"
MORE_INFO+="┌ ${GPU_NAME}\n"
MORE_INFO+="├─ GPU Load\t\t\t${GPU_UTIL}\n"
MORE_INFO+="├─ Temperature\t\t${GPU_TEMP}°C\n"
MORE_INFO+="├─ Memory Used\t\t${GPU_MEMORY}%\n"
MORE_INFO+="├─ Power Draw\t\t${GPU_POWER}\n"
MORE_INFO+="└─ Fan Speed\t\t${GPU_FAN_SPEED}%\n\n"

MORE_INFO+="┌ Drivers\n"
MORE_INFO+="├─ NVIDIA\t\t${DRIVER_VERSION}\n"
MORE_INFO+="└─ CUDA\t\t\t${CUDA_VERSION}"
MORE_INFO+="</tool>"

# Output panel
echo -e "${INFO}"

# Output hover menu
echo -e "${MORE_INFO}"