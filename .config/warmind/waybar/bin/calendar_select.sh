#!/usr/bin/env bash
# Fast day selection: updates warmind-waybar calendar state.json via jq, no Python startup overhead
set -euo pipefail

DATE="$1"
CACHE_DIR="$HOME/.cache/quickshell/warmind/waybar/calendar"
STATE="$CACHE_DIR/state.json"
mkdir -p "$CACHE_DIR"
TMP="$(mktemp "${CACHE_DIR}/.select_XXXXXX.tmp")"

LABEL="$(date -d "$DATE" "+%A, %B %-d")"

jq --arg date "$DATE" --arg label "$LABEL" '
  .selected_day = $date |
  .selected_day_label = $label |
  .selected_events = (
    [ .weeks[][] | select(.date == $date) | .events // [] ] | first // []
  )
' "$STATE" > "$TMP" && mv "$TMP" "$STATE"
