#!/usr/bin/env bash

## Copyright (C) 2020-2022 Aditya Shakya <adi1090x@gmail.com>
## Everyone is permitted to copy and distribute copies of this file under GNU-GPL3

rofi -dmenu \
     -password \
     -i \
     -no-fixed-num-lines \
     -p "User Password: " \
     -theme ~/.config/rofi/themes/askpass.rasi &
