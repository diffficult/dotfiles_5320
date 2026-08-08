#!/usr/bin/env bash
# Waybar Weather Module - OpenMeteo API
# Location: Mendoza, Argentina

# Configuration
readonly LAT="-32.8895"
readonly LON="-68.8458"
readonly LOCATION_NAME="Mendoza, Argentina"
readonly CACHE_DIR="${HOME}/.cache/waybar"
readonly CACHE_FILE="${CACHE_DIR}/weather_cache.json"
readonly CACHE_DURATION=21600  # 6 hours in seconds
readonly API_TIMEOUT=10

# Create cache directory
mkdir -p "$CACHE_DIR"

# Catppuccin Mocha Palette
readonly COLOR_CLEAR="#f9e2af"    # Yellow (Sun)
readonly COLOR_CLOUDY="#cdd6f4"   # Text/White (Cloud)
readonly COLOR_RAIN="#89b4fa"     # Blue (Rain)
readonly COLOR_SNOW="#94e2d5"     # Teal (Snow)
readonly COLOR_STORM="#eba0ac"    # Maroon (Storm)
readonly COLOR_NIGHT="#b4befe"    # Lavender (Night)
readonly COLOR_FOG="#a6adc8"      # Subtext0 (Fog)

# Nerd Font Weather Icons Configuration
# Paste your working Nerd Font symbols here
# Get symbols from: https://www.nerdfonts.com/cheat-sheet
readonly ICON_SUNNY="󰖙 "           # nf-md-weather_sunny (f0599)
readonly ICON_NIGHT="󰖔 "           # nf-md-weather_night (f0594)
readonly ICON_PARTLY_CLOUDY="󰖕 "   # nf-md-weather_partly_cloudy (f0595)
readonly ICON_NIGHT_PARTLY="󰼱 "    # nf-md-weather_night_partly_cloudy (f0f31)
readonly ICON_CLOUDY="󰖐 "          # nf-md-weather_cloudy (f0590)
readonly ICON_FOG="󰖑 "             # nf-md-weather_fog (f0591)
readonly ICON_DRIZZLE="󰼳 "         # nf-md-weather_partly_rainy (f0f33)
readonly ICON_RAINY="󰖗 "           # nf-md-weather_rainy (f0597)
readonly ICON_POURING="󰖖 "         # nf-md-weather_pouring (f0596)
readonly ICON_SNOWY="󰖘 "           # nf-md-weather_snowy (f0598)
readonly ICON_SNOWY_HEAVY="󰼶 "     # nf-md-weather_snowy_heavy (f0f36)
readonly ICON_LIGHTNING="󰖓 "       # nf-md-weather_lightning (f0593)
readonly ICON_LIGHTNING_RAINY="󰙾 " # nf-md-weather_lightning_rainy (f067e)

