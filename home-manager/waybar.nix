{
  config,
  lib,
  pkgs,
  ...
}: let
  palette = config.colorScheme.palette;
in {
  programs.waybar = {
    enable = true;
    systemd = {
      enable = false; # disable it,autostart it in hyprland conf
      target = "graphical-session.target";
    };
    style = ''
      * {
      font-family: "Lekton Nerd Font Mono";
      font-size: 16;
      border-radius: 0px;
      transition-property: background-color;
      transition-duration: 0.5s;
      }
      @keyframes blink_red {
      to {
      background-color: rgb(242, 143, 173);
      color: rgb(26, 24, 38);
      }
      }
      .warning, .critical, .urgent {
      animation-name: blink_red;
      animation-duration: 1s;
      animation-timing-function: linear;
      animation-iteration-count: infinite;
      animation-direction: alternate;
      }
      window#waybar {
      background-color: transparent;
      }
      window > box {
      background-color: #${palette.base00};
      }
      #workspaces {
      padding-left: 0px;
      padding-right: 4px;
      }
      #workspaces button {
      padding-top: 5px;
      padding-bottom: 5px;
      padding-left: 6px;
      padding-right: 6px;
      color:#${palette.base07};
      }
      #workspaces button.active {
      background-color: #${palette.base07};
      color: #${palette.base00};
      }
      #workspaces button.urgent {
      color: rgb(26, 24, 38);
      }
      #workspaces button:hover {
      background-color:#${palette.base06};
      color: #${palette.base01};
      }
      tooltip {
      background: #${palette.base00};
      }
      tooltip label {
      color: #${palette.base07};
      }
      #custom-rofi {
      font-size: 20px;
      padding-left: 8px;
      padding-right: 8px;
      color: #${palette.base07};
      }
      #mode, #clock, #memory, #temperature,#cpu, #temperature, #backlight,#wireplumber, #network, #battery, #custom-powermenu {
      padding-left: 5px;
      padding-right: 8px;
      }
      #mpris {
      padding-left: 5px;
      padding-right: 0px;
      }
      #memory {
      color: #${palette.base0B};
      }
      #cpu {
      color: #${palette.base0C};
      }
      #clock {
      color: #${palette.base07};
      }
      #window{
        color: #${palette.base0B};
        font-style: italic;
      }
      #custom-wall {
      color: #B38DAC;
      }
      #temperature {
      color: #${palette.base09};
      }
      #backlight {
      color: #A2BD8B;
      }
      #mpris {
      color: #${palette.base0B};
      }
      #wireplumber {
      color: #${palette.base08};
      }
      #network {
      color: #${palette.base07};
      }

      #network.disconnected {
      color: #CCCCCC;
      }
      #battery.charging, #battery.full, #battery.discharging {
      color: #CF876F;
      }
      #battery.critical:not(.charging) {
      color: #D6DCE7;
      }
      #custom-powermenu {
      color: #${palette.base0B};
      }
      #tray {
      padding-right: 5px;
      padding-left: 10px;
      }
      #tray menu {
      background: #${palette.base00};
      color: #${palette.base07};
      }
    '';
    settings = [
      {
        "layer" = "top";
        "position" = "top";
        modules-left = [
          "custom/rofi"
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
          "backlight"
          #"memory"
          #"cpu"
          "network"
          #"temperature"
          "battery"
          "tray"
          "custom/powermenu"
        ];
        "custom/rofi" = {
          "format" = "𝄞";
          #"on-click" = "pkill rofi || ~/.config/rofi/rofi.sh";
          "on-click" = "rofi -show window";
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
            "5" = "𝅗𝅥";
            "6" = "𝅘𝅥𝅱  ";
            "7" = "♯";
            "8" = "♮";
            "9" = "♭";
            "10" = "𝅝  ";
            sort-by-number = false;
          };
          "on-click" = "activate";
          "on-scroll-up" = "hyprctl dispatch workspace e+1";
          "on-scroll-down" = "hyprctl dispatch workspace e-1";
        };
        "backlight" = {
          "device" = "intel_backlight";
          "on-scroll-up" = "light -A 5";
          "on-scroll-down" = "light -U 5";
          "format" = "{icon} {percent}%";
          "format-icons" = [
            "○"
            "◎"
            "●"
          ];
        };
        "mpris" = {
          "format" = "♪【{artist} - {title}】";
          "format-paused" = "・【{artist} - {title}】";
        };
        "wireplumber" = {
          "scroll-step" = 2;
          "format" = "{icon} {volume}%";
          "format-muted" = "(° × ° )";
          "format-icons" = {
            "default" = [
              "♩~"
              "♪~"
              "♫~"
            ];
          };
          "on-click" = "pavucontrol";
          "tooltip" = true;
        };
        "battery" = {
          "interval" = 10;
          "states" = {
            "warning" = 20;
            "critical" = 10;
          };
          "format" = "{icon} {capacity}%";
          "format-icons" = [
            "󰁺"
            "󰁻"
            "󰁼"
            "󰁽"
            "󰁾"
            "󰁿"
            "󰂀"
            "󰂁"
            "󰂂"
            "󰁹"
          ];
          "format-full" = "{icon} {capacity}%";
          "format-charging" = "┫ {capacity}%";
          "tooltip" = false;
        };
        "clock" = {
          "interval" = 1;
          "format" = "{:%I:%M %p  %A %b %d}";
          "tooltip" = true;
          "tooltip-format" = "<tt>{calendar}</tt>";
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
          "format-disconnected" = "Disconnected :c";
          "format-ethernet" = "𝆺𝅥𝅯";
          "format-linked" = "𝆹𝅥𝅯 (No IP)";
          "format-wifi" = "𝆹𝅥𝅮";
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
        "custom/powermenu" = {
          "format" = "𓏲𝄢";
          "on-click" = "wlogout";
          "tooltip" = false;
        };
        "tray" = {
          "icon-size" = 15;
          "spacing" = 5;
        };
      }
    ];
  };
}
