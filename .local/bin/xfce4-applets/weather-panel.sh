#!/usr/bin/env bash

#
# Sunny🌣 🌞 ⛅ 🌤 🌥 ⛱
# rainy 🌦 🌧 ⛆ 🌢 ☂ ☔ 🌂 
# snowy 🌨 ☃ ⛄ ⛇ ❄ ❅ ❆
# windy 🌬 🎏 🎐
# foggy ☁ 🌫 🌁 
# stormy 🌩 ⛈ ☇ ☈
# tornado 🌪 🌀
# clear ☀ ☼ 🌞 🌑 🌒 🌓 🌔 🌕 🌖 🌗 🌘 🌙 ☾ 🌛 🌜 🌝 🌚
# 

#variable
#weatherreport="${XDG_DATA_HOME:-$HOME/.local/share}/weatherreport"

# Portable directory
readonly DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Size used for the icons is 24x24 (16x16 is also ok for a smaller panel)
readonly ICON="${DIR}/icons/gpu.png"


# Weather Values

#readonly WEATHER_REPORT="$(curl --silent http://wttr.in/$1?T0F)"
#readonly WEATHER_REPORT="$(curl --silent http://wttr.in/-32.89,-68.85?T0F)"
readonly WEATHER_REPORT="$(curl --silent http://wttr.in/Mendoza?T0F)"

readonly CURRENT_TEMP="$(curl -s http://rss.accuweather.com/rss/liveweather_rss.asp\?metric\=1\&locCode\="SAM|AR|AR013|MENDOZA" | perl -ne 'use utf8; if (/Currently/) {chomp;/\<title\>Currently: (.*)?\<\/title\>/; my @values=split(":",$1); if( $values[0] eq "Sunny" || $values[0] eq "Intermittent Clouds" || $values[0] eq "Hazy Sunshine" || $values[0] eq "Hazy Sunshine" || $values[0] eq "Hot") 
{
my $sun1 = "☀️";
binmode(STDOUT, ":utf8");
print "$sun1";
}
if( $values[0] eq "Mostly Sunny" || $values[0] eq "Partly Sunny") 
{
my $sun2 = "🌤";
binmode(STDOUT, ":utf8");
print "$sun2";
}
if( $values[0] eq "Mostly Cloudy" || $values[0] eq "Cloudy" || $values[0] eq "Dreary (Overcast)" || $values[0] eq "Fog")
{
my $cloud = "⛅";
binmode(STDOUT, ":utf8");
print "$cloud";
}
if( $values[0] eq "Fog")
{
my $foggy = "🌁";
binmode(STDOUT, ":utf8");
print "$foggy";
}
if( $values[0] eq "Partly Sunny w/ Showers")
{
my $rain1 = "🌦";
binmode(STDOUT, ":utf8");
print "$rain1";
}
if( $values[0] eq "Showers" || $values[0] eq "Mostly Cloudy w/ Showers" || $values[0] eq "Rain")
{
my $rain2 = "🌧️";
binmode(STDOUT, ":utf8");
print "$rain2";
}
if( $values[0] eq "T-Storms" || $values[0] eq "Mostly Cloudy w/ T-Storms"|| $values[0] eq "Partly Sunny w/ T-Storms")
{
my $rain3 = "⛈";
binmode(STDOUT, ":utf8");
print "$rain3";
}
if( $values[0] eq "Windy")
{
my $wind = "🌪";
binmode(STDOUT, ":utf8");
print "$wind";
} 
if( $values[0] eq "Flurries" || $values[0] eq "Mostly Cloudy w/ Flurries" || $values[0] eq "Partly Sunny w/ Flurries")
{
my $flurries = "❄️";
binmode(STDOUT, ":utf8");
print "$flurries";
}
if( $values[0] eq "Snow"|| $values[0] eq "Mostly Cloudy w/ Snow"|| $values[0] eq "Ice" || $values[0] eq "Sleet" || $values[0] eq "Freezing Rain"|| $values[0] eq "Rain and Snow"|| $values[0] eq "Cold")
{
my $snowy = "🌨";
binmode(STDOUT, ":utf8");
print "$snowy";
}
if($values[0] eq "Clear" || $values[0] eq "Mostly Clear" || $values[0] eq "Moonlight" || $values[0] eq "Hazy Moonlight")
{
my $night = "🌜";
binmode(STDOUT, ":utf8");
print "$night";
}
$values[1] =~ s/C/°C/g; print"$values[1]"; }')"

#### Panel
###if [[ $(file -b "${ICON}") =~ PNG|SVG ]]; then
###  INFO="<img>${ICON}</img>"
###  INFO+="<txt>"
###else
###  INFO="<txt>"
###fi
####INFO+="${GPU_UTIL}"
###INFO+=" $CURRENT_TEMP"°C"  "
###INFO+="</txt>"

# Tooltip
MORE_INFO="<tool>"
MORE_INFO+="${WEATHER_REPORT}"
MORE_INFO+="</tool>"

# Output panel
echo -e "<txt> ${CURRENT_TEMP} </txt>"

# Output hover menu
echo -e "${MORE_INFO}"