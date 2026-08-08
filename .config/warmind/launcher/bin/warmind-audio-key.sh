#!/usr/bin/env bash
set -euo pipefail

action="${1:-}"
qs_config="${WARMIND_LAUNCHER_CONFIG:-$HOME/.config/warmind/launcher}"

osd() {
  qs -c "$qs_config" ipc call osd "$@" >/dev/null 2>&1 || true
}

volume_pct() {
  wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null \
    | awk '/Volume:/ { printf "%d", ($2 * 100) + 0.5 }'
}

source_volume_pct() {
  wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null \
    | awk '/Volume:/ { printf "%d", ($2 * 100) + 0.5 }'
}

default_node_name() {
  local branch="$1"
  wpctl status 2>/dev/null | awk -v want="$branch" '
    /^Audio$/ { sec="audio"; branch=""; next }
    /^[A-Z][a-zA-Z]+$/ { sec=""; branch=""; next }
    /^[[:space:]]*[├└]─[[:space:]]*Sinks:/ { branch="sink"; next }
    /^[[:space:]]*[├└]─[[:space:]]*Sources:/ { branch="source"; next }
    /^[[:space:]]*[├└]─/ { branch=""; next }
    sec=="audio" && branch==want && index($0,"*")>0 {
      line=$0;
      sub(/^[ │├─└*]+/, "", line);
      sub(/^[0-9]+\. /, "", line);
      sub(/[[:space:]]*\[.*$/, "", line);
      print line;
      exit;
    }'
}

json_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '%s' "$value"
}

muted() {
  grep -q '\[MUTED\]' <<<"$1"
}

case "$action" in
  raise)
    wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+
    pct="$(volume_pct || true)"
    sink="$(default_node_name sink || true)"
    sink="$(json_escape "${sink:-OUTPUT}")"
    osd flash "{\"kind\":\"volume\",\"label\":\"$sink\",\"value\":${pct:-0},\"max\":150,\"text\":\"${pct:-0}%\"}"
    ;;
  lower)
    wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
    pct="$(volume_pct || true)"
    sink="$(default_node_name sink || true)"
    sink="$(json_escape "${sink:-OUTPUT}")"
    osd flash "{\"kind\":\"volume\",\"label\":\"$sink\",\"value\":${pct:-0},\"max\":150,\"text\":\"${pct:-0}%\"}"
    ;;
  mute)
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    state="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true)"
    pct="$(awk '/Volume:/ { printf "%d", ($2 * 100) + 0.5 }' <<<"$state")"
    sink="$(default_node_name sink || true)"
    sink="$(json_escape "${sink:-OUTPUT}")"
    if muted "$state"; then
      osd flash "{\"kind\":\"volume\",\"label\":\"$sink\",\"value\":${pct:-0},\"max\":150,\"text\":\"MUTED\",\"muted\":true}"
    else
      osd flash "{\"kind\":\"volume\",\"label\":\"$sink\",\"value\":${pct:-0},\"max\":150,\"text\":\"${pct:-0}%\"}"
    fi
    ;;
  mic-mute)
    wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
    state="$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null || true)"
    pct="$(awk '/Volume:/ { printf "%d", ($2 * 100) + 0.5 }' <<<"$state")"
    source="$(default_node_name source || true)"
    source="$(json_escape "${source:-INPUT}")"
    if muted "$state"; then
      osd flash "{\"kind\":\"mic\",\"label\":\"$source\",\"value\":${pct:-0},\"max\":150,\"text\":\"MUTED\",\"muted\":true}"
    else
      osd flash "{\"kind\":\"mic\",\"label\":\"$source\",\"value\":${pct:-0},\"max\":150,\"text\":\"${pct:-0}%\"}"
    fi
    ;;
  *)
    printf 'Usage: %s {raise|lower|mute|mic-mute}\n' "${0##*/}" >&2
    exit 2
    ;;
esac
