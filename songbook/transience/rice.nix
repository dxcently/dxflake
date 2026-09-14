# songbook/transience/rice.nix — "transience", the rice dxflake has always worn.
#
# A RICE is the look: the palette, and the stylesheets the surfaces wear. It is
# not the wiring. `programs.waybar.enable`, its systemd unit, `programs.rofi`
# and `programs.wlogout` stay in their dendrites, where any rice can reuse them
# — swapping the rice must never mean re-deciding whether waybar runs.
#
# Selected through the `rice` provider registry (songbook/default.nix), which
# the `shell` aggregation answers with "transience" by default. A host that
# wants another look writes one line:
#
#   users.<u>.aggregation.shell.rice.provider = "<other>";
#
# ── What transience actually owns ─────────────────────────────────────────
# waybar     the stylesheet (source/waybar.css) and the bar's own composition
#            — which modules sit where, and how each one reads.
# the palette  palette.nix is the source; livery.json is generated from it in
#            Aoide's v0 livery schema so `lyra livery lint
#            songbook/transience/livery.json` is a real check on it and
#            `lyra livery emit` can drive the same template. Rosé Pine, the
#            sixteen colours this desktop has always used.
# rofi, wlogout  NOTHING bespoke, and that is the honest answer rather than an
#            omission: both take the base16 scheme through Stylix and never had
#            a sheet of their own. Recording that here is the preservation —
#            inventing one would be a redesign. See design/intent.md.
# the dock   also nothing. dxflake ships no dock; the dock on screen is Aoide's
#            Quickshell `aoide-dock` surface. transience carries the same
#            palette into it rather than drawing a second one beside it.
#
# ── Where the colours come from ───────────────────────────────────────────
# The stylesheet is a TEMPLATE with `{{base16.baseXX}}` placeholders — Lyra's
# own `livery emit file` syntax, so the identical file renders either way and
# the two cannot drift into different sheets. At build time the values come
# from `config.lib.stylix.colors`, which is what the sheet read before it was a
# file, so a host whose palette is repainted by Aoide's stylix facet is still
# repainted. Both `livery.json` and `modules/dendrites/stylix.nix` read
# `palette.nix`, the one source, and tests/rice asserts the chain still lands.
{
  homeManager =
    {
      config,
      lib,
      ...
    }:
    let
      slots = [
        "base00"
        "base01"
        "base02"
        "base03"
        "base04"
        "base05"
        "base06"
        "base07"
        "base08"
        "base09"
        "base0A"
        "base0B"
        "base0C"
        "base0D"
        "base0E"
        "base0F"
      ];
      colour = slot: "#${config.lib.stylix.colors.${slot}}";
      fill = builtins.replaceStrings (map (s: "{{base16.${s}}}") slots) (map colour slots);
    in
    {
      programs.waybar = {
        style = fill (builtins.readFile ./source/waybar.css);
        settings = [
          {
            "layer" = "top";
            "position" = "top";
            modules-left = [
              "custom/powermenu"
              "hyprland/workspaces"
              "custom/wall"
            ];
            modules-center = [
              "clock"
              "hyprland/window"
            ];
            modules-right = [
              "mpris"
              "wireplumber"
              #"backlight"
              #"memory"
              #"cpu"
              #"network"
              #"temperature"
              "battery"
              "tray"
              #"custom/powermenu"
            ];
            "custom/powermenu" = {
              "format" = "𝄞";
              "on-click" = "wlogout";
              "tooltip" = false;
            };
            "hyprland/window" = {
              max-length = 25;
              separate-outputs = false;
              rewrite = {
                "" = "/ᐠ - ˕ -マ Ⳋ ⋆｡°✩♬ ♪";
              };
            };
            "hyprland/workspaces" = {
              "format" = "{icon}";
              "format-icons" = {
                "1" = "𝅘𝅥 ";
                "2" = "♫";
                "3" = "𝅘𝅥𝅯  ";
                "4" = "♬";
                "5" = "𝅘𝅥𝅱  ";
                "6" = "𝅗𝅥 ";
                "7" = "𝅝  ";
                "8" = "♯";
                "9" = "♮";
                "10" = "♭";
                "discord" = " ";
                "magic" = "♬⋆.˚";
                "scratch" = "ᝰ.ᐟ";
                sort-by-number = false;
              };
              "on-click" = "activate";
              "on-scroll-up" = "hyprctl dispatch workspace e+1";
              "on-scroll-down" = "hyprctl dispatch workspace e-1";
              "window-rewrite-default" = "🖿";
              "show-special" = true;
              "special-visible-only" = true;
              "persistent-workspaces" = {
                "DP-1" = [
                  1
                  3
                  4
                  5
                ];
                "HDMI-A-1" = [ 2 ];
                "eDP-1" = [
                  1
                  2
                  3
                  4
                ];
              };
            };
            "backlight" = {
              "device" = "intel_backlight";
              "on-scroll-up" = "light -A 5";
              "on-scroll-down" = "light -U 5";
              "format" = "{icon}  {percent}% /";
              "format-icons" = [
                "𝄖"
                "𝄗"
                "𝄘"
                "𝄙"
                "𝄚"
                "𝄛"
              ];
            };
            "mpris" = {
              "format" = "♪ « {artist} - {title} »";
              "format-paused" = "𝄩 [{artist} - {title}]";
              "max-length" = 50;
            };
            "wireplumber" = {
              "scroll-step" = 2;
              "format" = " / {icon} {volume}% /";
              "format-muted" = "/ (° × ° ) /";
              "format-icons" = {
                "default" = [
                  "𝅗𝅥 "
                  "♩~"
                  "♪~"
                  "♫~"
                  "♬~"
                ];
              };
              "on-click" = "pavucontrol";
              "on-click-right" = "bash ~/dxflake/scripts/sink_changer.sh";
              "tooltip" = true;
            };
            "battery" = {
              "interval" = 10;
              "states" = {
                "warning" = 20;
                "critical" = 10;
              };
              "format" = "{icon}  {capacity}% /";
              "format-icons" = [
                "𝄽"
                "𝄾"
                "𝄿"
                "𝅀"
                "𝅁"
                "𝅂"
              ];
              "format-full" = "𝆑 /";
              "format-charging" = "𝄮 {capacity}% /";
              "tooltip" = false;
            };
            "clock" = {
              "interval" = 1;
              "format" = "{:%I:%M %p  %A %b %d} /";
              "tooltip" = true;
              "tooltip-format" = "<tt>{calendar}</tt>";
              "calendar" = {
                "mode" = "year";
                "mode-mon-col" = 3;
                "weeks-pos" = "right";
                "on-scroll" = 1;
                "format" = {
                  "months" = "<span color='#${config.lib.stylix.colors.base0A}'><b>{}</b></span>";
                  "days" = "<span color='#000000'><b>{}</b></span>";
                  "weeks" = "<span color='#${config.lib.stylix.colors.base0D}'><b>W{}</b></span>";
                  "weekdays" = "<span color='#${config.lib.stylix.colors.base0C}'><b>{}</b></span>";
                  "today" = "<span color='#${config.lib.stylix.colors.base08}'><b><u>{}</u></b></span>";
                };
              };
              "on-click" = "hyprctl dispatch exec '[float] kitty --hold gcalcli agenda'";
            };
            /*
              "memory" = {
                "interval" = 1;
                "format" = "✿ {percentage}%";
                "states" = {
                  "warning" = 85;
                };
              };
              "cpu" = {
                "interval" = 1;
                "format" = "❀ {usage}%";
              };
            */
            "network" = {
              "format-disconnected" = "Disconnected :c /";
              "format-ethernet" = "𝆺𝅥𝅯 /";
              "format-linked" = "𝆹𝅥𝅯 (No IP) /";
              "format-wifi" = "𝆹𝅥𝅮 /";
              "interval" = 1;
              "tooltip" = true;
              "tooltip-format" = "{essid} ({ipaddr})";
              "on-click" = "nm-applet --indicator";
            };
            /*
              "temperature" = {
                #"critical-threshold"= 80;
                "tooltip" = false;
                "format" = "⋆.˚ {temperatureC}°C";
              };
            */
            /*
                "custom/powermenu" = {
                "format" = "/ 𓏲𝄢";
                "on-click" = "wlogout";
                "tooltip" = false;
              };
            */
            "tray" = {
              "icon-size" = 12;
              "spacing" = 6;
            };
          }
        ];
      };
    };
}
