#!/usr/bin/env bash
# Waybar Weather Module - Enhanced weather monitor using wttr.in
# Based on XFCE weather-panel3.sh applet
# Location: Mendoza, Argentina

# Configuration
readonly LOCATION="Mendoza"
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

# Weather emoji and Nerd Font mapping based on wttr.in weather codes
get_weather_icon_and_color() {
    local code="$1"
    local hour=$(date +%H)
    
    # Determine if it's night time (20:00 - 06:00)
    local is_night=0
    if (( hour >= 20 || hour <= 6 )); then
        is_night=1
    fi

    # Initialize variables
    # local emoji=""
    local icon=""
    local color=""

    # Weather code to icon/color mapping
    case "$code" in
        113) # Clear/Sunny
            if (( is_night == 1 )); then
                icon="🌛 "
                #icon=" " # fa-moon
                color="$COLOR_NIGHT"
            else
                icon="☀️"
                # icon="" # fa-sun
                color="$COLOR_CLEAR"
            fi
            ;;
        116) # Partly cloudy
             icon="⛅ "
             #icon=" " # fa-cloud-sun (using generic cloud-sun for now or nerd font equivalent)
             if (( is_night == 1 )); then
                 icon="🌙 "
                 #icon="" # fa-cloud-moon
                 color="$COLOR_NIGHT"
             else
                 color="$COLOR_CLEAR"
             fi
             ;;
        119|122) # Cloudy/Overcast
             icon="☁️ "
             #icon=" " # fa-cloud
             color="$COLOR_CLOUDY"
             ;;
        143|248|260) # Mist/Fog
             icon="🌫 "
             #icon=" " # fa-smog
             color="$COLOR_FOG"
             ;;
        176|263|266|293|296) # Light rain
             icon="🌦"
             #icon=" " # fa-cloud-sun-rain
             color="$COLOR_RAIN"
             ;;
        299|302|305|308|356|359|182|185|281|284|311|314|317|350|362|365|368) # Rain/Sleet
             icon="🌧"
             # icon=" " # fa-cloud-showers-heavy
             color="$COLOR_RAIN"
             ;;
        200|386|389) # Thunder
             icon="⛈ "
             #icon="" # fa-bolt (or storm icon)
             color="$COLOR_STORM"
             ;;
        179|227|230|329|332|335|338|371|374|377|320|323|326|395|392) # Snow
             icon="❄️ "
             #icon="" # fa-snowflake
             color="$COLOR_SNOW"
             ;;
        *) 
             icon="🌡"
             #icon="" # fa-thermometer-half
             color="$COLOR_CLOUDY"
             ;;
    esac
    
    echo "${icon}|${color}"
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

