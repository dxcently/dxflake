# session-guard

`instances.json` is not a hand-written fixture. It is `hyprctl instances -j`
captured off yomi-strix on 2026-09-14 while the hijack was live: entry 0 is the
login compositor, entry 1 a Hyprland nested inside it under a Chromium scope.
Every behavioural case in `run.sh` is that list, transformed — pids swapped for
live/dead ones, a `time` nulled — so the guard is tested against the shape
Hyprland actually emits rather than against a shape invented to suit it.
