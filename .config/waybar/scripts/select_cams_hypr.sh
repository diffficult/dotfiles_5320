#!/bin/bash

########################################
# CONFIG
########################################

TARGET_OUTPUT="DP-1"

REGION_WIDTH_PCT=40
REGION_HEIGHT_PCT=50

MARGIN_X=4
MARGIN_Y=4

MAX_FEEDS=4

MPV_OPTS="--no-keepaspect-window --video-aspect-override=16:9 --no-resume-playback --no-border"

RTSP_BASE="rtsp://admin:888888@192.168.3.30:554/cam/realmonitor?channel=%s&subtype=0"

CAM_PREFIX="Colegio Cam"

ROFI_CMD='rofi -dmenu -i -multi-select -kb-accept-alt "space" -kb-row-tab "" -ballot-selected-str "[x] " -ballot-unselected-str "[ ] "'

########################################
# TOGGLE: if cams are running, close them
########################################

active=$(hyprctl clients -j | jq -r '.[].title' | grep -c "^${CAM_PREFIX}")

HYPR="${HOME}/.config/warmind/launcher/bin/warmind-hypr"

if [ "$active" -gt 0 ]; then
    while hyprctl clients -j | jq -r '.[].title' | grep -q "^${CAM_PREFIX}"; do
        "$HYPR" close "title:^${CAM_PREFIX}" 2>/dev/null || true
        sleep 0.1
    done
    exit 0
fi

########################################
# FUNCTIONS
########################################

die() {
    echo "Error: $*" >&2
    exit 1
}

get_monitor_geom() {
    local mon="$1"
    local result
    result=$(hyprctl monitors -j | jq -r --arg m "$mon" \
        '.[] | select(.name==$m) | "\(.width) \(.height) \(.x) \(.y) \(.reserved[1])"')
    [ -n "$result" ] || die "Could not determine geometry for monitor $mon"
    echo "$result"
}

wait_for_window() {
    local title="$1"
    local i=0
    while [ $i -lt 75 ]; do
        hyprctl clients -j | jq -e --arg t "$title" \
            '.[] | select(.title==$t)' >/dev/null 2>&1 && return 0
        sleep 0.2
        i=$((i+1))
    done
    return 1
}

########################################
# STEP 1: CHOOSE FEEDS (ROFI MULTI-SELECT)
########################################

CAM_LIST=$(
    printf '%s\n' \
        "01" "02" "03" "04" "05" "06" "07" "08" \
        "09" "10" "11" "12" "13" "14" "15" "16"
)

# shellcheck disable=SC2086
selection=$(echo "$CAM_LIST" | eval $ROFI_CMD -p "Seleccionar cámaras") || exit 0

mapfile -t SEL_LINES <<< "$selection"

SELECTED_IDS=()
for line in "${SEL_LINES[@]}"; do
    cam_id=$(echo "$line" | awk '{print $1}')
    if [[ "$cam_id" =~ ^[0-9]{1,2}$ ]]; then
        printf -v cam_id "%02d" "$cam_id"
        SELECTED_IDS+=("$cam_id")
    fi
done

[ "${#SELECTED_IDS[@]}" -ge 1 ] || die "No cameras selected."

if [ "${#SELECTED_IDS[@]}" -gt "$MAX_FEEDS" ]; then
    SELECTED_IDS=("${SELECTED_IDS[@]:0:$MAX_FEEDS}")
fi

########################################
# STEP 2: CHOOSE CORNER (ROFI SINGLE-SELECT)
########################################

CORNER_MENU=$(
    printf '%s\n' \
        "󰧄 esquina superior izquierda" \
        "󰧆 esquina superior derecha" \
        "󰦸 esquina inferior izquierda" \
        "󰦺 esquina inferior derecha"
)

# shellcheck disable=SC2086
corner_sel=$(echo "$CORNER_MENU" | eval $ROFI_CMD -p "Ubicación") || exit 0