# WMO Weather code to Nerd Font icon and color mapping
# OpenMeteo uses WMO weather codes: https://open-meteo.com/en/docs
# Using Material Design Weather icons (nf-md-weather_*)
get_weather_icon_and_color() {
    local code="$1"
    local time_value="$2"
    local hour=""

    if [[ -n "$time_value" ]]; then
        if [[ "$time_value" == *T* ]]; then
            hour="${time_value##*T}"
        else
            hour="$time_value"
        fi
        hour="${hour%%:*}"
    else
        hour=$(date +%H)
    fi

    if [[ ! "$hour" =~ ^[0-9]{1,2}$ ]]; then
        hour=12
    fi
    hour=$((10#$hour))

    # Determine if it's night time (20:00 - 06:00)
    local is_night=0
    if (( hour >= 20 || hour <= 6 )); then
        is_night=1
    fi

    local icon=""
    local color=""

    # WMO Weather code mapping
    case "$code" in
        0) # Clear sky
            if (( is_night == 1 )); then
                icon="$ICON_NIGHT"
                color="$COLOR_NIGHT"
            else
                icon="$ICON_SUNNY"
                color="$COLOR_CLEAR"
            fi
            ;;
        1|2) # Mainly clear, partly cloudy
            if (( is_night == 1 )); then
                icon="$ICON_NIGHT_PARTLY"
                color="$COLOR_NIGHT"
            else
                icon="$ICON_PARTLY_CLOUDY"
                color="$COLOR_CLEAR"
            fi
            ;;
        3) # Overcast
            icon="$ICON_CLOUDY"
            color="$COLOR_CLOUDY"
            ;;
        45|48) # Fog
            icon="$ICON_FOG"
            color="$COLOR_FOG"
            ;;
        51|53|55|56|57) # Drizzle
            icon="$ICON_DRIZZLE"
            color="$COLOR_RAIN"
            ;;
        61|63|80|81) # Light to moderate rain
            icon="$ICON_RAINY"
            color="$COLOR_RAIN"
            ;;
        65|66|67|82) # Heavy rain
            icon="$ICON_POURING"
            color="$COLOR_RAIN"
            ;;
        71|73|85) # Light to moderate snow
            icon="$ICON_SNOWY"
            color="$COLOR_SNOW"
            ;;
        75|77|86) # Heavy snow
            icon="$ICON_SNOWY_HEAVY"
            color="$COLOR_SNOW"
            ;;
        95) # Thunderstorm
            icon="$ICON_LIGHTNING"
            color="$COLOR_STORM"
            ;;
        96|99) # Thunderstorm with hail
            icon="$ICON_LIGHTNING_RAINY"
            color="$COLOR_STORM"
            ;;
        *)
            icon="$ICON_PARTLY_CLOUDY"
            color="$COLOR_CLOUDY"
            ;;
    esac

    echo "${icon}|${color}"
}

# Get weather description from WMO code
get_weather_description() {
    local code="$1"

    case "$code" in
        0) echo "Clear sky" ;;
        1) echo "Mainly clear" ;;
        2) echo "Partly cloudy" ;;
        3) echo "Overcast" ;;
        45) echo "Foggy" ;;
        48) echo "Depositing rime fog" ;;
        51) echo "Light drizzle" ;;
        53) echo "Moderate drizzle" ;;
        55) echo "Dense drizzle" ;;
        56) echo "Light freezing drizzle" ;;
        57) echo "Dense freezing drizzle" ;;
        61) echo "Slight rain" ;;
        63) echo "Moderate rain" ;;
        65) echo "Heavy rain" ;;
        66) echo "Light freezing rain" ;;
        67) echo "Heavy freezing rain" ;;
        71) echo "Slight snow fall" ;;
        73) echo "Moderate snow fall" ;;
        75) echo "Heavy snow fall" ;;
        77) echo "Snow grains" ;;
        80) echo "Slight rain showers" ;;
        81) echo "Moderate rain showers" ;;
        82) echo "Violent rain showers" ;;
        85) echo "Slight snow showers" ;;
        86) echo "Heavy snow showers" ;;
        95) echo "Thunderstorm" ;;
        96) echo "Thunderstorm with slight hail" ;;
        99) echo "Thunderstorm with heavy hail" ;;
        *) echo "Unknown" ;;
    esac
}

