#!/bin/bash

#this prints out a string because of a "."
check_sinks() {
    wpctl status | rg -e '66|68' | rg '\*' | awk '/(66|68)/ {print $3}'
}

toggle_sink() {
    current_sink=$(check_sinks)
    if [ "$current_sink" == "68." ]; then
        wpctl set-default 66
        current_sink="66."
        dunstify -a "Audio Sink" "Headphones 󰋋" "Switched to sink 66"
    else
        wpctl set-default 68
        current_sink="68."
        dunstify -a "Audio Sink" "Speakers 󰓃" "Switched to sink 68"
    fi
}

toggle_sink
