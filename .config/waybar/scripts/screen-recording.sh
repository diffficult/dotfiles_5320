#!/bin/bash

if pgrep -f "^gpu-screen-recorder" >/dev/null; then
  icons=("󰑊" "󰻂" "󰻃")
  icon_index=$(( $(date +%s) % ${#icons[@]} ))

  printf '{"text": "%s", "tooltip": "Click to stop screen recording", "class": "active"}\n' "${icons[$icon_index]}"
else
  echo '{"text": "<span size=\"140%\"></span> ", "tooltip": "Click to start screen recording"}'
fi