# Check if cache is valid
is_cache_valid() {
    if [[ ! -f "$CACHE_FILE" ]]; then
        return 1
    fi

    local cache_time=$(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
    local current_time=$(date +%s)
    local age=$((current_time - cache_time))

    if (( age < CACHE_DURATION )); then
        return 0
    else
        return 1
    fi
}

# Fetch weather data from OpenMeteo API
fetch_weather() {
    if ! command -v curl &>/dev/null; then
        echo '{"text":"⚠️","tooltip":"curl not installed","class":"error"}'
        exit 0
    fi

    if ! command -v jq &>/dev/null; then
        echo '{"text":"⚠️","tooltip":"jq not installed","class":"error"}'
        exit 0
    fi

    # Build OpenMeteo API URL
    local api_url="https://api.open-meteo.com/v1/forecast"
    api_url+="?latitude=${LAT}"
    api_url+="&longitude=${LON}"
    api_url+="&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,wind_direction_10m"
    api_url+="&daily=temperature_2m_max,temperature_2m_min,weather_code"
    api_url+="&timezone=America/Argentina/Mendoza"
    api_url+="&forecast_days=3"

    local weather_data
    weather_data=$(curl --silent --max-time "$API_TIMEOUT" "$api_url" 2>/dev/null)

    if [[ -z "$weather_data" ]]; then
        echo '{"text":"⚠️","tooltip":"No response from weather service","class":"error"}'
        exit 0
    fi

    # Validate JSON
    if ! echo "$weather_data" | jq -e . >/dev/null 2>&1; then
        echo '{"text":"⚠️","tooltip":"Invalid weather data received","class":"error"}'
        exit 0
    fi

    # Cache the result
    echo "$weather_data" > "$CACHE_FILE"
    echo "$weather_data"
}

# Get weather data (from cache or fresh)
get_weather_data() {
    if is_cache_valid; then
        cat "$CACHE_FILE"
    else
        fetch_weather
    fi
}

# Fetch detailed hourly weather data for chart
fetch_detailed_weather() {
    local api_url="https://api.open-meteo.com/v1/forecast"
    api_url+="?latitude=${LAT}"
    api_url+="&longitude=${LON}"
    api_url+="&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m"
    api_url+="&hourly=temperature_2m,weather_code,relative_humidity_2m,wind_speed_10m,precipitation_probability"
    api_url+="&timezone=America/Argentina/Mendoza"
    api_url+="&forecast_days=3"

    curl --silent --max-time "$API_TIMEOUT" "$api_url" 2>/dev/null
}

# Display detailed weather view with temperature curve
show_detailed_view() {
    local weather_data="$1"

    # Fetch detailed hourly data if not present
    if ! echo "$weather_data" | jq -e '.hourly' >/dev/null 2>&1; then
        weather_data=$(fetch_detailed_weather)
    fi

    clear
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Weather Forecast - ${LOCATION_NAME}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if ! command -v jq &>/dev/null || [[ -z "$weather_data" ]]; then
        echo "Error: Unable to fetch detailed weather data"
        echo ""
        echo "Press any key to close..."
        read -n 1 -s
        return
    fi

    # Current conditions
    local temp=$(echo "$weather_data" | jq -r '.current.temperature_2m // "N/A"')
    local feels_like=$(echo "$weather_data" | jq -r '.current.apparent_temperature // "N/A"')
    local humidity=$(echo "$weather_data" | jq -r '.current.relative_humidity_2m // "N/A"')
    local wind=$(echo "$weather_data" | jq -r '.current.wind_speed_10m // "N/A"')
    local code=$(echo "$weather_data" | jq -r '.current.weather_code // "0"')
    local desc=$(get_weather_description "$code")
    local current_icon=$(get_weather_icon_and_color "$code" | cut -d'|' -f1)

    echo "  Current: ${current_icon} ${desc} - ${temp}°C (feels like ${feels_like}°C)"
    echo "  Humidity: ${humidity}% | Wind: ${wind} km/h"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  72-Hour Temperature Forecast"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Extract temperatures every 3 hours (24 data points for 72 hours)
    local temps=()
    local times=()
    local codes=()
    local original_indices=()
    local max_temp=-999
    local min_temp=999

    # Sample every 3 hours: 0, 3, 6, 9... 69
    for i in {0..69..3}; do
        local t=$(echo "$weather_data" | jq -r ".hourly.temperature_2m[$i] // \"null\"")
        if [[ "$t" != "null" ]]; then
            temps+=("$t")
            times+=($(echo "$weather_data" | jq -r ".hourly.time[$i]"))
            codes+=($(echo "$weather_data" | jq -r ".hourly.weather_code[$i] // \"0\""))
            original_indices+=("$i")

            # Track min/max for scaling
            if (( $(echo "$t > $max_temp" | bc -l) )); then
                max_temp=$t
            fi
            if (( $(echo "$t < $min_temp" | bc -l) )); then
                min_temp=$t
            fi
        fi
    done

    # Chart dimensions
    local chart_height=12
    local chart_width=${#temps[@]}  # Should be 24
    local spacing=3  # Spaces between data points
    local temp_range=$(echo "$max_temp - $min_temp" | bc -l)

    # Avoid division by zero
    if (( $(echo "$temp_range < 1" | bc -l) )); then
        temp_range=1
    fi

    # ANSI color codes
    local COLOR_RESET='\033[0m'
    local COLOR_HOT='\033[38;2;249;226;175m'    # Yellow (hot)
    local COLOR_WARM='\033[38;2;235;160;172m'   # Rosewater (warm)
    local COLOR_COOL='\033[38;2;137;180;250m'   # Blue (cool)
    local COLOR_COLD='\033[38;2;148;226;213m'   # Teal (cold)

    # Build the chart with line graph
    declare -A chart
    declare -A chart_colors

    # Calculate y positions for all points
    declare -a y_positions
    for i in "${!temps[@]}"; do
        local normalized=$(echo "scale=2; (${temps[$i]} - $min_temp) / $temp_range * ($chart_height - 1)" | bc -l)
        local y=$(printf "%.0f" "$normalized")
        y=$((chart_height - 1 - y))
        y_positions[$i]=$y
    done

    # First pass: draw all connecting lines
    for i in $(seq 0 $((${#temps[@]} - 2))); do
        local y=${y_positions[$i]}
        local next_y=${y_positions[$((i + 1))]}

        # Determine color for this segment
        local color=""
        if (( $(echo "${temps[$i]} >= 28" | bc -l) )); then
            color="$COLOR_HOT"
        elif (( $(echo "${temps[$i]} >= 24" | bc -l) )); then
            color="$COLOR_WARM"
        elif (( $(echo "${temps[$i]} >= 20" | bc -l) )); then
            color="$COLOR_COOL"
        else
            color="$COLOR_COLD"
        fi

        # Draw horizontal line at current height using small dots
        chart["$y,$i"]="·"
        chart_colors["$y,$i"]="$color"

        # Draw vertical line segments using small dots
        if (( next_y < y )); then
            # Line going up
            for ((line_y = y - 1; line_y >= next_y; line_y--)); do
                chart["$line_y,$i"]="·"
                chart_colors["$line_y,$i"]="$color"
            done
        elif (( next_y > y )); then
            # Line going down
            for ((line_y = y + 1; line_y <= next_y; line_y++)); do
                chart["$line_y,$i"]="·"
                chart_colors["$line_y,$i"]="$color"
            done
        fi
    done

    # Second pass: overlay weather icons and markers
    for i in "${!temps[@]}"; do
        local y=${y_positions[$i]}

        # Determine color based on temperature
        local color=""
        if (( $(echo "${temps[$i]} >= 28" | bc -l) )); then
            color="$COLOR_HOT"
        elif (( $(echo "${temps[$i]} >= 24" | bc -l) )); then
            color="$COLOR_WARM"
        elif (( $(echo "${temps[$i]} >= 20" | bc -l) )); then
            color="$COLOR_COOL"
        else
            color="$COLOR_COLD"
        fi

        # Overlay markers on the line
        local orig_idx=${original_indices[$i]}
        if (( orig_idx % 6 == 0 )); then
            # Show weather icon at 6-hour intervals
            local icon_data=$(get_weather_icon_and_color "${codes[$i]}" "${times[$i]}")
            local icon=$(echo "$icon_data" | cut -d'|' -f1)
            chart["$y,$i"]="$icon"
            chart_colors["$y,$i"]="$color"
        else
            # Show larger dot for 3-hour data points
            chart["$y,$i"]="•"
            chart_colors["$y,$i"]="$color"
        fi
    done

    # Print chart with temperature scale
    for y in $(seq 0 $((chart_height - 1))); do
        # Calculate temperature for this row
        local row_temp=$(echo "scale=1; $max_temp - ($y * $temp_range / ($chart_height - 1))" | bc -l)
        printf "%5.1f°C │" "$row_temp"

        for x in $(seq 0 $((chart_width - 1))); do
            if [[ -n "${chart[$y,$x]}" ]]; then
                echo -ne "${chart_colors[$y,$x]}${chart[$y,$x]}${COLOR_RESET}"
                # Add spacing after each data point
                if (( x < chart_width - 1 )); then
                    printf "%*s" "$((spacing - 1))" ""
                fi
            else
                printf "%*s" "$spacing" ""
            fi
        done
        echo ""
    done

    # Print x-axis
    printf "       └"
    for i in $(seq 0 $((chart_width - 1))); do
        printf "──"
        if (( i < chart_width - 1 )); then
            printf "─"
        fi
    done
    echo ""

    # Print time labels (every 4 data points = 12 hours)
    printf "        "
    for i in $(seq 0 $((chart_width - 1))); do
        if (( i % 4 == 0 )); then
            local time_str=$(echo "${times[$i]}" | cut -d'T' -f2 | cut -d':' -f1)
            printf "%-12s" "${time_str}h"
        fi
    done
    echo ""

    # Print date labels (every 8 data points = 24 hours)
    printf "        "
    for i in $(seq 0 $((chart_width - 1))); do
        if (( i % 8 == 0 )); then
            local date_str=$(echo "${times[$i]}" | cut -d'T' -f1)
            local day_name=$(date -d "$date_str" "+%a %d" 2>/dev/null)
            printf "%-24s" "$day_name"
        fi
    done
    echo ""
    echo ""

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  6-Hour Forecast Breakdown (Next 72 Hours)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Show 6-hour interval breakdown for 72 hours (12 entries)
    for hour in {0..66..6}; do
        local t=$(echo "$weather_data" | jq -r ".hourly.temperature_2m[$hour] // \"null\"")
        if [[ "$t" != "null" ]]; then
            local time_str=$(echo "$weather_data" | jq -r ".hourly.time[$hour]" | sed 's/T/ /')
            local code=$(echo "$weather_data" | jq -r ".hourly.weather_code[$hour] // \"0\"")
            local icon_data=$(get_weather_icon_and_color "$code" "$time_str")
            local icon=$(echo "$icon_data" | cut -d'|' -f1)
            local desc=$(get_weather_description "$code")
            local humid=$(echo "$weather_data" | jq -r ".hourly.relative_humidity_2m[$hour] // \"N/A\"")
            local wind_sp=$(echo "$weather_data" | jq -r ".hourly.wind_speed_10m[$hour] // \"N/A\"")
            local precip=$(echo "$weather_data" | jq -r ".hourly.precipitation_probability[$hour] // \"N/A\"")

            printf "  %16s  %s  %5.1f°C  %-20s  💧%3s%%  💨%4s km/h\n" \
                "$time_str" "$icon" "$t" "$desc" "$precip" "$wind_sp"
        fi
    done

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Press any key to close..."
    read -n 1 -s
}

# Main execution
main() {
    # Check for --detailed flag
    if [[ "$1" == "--detailed" ]]; then
        weather_data=$(get_weather_data)
        show_detailed_view "$weather_data"
        exit 0
    fi

    # Default: Output JSON for Waybar
    weather_data=$(get_weather_data)

    # Check for errors
    if [[ -z "$weather_data" ]]; then
        echo '{"text":"⚠️","tooltip":"Failed to get weather data","class":"error"}'
        exit 0
    fi

    # Parse weather data using jq
    if command -v jq &>/dev/null && [[ -n "$weather_data" ]]; then
        # Current conditions
        TEMP_C=$(echo "$weather_data" | jq -r '.current.temperature_2m // "N/A"')
        FEELS_LIKE_C=$(echo "$weather_data" | jq -r '.current.apparent_temperature // "N/A"')
        WEATHER_CODE=$(echo "$weather_data" | jq -r '.current.weather_code // "0"')
        HUMIDITY=$(echo "$weather_data" | jq -r '.current.relative_humidity_2m // "N/A"')
        WIND_SPEED=$(echo "$weather_data" | jq -r '.current.wind_speed_10m // "N/A"')
        WIND_DIR=$(echo "$weather_data" | jq -r '.current.wind_direction_10m // "N/A"')

        # Get weather description
        WEATHER_DESC=$(get_weather_description "$WEATHER_CODE")

        # Get weather icon and color
        ICON_AND_COLOR=$(get_weather_icon_and_color "$WEATHER_CODE")
        IFS='|' read -r WEATHER_ICON WEATHER_COLOR <<< "$ICON_AND_COLOR"

        # Build display text
        DISPLAY_TEXT="<span font_desc='JetBrainsMono Nerd Font 12' color='${WEATHER_COLOR}'>${WEATHER_ICON}</span><span font_desc='SF Compact Rounded Bold 12' color='${WEATHER_COLOR}'>${TEMP_C}°C</span>"

        # Build simplified tooltip
        TOOLTIP="📍 ${LOCATION_NAME}\\n"
        TOOLTIP+="${WEATHER_ICON}${WEATHER_DESC}\\n\\n"

        TOOLTIP+="🌡️ Current Conditions\\n"
        TOOLTIP+="├─ Temperature: ${TEMP_C}°C (feels like ${FEELS_LIKE_C}°C)\\n"
        TOOLTIP+="├─ Humidity: ${HUMIDITY}%\\n"
        TOOLTIP+="└─ Wind: ${WIND_SPEED} km/h at ${WIND_DIR}°\\n\\n"

        # Add 3-day forecast
        TOOLTIP+="📅 3-Day Forecast\\n"
        for i in 0 1 2; do
            DAY_DATE=$(echo "$weather_data" | jq -r ".daily.time[$i] // \"N/A\"")
            DAY_MAX=$(echo "$weather_data" | jq -r ".daily.temperature_2m_max[$i] // \"N/A\"")
            DAY_MIN=$(echo "$weather_data" | jq -r ".daily.temperature_2m_min[$i] // \"N/A\"")
            DAY_CODE=$(echo "$weather_data" | jq -r ".daily.weather_code[$i] // \"0\"")
            DAY_DESC=$(get_weather_description "$DAY_CODE")

            DAY_ICON_DATA=$(get_weather_icon_and_color "$DAY_CODE")
            IFS='|' read -r DAY_ICON _ <<< "$DAY_ICON_DATA"

            # Format date nicely
            if [[ "$DAY_DATE" != "N/A" ]]; then
                DAY_NAME=$(date -d "$DAY_DATE" "+%a %b %d" 2>/dev/null || echo "$DAY_DATE")
            else
                DAY_NAME="N/A"
            fi

            if (( i == 2 )); then
                TOOLTIP+="└─ ${DAY_NAME}: ${DAY_ICON} ${DAY_MIN}°C - ${DAY_MAX}°C  ${DAY_DESC}"
            else
                TOOLTIP+="├─ ${DAY_NAME}: ${DAY_ICON} ${DAY_MIN}°C - ${DAY_MAX}°C  ${DAY_DESC}\\n"
            fi
        done

        TOOLTIP+="\\n\\n🖱️ Actions\\n"
        TOOLTIP+="└─ Click to view detailed weather"

        # Output JSON for waybar
        echo "{\"text\":\"${DISPLAY_TEXT}\",\"tooltip\":\"${TOOLTIP}\",\"class\":\"normal\"}"
    else
        # Fallback if jq is not available or data is invalid
        echo '{"text":"⚠️","tooltip":"Unable to parse weather data. Install jq for full functionality.","class":"error"}'
    fi
}

main "$@"
