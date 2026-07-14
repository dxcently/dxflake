#!/usr/bin/env bash
set -euo pipefail

f="$HOME/.config/hypr/hyprland.conf"

if [ ! -L "$f" ]; then
    echo "not a symlink: $f"
    exit 1
fi

target=$(readlink -f "$f")

if [ ! -e "$target" ]; then
    echo "symlink target missing: $target"
    exit 1
fi

cp "$target" "$f.real"
rm "$f"
mv "$f.real" "$f"

echo "unsymlinked: $f (was -> $target)"
