#!/usr/bin/env bash
# Toggle the Warmind Launcher calendar popup from Waybar.
set -euo pipefail

exec qs -c /home/rx/.config/warmind/launcher ipc call calendar toggle
