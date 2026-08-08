#!/usr/bin/env bash
set -euo pipefail

# Screen recording script for Hyprland
# Usage: screenrecord-menu.sh
# Uses wf-recorder for screen recording

RECORD_DIR="${HOME}/Videos/Recordings"
mkdir -p "$RECORD_DIR"

TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
FILENAME="${RECORD_DIR}/recording_${TIMESTAMP}.mp4"

# Check if already recording
if pgrep -x wf-recorder >/dev/null 2>&1; then
  notify-send -t 2000 "Recording stopped" "Saved to last file" -i video-x-generic
  pkill -x wf-recorder
  exit 0
fi

# Start recording with area selection
notify-send -t 2000 "Recording started" "Select area to record..." -i video-x-generic
wf-recorder -g "$(slurp)" -f "$FILENAME" &

# Wait a bit and notify
sleep 1
if pgrep -x wf-recorder >/dev/null 2>&1; then
  notify-send -t 3000 "Recording active" "Saving to: ${FILENAME}" -i video-x-generic
else
  notify-send -t 3000 "Recording failed" "Could not start wf-recorder" -i dialog-error
fi
