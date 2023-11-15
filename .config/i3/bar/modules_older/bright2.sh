#!/bin/bash

brightn=$(cat /sys/class/backlight/acpi_video0/brightness)

##echo $brightn

brpercent=$(($brightn * 100 / 15));

echo $brpercent%

# color
if [[ $brpercent -eq 100 ]]; then
    echo "#ffffff"
elif [[ $brpercent -ge 80 ]]; then
    echo "#d1d4e0"
elif [[ $brpercent -ge 60 ]]; then
    echo "#7780a1"
elif [[ $brpercent -ge 40 ]]; then
    echo "#252936"
elif [[ $brpercent -ge 20 ]]; then
    echo "#1f222d"
fi
