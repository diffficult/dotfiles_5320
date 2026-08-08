#!/usr/bin/env bash
# Switch Hyprland workspace via Lua config manager API.
# Usage: hypr-workspace.sh <id|name|r+1|r-1|previous|...>
set -euo pipefail

target=${1:-}
if [[ -z "$target" ]]; then
  echo "usage: $0 <workspace>" >&2
  exit 2
fi

if [[ "$target" =~ ^[0-9]+$ ]]; then
  expr="hl.dispatch(hl.dsp.focus({ workspace = ${target} }))"
else
  # Escape backslashes and double quotes for Lua string literal.
  safe=${target//\\/\\\\}
  safe=${safe//\"/\\\"}
  expr="hl.dispatch(hl.dsp.focus({ workspace = \"${safe}\" }))"
fi

exec hyprctl eval "$expr"
