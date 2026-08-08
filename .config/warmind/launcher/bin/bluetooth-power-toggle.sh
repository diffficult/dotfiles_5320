#!/usr/bin/env sh
set -eu

state="$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered:/{print $2; exit}')"

if [ "$state" = "yes" ]; then
    bluetoothctl power off
else
    rfkill unblock bluetooth >/dev/null 2>&1 || true
    sleep 1
    bluetoothctl power on >/dev/null 2>&1 || true
fi
