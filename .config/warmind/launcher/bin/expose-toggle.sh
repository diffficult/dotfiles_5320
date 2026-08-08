#!/usr/bin/env bash
set -euo pipefail

live_expose="$HOME/.config/warmind/modules/expose"
repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../../../.." && pwd)"
repo_expose="$repo_root/config/warmind/modules/expose"

pick_expose_path() {
  if [[ -d "$live_expose" ]]; then
    printf '%s\n' "$live_expose"
    return 0
  fi
  if [[ -d "$repo_expose" ]]; then
    printf '%s\n' "$repo_expose"
    return 0
  fi
  return 1
}

expose_path="$(pick_expose_path)" || {
  echo "warmind expose: expose config not found" >&2
  exit 1
}

if qs -c "$expose_path" ipc call expose toggle >/dev/null 2>&1; then
  exit 0
fi

if command -v uwsm >/dev/null 2>&1; then
  nohup uwsm app -- qs -n -d -c "$expose_path" >/tmp/warmind-expose.log 2>&1 &
else
  nohup qs -n -d -c "$expose_path" >/tmp/warmind-expose.log 2>&1 &
fi

for _ in $(seq 1 40); do
  if qs -c "$expose_path" ipc call expose toggle >/dev/null 2>&1; then
    exit 0
  fi
  sleep 0.1
done

echo "warmind expose: failed to reach expose IPC after start" >&2
exit 1
