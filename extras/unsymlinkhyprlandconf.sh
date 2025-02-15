#!/bin/bash
#put this in hyprland .config folder and make backups dir
counter=$(ls "./backups/"hyprland.conf.backup* 2>/dev/null | sed -E 's/.*hyprland.conf.backup([0-9]+)/\1/' | sort -n | tail -n 1)

if [ -z "$counter" ]; then
    counter=0
fi

((counter++))

sudo cp hyprland.conf "./backups/hyprland.conf.backup${counter}"

cp hyprland.conf hyprland.conf.tmp
rm hyprland.conf
mv hyprland.conf.tmp hyprland.conf
