#!/usr/bin/env bash
set -euo pipefail

action="${1:-}"
mpd_host="${MPD_HOST:-127.0.0.1}"
mpd_port="${MPD_PORT:-6600}"

mpc_cmd() {
  mpc -h "$mpd_host" -p "$mpd_port" "$@"
}

mpd_available() {
  mpc_cmd status >/dev/null 2>&1
}

queue_has_tracks() {
  [[ -n "$(mpc_cmd playlist 2>/dev/null | awk 'NR == 1 { print; exit }')" ]]
}

status_state() {
  mpc_cmd status 2>/dev/null | awk '/^\[[a-z]+\]/ { gsub(/[\[\]]/, "", $1); print $1; exit }'
}

notify_queue_empty() {
  notify-send -u normal -t 2500 --hint=int:transient:1 "MPD QUEUE EMPTY" "Add tracks to the playlist before using media keys." >/dev/null 2>&1 || true
}

fallback_playerctl() {
  case "$action" in
    play-pause) playerctl play-pause >/dev/null 2>&1 || true ;;
    previous) playerctl previous >/dev/null 2>&1 || true ;;
    next) playerctl next >/dev/null 2>&1 || true ;;
  esac
}

control_mpd() {
  local state

  if ! queue_has_tracks; then
    notify_queue_empty
    return 0
  fi

  state="$(status_state || true)"
  case "$action" in
    play-pause)
      if [[ "$state" == "playing" || "$state" == "paused" ]]; then
        mpc_cmd -q toggle
      else
        mpc_cmd -q play
      fi
      ;;
    previous)
      if [[ "$state" == "playing" || "$state" == "paused" ]]; then
        mpc_cmd -q prev
      else
        mpc_cmd -q play
      fi
      ;;
    next)
      if [[ "$state" == "playing" || "$state" == "paused" ]]; then
        mpc_cmd -q next
      else
        mpc_cmd -q play
      fi
      ;;
    *)
      printf 'Usage: %s {play-pause|previous|next}\n' "${0##*/}" >&2
      exit 2
      ;;
  esac
}

case "$action" in
  play-pause|previous|next)
    if mpd_available; then
      control_mpd
    else
      fallback_playerctl
    fi
    ;;
  *)
    printf 'Usage: %s {play-pause|previous|next}\n' "${0##*/}" >&2
    exit 2
    ;;
esac
