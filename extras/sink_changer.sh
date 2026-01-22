#!/bin/bash

SINK1="SteelSeries Arctis 7 Game"
SINK2="Built-in Audio Analog Stereo"

CURRENT_ID=$(wpctl status | grep -A 15 "Sinks:" | grep '*' | grep -oP '\d+' | head -n 1)
ID1=$(wpctl status | grep -A 15 "Sinks:" | grep "$SINK1" | grep -oP '\d+' | head -n 1)
ID2=$(wpctl status | grep -A 15 "Sinks:" | grep "$SINK2" | grep -oP '\d+' | head -n 1)

if [ "$CURRENT_ID" == "$ID1" ]; then
    wpctl set-default "$ID2"
    dunstify -a "Audio Sink" "Speakers 󰓃" "Switched to Speakers"
else
    wpctl set-default "$ID1"
    dunstify -a "Audio Sink" "Headphones 󰋋" "Switched to Arctis 7"
fi
