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
      font-size: 15px;
      font-weight: bold;
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
      /* background: rgb(250, 244, 252); */
      background: #${palette.base00};
      }
      tooltip label {
      color: #${palette.base07};
      }
      #custom-launcher {
      font-size: 20px;
      padding-left: 8px;
      padding-right: 8px;
      color: #${palette.base07};
      }
      #mode, #clock, #memory, #temperature,#cpu,#custom-wall, #temperature, #backlight,#wireplumber, #network, #battery, #custom-powermenu, #custom-cava-internal {
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
      color: #${palette.base0A};
      }
      #tray {
      padding-right: 5px;
      padding-left: 10px;
      }
      #tray menu {
      background: #${palette.base00};
      color: #${palette.base07};
      }
      #custom-cava-internal{
      font-family: "Hack Nerd Font" ;
      }
    '';
    settings = [
      {
        "layer" = "top";
        "position" = "top";
        modules-left = [
          "custom/launcher"
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
        "custom/launcher" = {
          "format" = "𝄞";
          #"on-click" = "pkill rofi || ~/.config/rofi/launcher.sh";
          "tooltip" = false;
        };
        "hyprland/window" = {
          max-length = 25;
          separate-outputs = false;
          rewrite = {
            "" = "/ᐠ - ˕ -マ Ⳋ ⋆｡°✩♬ ♪";
          };
        };
        /*
        "custom/wall" = {
          "on-click" = ${sharedScripts.wallpaper_random}/bin/wallpaper_random";
          "on-click-middle" = "${sharedScripts.default_wall}/bin/default_wall";
          "on-click-right" = killall dynamic_wallpaper || ${sharedScripts.dynamic_wallpaper}/bin/dynamic_wallpaper &";
          "format" = " 󰠖 ";
          "tooltip" = false;
        };
        */
        "custom/cava-internal" = {
          "exec" = ""; # "sleep 1s && ${sharedScripts.cava-internal}/bin/cava-internal";
          "tooltip" = false;
        };
        "hyprland/workspaces" = {
          "format" = "♪";
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
            "☆"
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
        /*
        "mpd" = {
          "max-length" = 25;
          "format" = "<span foreground='#bb9af7'></span> {title}";
          "format-paused" = " {title}";
          "format-stopped" = "<span foreground='#bb9af7'></span>";
          "format-disconnected" = "";
          "on-click" = "mpc --quiet toggle";
          "on-click-right" = "mpc update; mpc ls | mpc add";
          "on-click-middle" = "kitty --class='ncmpcpp' ncmpcpp";
          "on-scroll-up" = "mpc --quiet prev";
          "on-scroll-down" = "mpc --quiet next";
          "smooth-scrolling-threshold" = 5;
          "tooltip-format" = "{title} - {artist} ({elapsedTime:%M:%S}/{totalTime:%H:%M:%S})";
        };
        */
        "network" = {
          "format-disconnected" = "Disconnected :c";
          "format-ethernet" = "𖤣.𖥧.𖡼.⚘";
          "format-linked" = "󰖪 (No IP)";
          "format-wifi" = "♬⋆.˚";
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
