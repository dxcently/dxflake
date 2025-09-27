#!/bin/bash

check_sinks() {
    pactl list sinks short | rg -e '66|68' | rg 'RUNNING' | awk '/(66|68)/ {print $1}'
}

toggle_sink() {
    current_sink=$(check_sinks)
    if [ "$current_sink" -eq 68 ]; then
        pactl set-default-sink 66
        current_sink=66
        dunstify -a "Audio Sink" "Headphones 󰋋" "Switched to sink 66"
    else
        pactl set-default-sink 68
        current_sink=68
        dunstify -a "Audio Sink" "Speakers 󰓃" "Switched to sink 68"
    fi
}

toggle_sink
