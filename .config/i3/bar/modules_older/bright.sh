#!/bin/sh
brightn=$(cat /sys/class/backlight/acpi_video0/brightness)
##echo $brightn
brpercent=$(($brightn \* 100 / 15))
echo $brpercent"%"
