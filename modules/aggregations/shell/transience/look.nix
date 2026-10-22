# modules/aggregations/shell/transience/look.nix — the look the shell wears.
#
# A plain home module, applied to each user the shell aggregation reaches
# (`home.module` in modules/aggregations/shell/default.nix). It owns the look
# only: the waybar stylesheet and composition, and the palette the Stylix
# colours follow. Whether waybar runs, whether rofi is installed, which systemd
# target the bar rides are the slots' and the dendrites'.
#
# It is NOT an Aoide rice and is never performed by `habit.rice`: a built-in
# rice requires Aoide's strillix runtime (lib/rices.nix, modules/nucleus/
# assertions.nix), and yomi-strix runs none. The look is therefore a module
# of its own, applied wherever the shell is selected.
#
# ── What transience owns ────────────────────────────────────────────────────
# waybar     the stylesheet (source/waybar.css) and the bar's composition.
# palette    palette.nix is the source; theme.json is generated from it in
#            Aoide's v0 theme schema for `strx theme lint`. Rosé Pine.
# rofi, wlogout  nothing bespoke: both take the base16 scheme through Stylix.
# the dock   nothing: dxflake ships no dock.
#
# The stylesheet is a template with `{{base16.baseXX}}` placeholders, filled
# from `config.lib.stylix.colors` at build time, so a host whose palette Aoide's
# stylix lane repaints is repainted too. `modules/dendrites/stylix.nix` and
# this file both read palette.nix.
{
  config,
  lib,
  pkgs,
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
  sinkChanger = pkgs.writeShellApplication {
    name = "sink-changer";
    runtimeInputs = with pkgs; [
      wireplumber
      dunst
      gnugrep
      coreutils
    ];
    text = builtins.readFile ./source/sink_changer.sh;
  };
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
          "on-click-right" = "${sinkChanger}/bin/sink-changer";
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
}
