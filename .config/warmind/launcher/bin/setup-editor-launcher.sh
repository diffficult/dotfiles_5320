#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 <window-title> <path>" >&2
  exit 1
fi

WINDOW_TITLE="$1"
TARGET_PATH="$2"
EDITOR_CMD="${EDITOR:-nano}"

if [[ -z "$EDITOR_CMD" ]]; then
  EDITOR_CMD="nano"
fi

# EDITOR is user-controlled shell syntax by convention (e.g. `code --wait`).
# Split it the same way a shell would, then append the target path as the
# final argv element.
eval "set -- $EDITOR_CMD"

exec "$(dirname "$0")/setup-terminal-launcher.sh" "$WINDOW_TITLE" "$@" "$TARGET_PATH"
