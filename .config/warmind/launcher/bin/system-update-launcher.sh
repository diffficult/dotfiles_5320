#!/usr/bin/env bash
set -euo pipefail

WINDOW_TITLE="Warmind System Update"
APP_ID="footclient-float"

if ! command -v footclient >/dev/null 2>&1; then
  notify-send "Warmind Launcher" "footclient is not installed" || true
  exit 1
fi

calc_window_size() {
  local default_w=1100
  local default_h=820
  local min_w=980
  local min_h=720
  local max_w=1500
  local max_h=1100
  local aw_json aw_w aw_h out_w out_h

  if ! command -v hyprctl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    printf '%sx%s\n' "$default_w" "$default_h"
    return
  fi

  aw_json="$(hyprctl activewindow -j 2>/dev/null || true)"
  aw_w="$(printf '%s' "$aw_json" | jq -r '.size[0] // empty' 2>/dev/null || true)"
  aw_h="$(printf '%s' "$aw_json" | jq -r '.size[1] // empty' 2>/dev/null || true)"

  if [[ ! "$aw_w" =~ ^[0-9]+$ ]] || [[ ! "$aw_h" =~ ^[0-9]+$ ]]; then
    printf '%sx%s\n' "$default_w" "$default_h"
    return
  fi

  out_w=$(( aw_w * 78 / 100 ))
  out_h=$(( aw_h * 82 / 100 ))
  (( out_w < min_w )) && out_w=$min_w
  (( out_h < min_h )) && out_h=$min_h
  (( out_w > max_w )) && out_w=$max_w
  (( out_h > max_h )) && out_h=$max_h

  printf '%sx%s\n' "$out_w" "$out_h"
}

WINDOW_SIZE="$(calc_window_size)"

exec footclient \
  --app-id="$APP_ID" \
  --title="$WINDOW_TITLE" \
  --window-size-pixels="$WINDOW_SIZE" \
  --working-directory="$HOME" \
  -e sh -c 'yay; echo; echo Update complete. Press Enter to close; read; rm -f ~/.cache/waybar/pacman_updates.cache'
