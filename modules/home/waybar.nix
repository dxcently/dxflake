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
      font-family: "Lekton Nerd Font";
      font-size: 16;
      border-radius: 0px;
      transition-property: background-color;
      transition-duration: 0.5s;
      }
      @keyframes blink_red {
      to {
      background-color: #CDB3C1;
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
      background-color: transparent;
      border-bottom: 1px solid black;
      }
      #workspaces {
      padding-left: 0px;
      padding-right: 4px;
      }
      #workspaces button {
      padding-top: 4px;
      padding-bottom: 3px;
      padding-left: 6px;
      padding-right: 6px;
      color:#${palette.base00};
      }
      #workspaces button.active {
      background: radial-gradient( 40px circle at top left, rgba(255, 255, 255, 0.7), rgba(255,255,255, 0) ), transparent;
      border: 1px solid black;
      color: #${palette.base00};
      }
      #workspaces button.urgent {
      color: rgb(26, 24, 38);
      }
      #workspaces button:hover {
      background-color:#${palette.base0B};
      color: #${palette.base0A};
      }
      tooltip {
      background: white;
      border: 1px solid black;
      border-radius: 0px;
      }
      tooltip label {
      color: #${palette.base00};
      }
      #custom-rofi {
      font-size: 20px;
      padding-left: 8px;
      padding-right: 8px;
      color: #${palette.base00};
      }
      #mode, #clock, #backlight, #wireplumber, #network, #battery, #custom-powermenu {
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
      color: #${palette.base00};
      font-weight: 600;
      }
      #window {
        color: #${palette.base08};
        font-style: italic;
      }
      #custom-wall {
      color: #B38DAC;
      }
      #temperature {
      color: #${palette.base09};
      }
      #backlight {
      color: #${palette.base08};
      }
      #mpris {
      color: #${palette.base08};
      }
      #wireplumber {
      color: #${palette.base08};
      }
      #network {
      color: #${palette.base0F};
      }

      #network.disconnected {
      color: #CCCCCC;
      }
      #battery.charging, #battery.full, #battery.discharging {
      color: #${palette.base08};
      }
      #battery.critical:not(.charging) {
      color: #D6DCE7;
      }
      #custom-powermenu {
      color: white;
      font-size: 20px;
      padding-left: 8px;
      padding-right: 8px;
      text-shadow: 0px 0px 2px black;
      }
      #tray {
      padding-right: 5px;
      padding-left: 10px;
      }
      #tray menu {
      background: white;
      border: 1px solid black;
      border-radius: 0px;
      color: black;
      }
    '';
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
            "5" = "𝅗𝅥 ";
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
          "format-paused" = "⏸ [{artist} - {title}]";
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
              "months" = "<span color='#${palette.base08}'><b>{}</b></span>";
              "days" = "<span color='#${palette.base00}'><b>{}</b></span>";
              "weeks" = "<span color='#${palette.base08}'><b>W{}</b></span>";
              "weekdays" = "<span color='#${palette.base0A}'><b>{}</b></span>";
              "today" = "<span color='#${palette.base0B}'><b><u>{}</u></b></span>";
            };
          };
          "on-click" = "kitty calcure";
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
        "tray" = {
          "icon-size" = 15;
          "spacing" = 5;
        };
        */
      }
    ];
  };
}
