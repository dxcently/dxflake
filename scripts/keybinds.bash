#!/bin/sh
# Keybindings cheatsheet for Hyprland, Neovim (nvf) and Yazi.
# Pulls from modules/dendrites/{hyprland,neovim,yazi}.nix.

# yad's --plug/--notebook uses X11 XEMBED, force XWayland under Hyprland.
export GDK_BACKEND=x11

KEY=$$

trap 'jobs -p | xargs -r kill 2>/dev/null' EXIT

yad --plug=$KEY --tabnum=1 \
  --list \
  --column=Key: \
  --column=Action: \
  --column=Command: \
  "SUPER + RETURN"        "Launch terminal"                  "kitty" \
  "SUPER + SPACE"         "App launcher"                     "rofi -show drun" \
  "SUPER + Tab"           "Window switcher"                  "rofi -show" \
  "ALT + Tab"             "Previous workspace"               "workspace, previous" \
  "SUPER + T"             "File manager (floating)"          "thunar" \
  "SUPER + C"             "Clipboard history"                "cliphist | rofi | wl-copy" \
  "SUPER + S"             "Region screenshot to satty"       "pkill hyprpicker; hyprshot -z --raw -m region | satty --filename -" \
  "SUPER + SHIFT + S"     "Output screenshot to satty"       "pkill hyprpicker; hyprshot -z --raw -m output | satty --filename -" \
  "SUPER + D"             "Vesktop on ws3 / toggle discord"  "vesktop + special:discord" \
  "SUPER + Q"             "Kill focused window"              "killactive" \
  "SUPER + V"             "Toggle floating"                  "togglefloating" \
  "SUPER + F"             "Toggle fullscreen"                "fullscreen" \
  "SUPER + P"             "Pseudo-tile"                      "pseudo" \
  "SUPER + H / J / K / L" "Move focus L / D / U / R"         "movefocus" \
  "SUPER + SHIFT + HJKL"  "Move window L / D / U / R"        "movewindow" \
  "SUPER + ALT + HJKL"    "Resize active window (±40px)"     "resizeactive" \
  "SUPER + ,"             "Scroll: resize to visible space"  "layoutmsg fit visible" \
  "SUPER + ."             "Scroll: resize to fit window"     "layoutmsg fit active" \
  "SUPER + p"             "Scroll: pop window to own column" "layoutmsg promote" \
  "SUPER + 1..0"          "Go to workspace 1..10"            "workspace, N" \
  "SUPER + SHIFT + 1..0"  "Move window to workspace 1..10"   "movetoworkspace, N" \
  "SUPER + X"             "Toggle special:magic"             "togglespecialworkspace" \
  "SUPER + Z"             "Toggle special:scratch (steam)"   "togglespecialworkspace" \
  "SUPER + R"             "Toggle special:replay (gsr)"      "togglespecialworkspace" \
  "SUPER + SHIFT + X/Z/D" "Send window to magic/scratch/dc"  "movetoworkspace, special:*" \
  "SUPER + LMB"           "Drag window"                      "movewindow" \
  "SUPER + RMB"           "Resize window"                    "resizewindow" \
  "XF86AudioRaise/Lower"  "Volume ±4%"                       "wpctl set-volume" \
  "XF86AudioMute"         "Toggle sink mute"                 "wpctl set-mute" \
  "XF86AudioMicMute"      "Toggle source mute"               "wpctl set-mute" \
  "XF86MonBrightness ±"   "Backlight ±5%"                    "brightnessctl s" \
  &

yad --plug=$KEY --tabnum=2 \
  --list \
  --column=Key: \
  --column=Mode: \
  --column=Action: \
  "&lt;leader&gt;y"   "n / v"   "Yank into system clipboard" \
  "&lt;leader&gt;Y"   "n / v"   "Yank to end-of-line into system clipboard" \
  "&lt;leader&gt;d"   "n / v"   "Cut into system clipboard" \
  "&lt;leader&gt;p"   "n / v"   "Paste from system clipboard" \
  "&lt;leader&gt;P"   "n / v"   "Paste before cursor from system clipboard" \
  "&lt;C-h&gt;"       "insert"  "Move left" \
  "&lt;C-j&gt;"       "insert"  "Move down" \
  "&lt;C-k&gt;"       "insert"  "Move up" \
  "&lt;C-l&gt;"       "insert"  "Move right" \
  "&lt;leader&gt;nt"  "normal"  "Toggle Neo-tree file browser" \
  "&lt;leader&gt;nh"  "normal"  "Clear search highlights (:nohl)" \
  "&lt;leader&gt;?"   "normal"  "Open cheatsheet.nvim" \
  "&lt;leader&gt;"    "—"       "Leader key is \\ (Vim default — nvf does not override)" \
  "&lt;C-Space&gt;"   "insert"  "Trigger nvim-cmp completion (default)" \
  "gd / gr / K"       "normal"  "LSP: definition / references / hover" \
  "&lt;leader&gt;ff"  "normal"  "Telescope find files (default nvf bind)" \
  "&lt;leader&gt;fg"  "normal"  "Telescope live grep (default nvf bind)" \
  ":noa w"            "normal"  "Writes bypassing autoformatter" \
  &

yad --plug=$KEY --tabnum=3 \
  --list \
  --column=Key: \
  --column=Action: \
  "h / j / k / l"  "Navigate parent / down / up / child" \
  "Enter"          "Open file with default opener" \
  "o / O"          "Open with… / interactive open" \
  "Space"          "Toggle selection on hovered" \
  "v"              "Visual selection mode" \
  "y"              "Yank (copy)" \
  "x"              "Yank (cut)" \
  "p / P"          "Paste / paste forced (overwrite)" \
  "d / D"          "Move to trash / permanent delete" \
  "a"              "Create file (end with / for dir)" \
  "r"              "Rename" \
  "."              "Toggle hidden files" \
  "s"              "Search by filename (fd)" \
  "S"              "Search by content (ripgrep)" \
  "/ , ?"          "Find next / find prev in cwd" \
  "n / N"          "Jump to next / prev match" \
  "gh / gc / g/"   "Go home / config / root" \
  "z / Z"          "Jump via zoxide / fzf" \
  "t"              "New tab"  \
  "1..9"           "Switch to tab N" \
  "Tab"            "Toggle preview pane" \
  ":"              "Run shell command (blocking)" \
  ";"              "Run shell command (background)" \
  "q"              "Quit" \
  "Q"              "Quit and cd to cwd (needs shell hook)" \
  "sy (alias)"     "Launch yazi as root" \
  &

yad --notebook --key=$KEY \
  --width=900 --height=650 \
  --center --fixed \
  --title="Keybindings — Hyprland / Vim / Yazi" \
  --tab="Hyprland" \
  --tab="Neovim (nvf)" \
  --tab="Yazi" \
  --button="Close":0
