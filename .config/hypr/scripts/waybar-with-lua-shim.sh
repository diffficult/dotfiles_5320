#!/usr/bin/env bash
# Launch waybar with a tiny LD_PRELOAD shim that rewrites legacy Hyprland
# IPC dispatches (workspace N) into Lua-manager form:
#   hl.dsp.focus({ workspace = N })
#
# The .so is built on demand from hypr_dispatch_shim.c (not versioned).
set -euo pipefail

CONF="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
SRC="$CONF/lib/hypr_dispatch_shim.c"
SHIM="$CONF/lib/libhypr_dispatch_shim.so"

ensure_shim() {
  if [[ ! -f "$SRC" ]]; then
    echo "waybar-with-lua-shim: missing source $SRC" >&2
    return 1
  fi
  if [[ -f "$SHIM" && "$SHIM" -nt "$SRC" ]]; then
    return 0
  fi
  if ! command -v gcc >/dev/null 2>&1; then
    echo "waybar-with-lua-shim: gcc required to build $SHIM" >&2
    return 1
  fi
  mkdir -p "$(dirname "$SHIM")"
  gcc -shared -fPIC -O2 -o "$SHIM" "$SRC" -ldl
}

if ensure_shim; then
  export LD_PRELOAD="$SHIM${LD_PRELOAD:+:$LD_PRELOAD}"
fi

exec waybar "$@"