# Fetch weather data from wttr.in JSON API
fetch_weather() {
    if ! command -v curl &>/dev/null; then
        echo '{"text":"⚠️","tooltip":"curl not installed","class":"error"}'
        exit 0
    fi

    if ! command -v jq &>/dev/null; then
        echo '{"text":"⚠️","tooltip":"jq not installed","class":"error"}'
        exit 0
    fi

    local weather_data
    weather_data=$(curl --silent --max-time "$API_TIMEOUT" "http://wttr.in/${LOCATION}?format=j1" 2>/dev/null)

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

# Main execution
weather_data=$(get_weather_data)

# Check for errors
if [[ -z "$weather_data" ]]; then
    echo '{"text":"⚠️","tooltip":"Failed to get weather data","class":"error"}'
    exit 0
fi

# Parse weather data using jq
if command -v jq &>/dev/null && [[ -n "$weather_data" ]]; then
    # Current conditions
    TEMP_C=$(echo "$weather_data" | jq -r '.current_condition[0].temp_C // "N/A"')
    FEELS_LIKE_C=$(echo "$weather_data" | jq -r '.current_condition[0].FeelsLikeC // "N/A"')
    WEATHER_DESC=$(echo "$weather_data" | jq -r '.current_condition[0].weatherDesc[0].value // "Unknown"')
    WEATHER_CODE=$(echo "$weather_data" | jq -r '.current_condition[0].weatherCode // "0"')
    HUMIDITY=$(echo "$weather_data" | jq -r '.current_condition[0].humidity // "N/A"')
    WIND_SPEED=$(echo "$weather_data" | jq -r '.current_condition[0].windspeedKmph // "N/A"')
    WIND_DIR=$(echo "$weather_data" | jq -r '.current_condition[0].winddir16Point // "N/A"')
    PRESSURE=$(echo "$weather_data" | jq -r '.current_condition[0].pressure // "N/A"')
    UV_INDEX=$(echo "$weather_data" | jq -r '.current_condition[0].uvIndex // "N/A"')
    VISIBILITY=$(echo "$weather_data" | jq -r '.current_condition[0].visibility // "N/A"')
    CLOUD_COVER=$(echo "$weather_data" | jq -r '.current_condition[0].cloudcover // "N/A"')
    PRECIP_MM=$(echo "$weather_data" | jq -r '.current_condition[0].precipMM // "N/A"')

    # Location info
    AREA_NAME=$(echo "$weather_data" | jq -r '.nearest_area[0].areaName[0].value // "Unknown"')
    COUNTRY=$(echo "$weather_data" | jq -r '.nearest_area[0].country[0].value // "Unknown"')

    # Get weather icon and color
    ICON_AND_COLOR=$(get_weather_icon_and_color "$WEATHER_CODE")
    IFS='|' read -r WEATHER_ICON WEATHER_COLOR <<< "$ICON_AND_COLOR"

    # Build display text
    DISPLAY_TEXT="<span font_desc='JetBrainsMono Nerd Font Bold 14' color='${WEATHER_COLOR}'>${WEATHER_ICON}  ${TEMP_C}°C</span>"

    # Build detailed tooltip
    TOOLTIP="📍 ${AREA_NAME}, ${COUNTRY}\n"
    TOOLTIP+="${WEATHER_ICON} ${WEATHER_DESC}\n\n"

    TOOLTIP+="🌡️ Current Conditions\n"
    TOOLTIP+="├─ Temperature: ${TEMP_C}°C (feels like ${FEELS_LIKE_C}°C)\n"
    TOOLTIP+="├─ Humidity: ${HUMIDITY}%\n"
    TOOLTIP+="├─ Wind: ${WIND_SPEED} km/h ${WIND_DIR}\n"
    TOOLTIP+="├─ Pressure: ${PRESSURE} hPa\n"
    TOOLTIP+="├─ Cloud Cover: ${CLOUD_COVER}%\n"
    TOOLTIP+="├─ Visibility: ${VISIBILITY} km\n"
    TOOLTIP+="├─ UV Index: ${UV_INDEX}\n"
    TOOLTIP+="└─ Precipitation: ${PRECIP_MM} mm\n\n"

    # Add 3-day forecast
    TOOLTIP+="📅 3-Day Forecast\n"
    for i in 0 1 2; do
        DAY_DATE=$(echo "$weather_data" | jq -r ".weather[$i].date // \"N/A\"")
        DAY_MAX=$(echo "$weather_data" | jq -r ".weather[$i].maxtempC // \"N/A\"")
        DAY_MIN=$(echo "$weather_data" | jq -r ".weather[$i].mintempC // \"N/A\"")
        DAY_DESC=$(echo "$weather_data" | jq -r ".weather[$i].hourly[4].weatherDesc[0].value // \"Unknown\"")
        DAY_CODE=$(echo "$weather_data" | jq -r ".weather[$i].hourly[4].weatherCode // \"0\"")
        
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
            TOOLTIP+="├─ ${DAY_NAME}: ${DAY_ICON} ${DAY_MIN}°C - ${DAY_MAX}°C  ${DAY_DESC}\n"
        fi
    done

    TOOLTIP+="\n\n🖱️ Actions\n"
    TOOLTIP+="└─ Click to view full weather report"

    # Output JSON for waybar
    echo "{\"text\":\"${DISPLAY_TEXT}\",\"tooltip\":\"${TOOLTIP}\",\"class\":\"normal\"}"
else
    # Fallback if jq is not available or data is invalid
    echo '{"text":"⚠️","tooltip":"Unable to parse weather data. Install jq for full functionality.","class":"error"}'
fi
