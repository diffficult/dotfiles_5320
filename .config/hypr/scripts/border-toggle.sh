#!/bin/bash
# Toggle border size between 0 and 1
CURRENT=$(hyprctl getoption general:border_size -j 2>/dev/null | jq -r '.int // 1')
if [ "$CURRENT" -eq 0 ]; then
    hyprctl keyword general:border_size 1
else
    hyprctl keyword general:border_size 0
fi