corner=""
case "$corner_sel" in
    "󰧄 esquina superior izquierda") corner="top-left" ;;
    "󰧆 esquina superior derecha")   corner="top-right" ;;
    "󰦸 esquina inferior izquierda") corner="bottom-left" ;;
    "󰦺 esquina inferior derecha")   corner="bottom-right" ;;
    *) die "Invalid corner selection." ;;
esac

########################################
# STEP 3: MONITOR GEOMETRY & REGION
########################################

read -r MON_W MON_H MON_X MON_Y RESERVED_TOP <<< "$(get_monitor_geom "$TARGET_OUTPUT")"

REGION_W=$(( MON_W * REGION_WIDTH_PCT / 100 ))
REGION_H=$(( MON_H * REGION_HEIGHT_PCT / 100 ))

case "$corner" in
    top-left)
        REGION_X=$(( MON_X + MARGIN_X ))
        REGION_Y=$(( MON_Y + RESERVED_TOP + MARGIN_Y ))
        ;;
    top-right)
        REGION_X=$(( MON_X + MON_W - REGION_W - MARGIN_X ))
        REGION_Y=$(( MON_Y + RESERVED_TOP + MARGIN_Y ))
        ;;
    bottom-left)
        REGION_X=$(( MON_X + MARGIN_X ))
        REGION_Y=$(( MON_Y + MON_H - REGION_H - MARGIN_Y ))
        ;;
    bottom-right)
        REGION_X=$(( MON_X + MON_W - REGION_W - MARGIN_X ))
        REGION_Y=$(( MON_Y + MON_H - REGION_H - MARGIN_Y ))
        ;;
    *)
        die "Unexpected corner value: $corner"
        ;;
esac

########################################
# STEP 4: PER-FEED WINDOW GRID
########################################

num_feeds=${#SELECTED_IDS[@]}

WIN_XS=()
WIN_YS=()
WIN_WS=()
WIN_HS=()

if [ "$num_feeds" -eq 1 ]; then
    WIN_WS[0]=$REGION_W
    WIN_HS[0]=$REGION_H
    WIN_XS[0]=$REGION_X
    WIN_YS[0]=$REGION_Y

elif [ "$num_feeds" -eq 2 ]; then
    half_w=$(( REGION_W / 2 ))

    WIN_WS=( "$half_w" "$half_w" )
    WIN_HS=( "$REGION_H" "$REGION_H" )
    WIN_XS=( "$REGION_X" $(( REGION_X + half_w )) )
    WIN_YS=( "$REGION_Y" "$REGION_Y" )

else
    half_w=$(( REGION_W / 2 ))
    half_h=$(( REGION_H / 2 ))

    WIN_WS=( "$half_w" "$half_w" "$half_w" "$half_w" )
    WIN_HS=( "$half_h" "$half_h" "$half_h" "$half_h" )
    WIN_XS=(
        "$REGION_X"
        $(( REGION_X + half_w ))
        "$REGION_X"
        $(( REGION_X + half_w ))
    )
    WIN_YS=(
        "$REGION_Y"
        "$REGION_Y"
        $(( REGION_Y + half_h ))
        $(( REGION_Y + half_h ))
    )
fi

########################################
# STEP 5: LAUNCH MPV AND POSITION WINDOWS
########################################

for i in "${!SELECTED_IDS[@]}"; do
    cam_id="${SELECTED_IDS[$i]}"
    url=$(printf "$RTSP_BASE" "$cam_id")
    title="${CAM_PREFIX} ${cam_id}"

    # shellcheck disable=SC2086
    mpv $MPV_OPTS --title="$title" "$url" &

    if wait_for_window "$title"; then
        X="${WIN_XS[$i]}"
        Y="${WIN_YS[$i]}"
        W="${WIN_WS[$i]}"
        H="${WIN_HS[$i]}"

        "$HYPR" place "${W}" "${H}" "${X}" "${Y}" "title:^(${title})$"
    fi
done

exit 0
